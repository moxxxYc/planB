import { runAllBuildProbes, type BuildProbeResult } from './BuildProbeSystem';
import type { DebugBuildPresetId } from '../types/game';

export interface BuildProbeValidationRow {
  presetId: DebugBuildPresetId;
  presetName: string;
  archetype: string;
  queued: number;
  deployed: number;
  combatImpactDamage: number;
  lowTierDeployShare: number;
  deploysPerSpawnHit: number;
  averageUnitLevel: number;
  firstTier3DeployMs?: number;
  queueReleaseRatePerSecond: number;
  burstWindowDeploys: number;
  chainDepth: number;
  warnings: string[];
}

export interface BuildProbeValidationReport {
  ok: boolean;
  seed: number;
  rows: BuildProbeValidationRow[];
  failures: string[];
}

export function buildProbeValidationReport(seed = 170): BuildProbeValidationReport {
  const results = runAllBuildProbes(seed);
  const rows = results.map(toValidationRow);
  const failures = results.flatMap(validateProbeResult);
  return {
    ok: failures.length === 0,
    seed,
    rows,
    failures,
  };
}

export function formatBuildProbeValidationReport(report: BuildProbeValidationReport): string {
  const status = report.ok ? 'BUILD PROBE VALIDATION PASS' : 'BUILD PROBE VALIDATION FAIL';
  const lines = [
    `${status} seed=${report.seed}`,
    'preset | archetype | queued/deployed | combat | lowTier | deploys/spawn | avgLv | tier3 | release/s | burst | chainDepth | warnings',
    ...report.rows.map((row) => [
      row.presetName,
      row.archetype,
      `${row.queued}/${row.deployed}`,
      row.combatImpactDamage,
      formatPercent(row.lowTierDeployShare),
      row.deploysPerSpawnHit.toFixed(1),
      row.averageUnitLevel.toFixed(1),
      formatMs(row.firstTier3DeployMs),
      row.queueReleaseRatePerSecond.toFixed(2),
      row.burstWindowDeploys,
      row.chainDepth,
      row.warnings.length === 0 ? 'none' : row.warnings.join(','),
    ].join(' | ')),
  ];

  if (!report.ok) {
    lines.push('failures:');
    lines.push(...report.failures.map((failure) => `- ${failure}`));
  }

  return lines.join('\n');
}

function toValidationRow(result: BuildProbeResult): BuildProbeValidationRow {
  const { metrics } = result;
  return {
    presetId: result.presetId,
    presetName: result.presetName,
    archetype: result.archetype,
    queued: metrics.unitsQueued,
    deployed: metrics.unitsDeployed,
    combatImpactDamage: metrics.combatImpactDamage,
    lowTierDeployShare: metrics.lowTierDeployShare,
    deploysPerSpawnHit: metrics.deploysPerSpawnHit,
    averageUnitLevel: metrics.averageUnitLevel,
    firstTier3DeployMs: metrics.firstTier3DeployMs,
    queueReleaseRatePerSecond: metrics.queueReleaseRatePerSecond,
    burstWindowDeploys: metrics.burstWindowDeploys,
    chainDepth: metrics.chainDepth,
    warnings: result.warnings,
  };
}

function validateProbeResult(result: BuildProbeResult): string[] {
  const failures = result.warnings.map((warning) => `${result.presetName}: ${warning}`);
  const { metrics } = result;

  if (metrics.chainDepth < 3) failures.push(`${result.presetName}: chain_depth_below_three`);
  if (metrics.combatImpactDamage <= 0) failures.push(`${result.presetName}: no_combat_damage`);

  if (result.presetId === 'swarm') {
    if (metrics.lowTierDeployShare <= 0.5) failures.push(`${result.presetName}: low_tier_share_too_low`);
    if (metrics.overflowProgressGranted <= 0) failures.push(`${result.presetName}: no_overflow_conversion`);
  }

  if (result.presetId === 'magic_copy') {
    if (metrics.spawnCopiesCreated <= 0) failures.push(`${result.presetName}: no_copy_created`);
    if (metrics.deploysPerSpawnHit <= 1) failures.push(`${result.presetName}: deploys_per_spawn_not_amplified`);
  }

  if (result.presetId === 'mech_elite') {
    if (metrics.eliteQueued <= 0) failures.push(`${result.presetName}: no_elite_queued`);
    if ((metrics.firstTier3DeployMs ?? Number.POSITIVE_INFINITY) > 30000) failures.push(`${result.presetName}: tier3_deploy_too_late`);
    if (metrics.averageUnitLevel <= 1) failures.push(`${result.presetName}: average_level_not_lifted`);
  }

  if (result.presetId === 'economy_industry') {
    if (metrics.goldEarned <= 0) failures.push(`${result.presetName}: no_gold_income`);
    if (metrics.queueReleaseRatePerSecond <= 0) failures.push(`${result.presetName}: no_queue_release_rate`);
    if (metrics.burstWindowDeploys <= 0) failures.push(`${result.presetName}: no_burst_deploys`);
  }

  if (result.presetId === 'recovery') {
    if (metrics.nonSpawnStreakMax < 3) failures.push(`${result.presetName}: recovery_streak_not_exercised`);
    if ((metrics.timeToRecoverySpawnMs ?? Number.POSITIVE_INFINITY) > 15000) failures.push(`${result.presetName}: recovery_too_late`);
    if (Object.values(metrics.recoverySources).reduce((sum, count) => sum + count, 0) <= 0) failures.push(`${result.presetName}: no_recovery_source`);
  }

  return failures;
}

function formatPercent(value: number): string {
  return `${Math.round(value * 100)}%`;
}

function formatMs(ms: number | undefined): string {
  return ms === undefined ? 'n/a' : `${(ms / 1000).toFixed(1)}s`;
}
