import { phaseDefs } from '../data/phases';
import { activePacingPreset } from '../data/pacing';
import { raceDefs } from '../data/races';
import { unitDefs } from '../data/units';
import { addToSpawnQueue } from './SpawnQueueSystem';
import { getDoctrineUpgradeCarry } from './DoctrineSystem';
import { getUpgradeCacheCarry, recordRelicGateBlocked, recordUpgradeCacheCarry } from './RelicSystem';
import {
  recordBuildingContribution,
  recordGateAcceleration,
  recordGateBlocked,
  recordOverflowProgress,
  recordQueueBurst,
} from './StatsSystem';
import type { GameState, RaceId, UnitGateState, UnitSlotDef, UnitSlotState } from '../types/game';

export type UnitBallResolution =
  | {
    status: 'resolved';
    unitId: string;
    slotIndex: number;
    spawnedCount: number;
    remainingProgress: number;
  }
  | {
    status: 'blocked';
    slotIndex: number;
    redirectSlotIndex: number;
    blockedGateHits: number;
  };

export function getUnitGateOpenBoundaryRatio(elapsedMs: number, durationMs: number): number {
  return getUnitGateState(elapsedMs, durationMs).openBoundaryRatio;
}

export function getUnitGateState(elapsedMs: number, durationMs: number): UnitGateState {
  const safeDuration = Math.max(1, durationMs);
  const progress = clamp(elapsedMs / (safeDuration * activePacingPreset.unitGateFullOpenPhaseRatio), 0, 1);
  const openBoundaryRatio = 0.2 + progress * 0.8;
  const openSlotCount = clamp(Math.ceil(openBoundaryRatio * 5 - 0.00001), 1, 5);
  return {
    elapsedMs,
    durationMs: safeDuration,
    openBoundaryRatio,
    openSlotCount,
    openUnitIndex: openSlotCount - 1,
  };
}

export function getUnlockedUnitSlotCount(_state: GameState, elapsedMs: number, durationMs: number): number {
  return getUnitGateState(elapsedMs, durationMs).openSlotCount;
}

export function addUnitSlotProgress(state: GameState, unitId: string, amount: number): number {
  const slot = findUnitSlotState(state, unitId);
  let progress = slot.progress + amount;
  let spawnedCount = 0;

  while (progress >= slot.requirement) {
    progress -= slot.requirement;
    spawnedCount += 1;
    queueSpecificUnit(state, unitId);
  }

  slot.progress = progress;
  if (spawnedCount > 0) spillProgressToNextSlot(state, slot, spawnedCount);
  return spawnedCount;
}

export function resolveUnitBallToSlot(
  state: GameState,
  slotIndex: number,
  ballValue: number,
  options: { elapsedMs?: number; durationMs?: number; blockedGateHits?: number } = {},
): UnitBallResolution {
  const race = raceDefs[state.currentRaceId];
  const phase = phaseDefs[state.phaseIndex] ?? phaseDefs.at(-1);
  const elapsedMs = options.elapsedMs ?? state.phaseElapsedMs;
  const durationMs = options.durationMs ?? phase?.durationMs ?? 60000;
  const normalGate = getUnitGateState(elapsedMs, durationMs);
  const effectiveGate = getEffectiveGateState(state, elapsedMs, durationMs);
  const unlockedCount = effectiveGate.openSlotCount;

  if (effectiveGate.openSlotCount > normalGate.openSlotCount) {
    recordBuildingContribution(state.stats.currentPhase, 'unit', effectiveGate.openSlotCount - normalGate.openSlotCount);
    recordGateAcceleration(state.stats.currentPhase);
  }

  if (slotIndex >= unlockedCount) {
    recordGateBlocked(state.stats.currentPhase);
    recordRelicGateBlocked(state);
    return {
      status: 'blocked',
      slotIndex,
      redirectSlotIndex: unlockedCount - 1,
      blockedGateHits: (options.blockedGateHits ?? 0) + 1,
    };
  }

  const slot = state.unitSlotStates[state.currentRaceId][clamp(slotIndex, 0, race.unitSlots.length - 1)];
  const spawnedCount = addUnitSlotProgress(state, slot.unitId, ballValue);
  return {
    status: 'resolved',
    unitId: slot.unitId,
    slotIndex: slot.index,
    spawnedCount,
    remainingProgress: slot.progress,
  };
}

export function getCurrentRaceUnitSlots(state: GameState): UnitSlotDef[] {
  return raceDefs[state.currentRaceId].unitSlots;
}

export function getCurrentRaceUnitSlotStates(state: GameState): UnitSlotState[] {
  return state.unitSlotStates[state.currentRaceId];
}

function findUnitSlot(unitId: string): UnitSlotDef {
  for (const race of Object.values(raceDefs)) {
    const slot = race.unitSlots.find((candidate) => candidate.unitId === unitId);
    if (slot) return slot;
  }
  throw new Error(`Unknown unit slot for ${unitId}`);
}

function findUnitSlotState(state: GameState, unitId: string): UnitSlotState {
  for (const slots of Object.values(state.unitSlotStates)) {
    const slot = slots.find((candidate) => candidate.unitId === unitId);
    if (slot) return slot;
  }
  throw new Error(`Unknown unit slot state for ${unitId}`);
}

function spillProgressToNextSlot(state: GameState, slot: UnitSlotState, spawnedCount: number) {
  const building = state.buildings.find((candidate) => candidate.id === 'unit_overflow_hatchery');
  const amount = (building?.level ?? 0) * spawnedCount;
  if (amount <= 0) return;

  const slots = state.unitSlotStates[state.currentRaceId];
  const nextSlot = slots[slot.index + 1];
  if (!nextSlot) return;

  nextSlot.progress += amount;
  recordBuildingContribution(state.stats.currentPhase, 'unit', amount);
  recordOverflowProgress(state.stats.currentPhase, amount);
  state.recentFloatingTexts.push({ label: `溢流孵化器：${nextSlot.label} +${amount}`, color: 0x86efac });
}

function getEffectiveGateState(state: GameState, elapsedMs: number, durationMs: number): UnitGateState {
  const building = state.buildings.find((candidate) => candidate.id === 'unit_gate_actuator');
  const level = building?.level ?? 0;
  if (level <= 0) return getUnitGateState(elapsedMs, durationMs);

  const effectiveDuration = durationMs * Math.max(0.29, 0.45 - (level - 1) * 0.08);
  return getUnitGateState(elapsedMs, effectiveDuration);
}

function queueSpecificUnit(state: GameState, unitId: string) {
  const unit = unitDefs[unitId];
  const raceId = unit.raceId as RaceId;
  const consumedLevelBonus = state.pendingSpawnLevelBonus;
  const baseLevel = (state.unitLevels[unitId] ?? 1)
    + consumedLevelBonus
    + state.modifiers.nextPhaseSpawnLevelBonus;
  const count = 1 + state.modifiers.spawnExtraCount + state.modifiers.pendingSpawnCopies;
  const createsElite = state.nextSpawnCreatesElite && unit.costTier > 1;
  const queueBurst = getQueueConveyorBurst(state);
  const tags = [
    unit.costTier === 1 ? 'basic' : 'advanced',
    ...(createsElite ? ['elite'] : []),
    ...queueBurst.tags,
  ];

  addToSpawnQueue(state, {
    unitId,
    side: 'player',
    count,
    lane: unit.lane,
    level: baseLevel,
    lifetime: createsElite ? 'elite' : 'standard',
    isElite: createsElite,
    releaseIntervalMs: queueBurst.releaseIntervalMs,
    tags,
  });

  if (createsElite) state.nextSpawnCreatesElite = false;
  if (raceId === 'hive' && unitId !== 'hive_grub' && state.modifiers.hiveExtraGrubCount > 0) {
    addToSpawnQueue(state, {
      unitId: 'hive_grub',
      side: 'player',
      count: state.modifiers.hiveExtraGrubCount,
      lane: unitDefs.hive_grub.lane,
      level: Math.max(1, baseLevel - 1),
      tags: ['basic'],
    });
  }

  const cachedLevelBonus = Math.max(
    getUpgradeCacheCarry(state, unitId, consumedLevelBonus),
    getDoctrineUpgradeCarry(state, unitId, consumedLevelBonus),
  );
  state.pendingSpawnLevelBonus = cachedLevelBonus;
  recordUpgradeCacheCarry(state, cachedLevelBonus);
  state.modifiers.pendingSpawnCopies = 0;
}

function getQueueConveyorBurst(state: GameState): { releaseIntervalMs?: number; tags: string[] } {
  const building = state.buildings.find((candidate) => candidate.id === 'unit_queue_conveyor');
  const level = building?.level ?? 0;
  if (level <= 0) return { tags: [] };

  const releaseIntervalMs = Math.max(260, 470 - level * 70);
  recordBuildingContribution(state.stats.currentPhase, 'unit', level);
  recordQueueBurst(state.stats.currentPhase);
  state.recentFloatingTexts.push({ label: `队列输送带：部署间隔 ${releaseIntervalMs}ms`, color: 0x93c5fd });
  return {
    releaseIntervalMs,
    tags: ['queue-burst'],
  };
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}
