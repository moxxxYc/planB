import { phaseDefs } from '../data/phases';
import { raceDefs } from '../data/races';
import { secondaryRaceDefs } from '../data/secondaryRaces';
import { createInitialGameState } from './GameState';
import { createPhaseStats } from './StatsSystem';
import type { GameState, PhaseStats, RaceId, SecondaryRaceId } from '../types/game';

export type RunOutcome = 'victory' | 'defeat';

export interface PrototypeRunConfig {
  mainRaceId: RaceId;
  secondaryRaceId?: SecondaryRaceId;
  seed?: number;
}

export interface RunEndSummary {
  title: string;
  subtitle: string;
  primaryLines: string[];
  diagnosisTags: string[];
  chainLines: string[];
  nextRunHint: string;
}

export function createPrototypeRunState(config: PrototypeRunConfig): GameState {
  return createInitialGameState(config.mainRaceId, config.seed ?? 24391, {
    secondaryRaceId: config.secondaryRaceId,
  });
}

export function buildRunSetupSummary(config: PrototypeRunConfig): string[] {
  const mainRace = raceDefs[config.mainRaceId];
  const secondaryRace = config.secondaryRaceId ? secondaryRaceDefs[config.secondaryRaceId] : undefined;
  return [
    `主族：${mainRace.name}`,
    `副族：${secondaryRace?.name ?? '无'}`,
    `目标：完成 ${phaseDefs.length} 个阶段并守住基地`,
  ];
}

export function buildRunEndSummary(state: GameState, outcome: RunOutcome): RunEndSummary {
  const lastStats = state.stats.lastPhase ?? state.stats.currentPhase ?? createPhaseStats();
  const totals = buildRunTotals(state, lastStats);
  const mainRace = raceDefs[state.currentRaceId];
  const secondaryRace = state.secondaryRaceId ? secondaryRaceDefs[state.secondaryRaceId] : undefined;
  const diagnosisTags = outcome === 'victory' ? ['构筑成型', '六阶段完成'] : buildFailureDiagnosisTags(lastStats);
  const archetype = state.buildArchetypeHint || state.chainHistory.at(-1)?.archetype || '混合构筑';

  return {
    title: outcome === 'victory' ? '原型通关' : '运行失败',
    subtitle: outcome === 'victory'
      ? '机器完成了当前六阶段验证链。'
      : '基地被击破，下一局应优先修复暴露出的机器瓶颈。',
    primaryLines: [
      `主族 ${mainRace.name} / 副族 ${secondaryRace?.name ?? '无'}`,
      `阶段 ${Math.min(state.phaseIndex + 1, phaseDefs.length)}/${phaseDefs.length}  奖励 ${state.selectedRewards.length}  构筑 ${archetype}`,
      `总入队 ${totals.unitsQueued}  总部署 ${totals.unitsDeployed}  高阶入队 ${totals.advancedUnitsQueued}  挡回 ${totals.gateBlockedEvents}`,
      `基地 我方 ${Math.ceil(state.battle.bases.player.hp)}/${state.battle.bases.player.maxHp}  敌方 ${Math.ceil(state.battle.bases.enemy.hp)}/${state.battle.bases.enemy.maxHp}`,
    ],
    diagnosisTags,
    chainLines: buildChainLines(state),
    nextRunHint: buildNextRunHint(diagnosisTags, outcome),
  };
}

function buildRunTotals(state: GameState, currentStats: PhaseStats) {
  const historyTotals = state.chainHistory.reduce((totals, entry) => ({
    unitsQueued: totals.unitsQueued + entry.unitsQueued,
    unitsDeployed: totals.unitsDeployed + entry.unitsDeployed,
    advancedUnitsQueued: totals.advancedUnitsQueued + entry.advancedUnitsQueued,
    gateBlockedEvents: totals.gateBlockedEvents + entry.gateBlockedEvents,
  }), {
    unitsQueued: 0,
    unitsDeployed: 0,
    advancedUnitsQueued: 0,
    gateBlockedEvents: 0,
  });

  if (state.chainHistory.length > 0) return historyTotals;

  return {
    unitsQueued: currentStats.unitsQueued,
    unitsDeployed: Object.values(currentStats.unitsDeployedById).reduce((sum, count) => sum + count, 0),
    advancedUnitsQueued: currentStats.advancedUnitsQueued,
    gateBlockedEvents: currentStats.gateBlockedEvents,
  };
}

function buildFailureDiagnosisTags(stats: PhaseStats): string[] {
  const tags: string[] = [];
  const nonSpawnHits = stats.slotTriggers.gold + stats.slotTriggers.magic + stats.slotTriggers.upgrade;

  if (stats.slotTriggers.spawn <= 0 || stats.unitsQueued <= 0) tags.push('出兵链断档');
  if (nonSpawnHits > 0 && stats.nonSpawnRecoveryEvents <= 0) tags.push('战备回流弱');
  if (stats.gateBlockedEvents >= 2) tags.push('高阶挡板卡顿');
  if (stats.unitsQueued > 0 && deployedCount(stats) < stats.unitsQueued) tags.push('队列释放偏慢');
  if (stats.playerBaseDamage > stats.enemyBaseDamage) tags.push('前线承压');

  return tags.length > 0 ? tags : ['战线承压'];
}

function buildNextRunHint(tags: string[], outcome: RunOutcome): string {
  if (outcome === 'victory') return '下局可以换主族或关闭副族，验证同一机器链是否仍然成立。';
  if (tags.includes('出兵链断档') && tags.includes('高阶挡板卡顿')) {
    return '下局优先修复：让非出兵收益更快回到 Unit Spawn，并降低早期高阶挡板依赖。';
  }
  if (tags.includes('队列释放偏慢')) return '下局优先修复：提高队列释放或减少只入队不部署的构筑。';
  if (tags.includes('战备回流弱')) return '下局优先修复：选择能把 Magic、Upgrade 或丢失回流到出兵的奖励。';
  return '下局优先修复：让早期 Unit Spawn 更稳定形成前线。';
}

function buildChainLines(state: GameState): string[] {
  if (state.chainHistory.length === 0) return ['暂无阶段链路记录'];
  return state.chainHistory.slice(-4).map((entry) => (
    `${entry.phaseName}: ${entry.archetype} / ${entry.dominantChamber} / 入队${entry.unitsQueued} 部署${entry.unitsDeployed}`
  ));
}

function deployedCount(stats: PhaseStats): number {
  return Object.values(stats.unitsDeployedById).reduce((sum, count) => sum + count, 0);
}
