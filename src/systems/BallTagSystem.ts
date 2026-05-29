import {
  recordNonSpawnRecovery,
  recordSpawnCopiesCreated,
  recordSpawnMarksCreated,
} from './StatsSystem';
import type { BallPayload, BallTagId, GameState } from '../types/game';

export function normalizeBallTags(tags: BallTagId[] = []): BallTagId[] {
  return Array.from(new Set(tags));
}

export function buildTaggedSplitRelaunchPlan(
  payload: BallPayload,
  extraSplitBalls = 0,
): Array<{ stage: 'launch'; value: number; tags: BallTagId[] }> {
  const tags = normalizeBallTags(payload.tags).filter((tag) => tag !== 'split+');
  const count = 2 + extraSplitBalls + (payload.tags.includes('split+') ? 1 : 0);
  return Array.from({ length: count }, () => ({
    stage: 'launch',
    value: payload.value,
    tags,
  }));
}

export function applyTaggedLaunchMiss(state: GameState, payload: BallPayload): number {
  if (!payload.tags.includes('recycle')) return 0;

  const recovered = Math.max(1, payload.value);
  state.pendingSpawnMarks += recovered;
  recordSpawnMarksCreated(state.stats.currentPhase, recovered);
  recordNonSpawnRecovery(state.stats.currentPhase, 'ball_tag_recycle', state.phaseElapsedMs);
  state.recentFloatingTexts.push({ label: `回收球：出兵标记 +${recovered}`, color: 0x86efac });
  return recovered;
}

export function applyDecisionSpawnTags(state: GameState, payload: BallPayload): BallPayload {
  let value = payload.value;
  const tags = normalizeBallTags(payload.tags);

  if (tags.includes('spawn-mark')) value += 1;
  if (tags.includes('heavy')) value += 1;
  if (tags.includes('copy-mark')) {
    state.modifiers.pendingSpawnCopies += 1;
    recordSpawnCopiesCreated(state.stats.currentPhase, 1);
    recordNonSpawnRecovery(state.stats.currentPhase, 'ball_tag_spawn', state.phaseElapsedMs);
    state.recentFloatingTexts.push({ label: '复制标记：下一次出兵复制 +1', color: 0xc084fc });
  }

  return {
    value,
    tags: tags.filter((tag) => tag === 'recycle' || tag === 'split+'),
  };
}
