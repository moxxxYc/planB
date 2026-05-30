import type { GameSpeedMultiplier, GameState } from '../types/game';

export const GAME_SPEED_STEPS: readonly GameSpeedMultiplier[] = [1, 2, 4] as const;

export function normalizeGameSpeed(value: number): GameSpeedMultiplier {
  if (!Number.isFinite(value) || value <= 1) return 1;
  if (value <= 2) return 2;
  return 4;
}

export function setGameSpeed(state: GameState, value: number): GameSpeedMultiplier {
  const speed = normalizeGameSpeed(value);
  state.speedMultiplier = speed;
  return speed;
}

export function cycleGameSpeed(state: GameState): GameSpeedMultiplier {
  const currentIndex = GAME_SPEED_STEPS.indexOf(normalizeGameSpeed(state.speedMultiplier));
  const nextIndex = (currentIndex + 1) % GAME_SPEED_STEPS.length;
  return setGameSpeed(state, GAME_SPEED_STEPS[nextIndex]);
}

export function getScaledDeltaMs(state: GameState, deltaMs: number): number {
  return Math.max(0, deltaMs) * normalizeGameSpeed(state.speedMultiplier);
}
