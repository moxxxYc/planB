import { describe, expect, it } from 'vitest';
import { raceDefs } from '../data/races';
import { rewardDefs } from '../data/rewards';
import { decisionSlotDefs, slotDefs } from '../data/slots';
import { unitDefs } from '../data/units';
import { createInitialGameState } from './GameState';
import { triggerSlot } from './SlotTriggerSystem';
import { getBattleFrontlineRatio, getBattleLaneOffset, spawnBattleUnit, updateBattle } from './BattleSystem';
import { applyReward, buildRewardChoices } from './RewardSystem';
import { completePhase, resumeNextPhase, startPhase, updatePhaseEnemySpawns } from './PhaseSystem';
import {
  buildLaunchSplitRelaunchPlan,
  getControlledGateBounceVelocity,
  getLauncherVelocity,
  getSweepingLauncherAngle,
} from './PinballMachineSystem';
import { addToSpawnQueue, updateSpawnQueue } from './SpawnQueueSystem';
import {
  addUnitSlotProgress,
  getCurrentRaceUnitSlotStates,
  getUnitGateState,
  getUnitGateOpenBoundaryRatio,
  getUnlockedUnitSlotCount,
  resolveUnitBallToSlot,
} from './UnitSpawnProgressSystem';
import {
  buildBattleHeatBands,
  clampBattleCameraCenter,
  getBattleCameraViewport,
  getBattleHotspotCameraCenter,
  getBattleHotspotRatio,
  getNextBattleCameraCenter,
  getPannedBattleCameraCenter,
  projectBattlePoint,
} from './BattlefieldViewSystem';

describe('slot trigger rules', () => {
  it('does not expose a charge slot or charge rewards', () => {
    expect(slotDefs.map((slot) => slot.id)).toEqual(['spawn', 'gold', 'magic', 'upgrade', 'special']);
    expect(rewardDefs.some((reward) => reward.id.includes('charge'))).toBe(false);
    expect(rewardDefs.some((reward) => reward.description.includes('蓄力') || reward.description.includes('CHARGE'))).toBe(false);
  });

  it('presents decision slots without SPECIAL and keeps SPAWN in the middle', () => {
    const decisionIds = decisionSlotDefs.map((slot) => slot.id);

    expect(decisionIds).toEqual(['gold', 'magic', 'spawn', 'upgrade']);
    expect(decisionIds).not.toContain('special');
    expect(Math.abs(decisionIds.indexOf('spawn') - (decisionIds.length - 1) / 2)).toBeLessThanOrEqual(0.5);
  });

  it('SPAWN records the decision outcome without directly queueing random units', () => {
    const state = createInitialGameState('hive', 7);

    triggerSlot(state, 'spawn');

    expect(state.spawnQueue.some((unit) => unit.side === 'player')).toBe(false);
    expect(state.stats.currentPhase.slotTriggers.spawn).toBe(1);
    expect(state.stats.currentPhase.unitsQueued).toBe(0);
  });

  it('UP strengthens later spawns and GOLD gives currency', () => {
    const state = createInitialGameState('mech', 2);

    triggerSlot(state, 'upgrade');
    triggerSlot(state, 'gold');
    triggerSlot(state, 'spawn');
    resolveUnitBallToSlot(state, 0, 1, { elapsedMs: 0, durationMs: 60000 });

    const queuedUnit = state.spawnQueue.find((unit) => unit.side === 'player');
    expect(queuedUnit?.level).toBeGreaterThan(1);
    expect(state.gold).toBeGreaterThan(0);
    expect(state.pendingSpawnLevelBonus).toBe(0);
  });

  it('MAGIC damages enemies without touching reserve queues', () => {
    const state = createInitialGameState('hive', 4);
    state.battle.units.push({
      id: 'enemy-test',
      defId: 'enemy_raider',
      side: 'enemy',
      hp: 38,
      maxHp: 38,
      damage: 5,
      x: 640,
      battleLane: 'middle',
      laneOffset: 0,
      attackTimerMs: 0,
      level: 1,
      lifetime: 'standard',
      isElite: false,
      veterancyXp: 0,
      veterancyLevel: 0,
      phaseSpawned: 0,
      tags: [],
      damageDone: 0,
      kills: 0,
      burstUntilMs: 0,
      spawnedAtMs: 0,
      lastAttackAtMs: -9999,
      lastHitAtMs: -9999,
    });

    triggerSlot(state, 'magic');
    const damagedEnemy = state.battle.units.find((unit) => unit.id === 'enemy-test');
    expect(damagedEnemy?.hp).toBeLessThan(38);
    expect(state.spawnQueue).toHaveLength(0);
  });
});

describe('pinball machine rules', () => {
  it('sweeps the launch turret across a deterministic 180 degree arc', () => {
    expect(getSweepingLauncherAngle(0, 2400)).toBe(-90);
    expect(getSweepingLauncherAngle(600, 2400)).toBe(0);
    expect(getSweepingLauncherAngle(1200, 2400)).toBe(90);
    expect(getSweepingLauncherAngle(1800, 2400)).toBe(0);
    expect(getSweepingLauncherAngle(2400, 2400)).toBe(-90);
  });

  it('converts the launch turret angle into non-random launch velocity', () => {
    expect(getLauncherVelocity(600, 2400, 3)).toEqual({ vx: 0, vy: 3 });
    expect(getLauncherVelocity(0, 2400, 3).vx).toBeCloseTo(-3, 5);
    expect(getLauncherVelocity(1200, 2400, 3).vx).toBeCloseTo(3, 5);
  });

  it('keeps split launch balls inside the launch zone instead of sending them to decision', () => {
    expect(buildLaunchSplitRelaunchPlan(2)).toEqual([
      { stage: 'launch', value: 2 },
      { stage: 'launch', value: 2 },
    ]);
  });

  it('caps high-tier blocker bounce velocity so repeated hits do not inject runaway energy', () => {
    expect(getControlledGateBounceVelocity({ vx: 22, vy: -31 })).toEqual({ vx: 4.8, vy: -5.2 });
    expect(getControlledGateBounceVelocity({ vx: -14, vy: 28 })).toEqual({ vx: -4.8, vy: -5.2 });
    expect(getControlledGateBounceVelocity({ vx: 1.5, vy: -2 })).toEqual({ vx: 1.5, vy: -5.2 });
  });
});

describe('unit spawn progress rules', () => {
  it('stores race unit slots as data-driven state with requirements and progress', () => {
    const state = createInitialGameState('hive', 12);

    const slots = getCurrentRaceUnitSlotStates(state);

    expect(slots.map((slot) => ({
      index: slot.index,
      unitId: slot.unitId,
      requirement: slot.requirement,
      progress: slot.progress,
    }))).toEqual([
      { index: 0, unitId: 'hive_grub', requirement: 1, progress: 0 },
      { index: 1, unitId: 'hive_spitter', requirement: 3, progress: 0 },
      { index: 2, unitId: 'hive_carapace', requirement: 5, progress: 0 },
      { index: 3, unitId: 'hive_brood_guard', requirement: 7, progress: 0 },
      { index: 4, unitId: 'hive_behemoth', requirement: 9, progress: 0 },
    ]);
  });

  it('spawns a specific unit from slot progress and preserves overflow progress', () => {
    const state = createInitialGameState('hive', 13);
    const slot = raceDefs.hive.unitSlots[1];

    addUnitSlotProgress(state, slot.unitId, 2);
    expect(getCurrentRaceUnitSlotStates(state)[1].progress).toBe(2);
    expect(state.spawnQueue).toHaveLength(0);

    addUnitSlotProgress(state, slot.unitId, 2);

    expect(state.spawnQueue.some((unit) => unit.unitId === slot.unitId && unit.side === 'player')).toBe(true);
    expect(getCurrentRaceUnitSlotStates(state)[1].progress).toBe(1);
  });

  it('opens the single unit gate continuously across the first half of the phase', () => {
    const state = createInitialGameState('mech', 17);
    const durationMs = 60000;
    const startGate = getUnitGateState(0, durationMs);
    const barelyOpenGate = getUnitGateState(1000, durationMs);
    const quarterGate = getUnitGateState(durationMs * 0.25, durationMs);
    const halfGate = getUnitGateState(durationMs * 0.5, durationMs);

    expect(getUnlockedUnitSlotCount(state, 0, durationMs)).toBe(1);
    expect(startGate.openUnitIndex).toBe(0);
    expect(startGate.openSlotCount).toBe(1);
    expect(getUnitGateOpenBoundaryRatio(0, durationMs)).toBe(0.2);
    expect(barelyOpenGate.openUnitIndex).toBe(1);
    expect(barelyOpenGate.openSlotCount).toBe(2);
    expect(quarterGate.openUnitIndex).toBeGreaterThan(0);
    expect(quarterGate.openUnitIndex).toBeLessThan(4);
    expect(getUnitGateOpenBoundaryRatio(durationMs * 0.25, durationMs)).toBeGreaterThan(0.2);
    expect(getUnitGateOpenBoundaryRatio(durationMs * 0.25, durationMs)).toBeLessThan(1);
    expect(getUnitGateOpenBoundaryRatio(durationMs * 0.5, durationMs)).toBe(1);
    expect(halfGate.openUnitIndex).toBe(4);
    expect(halfGate.openSlotCount).toBe(5);
    expect(getUnitGateOpenBoundaryRatio(durationMs * 0.8, durationMs)).toBe(1);
    expect(getUnlockedUnitSlotCount(state, durationMs * 0.5, durationMs)).toBe(5);
  });

  it('counts a ball as valid when it lands in a partially open unit slot', () => {
    const state = createInitialGameState('mech', 22);
    const gunnerSlot = raceDefs.mech.unitSlots[1];

    const result = resolveUnitBallToSlot(state, 1, 1, {
      elapsedMs: 1000,
      durationMs: 60000,
    });

    expect(result.status).toBe('resolved');
    expect(getCurrentRaceUnitSlotStates(state)[1]).toMatchObject({
      unitId: gunnerSlot.unitId,
      progress: 1,
    });
  });

  it('increments progress when a unit ball lands in an open slot', () => {
    const state = createInitialGameState('mech', 21);
    const gunnerSlot = raceDefs.mech.unitSlots[1];

    const result = resolveUnitBallToSlot(state, 1, 2, {
      elapsedMs: 30000,
      durationMs: 60000,
    });

    expect(result.status).toBe('resolved');
    expect(getCurrentRaceUnitSlotStates(state)[1]).toMatchObject({
      unitId: gunnerSlot.unitId,
      progress: 2,
    });
  });

  it('blocks covered high-tier slots without adding progress', () => {
    const state = createInitialGameState('mech', 23);
    const titanSlot = raceDefs.mech.unitSlots[4];

    const result = resolveUnitBallToSlot(state, 4, 1, {
      elapsedMs: 0,
      durationMs: 60000,
      blockedGateHits: 0,
    });

    expect(result.status).toBe('blocked');
    if (result.status !== 'blocked') throw new Error('Expected covered slot to block the unit ball');
    expect(result.redirectSlotIndex).toBe(0);
    expect(result.blockedGateHits).toBe(1);
    expect(getCurrentRaceUnitSlotStates(state)[4]).toMatchObject({
      unitId: titanSlot.unitId,
      progress: 0,
    });
    expect(state.spawnQueue.some((unit) => unit.unitId === titanSlot.unitId)).toBe(false);
  });
});

describe('battle simulation', () => {
  it('defines lane weights and aggro ranges for every battle unit', () => {
    for (const unit of Object.values(unitDefs)) {
      expect(unit.aggroRange).toBeGreaterThanOrEqual(unit.attackRange);
      expect(unit.laneWeights.top + unit.laneWeights.middle + unit.laneWeights.bottom).toBeGreaterThan(0);
    }
    expect(unitDefs.hive_grub.laneWeights.middle).toBeGreaterThan(0);
    expect(unitDefs.hive_behemoth.laneWeights.middle).toBeGreaterThan(unitDefs.hive_behemoth.laneWeights.top);
    expect(unitDefs.mech_gunner.aggroRange).toBeGreaterThan(unitDefs.mech_gunner.attackRange);
  });

  it('assigns a deterministic soft battle lane when units spawn', () => {
    const first = createInitialGameState('hive', 101);
    const second = createInitialGameState('hive', 101);

    const firstUnits = Array.from({ length: 8 }, () => spawnBattleUnit(first, 'player', 'hive_grub').battleLane);
    const secondUnits = Array.from({ length: 8 }, () => spawnBattleUnit(second, 'player', 'hive_grub').battleLane);

    expect(firstUnits).toEqual(secondUnits);
    expect(new Set(firstUnits).size).toBeGreaterThan(1);

    const behemoth = spawnBattleUnit(createInitialGameState('hive', 12), 'player', 'hive_behemoth');
    expect(['top', 'middle', 'bottom']).toContain(behemoth.battleLane);
  });

  it('uses broad deterministic lane offsets for the central 3/4 battlefield', () => {
    expect(getBattleLaneOffset('top', 0)).toBe(-74);
    expect(getBattleLaneOffset('middle', 0)).toBe(0);
    expect(getBattleLaneOffset('bottom', 0)).toBe(74);
    expect(getBattleLaneOffset('top', -12)).toBe(-86);
    expect(getBattleLaneOffset('bottom', 12)).toBe(86);
  });

  it('reports a deterministic frontline ratio from opposing lane pressure', () => {
    const state = createInitialGameState('mech', 10);
    const player = spawnBattleUnit(state, 'player', 'mech_drone');
    const enemy = spawnBattleUnit(state, 'enemy', 'enemy_raider');
    player.x = 360;
    enemy.x = 520;

    expect(getBattleFrontlineRatio(state)).toBeCloseTo(0.23125, 5);

    player.x = 600;
    expect(getBattleFrontlineRatio(state)).toBeGreaterThan(0.3);

    state.battle.units = state.battle.units.filter((unit) => unit.side === 'player');
    expect(getBattleFrontlineRatio(state)).toBeGreaterThan(0.3);
  });

  it('emits readable combat feedback events for attacks and deaths', () => {
    const state = createInitialGameState('hive', 14);
    const attacker = spawnBattleUnit(state, 'player', 'hive_spitter');
    const target = spawnBattleUnit(state, 'enemy', 'enemy_raider');
    attacker.x = 410;
    target.x = 456;
    target.hp = 6;

    updateBattle(state, 120);

    expect(state.battle.projectiles).toHaveLength(1);
    expect(state.battle.projectiles[0]).toMatchObject({
      side: 'player',
      fromUnitId: attacker.id,
      toUnitId: target.id,
      color: 0x60a5fa,
    });
    expect(state.battle.transientEffects).toEqual(expect.arrayContaining([
      expect.objectContaining({ type: 'hit', side: 'player', unitId: target.id }),
      expect.objectContaining({ type: 'death', side: 'enemy', unitId: target.id }),
    ]));
    expect(target.lastHitAtMs).toBe(state.battle.elapsedMs);
    expect(attacker.lastAttackAtMs).toBe(state.battle.elapsedMs);
  });

  it('uses aggro range and lane distance when choosing targets', () => {
    const state = createInitialGameState('mech', 202);
    const attacker = spawnBattleUnit(state, 'player', 'mech_gunner');
    const sameLane = spawnBattleUnit(state, 'enemy', 'enemy_raider');
    const nearOtherLane = spawnBattleUnit(state, 'enemy', 'enemy_raider');
    attacker.x = 400;
    attacker.battleLane = 'middle';
    attacker.laneOffset = 0;
    sameLane.x = 450;
    sameLane.battleLane = 'middle';
    sameLane.laneOffset = 0;
    sameLane.hp = 30;
    nearOtherLane.x = 420;
    nearOtherLane.battleLane = 'top';
    nearOtherLane.laneOffset = -74;
    nearOtherLane.hp = 30;

    updateBattle(state, 100);

    expect(sameLane.hp).toBeLessThan(30);
    expect(nearOtherLane.hp).toBe(30);
  });

  it('units move, attack, die, and damage bases deterministically', () => {
    const state = createInitialGameState('mech', 11);
    startPhase(state);
    triggerSlot(state, 'spawn');
    resolveUnitBallToSlot(state, 0, 1, { elapsedMs: 0, durationMs: 60000 });
    updateSpawnQueue(state, 1000);
    const playerUnit = state.battle.units.find((unit) => unit.side === 'player');
    if (!playerUnit) throw new Error('Expected queued player unit to deploy');
    playerUnit.battleLane = 'middle';
    playerUnit.laneOffset = 0;
    state.battle.units.push({
      id: 'enemy-target',
      defId: 'enemy_raider',
      side: 'enemy',
      hp: 18,
      maxHp: 18,
      damage: 5,
      x: 665,
      battleLane: 'middle',
      laneOffset: 0,
      attackTimerMs: 0,
      level: 1,
      lifetime: 'standard',
      isElite: false,
      veterancyXp: 0,
      veterancyLevel: 0,
      phaseSpawned: 0,
      tags: [],
      damageDone: 0,
      kills: 0,
      burstUntilMs: 0,
      spawnedAtMs: 0,
      lastAttackAtMs: -9999,
      lastHitAtMs: -9999,
    });

    for (let step = 0; step < 250; step += 1) {
      updateBattle(state, 100);
    }

    expect(state.stats.currentPhase.damageDealt).toBeGreaterThan(0);
    expect(state.stats.currentPhase.kills + state.stats.currentPhase.enemyBaseDamage).toBeGreaterThan(0);
  });
});

describe('battlefield view rules', () => {
  it('clamps camera viewport inside the long battle axis', () => {
    expect(clampBattleCameraCenter(0, 70, 1670, 640)).toBe(390);
    expect(clampBattleCameraCenter(1700, 70, 1670, 640)).toBe(1350);
    expect(getBattleCameraViewport(710, 70, 1670, 640)).toEqual({ startX: 390, endX: 1030, width: 640 });
  });

  it('does not auto-follow the frontline after the player takes manual camera control', () => {
    const nextCenter = getNextBattleCameraCenter({
      currentCenterX: 390,
      hotspotRatio: 0.8,
      playerBaseX: 70,
      enemyBaseX: 1670,
      viewportWorldWidth: 640,
      deltaMs: 16000,
      manualOverride: true,
    });

    expect(nextCenter).toBe(390);
  });

  it('snaps the camera back to the frontline hotspot when follow is restored', () => {
    const nextCenter = getBattleHotspotCameraCenter({
      hotspotRatio: 0.8,
      playerBaseX: 70,
      enemyBaseX: 1670,
      viewportWorldWidth: 640,
    });

    expect(nextCenter).toBe(1350);
  });

  it('pans the camera when the player drags the battlefield view', () => {
    const nextCenter = getPannedBattleCameraCenter({
      startCenterX: 710,
      pointerDeltaX: -120,
      screenPixelWidth: 810,
      playerBaseX: 70,
      enemyBaseX: 1670,
      viewportWorldWidth: 640,
    });

    expect(nextCenter).toBeGreaterThan(710);
  });

  it('projects world points relative to camera center', () => {
    const center = projectBattlePoint({
      worldX: 710,
      laneOffset: 0,
      cameraCenterX: 710,
      playerBaseX: 70,
      enemyBaseX: 1670,
      screenStart: { x: 170, y: 620 },
      screenEnd: { x: 1110, y: 260 },
      viewportWorldWidth: 640,
    });
    const right = projectBattlePoint({
      worldX: 1030,
      laneOffset: 0,
      cameraCenterX: 710,
      playerBaseX: 70,
      enemyBaseX: 1670,
      screenStart: { x: 170, y: 620 },
      screenEnd: { x: 1110, y: 260 },
      viewportWorldWidth: 640,
    });

    expect(center.x).toBeCloseTo(640, 0);
    expect(right.x).toBeGreaterThan(center.x);
  });

  it('marks points outside the camera viewport by visible ratio', () => {
    const left = projectBattlePoint({
      worldX: 200,
      laneOffset: 0,
      cameraCenterX: 710,
      playerBaseX: 70,
      enemyBaseX: 1670,
      screenStart: { x: 170, y: 620 },
      screenEnd: { x: 1110, y: 260 },
      viewportWorldWidth: 640,
    });

    expect(left.visibleRatio).toBeLessThan(0);
  });

  it('builds minimap heat bands and hotspot ratio from live units', () => {
    const state = createInitialGameState('hive', 303);
    const player = spawnBattleUnit(state, 'player', 'hive_grub');
    const enemy = spawnBattleUnit(state, 'enemy', 'enemy_raider');
    player.x = 700;
    enemy.x = 730;

    const bands = buildBattleHeatBands(state.battle.units, state.battle.bases.player.x, state.battle.bases.enemy.x, 12);
    expect(bands.some((band) => band.player > 0)).toBe(true);
    expect(bands.some((band) => band.enemy > 0)).toBe(true);
    expect(getBattleHotspotRatio(state)).toBeGreaterThan(0);
  });

  it('keeps heat bands stable when there are no units', () => {
    const state = createInitialGameState('mech', 404);
    const bands = buildBattleHeatBands(state.battle.units, state.battle.bases.player.x, state.battle.bases.enemy.x, 16);

    expect(bands).toHaveLength(16);
    expect(bands.every((band) => band.player === 0 && band.enemy === 0)).toBe(true);
  });
});

describe('reward rules', () => {
  it('offers three rewards and applies machine or unit modifiers', () => {
    const state = createInitialGameState('hive', 19);

    const choices = buildRewardChoices(state);
    expect(choices).toHaveLength(3);

    applyReward(state, 'wide_spawn');

    expect(state.slots.spawn.widthWeight).toBeGreaterThan(1);
  });
});

describe('continuous phase rules', () => {
  it('spawns enemy waves on the phase timer without requiring player spawns', () => {
    const state = createInitialGameState('hive', 41);
    startPhase(state);

    const previousElapsedMs = state.phaseElapsedMs;
    updateBattle(state, 3000);
    updatePhaseEnemySpawns(state, previousElapsedMs);

    expect(state.spawnQueue).toHaveLength(0);
    expect(state.battle.units.filter((unit) => unit.side === 'player')).toHaveLength(0);
    expect(state.battle.units.filter((unit) => unit.side === 'enemy')).toHaveLength(2);
    expect(state.battle.units.every((unit) => unit.x < state.battle.bases.enemy.x - 50)).toBe(true);
  });

  it('completes a phase without clearing persistent player state', () => {
    const state = createInitialGameState('hive', 31);
    startPhase(state);
    const standard = spawnBattleUnit(state, 'player', 'hive_grub', 1, false, { lifetime: 'standard' });
    const elite = spawnBattleUnit(state, 'player', 'hive_carapace', 2, false, { lifetime: 'elite', isElite: true });
    const temporary = spawnBattleUnit(state, 'player', 'hive_spitter', 1, false, { lifetime: 'temporary', tags: ['summon'] });
    addToSpawnQueue(state, {
      unitId: 'hive_grub',
      side: 'player',
      count: 4,
      lane: 'front',
      releaseIntervalMs: 250,
      tags: ['basic'],
    });
    state.gold = 100;
    state.machineUpgrades.push({ id: 'debug_machine' });
    state.buildings.push({ id: 'debug_building' });
    state.relics.push({ id: 'debug_relic' });

    completePhase(state, 'objective');

    expect(state.isBuildPause).toBe(true);
    expect(state.phaseActive).toBe(false);
    expect(state.battle.units.some((unit) => unit.id === standard.id)).toBe(true);
    const persistedElite = state.battle.units.find((unit) => unit.id === elite.id);
    expect(persistedElite).toBeDefined();
    expect(persistedElite?.veterancyXp).toBeGreaterThan(0);
    expect(state.battle.units.some((unit) => unit.id === temporary.id)).toBe(false);
    expect(state.spawnQueue.reduce((sum, item) => sum + item.count, 0)).toBe(4);
    expect(state.gold).toBe(100);
    expect(state.machineUpgrades).toHaveLength(1);
    expect(state.buildings).toHaveLength(1);
    expect(state.relics).toHaveLength(1);
  });

  it('keeps queued units when the soft cap blocks deployment and resumes after rewards', () => {
    const state = createInitialGameState('mech', 37);
    startPhase(state);
    addToSpawnQueue(state, {
      unitId: 'mech_drone',
      side: 'player',
      count: 3,
      lane: 'mid',
      releaseIntervalMs: 100,
      tags: ['basic'],
    });
    for (let index = 0; index < state.playerStandardUnitSoftCap; index += 1) {
      spawnBattleUnit(state, 'player', 'mech_drone', 1, false, { lifetime: 'standard' });
    }

    updateSpawnQueue(state, 500);
    expect(state.spawnQueue.reduce((sum, item) => sum + item.count, 0)).toBe(3);

    completePhase(state, 'objective');
    resumeNextPhase(state, 'wide_spawn');

    expect(state.phaseIndex).toBe(1);
    expect(state.isBuildPause).toBe(false);
    expect(state.phaseActive).toBe(true);
    expect(state.selectedRewards).toContain('wide_spawn');
    expect(state.spawnQueue.reduce((sum, item) => sum + item.count, 0)).toBe(3);
  });
});
