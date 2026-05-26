import { phaseDefs } from '../data/phases';
import { raceDefs } from '../data/races';
import { unitDefs } from '../data/units';
import { addToSpawnQueue } from './SpawnQueueSystem';
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
  const progress = clamp(elapsedMs / (safeDuration * 0.5), 0, 1);
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
  const unlockedCount = getUnitGateState(elapsedMs, durationMs).openSlotCount;

  if (slotIndex >= unlockedCount) {
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

function queueSpecificUnit(state: GameState, unitId: string) {
  const unit = unitDefs[unitId];
  const raceId = unit.raceId as RaceId;
  const baseLevel = (state.unitLevels[unitId] ?? 1)
    + state.pendingSpawnLevelBonus
    + state.modifiers.nextPhaseSpawnLevelBonus;
  const count = 1 + state.modifiers.spawnExtraCount + state.modifiers.pendingSpawnCopies;
  const createsElite = state.nextSpawnCreatesElite && unit.costTier > 1;

  addToSpawnQueue(state, {
    unitId,
    side: 'player',
    count,
    lane: unit.lane,
    level: baseLevel,
    lifetime: createsElite ? 'elite' : 'standard',
    isElite: createsElite,
    tags: [unit.costTier === 1 ? 'basic' : 'advanced', ...(createsElite ? ['elite'] : [])],
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

  state.pendingSpawnLevelBonus = 0;
  state.modifiers.pendingSpawnCopies = 0;
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}
