import type { GameState } from '../types/game';

const FIRST_LOOP_ASSIST_WINDOW_MS = 10000;

export type FirstSpawnAssistPlan = {
  forceDecisionSpawn: boolean;
  forceUnitSlotIndex?: number;
};

export function getFirstSpawnAssistPlan(state: GameState, elapsedMs = state.phaseElapsedMs): FirstSpawnAssistPlan {
  const hasPlayerUnit = state.battle.units.some((unit) => unit.side === 'player' && unit.hp > 0);
  const active = state.firstLoopAssistActive
    && !state.hasSeenFirstSpawnLoop
    && !hasPlayerUnit
    && state.phaseActive
    && elapsedMs <= FIRST_LOOP_ASSIST_WINDOW_MS;

  if (!active) {
    return { forceDecisionSpawn: false };
  }

  return {
    forceDecisionSpawn: !state.firstSpawnOutcomeForced,
    forceUnitSlotIndex: state.firstUnitSlotForced ? undefined : 0,
  };
}

export function markFirstSpawnOutcomeForced(state: GameState) {
  state.firstSpawnOutcomeForced = true;
}

export function markFirstUnitSlotForced(state: GameState) {
  state.firstUnitSlotForced = true;
}

export function markFirstSpawnLoopSeen(state: GameState) {
  state.hasSeenFirstSpawnLoop = true;
  state.firstLoopAssistActive = false;
}
