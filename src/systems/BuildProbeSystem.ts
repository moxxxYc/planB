import { debugBuildPresets } from '../data/debugPresets';
import { unitDefs } from '../data/units';
import { spawnBattleUnit, updateBattle } from './BattleSystem';
import { consumeSpawnMarkBonus, recordLaunchMiss } from './BuildingSystem';
import { buildPhaseTelemetrySummary } from './BuildTelemetrySystem';
import { applyDebugBuildPreset } from './DebugPresetSystem';
import { createInitialGameState } from './GameState';
import { startPhase } from './PhaseSystem';
import { recordDoctrineLaunchMiss } from './DoctrineSystem';
import { recordRelicLaunchMiss } from './RelicSystem';
import { triggerSlot } from './SlotTriggerSystem';
import { updateSpawnQueue } from './SpawnQueueSystem';
import { recordLaunchOutcome } from './StatsSystem';
import { resolveUnitBallToSlot } from './UnitSpawnProgressSystem';
import type { DebugBuildPresetId, GameState, RaceId, SlotId, SpawnQueueItem } from '../types/game';

export interface BuildProbeMetrics {
  slotTriggers: Record<SlotId, number>;
  unitsQueued: number;
  unitsDeployed: number;
  eliteQueued: number;
  highestQueuedTier: number;
  maxQueuedLevel: number;
  maxQueuedCount: number;
  goldEarned: number;
  spawnMarksCreated: number;
  spawnMarksConsumed: number;
  spawnCopiesCreated: number;
  nonSpawnRecoveryEvents: number;
  nonSpawnStreakMax: number;
  timeToRecoverySpawnMs?: number;
  recoverySources: Record<string, number>;
  relicTriggers: number;
  overflowProgressGranted: number;
  gateAccelerationEvents: number;
  queueBurstEvents: number;
  combatImpactChecks: number;
  combatImpactDamage: number;
  buildingContributionTotal: number;
  researchPoints: number;
  lowTierDeployShare: number;
  averageUnitLevel: number;
  deploysPerSpawnHit: number;
  firstTier3DeployMs?: number;
  queueReleaseRatePerSecond: number;
  burstWindowDeploys: number;
  crossChamberChainCount: number;
  chainDepth: number;
  deadEffectCount: number;
}

export interface BuildProbeResult {
  presetId: DebugBuildPresetId;
  presetName: string;
  raceId: RaceId;
  archetype: string;
  dominantChamber: string;
  metrics: BuildProbeMetrics;
  summaryLines: string[];
  warnings: string[];
}

const PROBE_PHASE_MS = 60000;

export function runAllBuildProbes(seed = 100): BuildProbeResult[] {
  return debugBuildPresets.map((preset, index) => runBuildProbe(preset.id, seed + index));
}

export function runBuildProbe(presetId: DebugBuildPresetId, seed = 100): BuildProbeResult {
  const preset = debugBuildPresets.find((candidate) => candidate.id === presetId);
  if (!preset) throw new Error(`Unknown debug build preset: ${presetId}`);

  const state = createInitialGameState(preset.raceId, seed);
  applyDebugBuildPreset(state, presetId);
  startPhase(state);

  const initialGold = state.gold;
  runProbeScript(state, presetId);
  const queuedSnapshot = state.spawnQueue.map((item) => ({ ...item }));
  const deploymentDurationMs = deployProbeQueue(state);
  const combatImpact = measureProbeCombatImpact(state);

  const telemetry = buildPhaseTelemetrySummary(state);
  const metrics = buildMetrics(state, queuedSnapshot, initialGold, combatImpact, deploymentDurationMs);
  const warnings = buildWarnings(presetId, metrics);
  metrics.deadEffectCount = warnings.length;
  return {
    presetId,
    presetName: preset.name,
    raceId: state.currentRaceId,
    archetype: telemetry.archetype,
    dominantChamber: telemetry.dominantChamber,
    metrics,
    summaryLines: [
      ...telemetry.lines,
      `探针 入队 ${metrics.unitsQueued} 部署 ${metrics.unitsDeployed} 最高阶 ${metrics.highestQueuedTier} 最高Lv ${metrics.maxQueuedLevel} 战斗影响 ${metrics.combatImpactDamage}`,
      `探针指标 低阶占比 ${formatProbePercent(metrics.lowTierDeployShare)} 部署/出兵 ${metrics.deploysPerSpawnHit.toFixed(1)} 平均Lv ${metrics.averageUnitLevel.toFixed(1)} T3 ${formatProbeMs(metrics.firstTier3DeployMs)} 释放 ${metrics.queueReleaseRatePerSecond.toFixed(2)}/s burst部署 ${metrics.burstWindowDeploys} 链深 ${metrics.chainDepth} 死效 ${metrics.deadEffectCount}`,
    ],
    warnings,
  };
}

function runProbeScript(state: GameState, presetId: DebugBuildPresetId) {
  if (presetId === 'swarm') {
    recordProbeLaunch(state, 'split');
    recordProbeLaunch(state, 'fire');
    resolveSpawnBall(state, 0, 3, 12000);
    return;
  }

  if (presetId === 'magic_copy') {
    recordProbeLaunch(state, 'fire');
    triggerSlot(state, 'magic');
    resolveSpawnBall(state, 0, 1, 12000);
    return;
  }

  if (presetId === 'mech_elite') {
    recordProbeLaunch(state, 'fire');
    triggerSlot(state, 'upgrade');
    resolveSpawnBall(state, 2, 5, 15000);
    return;
  }

  if (presetId === 'economy_industry') {
    recordProbeLaunch(state, 'fire');
    triggerGoldBurst(state);
    resolveSpawnBall(state, 0, 1, 12000);
    return;
  }

  recordProbeLaunchMiss(state);
  recordProbeLaunchMiss(state);
  recordProbeLaunchMiss(state);
  resolveUnitBallToSlot(state, 4, 1, { elapsedMs: 0, durationMs: PROBE_PHASE_MS });
  triggerGoldBurst(state);
  resolveSpawnBall(state, 0, 1, 12000);
}

function triggerGoldBurst(state: GameState) {
  triggerSlot(state, 'gold');
  triggerSlot(state, 'gold');
  triggerSlot(state, 'gold');
}

function recordProbeLaunchMiss(state: GameState) {
  recordProbeLaunch(state, 'miss');
  recordLaunchMiss(state);
  recordRelicLaunchMiss(state);
  recordDoctrineLaunchMiss(state);
}

function recordProbeLaunch(state: GameState, outcome: 'split' | 'fire' | 'miss') {
  recordLaunchOutcome(state.stats.currentPhase, outcome);
}

function resolveSpawnBall(state: GameState, slotIndex: number, baseValue: number, elapsedMs: number) {
  state.phaseElapsedMs = elapsedMs;
  triggerSlot(state, 'spawn');
  const ballValue = consumeSpawnMarkBonus(state, baseValue);
  resolveUnitBallToSlot(state, slotIndex, ballValue, {
    elapsedMs,
    durationMs: PROBE_PHASE_MS,
  });
}

function deployProbeQueue(state: GameState): number {
  const startedAtMs = state.battle.elapsedMs;
  for (let step = 0; step < 12; step += 1) {
    updateSpawnQueue(state, 700);
    updateBattle(state, 700);
  }
  return Math.max(0, state.battle.elapsedMs - startedAtMs);
}

function measureProbeCombatImpact(state: GameState): { checks: number; damage: number } {
  const player = state.battle.units.find((unit) => unit.side === 'player' && unit.hp > 0);
  if (!player) return { checks: 0, damage: 0 };

  const damageBefore = state.stats.currentPhase.damageDealt;
  const playerDef = unitDefs[player.defId];
  player.x = 360;
  player.attackTimerMs = 0;
  const enemy = spawnBattleUnit(state, 'enemy', 'enemy_raider');
  enemy.x = player.x + Math.max(14, Math.min(24, playerDef.attackRange - 2));
  enemy.battleLane = player.battleLane;
  enemy.laneOffset = player.laneOffset;
  enemy.attackTimerMs = 9999;

  for (let step = 0; step < 4; step += 1) {
    updateBattle(state, 300);
  }

  return {
    checks: 1,
    damage: Math.max(0, state.stats.currentPhase.damageDealt - damageBefore),
  };
}

function buildMetrics(
  state: GameState,
  queuedSnapshot: SpawnQueueItem[],
  initialGold: number,
  combatImpact: { checks: number; damage: number },
  deploymentDurationMs: number,
): BuildProbeMetrics {
  const stats = state.stats.currentPhase;
  const buildingContributionTotal = Object.values(stats.buildingContributions)
    .reduce((sum, amount) => sum + amount, 0);
  const playerUnits = state.battle.units.filter((unit) => unit.side === 'player');
  const lowTierDeployCount = playerUnits.filter((unit) => (unitDefs[unit.defId]?.costTier ?? 0) <= 2).length;
  const firstTier3DeployMs = playerUnits
    .filter((unit) => unitDefs[unit.defId]?.costTier === 3)
    .reduce<number | undefined>((first, unit) => first === undefined ? unit.spawnedAtMs : Math.min(first, unit.spawnedAtMs), undefined);
  const queuedUnitCount = queuedSnapshot.reduce((sum, item) => sum + item.count, 0);
  const queuedLevelTotal = queuedSnapshot.reduce((sum, item) => sum + item.count * item.level, 0);
  const activeChambers = getActiveProbeChambers(state).length;

  return {
    slotTriggers: { ...stats.slotTriggers },
    unitsQueued: stats.unitsQueued,
    unitsDeployed: playerUnits.length,
    eliteQueued: queuedSnapshot
      .filter((item) => item.isElite || item.lifetime === 'elite')
      .reduce((sum, item) => sum + item.count, 0),
    highestQueuedTier: queuedSnapshot.reduce((highest, item) => Math.max(highest, unitDefs[item.unitId]?.costTier ?? 0), 0),
    maxQueuedLevel: queuedSnapshot.reduce((highest, item) => Math.max(highest, item.level), 0),
    maxQueuedCount: queuedSnapshot.reduce((highest, item) => Math.max(highest, item.count), 0),
    goldEarned: state.gold - initialGold,
    spawnMarksCreated: stats.spawnMarksCreated,
    spawnMarksConsumed: stats.spawnMarksConsumed,
    spawnCopiesCreated: stats.spawnCopiesCreated,
    nonSpawnRecoveryEvents: stats.nonSpawnRecoveryEvents,
    nonSpawnStreakMax: stats.nonSpawnStreakMax,
    timeToRecoverySpawnMs: stats.timeToRecoverySpawnMs,
    recoverySources: { ...stats.recoverySources },
    relicTriggers: stats.relicTriggers,
    overflowProgressGranted: stats.overflowProgressGranted,
    gateAccelerationEvents: stats.gateAccelerationEvents,
    queueBurstEvents: stats.queueBurstEvents,
    combatImpactChecks: combatImpact.checks,
    combatImpactDamage: combatImpact.damage,
    buildingContributionTotal,
    researchPoints: state.researchPoints,
    lowTierDeployShare: playerUnits.length <= 0 ? 0 : lowTierDeployCount / playerUnits.length,
    averageUnitLevel: queuedUnitCount <= 0 ? 0 : queuedLevelTotal / queuedUnitCount,
    deploysPerSpawnHit: stats.slotTriggers.spawn <= 0 ? 0 : playerUnits.length / stats.slotTriggers.spawn,
    firstTier3DeployMs,
    queueReleaseRatePerSecond: deploymentDurationMs <= 0 ? 0 : playerUnits.length / (deploymentDurationMs / 1000),
    burstWindowDeploys: playerUnits.filter((unit) => unit.tags.includes('queue-burst')).length,
    crossChamberChainCount: Math.max(0, activeChambers - 1),
    chainDepth: activeChambers,
    deadEffectCount: 0,
  };
}

function getActiveProbeChambers(state: GameState): Array<'launch' | 'decision' | 'unit'> {
  const stats = state.stats.currentPhase;
  const launchSignals = stats.launchOutcomes.split
    + stats.launchOutcomes.fire
    + stats.launchOutcomes.miss
    + stats.buildingContributions.launch
    + stats.relicTriggers;
  const decisionSignals = stats.slotTriggers.gold
    + stats.slotTriggers.magic
    + stats.slotTriggers.spawn
    + stats.slotTriggers.upgrade
    + stats.buildingContributions.decision
    + stats.spawnCopiesCreated
    + state.researchPoints;
  const unitSignals = stats.unitsQueued
    + stats.unitsSpawned
    + stats.buildingContributions.unit
    + stats.overflowProgressGranted
    + stats.gateAccelerationEvents
    + stats.queueBurstEvents;

  return [
    ...(launchSignals > 0 ? ['launch' as const] : []),
    ...(decisionSignals > 0 ? ['decision' as const] : []),
    ...(unitSignals > 0 ? ['unit' as const] : []),
  ];
}

function buildWarnings(presetId: DebugBuildPresetId, metrics: BuildProbeMetrics): string[] {
  const warnings: string[] = [];
  if (metrics.unitsQueued <= 0) warnings.push('no_units_queued');
  if (metrics.unitsDeployed <= 0) warnings.push('no_units_deployed');
  if (metrics.buildingContributionTotal <= 0) warnings.push('no_building_contribution');
  if (presetId === 'magic_copy' && metrics.spawnCopiesCreated <= 0) warnings.push('copy_probe_did_not_create_copies');
  if (presetId === 'mech_elite' && metrics.eliteQueued <= 0) warnings.push('elite_probe_did_not_queue_elite');
  if (metrics.combatImpactChecks <= 0 || metrics.combatImpactDamage <= 0) warnings.push('no_combat_impact');
  if ((presetId === 'economy_industry' || presetId === 'recovery') && metrics.nonSpawnRecoveryEvents <= 0) {
    warnings.push('recovery_probe_did_not_recover_non_spawn');
  }
  return warnings;
}

function formatProbePercent(value: number): string {
  return `${Math.round(value * 100)}%`;
}

function formatProbeMs(ms: number | undefined): string {
  return ms === undefined ? '未部署' : `${(ms / 1000).toFixed(1)}s`;
}
