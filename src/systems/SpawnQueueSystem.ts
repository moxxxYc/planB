import { spawnBattleUnit } from './BattleSystem';
import { unitDefs } from '../data/units';
import type { GameState, LaneName, Side, SpawnQueueItem, UnitLifetime } from '../types/game';

const DEFAULT_RELEASE_INTERVAL_MS = 650;

export type SpawnQueueInput = {
  unitId: string;
  side: Side;
  count: number;
  lane?: LaneName;
  releaseIntervalMs?: number;
  nextReleaseInMs?: number;
  level?: number;
  lifetime?: UnitLifetime;
  isElite?: boolean;
  tags?: string[];
};

export function addToSpawnQueue(state: GameState, input: SpawnQueueInput) {
  const tags = input.tags ?? [];
  const isElite = input.isElite ?? tags.includes('elite');
  const lifetime = input.lifetime ?? (isElite ? 'elite' : 'standard');
  const item: SpawnQueueItem = {
    id: `queue-${state.nextQueueId++}`,
    unitId: input.unitId,
    side: input.side,
    count: input.count,
    lane: input.lane ?? 'mid',
    releaseIntervalMs: input.releaseIntervalMs ?? DEFAULT_RELEASE_INTERVAL_MS,
    nextReleaseInMs: input.nextReleaseInMs ?? 0,
    level: input.level ?? 1,
    lifetime,
    isElite,
    tags: [...tags, ...(isElite && !tags.includes('elite') ? ['elite'] : [])],
  };

  const existing = state.spawnQueue.find((candidate) => canMergeQueueItem(candidate, item));
  if (existing) {
    existing.count += item.count;
    existing.nextReleaseInMs = Math.min(existing.nextReleaseInMs, item.nextReleaseInMs);
  } else {
    state.spawnQueue.push(item);
  }

  if (item.side === 'player') {
    const unit = unitDefs[item.unitId];
    state.stats.currentPhase.unitsQueued += item.count;
    const eliteText = item.isElite ? ' 精英' : '';
    state.recentFloatingTexts.push({ label: `Lv${item.level} ${unit.name}${eliteText} 入队 x${item.count}`, color: item.isElite ? 0xfacc15 : 0x4ade80 });
  }
}

export function updateSpawnQueue(state: GameState, deltaMs: number) {
  if (state.isBuildPause || !state.phaseActive) return;

  for (const item of state.spawnQueue) {
    item.nextReleaseInMs -= deltaMs * getQueueReleaseSpeedMultiplier(state);
    if (item.nextReleaseInMs > 0) continue;
    if (!canDeployFromQueue(state, item)) continue;

    spawnBattleUnit(state, item.side, item.unitId, item.level, false, {
      lifetime: item.lifetime,
      isElite: item.isElite,
      tags: item.tags,
    });
    item.count -= 1;
    item.nextReleaseInMs = item.releaseIntervalMs;
    if (item.side === 'player') {
      const unit = unitDefs[item.unitId];
      const eliteText = item.isElite ? ' 精英' : '';
      state.recentFloatingTexts.push({ label: `Lv${item.level} ${unit.name}${eliteText} 部署`, color: item.isElite ? 0xfacc15 : 0x86efac });
    }
  }

  state.spawnQueue = state.spawnQueue.filter((item) => item.count > 0);
}

export function countQueuedUnits(state: GameState) {
  return state.spawnQueue.reduce((sum, item) => sum + item.count, 0);
}

export function canDeployFromQueue(state: GameState, item: SpawnQueueItem): boolean {
  if (item.side !== 'player') return true;

  if (item.isElite || item.lifetime === 'elite') {
    const eliteCount = state.battle.units.filter((unit) => unit.side === 'player' && unit.isElite && unit.hp > 0).length;
    return eliteCount < state.eliteUnitCap;
  }

  const standardCount = state.battle.units.filter((unit) => (
    unit.side === 'player'
    && unit.hp > 0
    && unit.lifetime === 'standard'
  )).length;
  return standardCount < state.playerStandardUnitSoftCap;
}

function canMergeQueueItem(left: SpawnQueueItem, right: SpawnQueueItem): boolean {
  return left.unitId === right.unitId
    && left.side === right.side
    && left.lane === right.lane
    && left.level === right.level
    && left.lifetime === right.lifetime
    && left.isElite === right.isElite
    && left.releaseIntervalMs === right.releaseIntervalMs
    && left.tags.join('|') === right.tags.join('|');
}

function getQueueReleaseSpeedMultiplier(state: GameState): number {
  return 1 + state.modifiers.queueReleaseSpeedBonus;
}
