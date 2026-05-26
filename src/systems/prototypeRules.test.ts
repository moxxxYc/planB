import { describe, expect, it } from 'vitest';
import { raceDefs } from '../data/races';
import { rewardDefs } from '../data/rewards';
import { slotDefs } from '../data/slots';
import { createInitialGameState } from './GameState';
import { triggerSlot } from './SlotTriggerSystem';
import { spawnBattleUnit, updateBattle } from './BattleSystem';
import { applyReward, buildRewardChoices } from './RewardSystem';
import { completePhase, resumeNextPhase, startPhase, updatePhaseEnemySpawns } from './PhaseSystem';
import { addToSpawnQueue, updateSpawnQueue } from './SpawnQueueSystem';
import {
  addUnitSlotProgress,
  getUnitGateOpenBoundaryRatio,
  getUnlockedUnitSlotCount,
  resolveUnitBallToSlot,
} from './UnitSpawnProgressSystem';

describe('slot trigger rules', () => {
  it('does not expose a charge slot or charge rewards', () => {
    expect(slotDefs.map((slot) => slot.id)).toEqual(['spawn', 'gold', 'magic', 'upgrade', 'special']);
    expect(rewardDefs.some((reward) => reward.id.includes('charge'))).toBe(false);
    expect(rewardDefs.some((reward) => reward.description.includes('蓄力') || reward.description.includes('CHARGE'))).toBe(false);
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
    });

    triggerSlot(state, 'magic');
    const damagedEnemy = state.battle.units.find((unit) => unit.id === 'enemy-test');
    expect(damagedEnemy?.hp).toBeLessThan(38);
    expect(state.spawnQueue).toHaveLength(0);
  });
});

describe('unit spawn progress rules', () => {
  it('spawns a specific unit from slot progress and preserves overflow progress', () => {
    const state = createInitialGameState('hive', 13);
    const slot = raceDefs.hive.unitSlots[1];

    addUnitSlotProgress(state, slot.unitId, 2);
    expect(state.unitSlotProgress[slot.unitId]).toBe(2);
    expect(state.spawnQueue).toHaveLength(0);

    addUnitSlotProgress(state, slot.unitId, 2);

    expect(state.spawnQueue.some((unit) => unit.unitId === slot.unitId && unit.side === 'player')).toBe(true);
    expect(state.unitSlotProgress[slot.unitId]).toBe(1);
  });

  it('opens the single unit gate continuously across the first half of the phase', () => {
    const state = createInitialGameState('mech', 17);
    const durationMs = 60000;

    expect(getUnlockedUnitSlotCount(state, 0, durationMs)).toBe(1);
    expect(getUnitGateOpenBoundaryRatio(0, durationMs)).toBe(0.2);
    expect(getUnitGateOpenBoundaryRatio(durationMs * 0.25, durationMs)).toBeGreaterThan(0.2);
    expect(getUnitGateOpenBoundaryRatio(durationMs * 0.25, durationMs)).toBeLessThan(1);
    expect(getUnitGateOpenBoundaryRatio(durationMs * 0.5, durationMs)).toBe(1);
    expect(getUnitGateOpenBoundaryRatio(durationMs * 0.8, durationMs)).toBe(1);
    expect(getUnlockedUnitSlotCount(state, durationMs * 0.5, durationMs)).toBe(5);
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
    expect(state.unitSlotProgress[titanSlot.unitId]).toBe(0);
    expect(state.spawnQueue.some((unit) => unit.unitId === titanSlot.unitId)).toBe(false);
  });
});

describe('battle simulation', () => {
  it('units move, attack, die, and damage bases deterministically', () => {
    const state = createInitialGameState('mech', 11);
    startPhase(state);
    triggerSlot(state, 'spawn');
    resolveUnitBallToSlot(state, 0, 1, { elapsedMs: 0, durationMs: 60000 });
    updateSpawnQueue(state, 1000);
    state.battle.units.push({
      id: 'enemy-target',
      defId: 'enemy_raider',
      side: 'enemy',
      hp: 18,
      maxHp: 18,
      damage: 5,
      x: 665,
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
    });

    for (let step = 0; step < 250; step += 1) {
      updateBattle(state, 100);
    }

    expect(state.stats.currentPhase.damageDealt).toBeGreaterThan(0);
    expect(state.stats.currentPhase.kills + state.stats.currentPhase.enemyBaseDamage).toBeGreaterThan(0);
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
