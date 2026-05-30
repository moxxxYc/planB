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
import { applyReward, buildRewardChoices, rewardChambers } from './RewardSystem';
import { triggerSlot } from './SlotTriggerSystem';
import { updateSpawnQueue } from './SpawnQueueSystem';
import { recordLaunchOutcome } from './StatsSystem';
import { resolveUnitBallToSlot } from './UnitSpawnProgressSystem';
import type { DebugBuildPresetId, GameState, RaceId, RewardChamber, RewardDef, RewardSourceType, SlotId, SpawnQueueItem } from '../types/game';

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

export interface NaturalBlueprintRewardSelection {
  phaseIndex: number;
  rewardId: string;
  rewardName: string;
  chamber: RewardChamber;
  sourceType: RewardSourceType;
}

export interface NaturalBlueprintRewardProbeMetrics {
  launchBlueprints: number;
  decisionBlueprints: number;
  unitBlueprints: number;
  naturalLaunchOrDecisionBuildingInstalled: boolean;
  nonSpawnRecoveryWithin15s: boolean;
  recoveredUnitBallValue: number;
  unitsQueued: number;
  unitsDeployed: number;
  combatImpactDamage: number;
}

export interface NaturalBlueprintRewardProbeResult {
  probeId: 'natural_blueprint_reward_probe';
  debugPresetUsed: false;
  ok: boolean;
  raceId: RaceId;
  rewardSelections: NaturalBlueprintRewardSelection[];
  offeredChambersByPhase: RewardChamber[][];
  acquiredChambers: RewardChamber[];
  phaseTwoArchetype: string;
  finalArchetype: string;
  metrics: NaturalBlueprintRewardProbeMetrics;
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

export function runNaturalBlueprintRewardProbe(seed = 180): NaturalBlueprintRewardProbeResult {
  const state = createInitialGameState('hive', seed);
  const rewardSelections: NaturalBlueprintRewardSelection[] = [];
  const offeredChambersByPhase: RewardChamber[][] = [];
  let phaseTwoArchetype = '混合构筑';

  rewardChambers.forEach((targetChamber, index) => {
    const choices = buildRewardChoices(state);
    offeredChambersByPhase.push(choices.map((reward) => reward.chamber));
    const selected = selectChamberReward(choices, targetChamber);
    applyReward(state, selected.id);
    state.selectedRewards.push(selected.id);
    rewardSelections.push({
      phaseIndex: index,
      rewardId: selected.id,
      rewardName: selected.name,
      chamber: selected.chamber,
      sourceType: selected.sourceType,
    });
    if (index === 1) phaseTwoArchetype = buildPhaseTelemetrySummary(state).archetype;
  });

  startPhase(state);
  const recoveredUnitBallValue = exerciseNaturalRecoveryIntoSpawn(state);
  const queuedSnapshot = state.spawnQueue.map((item) => ({ ...item }));
  deployProbeQueue(state);
  const combatImpact = measureProbeCombatImpact(state);
  const telemetry = buildPhaseTelemetrySummary(state);
  const acquiredChambers = rewardChambers.filter((chamber) => rewardSelections.some((selection) => selection.chamber === chamber));
  const metrics = buildNaturalBlueprintMetrics(state, rewardSelections, queuedSnapshot, combatImpact, recoveredUnitBallValue);
  const warnings = buildNaturalBlueprintWarnings(offeredChambersByPhase, acquiredChambers, metrics);

  return {
    probeId: 'natural_blueprint_reward_probe',
    debugPresetUsed: false,
    ok: warnings.length === 0,
    raceId: state.currentRaceId,
    rewardSelections,
    offeredChambersByPhase,
    acquiredChambers,
    phaseTwoArchetype,
    finalArchetype: telemetry.archetype,
    metrics,
    summaryLines: [
      `natural_blueprint_reward_probe ${rewardSelections.map((selection) => `${selection.chamber}:${selection.rewardName}`).join(' / ')}`,
      ...telemetry.lines,
      `自然奖励 入队 ${metrics.unitsQueued} 部署 ${metrics.unitsDeployed} 回流球值 ${metrics.recoveredUnitBallValue} 战斗影响 ${metrics.combatImpactDamage}`,
    ],
    warnings,
  };
}

function runProbeScript(state: GameState, presetId: DebugBuildPresetId) {
  if (presetId === 'swarm') {
    recordProbeLaunch(state, 'split');
    recordProbeLaunch(state, 'spawn');
    resolveSpawnBall(state, 0, 3, 12000);
    return;
  }

  if (presetId === 'magic_copy') {
    recordProbeLaunch(state, 'standby');
    triggerSlot(state, 'magic');
    recordProbeLaunch(state, 'spawn');
    resolveSpawnBall(state, 0, 1, 12000);
    return;
  }

  if (presetId === 'mech_elite') {
    recordProbeLaunch(state, 'standby');
    triggerSlot(state, 'upgrade');
    recordProbeLaunch(state, 'spawn');
    resolveSpawnBall(state, 2, 5, 15000);
    return;
  }

  if (presetId === 'economy_industry') {
    recordProbeLaunch(state, 'standby');
    triggerGoldBurst(state);
    recordProbeLaunch(state, 'spawn');
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

function selectChamberReward(choices: RewardDef[], chamber: RewardChamber): RewardDef {
  const selected = choices.find((reward) => reward.chamber === chamber);
  if (!selected) throw new Error(`Natural blueprint probe did not offer ${chamber}`);
  return selected;
}

function exerciseNaturalRecoveryIntoSpawn(state: GameState): number {
  const hasCoinPress = state.buildings.some((building) => building.id === 'decision_coin_press');
  if (hasCoinPress) {
    for (const elapsedMs of [2000, 6000, 10000]) {
      state.phaseElapsedMs = elapsedMs;
      triggerSlot(state, 'gold');
    }
  } else {
    state.phaseElapsedMs = 8000;
    triggerSlot(state, 'magic');
  }

  state.phaseElapsedMs = 12000;
  triggerSlot(state, 'spawn');
  const recoveredValue = consumeSpawnMarkBonus(state, 1);
  resolveUnitBallToSlot(state, 0, recoveredValue, {
    elapsedMs: state.phaseElapsedMs,
    durationMs: PROBE_PHASE_MS,
  });
  return recoveredValue;
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

function recordProbeLaunch(state: GameState, outcome: 'standby' | 'split' | 'spawn' | 'miss') {
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

function buildNaturalBlueprintMetrics(
  state: GameState,
  selections: NaturalBlueprintRewardSelection[],
  queuedSnapshot: SpawnQueueItem[],
  combatImpact: { checks: number; damage: number },
  recoveredUnitBallValue: number,
): NaturalBlueprintRewardProbeMetrics {
  const playerUnits = state.battle.units.filter((unit) => unit.side === 'player');
  return {
    launchBlueprints: selections.filter((selection) => selection.chamber === 'launch').length,
    decisionBlueprints: selections.filter((selection) => selection.chamber === 'decision').length,
    unitBlueprints: selections.filter((selection) => selection.chamber === 'unit').length,
    naturalLaunchOrDecisionBuildingInstalled: state.buildings.some((building) => building.chamber === 'launch' || building.chamber === 'decision'),
    nonSpawnRecoveryWithin15s: (state.stats.currentPhase.timeToRecoverySpawnMs ?? Number.POSITIVE_INFINITY) <= 15000
      || state.stats.currentPhase.spawnCopiesCreated > 0,
    recoveredUnitBallValue,
    unitsQueued: queuedSnapshot.reduce((sum, item) => sum + item.count, 0),
    unitsDeployed: playerUnits.length,
    combatImpactDamage: combatImpact.damage,
  };
}

function buildNaturalBlueprintWarnings(
  offeredChambersByPhase: RewardChamber[][],
  acquiredChambers: RewardChamber[],
  metrics: NaturalBlueprintRewardProbeMetrics,
): string[] {
  const warnings: string[] = [];
  const completeOffer = rewardChambers.join('|');
  if (!offeredChambersByPhase.every((chambers) => chambers.join('|') === completeOffer)) {
    warnings.push('phase_reward_not_three_chamber_offer');
  }
  for (const chamber of rewardChambers) {
    if (!acquiredChambers.includes(chamber)) warnings.push(`missing_${chamber}_blueprint_acquisition`);
  }
  if (!metrics.naturalLaunchOrDecisionBuildingInstalled) warnings.push('no_launch_or_decision_building_from_natural_reward');
  if (!metrics.nonSpawnRecoveryWithin15s) warnings.push('no_non_spawn_recovery_within_15s');
  if (metrics.unitsQueued <= 0) warnings.push('no_units_queued');
  if (metrics.unitsDeployed <= 0) warnings.push('no_units_deployed');
  if (metrics.combatImpactDamage <= 0) warnings.push('no_combat_impact');
  return warnings;
}

function getActiveProbeChambers(state: GameState): Array<'launch' | 'decision' | 'unit'> {
  const stats = state.stats.currentPhase;
  const launchSignals = stats.launchOutcomes.standby
    + stats.launchOutcomes.split
    + stats.launchOutcomes.spawn
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
