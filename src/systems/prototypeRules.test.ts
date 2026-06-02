import { describe, expect, it } from 'vitest';
import { phaseDefs } from '../data/phases';
import { raceDefs } from '../data/races';
import { activePacingPreset } from '../data/pacing';
import { phaseToolDefs } from '../data/phaseTools';
import { rewardDefs } from '../data/rewards';
import { relicDefs } from '../data/relics';
import { doctrineTechDefs } from '../data/doctrineTechs';
import { decisionSlotDefs, slotDefs } from '../data/slots';
import { unitDefs } from '../data/units';
import { svgAssets } from '../rendering/assets';
import { createRewardDescriptionTextStyle, REWARD_CARD_DESCRIPTION_WRAP_WIDTH } from '../rendering/rewardTextLayout';
import { createDefaultPrototypeGameState, createInitialGameState } from './GameState';
import { triggerSlot } from './SlotTriggerSystem';
import { getBattleContactRatio, getBattleFrontlineRatio, getBattleLaneOffset, spawnBattleUnit, spawnDebugRaceUnit, updateBattle } from './BattleSystem';
import { applyReward, buildRewardChoices, rerollRewardChoices } from './RewardSystem';
import { completePhase, resumeNextPhase, startPhase, updatePhaseEnemySpawns } from './PhaseSystem';
import { buyPhaseTool, getPhaseToolWindowState, refreshPhaseToolStock } from './PhaseToolSystem';
import { createPhaseStats, recordLaunchOutcome } from './StatsSystem';
import {
  applyDecisionSpawnTags,
  applyTaggedLaunchMiss,
  buildTaggedSplitRelaunchPlan,
} from './BallTagSystem';
import { buildWeightedSlotLayouts } from './DecisionSlotLayoutSystem';
import {
  consumeSpawnMarkBonus,
  getAvailableUnitStructureDefs,
  getBuildingSummary,
  getUnitStructureGoldCost,
  getEffectiveUnitGateState,
  getExtraSplitBallCount,
  buyUnitStructureWithGold,
  installOrUpgradeBuilding,
  isBuildingReward,
  recordLaunchMiss,
} from './BuildingSystem';
import { applyDebugBuildPreset, debugBuildPresets } from './DebugPresetSystem';
import { buildChamberPanelSummaries, buildIdentityVisualSummary, buildPhaseTelemetrySummary, getDominantBuildChamber } from './BuildTelemetrySystem';
import * as BuildTelemetrySystem from './BuildTelemetrySystem';
import { runAllBuildProbes, runBuildProbe, runNaturalBlueprintRewardProbe, runArcaneSecondaryRuneProbe } from './BuildProbeSystem';
import { buildProbeValidationReport, formatBuildProbeValidationReport } from './BuildProbeValidationSystem';
import { buildIdentitySmokePlan } from './BuildVisualSmokeSystem';
import { buildMvpReadinessReport, formatMvpReadinessReport } from './MvpReadinessSystem';
import { buildRuntimeVisualTimingReport } from './RuntimeVisualTimingSystem';
import {
  buildRunEndSummary,
  buildRunSetupSummary,
  createPrototypeRunState,
} from './RunFlowSystem';
import {
  buildCompactHudBlocks,
  getEventFeedSlot,
  getUiDensityPlan,
  toggleBuildShopDrawerState,
  toggleDebugDrawerState,
} from './UiDensitySystem';
import { buildPrototypeLayout, buildRightAlignedButtonRow, buildTopZoneLayout } from './PrototypeLayoutSystem';
import {
  installRelic,
  isRelicReward,
  recordRelicLaunchMiss,
} from './RelicSystem';
import {
  buyDoctrineTechWithResearch,
  isDoctrineTechReward,
  recordDoctrineLaunchMiss,
  unlockDoctrineTech,
} from './DoctrineSystem';
import { getFirstSpawnAssistPlan, markFirstSpawnLoopSeen } from './FirstSpawnLoopAssistSystem';
import {
  buildLaunchOutcomeSlotLayouts,
  buildLaunchSplitRelaunchPlan,
  getControlledGateBounceVelocity,
  getLauncherVelocity,
  getSweepingLauncherAngle,
  resolveLaunchOutcomeWithSplitLimit,
} from './PinballMachineSystem';
import { addToSpawnQueue, updateSpawnQueue } from './SpawnQueueSystem';
import {
  addUnitSlotProgress,
  getCurrentRaceUnitSlotStates,
  getUnitGateState,
  getUnitGateOpenBoundaryRatio,
  getUnlockedUnitSlotCount,
  formatUnitProgressOutcomeLabel,
  resolveUnitBallToSlot,
} from './UnitSpawnProgressSystem';
import {
  buildBattleHeatBands,
  clampBattleCameraCenter,
  clampBattleProjectionToBounds,
  getBattleCameraViewport,
  getBattleHotspotCameraCenter,
  getBattleHotspotRatio,
  getNextBattleCameraCenter,
  getPannedBattleCameraCenter,
  projectBattlePoint,
} from './BattlefieldViewSystem';
import {
  GAME_SPEED_STEPS,
  cycleGameSpeed,
  getScaledDeltaMs,
  setGameSpeed,
} from './SpeedSystem';

describe('slot trigger rules', () => {
  it('does not expose a charge slot or charge rewards', () => {
    expect(slotDefs.map((slot) => slot.id)).toEqual(['spawn', 'gold', 'magic', 'upgrade', 'special']);
    expect(rewardDefs.some((reward) => reward.id.includes('charge'))).toBe(false);
    expect(rewardDefs.some((reward) => reward.description.includes('蓄力') || reward.description.includes('CHARGE'))).toBe(false);
  });

  it('presents standby slots without SPAWN or SPECIAL', () => {
    const decisionIds = decisionSlotDefs.map((slot) => slot.id);

    expect(decisionIds).toEqual(['gold', 'magic', 'upgrade']);
    expect(decisionIds).not.toContain('spawn');
    expect(decisionIds).not.toContain('special');
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

  it('skips MAGIC effects when magic is disabled without changing other slot behavior', () => {
    const state = createInitialGameState('hive', 5);
    state.settings.magicEnabled = false;
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

    const result = triggerSlot(state, 'magic');

    expect(result).toEqual({ status: 'disabled', slotId: 'magic' });
    expect(state.battle.units.find((unit) => unit.id === 'enemy-test')?.hp).toBe(38);
    expect(state.stats.currentPhase.slotTriggers.magic).toBe(0);
    expect(state.recentFloatingTexts.at(-1)?.label).toBe('法术已关闭');

    triggerSlot(state, 'gold');
    expect(state.gold).toBeGreaterThan(0);
  });
});

describe('pinball machine rules', () => {
  it('starts at normal speed and cycles through capped mouse-only speed steps', () => {
    const state = createInitialGameState('hive', 7);

    expect(state.speedMultiplier).toBe(1);
    expect(GAME_SPEED_STEPS).toEqual([1, 2, 4]);
    expect(cycleGameSpeed(state)).toBe(2);
    expect(cycleGameSpeed(state)).toBe(4);
    expect(cycleGameSpeed(state)).toBe(1);
  });

  it('clamps direct game speed changes to the supported maximum of 4x', () => {
    const state = createInitialGameState('mech', 8);

    expect(setGameSpeed(state, 3)).toBe(4);
    expect(state.speedMultiplier).toBe(4);
    expect(setGameSpeed(state, 12)).toBe(4);
    expect(state.speedMultiplier).toBe(4);
    expect(setGameSpeed(state, 0)).toBe(1);
    expect(state.speedMultiplier).toBe(1);
  });

  it('scales custom simulation delta with the selected game speed', () => {
    const state = createInitialGameState('hive', 9);

    expect(getScaledDeltaMs(state, 250)).toBe(250);
    setGameSpeed(state, 4);
    expect(getScaledDeltaMs(state, 250)).toBe(1000);
    expect(getScaledDeltaMs(state, -10)).toBe(0);
  });

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

  it('weights launch outcome slots as standby 2, split 1, spawn 2 by default', () => {
    const layouts = buildLaunchOutcomeSlotLayouts(0, 500, 0, 0);

    expect(layouts.map((slot) => slot.id)).toEqual(['standby', 'split', 'spawn']);
    expect(layouts.map((slot) => slot.plateWidth)).toEqual([200, 100, 200]);
  });

  it('converts a third split from the same original ball into spawn', () => {
    expect(resolveLaunchOutcomeWithSplitLimit('split', 0)).toEqual({
      outcome: 'split',
      nextSplitCount: 1,
      limitReached: false,
    });
    expect(resolveLaunchOutcomeWithSplitLimit('split', 1)).toEqual({
      outcome: 'split',
      nextSplitCount: 2,
      limitReached: false,
    });
    expect(resolveLaunchOutcomeWithSplitLimit('split', 2)).toEqual({
      outcome: 'spawn',
      nextSplitCount: 2,
      limitReached: true,
    });
    expect(resolveLaunchOutcomeWithSplitLimit('standby', 2)).toEqual({
      outcome: 'standby',
      nextSplitCount: 2,
      limitReached: false,
    });
  });

  it('lets a launch building add an extra split relaunch ball', () => {
    const state = createInitialGameState('hive', 61);

    installOrUpgradeBuilding(state, 'launch_splitter_rack');

    expect(getExtraSplitBallCount(state)).toBe(1);
    expect(buildLaunchSplitRelaunchPlan(2, getExtraSplitBallCount(state))).toEqual([
      { stage: 'launch', value: 2 },
      { stage: 'launch', value: 2 },
      { stage: 'launch', value: 2 },
    ]);
  });

  it('lets a recycle building turn launch misses into future spawn marks', () => {
    const state = createInitialGameState('hive', 62);

    installOrUpgradeBuilding(state, 'launch_recycle_buffer');
    recordLaunchMiss(state);

    expect(state.pendingSpawnMarks).toBe(1);
    expect(consumeSpawnMarkBonus(state, 1)).toBe(2);
    expect(state.pendingSpawnMarks).toBe(0);
  });

  it('uses ball tags to change split, miss recovery, and later spawn value', () => {
    const splitPlan = buildTaggedSplitRelaunchPlan({
      value: 2,
      tags: ['split+', 'spawn-mark'],
    });

    expect(splitPlan).toEqual([
      { stage: 'launch', value: 2, tags: ['spawn-mark'] },
      { stage: 'launch', value: 2, tags: ['spawn-mark'] },
      { stage: 'launch', value: 2, tags: ['spawn-mark'] },
    ]);

    const recycle = createInitialGameState('hive', 66);
    const recovered = applyTaggedLaunchMiss(recycle, {
      value: 2,
      tags: ['recycle'],
    });
    expect(recovered).toBe(2);
    expect(recycle.pendingSpawnMarks).toBe(2);
    expect(recycle.stats.currentPhase.spawnMarksCreated).toBe(2);

    const spawn = createInitialGameState('hive', 67);
    const taggedSpawn = applyDecisionSpawnTags(spawn, {
      value: 1,
      tags: ['spawn-mark', 'copy-mark', 'heavy'],
    });
    expect(taggedSpawn).toEqual({ value: 3, tags: [] });
    expect(spawn.modifiers.pendingSpawnCopies).toBe(1);
    expect(spawn.stats.currentPhase.spawnCopiesCreated).toBe(1);
    expect(spawn.stats.currentPhase.nonSpawnRecoveryEvents).toBe(1);
  });

  it('caps high-tier blocker bounce velocity so repeated hits do not inject runaway energy', () => {
    expect(getControlledGateBounceVelocity({ vx: 22, vy: -31 })).toEqual({ vx: 4.8, vy: -5.2 });
    expect(getControlledGateBounceVelocity({ vx: -14, vy: 28 })).toEqual({ vx: -4.8, vy: -5.2 });
    expect(getControlledGateBounceVelocity({ vx: 1.5, vy: -2 })).toEqual({ vx: 1.5, vy: -5.2 });
  });
});

describe('unit spawn progress rules', () => {
  describe('arcane secondary rune state', () => {
    it('starts the playable prototype with Arcane secondary visible in the HUD', () => {
      const state = createDefaultPrototypeGameState();
      const blocks = buildCompactHudBlocks(state);
      const secondaryBlock = blocks.find((block) => block.label === '副族');
      const nextSpawnBlock = blocks.find((block) => block.label === '下次出兵');

      expect(state.currentRaceId).toBe('hive');
      expect(state.secondaryRaceId).toBe('arcane');
      expect(secondaryBlock).toMatchObject({
        value: '秘仪议会',
        detail: 'Rune 0/5',
      });
      expect(nextSpawnBlock?.value).toContain('Rune 0/5');
    });

    it('keeps Arcane secondary separate from the Hive or Mech main race', () => {
      const state = createInitialGameState('hive', 201, { secondaryRaceId: 'arcane' });

      expect(state.currentRaceId).toBe('hive');
      expect(state.secondaryRaceId).toBe('arcane');
      expect(Object.keys(state.unitSlotStates)).toEqual(['hive', 'mech']);
      expect(state.arcaneRune).toMatchObject({
        current: 0,
        cap: 5,
        totalGenerated: 0,
        totalSpent: 0,
        totalProgressGranted: 0,
        cappedHits: 0,
        noSocketTriggers: 0,
        socketChargeProgress: 0,
      });
    });

    it('does not activate Arcane secondary by default', () => {
      const state = createInitialGameState('mech', 202);

      expect(state.currentRaceId).toBe('mech');
      expect(state.secondaryRaceId).toBeUndefined();
      expect(state.arcaneRune.current).toBe(0);
      expect(state.arcaneRune.cap).toBe(5);
    });
  });

  describe('secondary race data', () => {
    it('defines Arcane as a support package, not as a second full race', async () => {
      const { secondaryRaceDefs } = await import('../data/secondaryRaces');
      const arcane = secondaryRaceDefs.arcane;

      expect(arcane.id).toBe('arcane');
      expect(arcane.name).toBe('秘仪议会');
      expect(arcane.supportUnits.map((unit) => unit.id)).toEqual(['arcane_rune_acolyte', 'arcane_refraction_guard']);
      expect(arcane.coreTrait.id).toBe('rune_conversion');
      expect(arcane.machineModifier.id).toBe('standby_rune_conversion');
      expect(arcane.forbiddenAsSecondary).toEqual([
        'guardian_hero_pool',
        'building_pool',
        'second_unit_spawn_board',
        'manual_rune_button',
      ]);
    });
  });

  describe('arcane secondary rune rules', () => {
    it('creates Rune from Magic and Upgrade, never from Gold', () => {
      const state = createInitialGameState('hive', 203, { secondaryRaceId: 'arcane' });

      triggerSlot(state, 'magic');
      triggerSlot(state, 'gold');
      triggerSlot(state, 'upgrade');

      expect(state.arcaneRune.current).toBe(2);
      expect(state.arcaneRune.totalGenerated).toBe(2);
      expect(state.stats.currentPhase.runeGenerated).toBe(2);
      expect(state.recentFloatingTexts.map((item) => item.label)).toEqual(expect.arrayContaining([
        'Rune +1: Magic',
        '金币 +15',
        'Rune +1: Upgrade',
      ]));
    });

    it('does not create Rune when Arcane is not selected as secondary', () => {
      const state = createInitialGameState('hive', 204);

      triggerSlot(state, 'magic');
      triggerSlot(state, 'upgrade');

      expect(state.arcaneRune.current).toBe(0);
      expect(state.stats.currentPhase.runeGenerated).toBe(0);
    });

    it('caps Rune at 5 and records capped Magic or Upgrade hits', () => {
      const state = createInitialGameState('hive', 205, { secondaryRaceId: 'arcane' });

      for (let index = 0; index < 7; index += 1) triggerSlot(state, 'magic');

      expect(state.arcaneRune.current).toBe(5);
      expect(state.arcaneRune.totalGenerated).toBe(5);
      expect(state.arcaneRune.cappedHits).toBe(2);
      expect(state.stats.currentPhase.runeCappedHits).toBe(2);
    });

    it('spends all stored Rune on the next resolved Unit Spawn as main-race slot progress', () => {
      const state = createInitialGameState('hive', 206, { secondaryRaceId: 'arcane' });
      state.arcaneRune.current = 3;
      const spitterSlot = raceDefs.hive.unitSlots[1];

      const result = resolveUnitBallToSlot(state, 1, 1, {
        elapsedMs: 1000,
        durationMs: 60000,
      });

      expect(result).toMatchObject({
        status: 'resolved',
        unitId: spitterSlot.unitId,
        slotIndex: 1,
        runeProgressSpent: 3,
        progressAdded: 4,
      });
      expect(state.arcaneRune.current).toBe(0);
      expect(state.arcaneRune.totalSpent).toBe(3);
      expect(state.arcaneRune.totalProgressGranted).toBe(3);
      expect(state.stats.currentPhase.runeSpent).toBe(3);
      expect(state.stats.currentPhase.runeProgressGranted).toBe(3);
      expect(getCurrentRaceUnitSlotStates(state)[1].progress).toBe(1);
      expect(state.spawnQueue.some((item) => item.unitId === spitterSlot.unitId)).toBe(true);
    });

    it('labels Rune-driven wraparound as total progress, queued units, and remaining progress', () => {
      const state = createInitialGameState('hive', 212, { secondaryRaceId: 'arcane' });
      state.arcaneRune.current = 3;
      const spitterSlot = raceDefs.hive.unitSlots[1];

      const result = resolveUnitBallToSlot(state, 1, 1, {
        elapsedMs: 1000,
        durationMs: 60000,
      });

      expect(result.status).toBe('resolved');
      expect(result.status === 'resolved'
        ? formatUnitProgressOutcomeLabel(result, spitterSlot.requirement)
        : '').toBe('进度+4 入队x1 剩1/3');
    });

    it('does not spend Rune when a high-tier Unit Spawn is blocked by the gate', () => {
      const state = createInitialGameState('mech', 207, { secondaryRaceId: 'arcane' });
      state.arcaneRune.current = 2;

      const result = resolveUnitBallToSlot(state, 4, 1, {
        elapsedMs: 0,
        durationMs: 60000,
      });

      expect(result.status).toBe('blocked');
      expect(state.arcaneRune.current).toBe(2);
      expect(state.stats.currentPhase.runeSpent).toBe(0);
    });
  });

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

  it('lets a unit building spill queued overflow into the next unit slot', () => {
    const state = createInitialGameState('hive', 64);
    const spitterSlot = raceDefs.hive.unitSlots[1];
    const carapaceSlot = raceDefs.hive.unitSlots[2];

    installOrUpgradeBuilding(state, 'unit_overflow_hatchery');
    addUnitSlotProgress(state, spitterSlot.unitId, spitterSlot.requirement);

    expect(state.spawnQueue.some((unit) => unit.unitId === spitterSlot.unitId)).toBe(true);
    expect(getCurrentRaceUnitSlotStates(state)[2]).toMatchObject({
      unitId: carapaceSlot.unitId,
      progress: 1,
    });
  });

  it('lets a unit queue conveyor building turn queued units into a deployment burst', () => {
    const state = createInitialGameState('hive', 66);
    const grubSlot = raceDefs.hive.unitSlots[0];

    installOrUpgradeBuilding(state, 'unit_queue_conveyor');
    addUnitSlotProgress(state, grubSlot.unitId, grubSlot.requirement);

    const queued = state.spawnQueue.find((unit) => unit.unitId === grubSlot.unitId);
    expect(queued?.releaseIntervalMs).toBeLessThan(650);
    expect(queued?.tags).toContain('queue-burst');
    expect(state.stats.currentPhase.buildingContributions.unit).toBeGreaterThan(0);
    expect((state.stats.currentPhase as { queueBurstEvents?: number }).queueBurstEvents).toBe(1);
  });

  it('opens the single unit gate continuously across the first build-focused phase window', () => {
    const state = createInitialGameState('mech', 17);
    const durationMs = 60000;
    const startGate = getUnitGateState(0, durationMs);
    const barelyOpenGate = getUnitGateState(1000, durationMs);
    const quarterGate = getUnitGateState(durationMs * 0.25, durationMs);
    const oldFullOpenGate = getUnitGateState(durationMs * 0.4, durationMs);
    const phaseEndGate = getUnitGateState(durationMs, durationMs);
    const fullOpenGate = getUnitGateState(durationMs * activePacingPreset.unitGateFullOpenPhaseRatio, durationMs);

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
    expect(oldFullOpenGate.openSlotCount).toBeLessThan(5);
    expect(phaseEndGate.openBoundaryRatio).toBeCloseTo(0.6, 5);
    expect(getUnitGateOpenBoundaryRatio(durationMs * activePacingPreset.unitGateFullOpenPhaseRatio, durationMs)).toBe(1);
    expect(fullOpenGate.openUnitIndex).toBe(4);
    expect(fullOpenGate.openSlotCount).toBe(5);
    expect(getUnitGateOpenBoundaryRatio(durationMs * 0.8, durationMs)).toBeLessThan(1);
    expect(getUnlockedUnitSlotCount(state, durationMs * activePacingPreset.unitGateFullOpenPhaseRatio, durationMs)).toBe(5);
  });

  it('lets a unit gate building open high-tier slots earlier', () => {
    const plain = createInitialGameState('mech', 65);
    const built = createInitialGameState('mech', 65);

    installOrUpgradeBuilding(built, 'unit_gate_actuator');

    expect(getEffectiveUnitGateState(plain, 15000, 60000).openSlotCount).toBeLessThan(5);
    expect(getEffectiveUnitGateState(built, 15000, 60000).openSlotCount).toBeGreaterThan(
      getEffectiveUnitGateState(plain, 15000, 60000).openSlotCount,
    );
    expect(getEffectiveUnitGateState(built, 15000, 60000).openSlotCount).toBeGreaterThanOrEqual(3);
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

  it('debug-spawns the requested current-race unit slot for author testing', () => {
    const state = createInitialGameState('mech', 104);
    state.unitLevels.mech_titan = 3;

    const unit = spawnDebugRaceUnit(state, 4);

    expect(unit).toMatchObject({
      defId: 'mech_titan',
      side: 'player',
      level: 3,
      lifetime: 'standard',
    });
    expect(state.battle.units.at(-1)?.id).toBe(unit.id);
    expect(state.stats.currentPhase.unitsSpawned).toBe(1);
    expect(state.recentFloatingTexts.at(-1)?.label).toBe('调试生成 Lv3 泰坦');
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

  it('does not report a visible battle contact marker before opposing units meet', () => {
    const state = createInitialGameState('hive', 102);
    const player = spawnBattleUnit(state, 'player', 'hive_grub');
    const enemy = spawnBattleUnit(state, 'enemy', 'enemy_raider');
    player.x = 420;
    player.battleLane = 'middle';
    player.laneOffset = 0;
    enemy.x = 760;
    enemy.battleLane = 'middle';
    enemy.laneOffset = 0;

    expect(getBattleContactRatio(state)).toBeUndefined();

    enemy.x = 445;

    expect(getBattleContactRatio(state)).toBeCloseTo(0.2265625, 5);
  });

  it('applies ranged attack damage when the projectile impacts', () => {
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
      damage: 8,
      color: 0x60a5fa,
    });
    expect(target.hp).toBe(6);
    expect(state.stats.currentPhase.damageDealt).toBe(0);
    expect(state.battle.transientEffects.some((effect) => effect.type === 'hit' && effect.unitId === target.id)).toBe(false);

    updateBattle(state, 259);

    expect(target.hp).toBe(6);

    updateBattle(state, 1);

    expect(state.battle.transientEffects).toEqual(expect.arrayContaining([
      expect.objectContaining({ type: 'hit', side: 'player', unitId: target.id, damage: 8 }),
      expect.objectContaining({ type: 'death', side: 'enemy', unitId: target.id }),
    ]));
    expect(target.hp).toBe(0);
    expect(target.lastHitAtMs).toBe(state.battle.elapsedMs);
    expect(attacker.lastAttackAtMs).toBe(120);
  });

  it('lets both bases fire low-damage defense shots at nearby enemy units', () => {
    const state = createInitialGameState('hive', 55);
    const enemyNearPlayerBase = spawnBattleUnit(state, 'enemy', 'enemy_raider');
    const playerNearEnemyBase = spawnBattleUnit(state, 'player', 'hive_grub');
    enemyNearPlayerBase.x = state.battle.bases.player.x + 86;
    enemyNearPlayerBase.battleLane = 'middle';
    enemyNearPlayerBase.laneOffset = 0;
    enemyNearPlayerBase.hp = 34;
    playerNearEnemyBase.x = state.battle.bases.enemy.x - 86;
    playerNearEnemyBase.battleLane = 'middle';
    playerNearEnemyBase.laneOffset = 0;
    playerNearEnemyBase.hp = 35;

    updateBattle(state, 100);

    expect(state.battle.projectiles).toEqual(expect.arrayContaining([
      expect.objectContaining({
        side: 'player',
        fromBaseSide: 'player',
        toUnitId: enemyNearPlayerBase.id,
        damage: 6,
      }),
      expect.objectContaining({
        side: 'enemy',
        fromBaseSide: 'enemy',
        toUnitId: playerNearEnemyBase.id,
        damage: 6,
      }),
    ]));
    expect(enemyNearPlayerBase.hp).toBe(34);
    expect(playerNearEnemyBase.hp).toBe(35);

    updateBattle(state, 240);

    expect(enemyNearPlayerBase.hp).toBe(28);
    expect(playerNearEnemyBase.hp).toBe(29);
    expect(state.stats.currentPhase.damageDealt).toBe(6);
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

    expect(state.battle.projectiles[0]).toMatchObject({
      fromUnitId: attacker.id,
      toUnitId: sameLane.id,
    });
    updateBattle(state, 260);

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

  it('keeps upper-lane unit projections inside the battlefield visual bounds', () => {
    const raw = projectBattlePoint({
      worldX: 1030,
      laneOffset: -86,
      cameraCenterX: 710,
      playerBaseX: 70,
      enemyBaseX: 1670,
      screenStart: { x: 300, y: 552 },
      screenEnd: { x: 1110, y: 260 },
      viewportWorldWidth: 640,
    });

    expect(raw.y).toBeLessThan(216);
    expect(clampBattleProjectionToBounds(raw, {
      left: 0,
      right: 1280,
      top: 216,
      bottom: 640,
      topPadding: 52,
      bottomPadding: 32,
    })).toMatchObject({
      y: 268,
      depth: 268,
    });
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

  it('focuses automatic camera follow on the living player unit closest to the enemy base', () => {
    const state = createInitialGameState('hive', 304);
    const backline = spawnBattleUnit(state, 'player', 'hive_grub');
    const vanguard = spawnBattleUnit(state, 'player', 'hive_spitter');
    const enemy = spawnBattleUnit(state, 'enemy', 'enemy_raider');
    backline.x = 420;
    vanguard.x = 910;
    enemy.x = 760;

    const span = state.battle.bases.enemy.x - state.battle.bases.player.x;
    expect(getBattleHotspotRatio(state)).toBeCloseTo((vanguard.x - state.battle.bases.player.x) / span, 5);

    vanguard.hp = 0;
    expect(getBattleHotspotRatio(state)).toBeCloseTo((backline.x - state.battle.bases.player.x) / span, 5);
  });

  it('uses true enemy-base distance for automatic player-unit camera focus', () => {
    const state = createInitialGameState('hive', 305);
    const nearEnemyBase = spawnBattleUnit(state, 'player', 'hive_grub');
    const overshotEnemyBase = spawnBattleUnit(state, 'player', 'hive_spitter');
    nearEnemyBase.x = state.battle.bases.enemy.x - 70;
    overshotEnemyBase.x = state.battle.bases.enemy.x + 130;

    const span = state.battle.bases.enemy.x - state.battle.bases.player.x;
    expect(getBattleHotspotRatio(state)).toBeCloseTo((nearEnemyBase.x - state.battle.bases.player.x) / span, 5);
  });

  it('keeps heat bands stable when there are no units', () => {
    const state = createInitialGameState('mech', 404);
    const bands = buildBattleHeatBands(state.battle.units, state.battle.bases.player.x, state.battle.bases.enemy.x, 16);

    expect(bands).toHaveLength(16);
    expect(bands.every((band) => band.player === 0 && band.enemy === 0)).toBe(true);
  });
});

describe('run shell rules', () => {
  it('builds a configured prototype run from main race and optional Arcane secondary', () => {
    const hiveArcane = createPrototypeRunState({ mainRaceId: 'hive', secondaryRaceId: 'arcane', seed: 301 });
    const mechOnly = createPrototypeRunState({ mainRaceId: 'mech', seed: 302 });

    expect(hiveArcane.currentRaceId).toBe('hive');
    expect(hiveArcane.secondaryRaceId).toBe('arcane');
    expect(hiveArcane.phaseActive).toBe(false);
    expect(hiveArcane.phaseIndex).toBe(0);

    expect(mechOnly.currentRaceId).toBe('mech');
    expect(mechOnly.secondaryRaceId).toBeUndefined();
    expect(buildRunSetupSummary({ mainRaceId: 'mech' })).toEqual([
      '主族：机械',
      '副族：无',
      '目标：完成 6 个阶段并守住基地',
    ]);
  });

  it('summarizes a full-run victory with chain identity and run totals', () => {
    const state = createPrototypeRunState({ mainRaceId: 'hive', secondaryRaceId: 'arcane', seed: 303 });
    state.phaseIndex = phaseDefs.length - 1;
    state.buildArchetypeHint = '虫群爆兵';
    state.selectedRewards = ['launch_recycle_buffer', 'decision_arc_coil'];
    state.chainHistory.push({
      phaseIndex: 0,
      phaseId: 'outer_gate',
      phaseName: '外门',
      reason: 'objective',
      archetype: '虫群爆兵',
      dominantChamber: '出兵区',
      resourceReturnRate: 0.5,
      summaryLines: ['构筑 虫群爆兵 主仓 出兵区'],
      completedAtMs: 42000,
      unitsQueued: 4,
      unitsDeployed: 3,
      advancedUnitsQueued: 1,
      gateBlockedEvents: 0,
    });

    const summary = buildRunEndSummary(state, 'victory');

    expect(summary.title).toBe('原型通关');
    expect(summary.primaryLines).toEqual(expect.arrayContaining([
      '主族 虫群 / 副族 秘仪议会',
      '阶段 6/6  奖励 2  构筑 虫群爆兵',
      '总入队 4  总部署 3  高阶入队 1  挡回 0',
    ]));
    expect(summary.diagnosisTags).toEqual(['构筑成型', '六阶段完成']);
  });

  it('diagnoses a failed run from machine-chain bottlenecks', () => {
    const state = createPrototypeRunState({ mainRaceId: 'mech', seed: 304 });
    state.battle.bases.player.hp = 0;
    state.stats.currentPhase.slotTriggers.gold = 4;
    state.stats.currentPhase.slotTriggers.magic = 3;
    state.stats.currentPhase.slotTriggers.upgrade = 2;
    state.stats.currentPhase.slotTriggers.spawn = 0;
    state.stats.currentPhase.unitsQueued = 0;
    state.stats.currentPhase.playerBaseDamage = 180;
    state.stats.currentPhase.enemyBaseDamage = 20;
    state.stats.currentPhase.gateBlockedEvents = 3;

    const summary = buildRunEndSummary(state, 'defeat');

    expect(summary.title).toBe('运行失败');
    expect(summary.diagnosisTags).toEqual([
      '出兵链断档',
      '战备回流弱',
      '高阶挡板卡顿',
      '前线承压',
    ]);
    expect(summary.nextRunHint).toBe('下局优先修复：让非出兵收益更快回到 Unit Spawn，并降低早期高阶挡板依赖。');
  });
});

describe('reward rules', () => {
  it('configures reward description text for centered CJK wrapping inside cards', () => {
    const style = createRewardDescriptionTextStyle({ color: '#cbd5e1', fontSize: '10px' });

    expect(style.align).toBe('center');
    expect(style.fixedWidth).toBe(REWARD_CARD_DESCRIPTION_WRAP_WIDTH);
    expect(style.wordWrap).toEqual({
      width: REWARD_CARD_DESCRIPTION_WRAP_WIDTH,
      useAdvancedWrap: true,
    });
    expect(style.lineSpacing).toBeGreaterThanOrEqual(1);
  });

  it('installs and upgrades chamber buildings from reward blueprints', () => {
    const state = createInitialGameState('hive', 60);

    const first = installOrUpgradeBuilding(state, 'decision_coin_press');
    const second = installOrUpgradeBuilding(state, 'decision_coin_press');

    expect(first.status).toBe('installed');
    expect(second.status).toBe('upgraded');
    expect(state.buildings).toEqual([
      { id: 'decision_coin_press', chamber: 'decision', level: 2 },
    ]);
    expect(getBuildingSummary(state)).toContain('战备区: 铸币导槽 Lv2');
  });

  it('lets gold buy and upgrade unit structures outside phase-end rewards', () => {
    const state = createInitialGameState('hive', 61);
    state.gold = getUnitStructureGoldCost(state, 'unit_queue_conveyor');

    const installed = buyUnitStructureWithGold(state, 'unit_queue_conveyor');

    expect(installed.status).toBe('purchased');
    expect(state.gold).toBe(0);
    expect(state.unitStructures).toEqual([{ id: 'unit_queue_conveyor', chamber: 'unit', level: 1 }]);
    expect(buyUnitStructureWithGold(state, 'launch_splitter_rack').status).toBe('not_unit_structure');

    state.gold = getUnitStructureGoldCost(state, 'unit_queue_conveyor');
    const upgraded = buyUnitStructureWithGold(state, 'unit_queue_conveyor');

    expect(upgraded.status).toBe('upgraded');
    expect(state.unitStructures[0]).toMatchObject({ id: 'unit_queue_conveyor', level: 2 });
  });

  it('rejects unit structure purchases when gold is insufficient', () => {
    const state = createInitialGameState('hive', 62);
    state.gold = getUnitStructureGoldCost(state, 'unit_gate_actuator') - 1;

    const result = buyUnitStructureWithGold(state, 'unit_gate_actuator');

    expect(result).toMatchObject({
      status: 'insufficient_gold',
      id: 'unit_gate_actuator',
      gold: state.gold,
    });
    expect(state.unitStructures).toEqual([]);
  });

  it('lets the Unit Spawn structure layer hold three gold-built structures', () => {
    const state = createInitialGameState('hive', 63);
    const structureIds = ['unit_overflow_hatchery', 'unit_gate_actuator', 'unit_queue_conveyor'];

    for (const id of structureIds) {
      state.gold = getUnitStructureGoldCost(state, id);
      expect(buyUnitStructureWithGold(state, id).status).toBe('purchased');
    }

    expect(state.unitStructures.map((building) => building.id)).toEqual(structureIds);
    expect(getAvailableUnitStructureDefs(state).map((def) => def.id)).toEqual(structureIds);
    expect(installOrUpgradeBuilding(state, 'decision_coin_press').status).toBe('installed');
    expect(installOrUpgradeBuilding(state, 'decision_arc_coil').status).toBe('installed');
    expect(installOrUpgradeBuilding(state, 'launch_splitter_rack').status).toBe('installed');
  });

  it('offers three rewards and applies machine or unit modifiers', () => {
    const state = createInitialGameState('hive', 19);

    const choices = buildRewardChoices(state);
    expect(choices).toHaveLength(3);

    applyReward(state, 'wide_spawn');

    expect(state.slots.spawn.widthWeight).toBeGreaterThan(1);
  });

  it('offers phase-end rewards as one blueprint for each machine chamber', () => {
    const state = createInitialGameState('hive', 20);

    const choices = buildRewardChoices(state);

    expect(choices).toHaveLength(3);
    expect(choices.map((reward) => reward.chamber)).toEqual(['launch', 'decision', 'unit']);
    expect(choices.map((reward) => reward.sourceType)).toEqual(['building', 'building', 'building']);
    expect(choices.every((reward) => reward.tag.includes('蓝图'))).toBe(true);
    expect(new Set(choices.map((reward) => reward.chamber)).size).toBe(3);
  });

  it('falls back to same-chamber legacy cards after permanent blueprint choices are exhausted', () => {
    const state = createInitialGameState('hive', 28);
    state.relics = relicDefs.map((relic) => ({ id: relic.id }));
    state.doctrineTechs = doctrineTechDefs.map((tech) => ({ id: tech.id }));
    for (const buildingId of ['launch_splitter_rack', 'launch_recycle_buffer']) {
      installOrUpgradeBuilding(state, buildingId);
      installOrUpgradeBuilding(state, buildingId);
      installOrUpgradeBuilding(state, buildingId);
    }

    const choices = buildRewardChoices(state);
    const launchChoice = choices.find((reward) => reward.chamber === 'launch');

    expect(choices).toHaveLength(3);
    expect(launchChoice?.sourceType).toBe('legacy');
    expect(['extra_ball_interval', 'double_drop']).toContain(launchChoice?.id);
    expect(choices.map((reward) => reward.chamber)).toEqual(['launch', 'decision', 'unit']);
    expect(choices.every((reward) => reward.sourceType !== 'relic')).toBe(true);
  });

  it('lets a decision building convert repeated gold hits into spawn mark value', () => {
    const state = createInitialGameState('hive', 63);

    installOrUpgradeBuilding(state, 'decision_coin_press');
    triggerSlot(state, 'gold');
    triggerSlot(state, 'gold');
    expect(state.pendingSpawnMarks).toBe(0);

    triggerSlot(state, 'gold');

    expect(state.pendingSpawnMarks).toBe(2);
    expect(state.recentFloatingTexts.at(-1)?.label).toBe('铸币导槽：出兵标记 +1');
  });

  it('lays out standby slots from live width weights instead of equal columns', () => {
    const state = createInitialGameState('hive', 19);
    state.slots.gold.widthWeight = 1.3;
    state.slots.upgrade.widthWeight = 1.2;

    const layouts = buildWeightedSlotLayouts(
      decisionSlotDefs.map((slot) => state.slots[slot.id]),
      240,
      360,
      9,
      4,
    );
    const magic = layouts.find((slot) => slot.id === 'magic');
    const gold = layouts.find((slot) => slot.id === 'gold');
    const upgrade = layouts.find((slot) => slot.id === 'upgrade');

    expect(layouts).toHaveLength(3);
    expect(layouts.map((slot) => slot.id)).toEqual(['gold', 'magic', 'upgrade']);
    expect(gold?.sensorWidth).toBeGreaterThan(magic?.sensorWidth ?? 0);
    expect(upgrade?.plateWidth).toBeGreaterThan(magic?.plateWidth ?? 0);
    expect(layouts[0].left).toBeCloseTo(249);
    expect(layouts.at(-1)?.right).toBeCloseTo(591);
  });

  it('rerolls a reward offer once by spending gold and avoids the same full offer', () => {
    const state = createInitialGameState('hive', 88);
    state.gold = 10;
    const first = buildRewardChoices(state);
    const rerolled = rerollRewardChoices(state, first, { cost: 10 });

    expect(rerolled.status).toBe('rerolled');
    if (rerolled.status !== 'rerolled') throw new Error('Expected a rerolled reward offer');
    expect(state.gold).toBe(0);
    expect(rerolled.choices).toHaveLength(3);
    expect(rerolled.choices.map((reward) => reward.id)).not.toEqual(first.map((reward) => reward.id));
    expect(rerollRewardChoices(state, rerolled.choices, { cost: 10 }).status).toBe('insufficient_gold');
  });
});

describe('event relic rules', () => {
  it('installs event relics from rewards without duplicating them', () => {
    const state = createInitialGameState('hive', 80);

    const first = installRelic(state, 'entropy_fuse');
    const second = installRelic(state, 'entropy_fuse');

    expect(first.status).toBe('installed');
    expect(second.status).toBe('already_owned');
    expect(state.relics).toEqual([{ id: 'entropy_fuse' }]);
  });

  it('turns repeated misses into a future spawn mark through entropy fuse', () => {
    const state = createInitialGameState('hive', 81);

    installRelic(state, 'entropy_fuse');
    recordRelicLaunchMiss(state);
    recordRelicLaunchMiss(state);
    expect(state.pendingSpawnMarks).toBe(0);

    recordRelicLaunchMiss(state);

    expect(state.pendingSpawnMarks).toBe(1);
    expect(state.relicEvents.entropyCharges).toBe(0);
    expect(state.stats.currentPhase.relicTriggers).toBe(1);
  });

  it('lets a gate relic convert blocked high-tier balls into spawn marks', () => {
    const state = createInitialGameState('mech', 82);

    installRelic(state, 'gate_momentum');
    const result = resolveUnitBallToSlot(state, 4, 1, { elapsedMs: 0, durationMs: 60000 });

    expect(result.status).toBe('blocked');
    expect(state.pendingSpawnMarks).toBe(1);
    expect(state.stats.currentPhase.relicTriggers).toBe(1);
  });

  it('lets a spell echo relic and upgrade cache relic support later spawns', () => {
    const magic = createInitialGameState('hive', 83);
    const upgrade = createInitialGameState('mech', 84);

    installRelic(magic, 'spell_echo_relic');
    triggerSlot(magic, 'magic');
    expect(magic.modifiers.pendingSpawnCopies).toBe(1);

    installRelic(upgrade, 'upgrade_cache');
    triggerSlot(upgrade, 'upgrade');
    resolveUnitBallToSlot(upgrade, 0, 1, { elapsedMs: 0, durationMs: 60000 });
    expect(upgrade.pendingSpawnLevelBonus).toBe(1);
  });

  it('uses a launch relic to tag the next launch ball at phase start', () => {
    const state = createInitialGameState('hive', 91);
    state.pendingLaunchBallTags = ['copy-mark'];

    installRelic(state, 'prism_magazine');
    startPhase(state);

    expect(state.pendingLaunchBallTags).toEqual(['copy-mark', 'split+', 'spawn-mark']);
    expect(state.stats.currentPhase.relicTriggers).toBe(1);
  });
});

describe('doctrine tech rules', () => {
  it('converts any three consecutive non-spawn decisions into a baseline spawn mark', () => {
    const state = createInitialGameState('hive', 92);

    triggerSlot(state, 'gold');
    triggerSlot(state, 'magic');
    expect(state.pendingSpawnMarks).toBe(0);
    expect(state.doctrineEvents.nonSpawnStreak).toBe(2);

    triggerSlot(state, 'gold');

    expect(state.pendingSpawnMarks).toBe(1);
    expect(state.doctrineEvents.nonSpawnStreak).toBe(0);
    expect(state.stats.currentPhase.spawnMarksCreated).toBe(1);
    expect(state.stats.currentPhase.nonSpawnRecoveryEvents).toBe(1);
    expect(buildPhaseTelemetrySummary(state).lines.some((line) => line.includes('保底 0/3'))).toBe(true);
  });

  it('resets the baseline non-spawn streak when spawn is hit', () => {
    const state = createInitialGameState('hive', 93);

    triggerSlot(state, 'gold');
    triggerSlot(state, 'magic');
    triggerSlot(state, 'spawn');
    triggerSlot(state, 'upgrade');

    expect(state.pendingSpawnMarks).toBe(0);
    expect(state.doctrineEvents.nonSpawnStreak).toBe(1);
  });

  it('lets magic and upgrade hits create baseline research that returns into spawn marks', () => {
    const state = createInitialGameState('hive', 90);

    triggerSlot(state, 'magic');
    triggerSlot(state, 'upgrade');
    triggerSlot(state, 'magic');
    expect(state.pendingSpawnMarks).toBe(1);

    triggerSlot(state, 'upgrade');

    expect(state.researchPoints).toBe(4);
    expect(state.doctrineEvents.researchReturnProgress).toBe(0);
    expect(state.pendingSpawnMarks).toBe(2);
    expect(state.stats.currentPhase.spawnMarksCreated).toBe(2);
    expect(state.stats.currentPhase.nonSpawnRecoveryEvents).toBe(2);
    expect(buildPhaseTelemetrySummary(state).lines.some((line) => line.includes('研究 4(0/4)'))).toBe(true);
  });

  it('unlocks doctrine techs once and applies immediate machine effects', () => {
    const state = createInitialGameState('hive', 85);

    const first = unlockDoctrineTech(state, 'launch_extra_launcher');
    const second = unlockDoctrineTech(state, 'launch_extra_launcher');
    unlockDoctrineTech(state, 'decision_slot_calibration');
    unlockDoctrineTech(state, 'unit_mobilization_links');

    expect(first.status).toBe('unlocked');
    expect(second.status).toBe('already_unlocked');
    expect(state.doctrineTechs).toEqual([
      { id: 'launch_extra_launcher' },
      { id: 'decision_slot_calibration' },
      { id: 'unit_mobilization_links' },
    ]);
    expect(state.modifiers.ballCount).toBe(2);
    expect(state.slots.spawn.widthWeight).toBeGreaterThan(1);
    expect(state.modifiers.queueReleaseSpeedBonus).toBeGreaterThan(0);
  });

  it('spends research points to buy doctrine tech during a run', () => {
    const state = createInitialGameState('hive', 88);
    state.researchPoints = 2;

    expect(buyDoctrineTechWithResearch(state, 'decision_slot_calibration').status).toBe('insufficient_research');
    expect(state.doctrineTechs).toEqual([]);

    state.researchPoints = 4;
    const bought = buyDoctrineTechWithResearch(state, 'decision_slot_calibration');

    expect(bought).toEqual({ status: 'unlocked', id: 'decision_slot_calibration', cost: 3 });
    expect(state.researchPoints).toBe(1);
    expect(state.doctrineTechs).toEqual([{ id: 'decision_slot_calibration' }]);
    expect(state.slots.spawn.widthWeight).toBeGreaterThan(1);
    expect(buyDoctrineTechWithResearch(state, 'decision_slot_calibration').status).toBe('already_unlocked');
    expect(state.researchPoints).toBe(1);
  });

  it('uses conversion doctrine to turn non-spawn decisions into research and spawn marks', () => {
    const state = createInitialGameState('hive', 86);

    unlockDoctrineTech(state, 'decision_conversion_matrix');
    triggerSlot(state, 'gold');
    triggerSlot(state, 'magic');
    expect(state.pendingSpawnMarks).toBe(0);

    triggerSlot(state, 'upgrade');

    expect(state.researchPoints).toBe(5);
    expect(state.pendingSpawnMarks).toBe(2);
    expect(state.doctrineEvents.conversionHits).toBe(0);
  });

  it('uses launch and unit doctrine to recover misses and preserve low-tier upgrade loss', () => {
    const launch = createInitialGameState('hive', 87);
    const unit = createInitialGameState('mech', 89);

    unlockDoctrineTech(launch, 'launch_loss_research');
    recordDoctrineLaunchMiss(launch);
    recordDoctrineLaunchMiss(launch);
    expect(launch.researchPoints).toBe(2);
    expect(launch.pendingSpawnMarks).toBe(1);

    unlockDoctrineTech(unit, 'unit_elite_escort');
    triggerSlot(unit, 'upgrade');
    resolveUnitBallToSlot(unit, 0, 1, { elapsedMs: 0, durationMs: 60000 });
    expect(unit.pendingSpawnLevelBonus).toBe(1);
  });
});

describe('debug build presets', () => {
  it('defines reproducible presets for the target build identities', () => {
    expect(debugBuildPresets.map((preset) => preset.id)).toEqual([
      'swarm',
      'magic_copy',
      'mech_elite',
      'economy_industry',
      'recovery',
    ]);
  });

  it('applies the swarm preset with launch and unit buildings', () => {
    const state = createInitialGameState('mech', 70);

    const result = applyDebugBuildPreset(state, 'swarm');

    expect(result.status).toBe('applied');
    expect(state.currentRaceId).toBe('hive');
    expect(state.buildings.map((building) => building.id)).toEqual(expect.arrayContaining([
      'launch_splitter_rack',
      'unit_overflow_hatchery',
    ]));
    expect(state.modifiers.ballCount).toBeGreaterThan(1);
    expect(state.modifiers.spawnExtraCount).toBeGreaterThan(0);
  });

  it('applies magic, elite, economy, and recovery presets with distinct machine states', () => {
    const magic = createInitialGameState('hive', 71);
    const elite = createInitialGameState('hive', 72);
    const economy = createInitialGameState('hive', 73);
    const recovery = createInitialGameState('hive', 74);

    applyDebugBuildPreset(magic, 'magic_copy');
    applyDebugBuildPreset(elite, 'mech_elite');
    applyDebugBuildPreset(economy, 'economy_industry');
    applyDebugBuildPreset(recovery, 'recovery');

    expect(magic.buildings.map((building) => building.id)).toContain('decision_arc_coil');
    expect(magic.modifiers.magicSpawnCopyBonus).toBeGreaterThan(0);
    expect(elite.currentRaceId).toBe('mech');
    expect(elite.buildings.map((building) => building.id)).toContain('unit_gate_actuator');
    expect(elite.nextSpawnCreatesElite).toBe(true);
    expect(economy.gold).toBeGreaterThan(80);
    expect(economy.buildings.map((building) => building.id)).toContain('decision_coin_press');
    expect(recovery.pendingSpawnMarks).toBeGreaterThan(0);
    expect(recovery.buildings.map((building) => building.id)).toContain('launch_recycle_buffer');
  });

  it('replaces previous preset modifiers so debug runs are reproducible', () => {
    const state = createInitialGameState('hive', 75);

    applyDebugBuildPreset(state, 'swarm');
    expect(state.modifiers.spawnExtraCount).toBeGreaterThan(0);

    applyDebugBuildPreset(state, 'magic_copy');

    expect(state.buildings.map((building) => building.id)).toEqual([
      'decision_arc_coil',
      'launch_splitter_rack',
    ]);
    expect(state.modifiers.spawnExtraCount).toBe(0);
    expect(state.modifiers.magicSpawnCopyBonus).toBeGreaterThan(0);
  });
});

describe('build telemetry rules', () => {
  it('persists the v1.2 named build-surface state fields', () => {
    const state = createInitialGameState('hive', 178);
    const namedState = state as unknown as {
      launchRelics?: Array<{ id: string }>;
      decisionTechs?: Array<{ id: string }>;
      unitStructures?: Array<{ id: string; level: number }>;
      ballTags?: string[];
    };

    expect(namedState.launchRelics).toEqual([]);
    expect(namedState.decisionTechs).toEqual([]);
    expect(namedState.unitStructures).toEqual([]);
    expect(namedState.ballTags).toEqual([]);

    installRelic(state, 'prism_magazine');
    unlockDoctrineTech(state, 'decision_slot_calibration');
    installOrUpgradeBuilding(state, 'launch_splitter_rack');
    installOrUpgradeBuilding(state, 'decision_coin_press');
    installOrUpgradeBuilding(state, 'unit_queue_conveyor');
    state.gold = 40;
    state.phaseToolStock = ['marked_shot'];
    startPhase(state);
    state.phaseElapsedMs = phaseDefs[state.phaseIndex].durationMs * 0.5;
    buyPhaseTool(state, 'marked_shot');

    expect(namedState.launchRelics).toEqual([{ id: 'prism_magazine' }]);
    expect(namedState.decisionTechs).toEqual([{ id: 'decision_slot_calibration' }]);
    expect(namedState.unitStructures).toEqual([{ id: 'unit_queue_conveyor', chamber: 'unit', level: 1 }]);
    expect(namedState.ballTags).toEqual(['split+', 'spawn-mark', 'copy-mark']);
  });

  it('formats the three required build-surface HUD summaries', () => {
    const state = createInitialGameState('hive', 79);

    installRelic(state, 'prism_magazine');
    installRelic(state, 'spell_echo_relic');
    unlockDoctrineTech(state, 'launch_extra_launcher');
    unlockDoctrineTech(state, 'decision_slot_calibration');
    installOrUpgradeBuilding(state, 'launch_splitter_rack');
    installOrUpgradeBuilding(state, 'unit_queue_conveyor');

    const buildSurfaceHudSummaries = (BuildTelemetrySystem as unknown as {
      buildSurfaceHudSummaries?: (state: ReturnType<typeof createInitialGameState>) => {
        relics: string;
        techs: string;
        structures: string;
      };
    }).buildSurfaceHudSummaries;

    expect(buildSurfaceHudSummaries).toBeTypeOf('function');
    expect(buildSurfaceHudSummaries?.(state)).toEqual({
      relics: '棱镜弹匣 / 法术回声石',
      techs: '副投射学 / 中央校准学',
      structures: '队列输送带L1',
    });
  });

  it('defaults to a low-noise play layout and keeps debug surfaces behind a drawer', () => {
    const playPlan = getUiDensityPlan('play');
    const debugPlan = getUiDensityPlan('debug');

    expect(playPlan.showDebugControls).toBe(false);
    expect(playPlan.showBuildShopPanel).toBe(false);
    expect(playPlan.showTopChamberSummaries).toBe(false);
    expect(playPlan.showTopExplanatoryText).toBe(false);
    expect(playPlan.showBuildIdentityOverlay).toBe(false);
    expect(playPlan.showTransferTrails).toBe(false);
    expect(playPlan.visibleEventFeedRows).toBe(3);
    expect(debugPlan.showDebugControls).toBe(true);
    expect(debugPlan.showBuildShopPanel).toBe(false);
    expect(debugPlan.showTopChamberSummaries).toBe(true);
    expect(debugPlan.showTopExplanatoryText).toBe(true);
    expect(debugPlan.showBuildIdentityOverlay).toBe(true);
    expect(debugPlan.showTransferTrails).toBe(true);
  });

  it('keeps debug and build drawers mutually exclusive', () => {
    expect(toggleDebugDrawerState({ mode: 'play', buildShopOpen: false })).toEqual({ mode: 'debug', buildShopOpen: false });
    expect(toggleDebugDrawerState({ mode: 'play', buildShopOpen: true })).toEqual({ mode: 'debug', buildShopOpen: false });
    expect(toggleBuildShopDrawerState({ mode: 'debug', buildShopOpen: false })).toEqual({ mode: 'play', buildShopOpen: true });
    expect(toggleBuildShopDrawerState({ mode: 'play', buildShopOpen: true })).toEqual({ mode: 'play', buildShopOpen: false });
  });

  it('shrinks pinball slot frames to one third and gives the reclaimed height to the battlefield', () => {
    const layout = buildPrototypeLayout({
      gameW: 1280,
      gameH: 720,
      topY: 12,
      hudH: 104,
    });

    expect(layout.outcomeSlotH).toBe(14);
    expect(layout.unitSlotH).toBe(16);
    expect(layout.topH).toBe(164);
    expect(layout.battleY).toBe(184);
    expect(layout.battleH).toBe(424);
  });

  it('places standby, launch, and unit zones from left to right', () => {
    const zones = buildTopZoneLayout({
      gameW: 1280,
      sideMargin: 14,
      gap: 10,
      launchW: 225,
      decisionW: 350,
      unitW: 657,
      unitWidthScale: 0.75,
    });

    expect(zones.launch.w).toBeCloseTo(389.25, 5);
    expect(zones.decision.w).toBe(350);
    expect(zones.unit.w).toBeCloseTo(492.75, 5);
    expect(zones.decision.x).toBe(14);
    expect(zones.launch.x).toBe(374);
    expect(zones.unit.x).toBeCloseTo(773.25, 5);
    expect(zones.unit.x + zones.unit.w).toBe(1266);
  });

  it('keeps top-row debug preset buttons clear of the drawer toggles', () => {
    const drawerToggleLeft = 1280 - 150;
    const row = buildRightAlignedButtonRow({
      rightEdge: drawerToggleLeft - 10,
      leadingButtonWidth: 56,
      leadingGap: 10,
      itemCount: debugBuildPresets.length,
      itemWidth: 54,
      gap: 6,
    });

    expect(row.leadingX + 56).toBeLessThan(row.itemXs[0]);
    expect(Math.max(...row.itemXs.map((x) => x + 54))).toBeLessThanOrEqual(drawerToggleLeft - 10);
  });

  it('routes machine feedback into a small battlefield event feed', () => {
    expect(getEventFeedSlot(0)).toEqual({ x: 1242, y: 242, row: 0, align: 'right' });
    expect(getEventFeedSlot(1)).toEqual({ x: 1242, y: 266, row: 1, align: 'right' });
    expect(getEventFeedSlot(2)).toEqual({ x: 1242, y: 290, row: 2, align: 'right' });
    expect(getEventFeedSlot(3)).toEqual({ x: 1242, y: 242, row: 0, align: 'right' });
  });

  it('compresses the bottom HUD into stable readable status blocks', () => {
    const state = createInitialGameState('hive', 79);
    state.gold = 91;
    state.researchPoints = 20;
    state.pendingSpawnLevelBonus = 1;
    startPhase(state);
    state.stats.currentPhase.slotTriggers.gold = 7;
    state.stats.currentPhase.slotTriggers.magic = 3;
    state.stats.currentPhase.slotTriggers.spawn = 5;
    state.stats.currentPhase.slotTriggers.upgrade = 2;

    const blocks = buildCompactHudBlocks(state);

    expect(blocks.map((block) => block.label)).toEqual(['战况', '副族', '基地', '资源', '部队', '下次出兵', '战备']);
    expect(blocks).toHaveLength(7);
    expect(blocks[0]).toMatchObject({ value: '虫群 1/6', detail: '推进中' });
    expect(blocks[1]).toMatchObject({ value: '无' });
    expect(blocks[3].value).toBe('金 91 / 研 20');
    expect(blocks[5].value).toBe('Lv+1');
    expect(blocks[6].value).toBe('金7 法3 出5 升2');
  });

  describe('arcane secondary UI summaries', () => {
    it('adds compact Rune state to the next-spawn HUD block only when Arcane is secondary', () => {
      const plain = createInitialGameState('hive', 208);
      const arcane = createInitialGameState('hive', 209, { secondaryRaceId: 'arcane' });
      arcane.arcaneRune.current = 3;
      arcane.pendingSpawnLevelBonus = 1;

      expect(buildCompactHudBlocks(plain).find((block) => block.label === '下次出兵')?.value).toBe('Lv+0');
      expect(buildCompactHudBlocks(arcane).find((block) => block.label === '副族')?.detail).toBe('Rune 3/5');
      expect(buildCompactHudBlocks(arcane).find((block) => block.label === '下次出兵')?.value).toBe('Lv+1 / Rune 3/5');
    });

    it('adds Rune telemetry only for Arcane secondary runs', () => {
      const plain = createInitialGameState('hive', 210);
      const arcane = createInitialGameState('hive', 211, { secondaryRaceId: 'arcane' });

      triggerSlot(arcane, 'magic');
      resolveUnitBallToSlot(arcane, 0, 1, { elapsedMs: 0, durationMs: 60000 });

      expect(buildPhaseTelemetrySummary(plain).lines.some((line) => line.includes('秘仪 Rune'))).toBe(false);
      expect(buildPhaseTelemetrySummary(arcane).lines.some((line) => line.includes('秘仪 Rune 生成1 消耗1 进度+1'))).toBe(true);
    });
  });

  it('keeps top-row chamber summaries compact for structure art readability', () => {
    const state = createInitialGameState('hive', 97);

    installOrUpgradeBuilding(state, 'launch_splitter_rack');
    installOrUpgradeBuilding(state, 'launch_recycle_buffer');
    installOrUpgradeBuilding(state, 'decision_coin_press');
    installOrUpgradeBuilding(state, 'decision_arc_coil');
    installOrUpgradeBuilding(state, 'unit_overflow_hatchery');
    installOrUpgradeBuilding(state, 'unit_gate_actuator');
    installOrUpgradeBuilding(state, 'unit_queue_conveyor');
    installRelic(state, 'prism_magazine');
    installRelic(state, 'spell_echo_relic');
    installRelic(state, 'entropy_fuse');
    unlockDoctrineTech(state, 'launch_extra_launcher');
    unlockDoctrineTech(state, 'decision_slot_calibration');
    unlockDoctrineTech(state, 'unit_mobilization_links');

    const summaries = buildChamberPanelSummaries(state);

    expect(summaries.launch).toEqual([
      '建筑: 分裂联箱L1 / 回收缓冲L1',
      '遗物: 棱镜弹匣 / 法术回声石 / +1',
    ]);
    expect(summaries.decision).toEqual([
      '建筑: 铸币导槽L1 / 电弧回声L1',
      '科技: 副投射学 / 中央校准学 / +1',
    ]);
    expect(summaries.unit).toEqual([
      '工事: 溢流孵化器L1 / 高阶绞盘L1 / +1',
    ]);
    expect(Object.values(summaries).every((lines) => lines.length <= 2)).toBe(true);
  });

  it('maps each target build identity to distinct visible machine signatures', () => {
    const expected = [
      ['swarm', '虫群爆兵', '分裂增殖', '发兵扩张', '溢流输送'],
      ['magic_copy', '法术复制', '棱镜弹匣', '法术复制', '复制兑现'],
      ['mech_elite', '机械精英', '稳定供球', '升级校准', '高阶绞盘'],
      ['economy_industry', '经济工业', '回收供能', '金币工业', '队列爆发'],
      ['recovery', '逆风修复', '丢失回收', '金币保底', '修复输送'],
    ] as const;

    const accentColors = new Set<number>();
    for (const [presetId, archetype, launch, decision, unit] of expected) {
      const state = createInitialGameState('hive', 190);
      applyDebugBuildPreset(state, presetId);

      const visual = buildIdentityVisualSummary(state);
      accentColors.add(visual.accentColor);

      expect(visual.archetype).toBe(archetype);
      expect(visual.badgeText).toContain(archetype);
      expect(visual.chambers.launch).toMatchObject({ label: launch });
      expect(visual.chambers.decision).toMatchObject({ label: decision });
      expect(visual.chambers.unit).toMatchObject({ label: unit });
      expect(Object.values(visual.chambers).every((chamber) => chamber.iconKey.startsWith('icon_'))).toBe(true);
      expect(Object.values(visual.zoneEmphasis).some((emphasis) => emphasis > 0)).toBe(true);
    }

    expect(accentColors.size).toBe(expected.length);
  });

  it('maps each target build identity to loadable structure art in every chamber', () => {
    const assetKeys = new Set<string>(svgAssets.map(([key]) => key));
    const expectedAssetByPreset = [
      ['swarm', 'structure_swarm'],
      ['magic_copy', 'structure_magic_copy'],
      ['mech_elite', 'structure_mech_elite'],
      ['economy_industry', 'structure_economy_industry'],
      ['recovery', 'structure_recovery'],
    ] as const;

    for (const [presetId, assetKey] of expectedAssetByPreset) {
      const state = createInitialGameState('hive', 190);
      applyDebugBuildPreset(state, presetId);

      const visual = buildIdentityVisualSummary(state);
      const chamberStructures = Object.values(visual.structures);
      const structureAssetKeys = chamberStructures.flat().map((structure) => structure.assetKey);

      expect(structureAssetKeys).toContain(assetKey);
      expect(structureAssetKeys.every((key) => assetKeys.has(key))).toBe(true);
      expect(chamberStructures.every((structures) => structures.length > 0)).toBe(true);
      expect(chamberStructures.flat().every((structure) => structure.label.length > 0)).toBe(true);
      expect(chamberStructures.flat().some((structure) => structure.intensity >= 3)).toBe(true);
    }
  });

  it('builds a stable screenshot plan for every debug build identity', () => {
    const plan = buildIdentitySmokePlan('docs');

    expect(plan.map((item) => item.presetId)).toEqual(debugBuildPresets.map((preset) => preset.id));
    expect(plan.map((item) => item.action)).toEqual(debugBuildPresets.map((preset) => `preset-${preset.id}`));
    expect(new Set(plan.map((item) => item.outputPath)).size).toBe(debugBuildPresets.length);
    expect(plan.every((item) => item.outputPath.startsWith('docs/build-identity-'))).toBe(true);
    expect(plan.every((item) => item.outputPath.endsWith('-smoke.png'))).toBe(true);
    expect(plan.every((item) => item.displayName.length > 0)).toBe(true);
  });

  it('builds a requirement-by-requirement MVP readiness report with evidence states', () => {
    const report = buildMvpReadinessReport(170);
    const output = formatMvpReadinessReport(report);

    expect(report.items.map((item) => item.id)).toEqual([
      'three_surface_layers',
      'named_state_fields',
      'midgame_pacing',
      'three_chamber_blueprint_rewards',
      'debug_build_identities',
      'cross_chamber_chain',
      'recovery_guardrail',
      'phase_telemetry_answers',
      'expected_outputs',
      'automated_validation',
      'runtime_visual_timing',
    ]);
    expect(report.counts.proved).toBeGreaterThan(0);
    expect(report.counts.partial).toBe(0);
    expect(report.counts.missing).toBe(0);
    expect(report.readyForCompletion).toBe(true);
    expect(output).toContain('MVP READINESS');
    expect(output).toContain('READY');
    expect(output).toContain('runtime_visual_timing');
  });

  it('proves at least two chamber visual changes within the first 90 seconds', () => {
    const report = buildRuntimeVisualTimingReport(170);

    expect(report.timeLimitMs).toBe(90000);
    expect(report.passes).toBe(true);
    expect(report.changedChamberCount).toBeGreaterThanOrEqual(2);
    expect(report.changedChambers).toEqual(expect.arrayContaining(['launch', 'decision']));
    expect(report.events.every((event) => event.atMs <= report.timeLimitMs)).toBe(true);
    expect(report.events.some((event) => event.changedChambers.includes('launch'))).toBe(true);
    expect(report.events.some((event) => event.changedChambers.includes('decision'))).toBe(true);
  });

  it('records chamber contribution and recovery when buildings convert non-spawn results', () => {
    const state = createInitialGameState('hive', 76);

    installOrUpgradeBuilding(state, 'launch_recycle_buffer');
    installOrUpgradeBuilding(state, 'decision_coin_press');
    installOrUpgradeBuilding(state, 'unit_overflow_hatchery');
    recordLaunchMiss(state);
    triggerSlot(state, 'gold');
    triggerSlot(state, 'gold');
    triggerSlot(state, 'gold');
    addUnitSlotProgress(state, raceDefs.hive.unitSlots[0].unitId, 1);

    expect(state.stats.currentPhase.buildingContributions.launch).toBe(1);
    expect(state.stats.currentPhase.buildingContributions.decision).toBe(1);
    expect(state.stats.currentPhase.buildingContributions.unit).toBe(1);
    expect(state.stats.currentPhase.spawnMarksCreated).toBe(3);
    expect(state.stats.currentPhase.nonSpawnRecoveryEvents).toBe(3);
    expect(state.stats.currentPhase.overflowProgressGranted).toBe(1);
    expect(buildPhaseTelemetrySummary(state).resourceReturnRate).toBe(1);
  });

  it('prints resource return efficiency in the phase telemetry summary', () => {
    const state = createInitialGameState('hive', 81);

    installOrUpgradeBuilding(state, 'decision_coin_press');
    triggerSlot(state, 'gold');
    triggerSlot(state, 'gold');
    triggerSlot(state, 'gold');

    const summary = buildPhaseTelemetrySummary(state);

    expect(summary.resourceReturnRate).toBeCloseTo(2 / 3, 5);
    expect(summary.lines.some((line) => line.includes('回流效率 67%'))).toBe(true);
  });

  it('tracks non-spawn recovery streak, latency, and source for guardrail probes', () => {
    const state = createInitialGameState('hive', 82);

    state.phaseElapsedMs = 1000;
    triggerSlot(state, 'gold');
    state.phaseElapsedMs = 6000;
    triggerSlot(state, 'magic');
    state.phaseElapsedMs = 12000;
    triggerSlot(state, 'upgrade');

    const stats = state.stats.currentPhase;
    const summary = buildPhaseTelemetrySummary(state);

    expect(stats.nonSpawnStreakMax).toBe(3);
    expect(stats.timeToRecoverySpawnMs).toBe(11000);
    expect(stats.recoverySources.baseline_fallback).toBe(1);
    expect(summary.lines.some((line) => line.includes('最长非出兵 3'))).toBe(true);
    expect(summary.lines.some((line) => line.includes('首次回流 11.0s'))).toBe(true);
    expect(summary.lines.some((line) => line.includes('来源 保底x1'))).toBe(true);
  });

  it('summarizes dominant chamber and build archetype for phase completion', () => {
    const state = createInitialGameState('mech', 77);

    applyDebugBuildPreset(state, 'mech_elite');
    triggerSlot(state, 'upgrade');
    resolveUnitBallToSlot(state, 2, 5, { elapsedMs: 15000, durationMs: 60000 });

    const summary = buildPhaseTelemetrySummary(state);

    expect(getDominantBuildChamber(state.stats.currentPhase)).toBe('unit');
    expect(summary.archetype).toBe('机械精英');
    expect(summary.dominantChamber).toBe('出兵区');
    expect(summary.lines.some((line) => line.includes('主仓 出兵区'))).toBe(true);
  });

  it('summarizes high-tier queue ratio and blocked gate bounces', () => {
    const state = createInitialGameState('mech', 79);

    resolveUnitBallToSlot(state, 4, 1, { elapsedMs: 0, durationMs: 60000 });
    resolveUnitBallToSlot(state, 1, 3, { elapsedMs: 1000, durationMs: 60000 });

    const summary = buildPhaseTelemetrySummary(state);

    expect((state.stats.currentPhase as { gateBlockedEvents?: number }).gateBlockedEvents).toBe(1);
    expect((state.stats.currentPhase as { advancedUnitsQueued?: number }).advancedUnitsQueued).toBe(1);
    expect(summary.lines.some((line) => line.includes('高阶 1/1'))).toBe(true);
    expect(summary.lines.some((line) => line.includes('挡回 1'))).toBe(true);
  });

  it('persists chain history and archetype hints when a phase completes', () => {
    const state = createInitialGameState('mech', 80);

    applyDebugBuildPreset(state, 'mech_elite');
    startPhase(state);
    triggerSlot(state, 'upgrade');
    resolveUnitBallToSlot(state, 2, 5, { elapsedMs: 15000, durationMs: 60000 });

    completePhase(state, 'objective');

    const chainHistory = (state as {
      chainHistory?: Array<{
        phaseIndex: number;
        phaseName: string;
        reason: string;
        archetype: string;
        dominantChamber: string;
        summaryLines: string[];
      }>;
    }).chainHistory;

    expect((state as { buildArchetypeHint?: string }).buildArchetypeHint).toBe('机械精英');
    expect(chainHistory).toHaveLength(1);
    expect(chainHistory?.[0]).toMatchObject({
      phaseIndex: 0,
      phaseName: phaseDefs[0].name,
      reason: 'objective',
      archetype: '机械精英',
      dominantChamber: '出兵区',
    });
    expect(chainHistory?.[0].summaryLines.some((line) => line.includes('高阶'))).toBe(true);
    expect(chainHistory?.[0].summaryLines.some((line) => line.includes('挡回'))).toBe(true);
  });

  it('summarizes the full phase chain from launch outcomes to concrete queue deployment', () => {
    const state = createInitialGameState('hive', 78);
    state.gold = 40;
    state.phaseToolStock = ['spawn_beacon'];
    startPhase(state);
    state.phaseElapsedMs = phaseDefs[state.phaseIndex].durationMs * 0.5;

    recordLaunchOutcome(state.stats.currentPhase, 'standby');
    recordLaunchOutcome(state.stats.currentPhase, 'split');
    recordLaunchOutcome(state.stats.currentPhase, 'spawn');
    recordLaunchOutcome(state.stats.currentPhase, 'miss');
    triggerSlot(state, 'gold');
    buyPhaseTool(state, 'spawn_beacon');
    addToSpawnQueue(state, {
      unitId: 'hive_grub',
      side: 'player',
      count: 2,
      lane: 'front',
      releaseIntervalMs: 100,
      tags: ['basic'],
    });
    updateSpawnQueue(state, 1000);

    const summary = buildPhaseTelemetrySummary(state);

    expect(state.stats.currentPhase.phaseToolsPurchased).toBe(1);
    expect(state.stats.currentPhase.unitsQueuedById.hive_grub).toBe(2);
    expect(state.stats.currentPhase.unitsDeployedById.hive_grub).toBe(1);
    expect(summary.lines).toEqual(expect.arrayContaining([
      '发球 战备1 分裂1 发兵1 丢失1  战备 金1 法0 升0  发兵0',
      '回流工具 1  标记 2/0  复制 0  遗物 0  研究 0(0/4)  保底 1/3  回流效率 100%  最长非出兵 1  首次回流 0.0s  来源 工具x1',
      '入队 幼虫兵x2  部署 幼虫兵x1  高阶 0/2',
    ]));
  });
});

describe('build probe rules', () => {
  it('runs the swarm preset through a reproducible spawn-output probe', () => {
    const result = runBuildProbe('swarm', 120);

    expect(result.presetId).toBe('swarm');
    expect(result.archetype).toBe('虫群爆兵');
    expect(result.metrics.unitsQueued).toBeGreaterThanOrEqual(4);
    expect(result.metrics.unitsDeployed).toBeGreaterThan(0);
    expect(result.metrics.buildingContributionTotal).toBeGreaterThan(0);
    expect(result.metrics.overflowProgressGranted).toBeGreaterThan(0);
    expect(result.warnings).toEqual([]);
  });

  it('distinguishes copy, elite, economy, and recovery probes through live metrics', () => {
    const magic = runBuildProbe('magic_copy', 121);
    const elite = runBuildProbe('mech_elite', 122);
    const economy = runBuildProbe('economy_industry', 123);
    const recovery = runBuildProbe('recovery', 124);

    expect(magic.archetype).toBe('法术复制');
    expect(magic.metrics.spawnCopiesCreated).toBeGreaterThan(0);
    expect(magic.metrics.maxQueuedCount).toBeGreaterThan(1);
    expect(elite.archetype).toBe('机械精英');
    expect(elite.metrics.eliteQueued).toBeGreaterThan(0);
    expect(elite.metrics.highestQueuedTier).toBeGreaterThanOrEqual(2);
    expect(economy.archetype).toBe('经济工业');
    expect(economy.metrics.goldEarned).toBeGreaterThan(0);
    expect(economy.metrics.spawnMarksCreated).toBeGreaterThan(0);
    expect(recovery.archetype).toBe('逆风修复');
    expect(recovery.metrics.nonSpawnRecoveryEvents).toBeGreaterThan(0);
    expect(recovery.metrics.nonSpawnStreakMax).toBeGreaterThanOrEqual(3);
    expect(recovery.metrics.timeToRecoverySpawnMs).toBeLessThanOrEqual(15000);
    expect(Object.values(recovery.metrics.recoverySources).reduce((sum, count) => sum + count, 0)).toBeGreaterThan(0);
    expect(recovery.summaryLines.some((line) => line.includes('首次回流'))).toBe(true);
  });

  it('reports every debug preset without dead-effect warnings', () => {
    const results = runAllBuildProbes(130);

    expect(results.map((result) => result.presetId)).toEqual(debugBuildPresets.map((preset) => preset.id));
    expect(results.every((result) => result.summaryLines.length >= 3)).toBe(true);
    expect(results.flatMap((result) => result.warnings)).toEqual([]);
  });

  it('proves the build probe chain reaches combat impact after deployment', () => {
    const result = runBuildProbe('swarm', 150);
    const metrics = result.metrics as {
      combatImpactDamage?: number;
      combatImpactChecks?: number;
    };

    expect(metrics.combatImpactChecks).toBeGreaterThan(0);
    expect(metrics.combatImpactDamage).toBeGreaterThan(0);
    expect(result.summaryLines.some((line) => line.includes('战斗影响'))).toBe(true);
    expect(result.warnings).not.toContain('no_combat_impact');
  });

  it('proves natural phase rewards can form a three-chamber blueprint build without debug presets', () => {
    const result = runNaturalBlueprintRewardProbe(180);

    expect(result.probeId).toBe('natural_blueprint_reward_probe');
    expect(result.debugPresetUsed).toBe(false);
    expect(result.ok).toBe(true);
    expect(result.rewardSelections.map((selection) => selection.chamber)).toEqual(['launch', 'decision', 'unit']);
    expect(result.rewardSelections.every((selection) => selection.sourceType === 'building')).toBe(true);
    expect(result.offeredChambersByPhase.every((chambers) => chambers.join('|') === 'launch|decision|unit')).toBe(true);
    expect(result.acquiredChambers).toEqual(['launch', 'decision', 'unit']);
    expect(result.phaseTwoArchetype).not.toBe('混合构筑');
    expect(result.metrics.launchBlueprints).toBeGreaterThan(0);
    expect(result.metrics.decisionBlueprints).toBeGreaterThan(0);
    expect(result.metrics.unitBlueprints).toBeGreaterThan(0);
    expect(result.metrics.naturalLaunchOrDecisionBuildingInstalled).toBe(true);
    expect(result.metrics.nonSpawnRecoveryWithin15s).toBe(true);
    expect(result.metrics.unitsQueued).toBeGreaterThan(0);
    expect(result.metrics.unitsDeployed).toBeGreaterThan(0);
    expect(result.warnings).toEqual([]);
  });

  it('proves Arcane secondary converts Magic and Upgrade into the next Unit Spawn progress', () => {
    const result = runArcaneSecondaryRuneProbe();

    expect(result.probeId).toBe('arcane_secondary_rune_probe');
    expect(result.debugPresetUsed).toBe(false);
    expect(result.ok).toBe(true);
    expect(result.mainRaceId).toBe('hive');
    expect(result.secondaryRaceId).toBe('arcane');
    expect(result.metrics.runeGenerated).toBe(2);
    expect(result.metrics.runeSpent).toBe(2);
    expect(result.metrics.goldGeneratedRune).toBe(false);
    expect(result.metrics.unitProgressFromRune).toBe(2);
    expect(result.summaryLines.some((line) => line.includes('Arcane secondary Rune'))).toBe(true);
  });

  it('reports the v1.2 scenario metrics needed to compare build identities', () => {
    const swarm = runBuildProbe('swarm', 160);
    const magic = runBuildProbe('magic_copy', 161);
    const elite = runBuildProbe('mech_elite', 162);
    const economy = runBuildProbe('economy_industry', 163);
    const recovery = runBuildProbe('recovery', 164);

    expect(swarm.metrics.lowTierDeployShare).toBeGreaterThan(0.5);
    expect(swarm.metrics.crossChamberChainCount).toBeGreaterThanOrEqual(2);
    expect(magic.metrics.deploysPerSpawnHit).toBeGreaterThan(1);
    expect(magic.metrics.crossChamberChainCount).toBeGreaterThanOrEqual(2);
    expect(elite.metrics.averageUnitLevel).toBeGreaterThan(1);
    expect(elite.metrics.firstTier3DeployMs).toBeLessThanOrEqual(30000);
    expect(economy.metrics.queueReleaseRatePerSecond).toBeGreaterThan(0);
    expect(economy.metrics.burstWindowDeploys).toBeGreaterThan(0);
    expect(recovery.metrics.deadEffectCount).toBe(0);

    expect(swarm.summaryLines.some((line) => line.includes('低阶占比'))).toBe(true);
    expect(magic.summaryLines.some((line) => line.includes('部署/出兵'))).toBe(true);
    expect(economy.summaryLines.some((line) => line.includes('burst部署'))).toBe(true);
  });

  it('builds a runnable v1.2 validation report for all debug presets', () => {
    const report = buildProbeValidationReport(170);
    const output = formatBuildProbeValidationReport(report);

    expect(report.ok).toBe(true);
    expect(report.rows.map((row) => row.presetId)).toEqual(debugBuildPresets.map((preset) => preset.id));
    expect(report.naturalBlueprintRewardProbe.ok).toBe(true);
    expect(report.failures).toEqual([]);
    expect(output).toContain('BUILD PROBE VALIDATION PASS');
    expect(output).toContain('natural_blueprint_reward_probe');
    expect(output).toContain('虫群爆兵');
    expect(output).toContain('法术复制');
    expect(output).toContain('机械精英');
    expect(output).toContain('经济工业');
    expect(output).toContain('逆风修复');
    expect(output).toContain('chainDepth');
    expect(output).toContain('burst');
  });
});

describe('pacing preset rules', () => {
  it('uses a fast build-focused pacing preset for early build identity', () => {
    expect(activePacingPreset.id).toBe('fast_build_validation');
    expect(activePacingPreset.autoLaunchIntervalMs).toBeLessThanOrEqual(1150);
    expect(activePacingPreset.unitGateFullOpenPhaseRatio).toBeCloseTo(2, 5);
    expect(activePacingPreset.phaseDurationsMs).toHaveLength(phaseDefs.length);
    expect(Math.max(...activePacingPreset.phaseDurationsMs)).toBeLessThanOrEqual(55000);
    expect(Math.min(...activePacingPreset.phaseDurationsMs)).toBeGreaterThanOrEqual(40000);
    expect(phaseDefs.map((phase) => phase.durationMs)).toEqual(activePacingPreset.phaseDurationsMs);
  });
});

describe('phase tool rules', () => {
  it('creates a deterministic one-use phase tool stock from data', () => {
    const state = createInitialGameState('hive', 140);

    expect(state.phaseToolStock).toHaveLength(3);
    expect(new Set(state.phaseToolStock).size).toBe(3);
    expect(state.phaseToolStock.every((id) => phaseToolDefs.some((tool) => tool.id === id))).toBe(true);

    const firstStock = [...state.phaseToolStock];
    refreshPhaseToolStock(state);
    expect(state.phaseToolStock).toEqual(firstStock);

    state.phaseIndex = 1;
    refreshPhaseToolStock(state);
    expect(state.phaseToolStock).toHaveLength(3);
    expect(state.usedPhaseTools).toEqual([]);
  });

  it('lets gold buy a spawn beacon that immediately creates future spawn value', () => {
    const state = createInitialGameState('hive', 141);
    startPhase(state);
    state.phaseElapsedMs = phaseDefs[state.phaseIndex].durationMs * 0.5;
    state.gold = 40;
    state.phaseToolStock = ['spawn_beacon', 'hot_slot_calibrator', 'queue_surge'];

    const result = buyPhaseTool(state, 'spawn_beacon');

    expect(result.status).toBe('purchased');
    expect(state.gold).toBe(20);
    expect(state.pendingSpawnMarks).toBe(2);
    expect(state.stats.currentPhase.spawnMarksCreated).toBe(2);
    expect(state.stats.currentPhase.nonSpawnRecoveryEvents).toBe(1);
    expect(state.phaseToolStock).not.toContain('spawn_beacon');
    expect(buyPhaseTool(state, 'spawn_beacon').status).toBe('already_used');
  });

  it('lets a hot-slot tool turn stage gold into immediate unit progress', () => {
    const state = createInitialGameState('mech', 142);
    startPhase(state);
    state.phaseElapsedMs = phaseDefs[state.phaseIndex].durationMs * 0.5;
    state.gold = 40;
    state.phaseToolStock = ['hot_slot_calibrator'];

    const result = buyPhaseTool(state, 'hot_slot_calibrator');

    expect(result.status).toBe('purchased');
    expect(state.gold).toBe(15);
    expect(state.spawnQueue.some((unit) => unit.unitId === 'mech_drone')).toBe(true);
    expect(state.stats.currentPhase.unitsQueued).toBeGreaterThan(0);
    expect(state.stats.currentPhase.nonSpawnRecoveryEvents).toBe(1);
  });

  it('lets a marked-shot tool load the next launch ball with build tags', () => {
    const state = createInitialGameState('hive', 143);
    startPhase(state);
    state.phaseElapsedMs = phaseDefs[state.phaseIndex].durationMs * 0.5;
    state.gold = 40;
    state.phaseToolStock = ['marked_shot'];

    const result = buyPhaseTool(state, 'marked_shot');

    expect(result.status).toBe('purchased');
    expect(state.gold).toBe(18);
    expect(state.pendingLaunchBallTags).toEqual(['split+', 'spawn-mark', 'copy-mark']);
    expect(state.stats.currentPhase.nonSpawnRecoveryEvents).toBe(1);
  });

  it('opens phase tool purchases only at the mid-phase recovery window', () => {
    const state = createInitialGameState('hive', 144);
    startPhase(state);
    state.gold = 40;
    state.phaseToolStock = ['spawn_beacon'];

    state.phaseElapsedMs = phaseDefs[state.phaseIndex].durationMs * 0.2;
    expect(getPhaseToolWindowState(state)).toMatchObject({ isOpen: false });
    expect(buyPhaseTool(state, 'spawn_beacon').status).toBe('window_closed');
    expect(state.gold).toBe(40);
    expect(state.pendingSpawnMarks).toBe(0);

    state.phaseElapsedMs = phaseDefs[state.phaseIndex].durationMs * 0.5;
    expect(getPhaseToolWindowState(state)).toMatchObject({ isOpen: true });
    expect(buyPhaseTool(state, 'spawn_beacon').status).toBe('purchased');
    expect(state.gold).toBe(20);
    expect(state.pendingSpawnMarks).toBe(2);
  });

  it('limits the phase tool window to one purchase per phase', () => {
    const state = createInitialGameState('hive', 145);
    startPhase(state);
    state.phaseElapsedMs = phaseDefs[state.phaseIndex].durationMs * 0.5;
    state.gold = 80;
    state.phaseToolStock = ['spawn_beacon', 'hot_slot_calibrator'];

    expect(buyPhaseTool(state, 'spawn_beacon').status).toBe('purchased');
    const goldAfterFirstPurchase = state.gold;

    expect(buyPhaseTool(state, 'hot_slot_calibrator').status).toBe('window_used');
    expect(state.gold).toBe(goldAfterFirstPurchase);
    expect(state.phaseToolStock).toContain('hot_slot_calibrator');

    state.phaseIndex = 1;
    state.stats.currentPhase = createPhaseStats();
    refreshPhaseToolStock(state);
    startPhase(state);
    state.phaseElapsedMs = phaseDefs[state.phaseIndex].durationMs * 0.5;
    state.gold = 80;
    state.phaseToolStock = ['hot_slot_calibrator'];

    expect(buyPhaseTool(state, 'hot_slot_calibrator').status).toBe('purchased');
  });
});

describe('first spawn loop assist rules', () => {
  it('requests one forced spawn loop in the first ten seconds until a player unit appears', () => {
    const state = createInitialGameState('hive', 91);
    startPhase(state);

    expect(getFirstSpawnAssistPlan(state, 2000)).toEqual({
      forceDecisionSpawn: true,
      forceUnitSlotIndex: 0,
    });

    markFirstSpawnLoopSeen(state);

    expect(getFirstSpawnAssistPlan(state, 3000)).toEqual({
      forceDecisionSpawn: false,
      forceUnitSlotIndex: undefined,
    });
  });
});

describe('queue visibility rules', () => {
  it('names queued and deployed units with levels in floating feedback', () => {
    const state = createInitialGameState('hive', 92);
    startPhase(state);
    triggerSlot(state, 'upgrade');

    resolveUnitBallToSlot(state, 0, 1, { elapsedMs: 0, durationMs: 60000 });
    expect(state.recentFloatingTexts.some((text) => text.label.includes('Lv2 幼虫兵 入队'))).toBe(true);

    updateSpawnQueue(state, 1000);
    expect(state.recentFloatingTexts.some((text) => text.label.includes('Lv2 幼虫兵 部署'))).toBe(true);
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
    state.buildings.push({ id: 'launch_splitter_rack', chamber: 'launch', level: 1 });
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
