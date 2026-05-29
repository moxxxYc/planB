import { relicDefs } from '../data/relics';
import { unitDefs } from '../data/units';
import {
  recordNonSpawnRecovery,
  recordRelicTrigger,
  recordSpawnCopiesCreated,
  recordSpawnMarksCreated,
} from './StatsSystem';
import type { BallTagId, GameState, RelicDef } from '../types/game';

export type RelicInstallResult =
  | { status: 'installed'; id: string }
  | { status: 'already_owned'; id: string }
  | { status: 'unknown_relic'; id: string };

export function getRelicDef(id: string): RelicDef | undefined {
  return relicDefs.find((relic) => relic.id === id);
}

export function getAvailableRelicRewardDefs(state: GameState): RelicDef[] {
  return relicDefs.filter((relic) => !hasRelic(state, relic.id));
}

export function isRelicReward(id: string): boolean {
  return Boolean(getRelicDef(id));
}

export function hasRelic(state: GameState, id: string): boolean {
  return state.relics.some((relic) => relic.id === id);
}

export function installRelic(state: GameState, id: string): RelicInstallResult {
  if (!getRelicDef(id)) return { status: 'unknown_relic', id };
  if (hasRelic(state, id)) return { status: 'already_owned', id };

  state.relics.push({ id });
  state.recentFloatingTexts.push({ label: `${getRelicDef(id)?.name ?? id} 已获得`, color: 0xfacc15 });
  return { status: 'installed', id };
}

export function recordRelicLaunchMiss(state: GameState): number {
  if (!hasRelic(state, 'entropy_fuse')) return 0;

  state.relicEvents.entropyCharges += 1;
  if (state.relicEvents.entropyCharges < 3) return 0;

  state.relicEvents.entropyCharges = 0;
  createRelicSpawnMark(state, '逆熵保险丝：出兵标记 +1');
  return 1;
}

export function recordRelicGateBlocked(state: GameState): number {
  if (!hasRelic(state, 'gate_momentum')) return 0;

  createRelicSpawnMark(state, '挡板动量芯：出兵标记 +1');
  return 1;
}

export function recordRelicMagicHit(state: GameState): number {
  if (!hasRelic(state, 'spell_echo_relic')) return 0;

  state.modifiers.pendingSpawnCopies += 1;
  recordRelicTrigger(state.stats.currentPhase);
  recordSpawnCopiesCreated(state.stats.currentPhase, 1);
  recordNonSpawnRecovery(state.stats.currentPhase, 'relic_spell_echo', state.phaseElapsedMs);
  state.recentFloatingTexts.push({ label: '法术回声石：复制 +1', color: 0xc084fc });
  return 1;
}

export function primeLaunchRelicTags(state: GameState): BallTagId[] {
  if (!hasRelic(state, 'prism_magazine')) return [];

  const tags: BallTagId[] = ['split+', 'spawn-mark'];
  setBallTags(state, mergeBallTags(state.pendingLaunchBallTags, tags));
  recordRelicTrigger(state.stats.currentPhase);
  state.recentFloatingTexts.push({ label: '棱镜弹匣：下一发带标签', color: 0xc084fc });
  return tags;
}

export function setBallTags(state: GameState, tags: BallTagId[]) {
  state.pendingLaunchBallTags = tags;
  state.ballTags = state.pendingLaunchBallTags;
}

export function getUpgradeCacheCarry(state: GameState, unitId: string, consumedLevelBonus: number): number {
  if (!hasRelic(state, 'upgrade_cache')) return 0;
  if (consumedLevelBonus <= 0) return 0;
  if (unitDefs[unitId]?.costTier !== 1) return 0;
  return 1;
}

export function recordUpgradeCacheCarry(state: GameState, amount: number) {
  if (amount <= 0) return;

  recordRelicTrigger(state.stats.currentPhase);
  state.recentFloatingTexts.push({ label: `校准存储芯：保留 Lv+${amount}`, color: 0x60a5fa });
}

function mergeBallTags(left: BallTagId[], right: BallTagId[]): BallTagId[] {
  return Array.from(new Set([...left, ...right]));
}

function createRelicSpawnMark(state: GameState, label: string) {
  state.pendingSpawnMarks += 1;
  recordRelicTrigger(state.stats.currentPhase);
  recordSpawnMarksCreated(state.stats.currentPhase, 1);
  recordNonSpawnRecovery(state.stats.currentPhase, 'relic_spawn_mark', state.phaseElapsedMs);
  state.recentFloatingTexts.push({ label, color: 0xfacc15 });
}
