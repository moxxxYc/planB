import type { BuildingChamber, LaunchOutcomeId, PhaseStats, SlotId } from '../types/game';

export function createPhaseStats(): PhaseStats {
  return {
    slotTriggers: {
      spawn: 0,
      upgrade: 0,
      gold: 0,
      magic: 0,
      special: 0,
    },
    launchOutcomes: {
      split: 0,
      fire: 0,
      miss: 0,
    },
    buildingContributions: {
      launch: 0,
      decision: 0,
      unit: 0,
    },
    spawnMarksCreated: 0,
    spawnMarksConsumed: 0,
    spawnCopiesCreated: 0,
    nonSpawnRecoveryEvents: 0,
    currentNonSpawnStreak: 0,
    nonSpawnStreakMax: 0,
    nonSpawnStreakStartedAtMs: undefined,
    timeToRecoverySpawnMs: undefined,
    recoverySources: {},
    phaseToolsPurchased: 0,
    relicTriggers: 0,
    overflowProgressGranted: 0,
    gateAccelerationEvents: 0,
    gateBlockedEvents: 0,
    queueBurstEvents: 0,
    unitsQueuedById: {},
    unitsDeployedById: {},
    unitsSpawned: 0,
    unitsQueued: 0,
    advancedUnitsQueued: 0,
    damageDealt: 0,
    kills: 0,
    eliteXpGained: 0,
    enemyBaseDamage: 0,
    playerBaseDamage: 0,
  };
}

export function recordSlot(stats: PhaseStats, slotId: SlotId, elapsedMs = 0) {
  stats.slotTriggers[slotId] += 1;
  if (slotId === 'spawn') {
    stats.currentNonSpawnStreak = 0;
    stats.nonSpawnStreakStartedAtMs = undefined;
    return;
  }

  if (slotId !== 'gold' && slotId !== 'magic' && slotId !== 'upgrade') return;
  if (stats.currentNonSpawnStreak === 0) stats.nonSpawnStreakStartedAtMs = elapsedMs;
  stats.currentNonSpawnStreak += 1;
  stats.nonSpawnStreakMax = Math.max(stats.nonSpawnStreakMax, stats.currentNonSpawnStreak);
}

export function recordLaunchOutcome(stats: PhaseStats, outcome: LaunchOutcomeId) {
  stats.launchOutcomes[outcome] += 1;
}

export function recordBuildingContribution(stats: PhaseStats, chamber: BuildingChamber, amount = 1) {
  stats.buildingContributions[chamber] += amount;
}

export function recordSpawnMarksCreated(stats: PhaseStats, amount: number) {
  stats.spawnMarksCreated += amount;
}

export function recordSpawnMarksConsumed(stats: PhaseStats, amount: number) {
  stats.spawnMarksConsumed += amount;
}

export function recordSpawnCopiesCreated(stats: PhaseStats, amount: number) {
  stats.spawnCopiesCreated += amount;
}

export function recordNonSpawnRecovery(stats: PhaseStats, source = 'unknown', elapsedMs = 0) {
  stats.nonSpawnRecoveryEvents += 1;
  stats.recoverySources[source] = (stats.recoverySources[source] ?? 0) + 1;
  if (stats.timeToRecoverySpawnMs === undefined && stats.nonSpawnStreakStartedAtMs !== undefined) {
    stats.timeToRecoverySpawnMs = Math.max(0, elapsedMs - stats.nonSpawnStreakStartedAtMs);
  }
}

export function recordPhaseToolPurchase(stats: PhaseStats) {
  stats.phaseToolsPurchased += 1;
}

export function recordUnitQueued(stats: PhaseStats, unitId: string, count: number) {
  stats.unitsQueuedById[unitId] = (stats.unitsQueuedById[unitId] ?? 0) + count;
}

export function recordAdvancedUnitQueued(stats: PhaseStats, count: number) {
  stats.advancedUnitsQueued += count;
}

export function recordUnitDeployed(stats: PhaseStats, unitId: string) {
  stats.unitsDeployedById[unitId] = (stats.unitsDeployedById[unitId] ?? 0) + 1;
}

export function recordRelicTrigger(stats: PhaseStats) {
  stats.relicTriggers += 1;
}

export function recordOverflowProgress(stats: PhaseStats, amount: number) {
  stats.overflowProgressGranted += amount;
}

export function recordGateAcceleration(stats: PhaseStats) {
  stats.gateAccelerationEvents += 1;
}

export function recordGateBlocked(stats: PhaseStats) {
  stats.gateBlockedEvents += 1;
}

export function recordQueueBurst(stats: PhaseStats) {
  stats.queueBurstEvents += 1;
}
