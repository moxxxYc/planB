import { raceDefs } from '../data/races';
import { buildPhaseToolStock } from '../data/phaseTools';
import { createSlotState } from '../data/slots';
import { createPhaseStats } from './StatsSystem';
import type { BallTagId, BuildingInstance, GameState, PersistentRunItem, RaceId, SecondaryRaceId, UnitSlotState } from '../types/game';

export interface CreateInitialGameStateOptions {
  secondaryRaceId?: SecondaryRaceId;
}

export function createDefaultPrototypeGameState(seed = 24391): GameState {
  return createInitialGameState('hive', seed, { secondaryRaceId: 'arcane' });
}

export function createInitialGameState(
  raceId: RaceId = 'hive',
  seed = 1,
  options: CreateInitialGameStateOptions = {},
): GameState {
  const unitLevels: Record<string, number> = {};
  for (const unitId of [...raceDefs.hive.unitPool, ...raceDefs.mech.unitPool]) {
    unitLevels[unitId] = 1;
  }
  const unitSlotStates: Record<RaceId, UnitSlotState[]> = {
    hive: raceDefs.hive.unitSlots.map((slot) => ({ ...slot, progress: 0 })),
    mech: raceDefs.mech.unitSlots.map((slot) => ({ ...slot, progress: 0 })),
  };
  const ballTags: BallTagId[] = [];
  const buildings: BuildingInstance[] = [];
  const unitStructures: BuildingInstance[] = [];
  const launchRelics: PersistentRunItem[] = [];
  const decisionTechs: PersistentRunItem[] = [];

  return {
    seed,
    currentRaceId: raceId,
    secondaryRaceId: options.secondaryRaceId,
    speedMultiplier: 1,
    phaseIndex: 0,
    phaseActive: false,
    isBuildPause: false,
    gold: 0,
    pendingSpawnLevelBonus: 0,
    hasSeenFirstSpawnLoop: false,
    firstLoopAssistActive: true,
    firstSpawnOutcomeForced: false,
    firstUnitSlotForced: false,
    upTriggerCountTowardElite: 0,
    nextSpawnCreatesElite: false,
    pendingSpawnMarks: 0,
    pendingLaunchBallTags: ballTags,
    ballTags,
    buildingEvents: {
      coinPressGoldHits: 0,
    },
    relicEvents: {
      entropyCharges: 0,
    },
    doctrineEvents: {
      conversionHits: 0,
      launchLosses: 0,
      researchReturnProgress: 0,
      nonSpawnStreak: 0,
    },
    arcaneRune: {
      current: 0,
      cap: 5,
      totalGenerated: 0,
      totalSpent: 0,
      totalProgressGranted: 0,
      cappedHits: 0,
      noSocketTriggers: 0,
      socketChargeProgress: 0,
    },
    researchPoints: 0,
    nextUnitId: 1,
    nextBallId: 1,
    nextQueueId: 1,
    phaseElapsedMs: 0,
    playerStandardUnitSoftCap: 50,
    eliteUnitCap: 8,
    spawnQueue: [],
    machineUpgrades: [],
    slotUpgrades: [],
    buildings,
    relics: launchRelics,
    doctrineTechs: decisionTechs,
    launchRelics,
    decisionTechs,
    unitStructures,
    phaseToolStock: buildPhaseToolStock(seed, 0),
    usedPhaseTools: [],
    selectedRewards: [],
    chainHistory: [],
    buildArchetypeHint: '混合构筑',
    slots: createSlotState(),
    battle: {
      units: [],
      bases: {
        player: { side: 'player', hp: 500, maxHp: 500, x: 70, laneOffset: 0, attackTimerMs: 0, lastAttackAtMs: -9999, lastHitAtMs: -9999 },
        enemy: { side: 'enemy', hp: 500, maxHp: 500, x: 1670, laneOffset: 0, attackTimerMs: 0, lastAttackAtMs: -9999, lastHitAtMs: -9999 },
      },
      camera: {
        centerX: 710,
        viewportWorldWidth: 640,
        manualUntilMs: 0,
        manualOverride: false,
      },
      elapsedMs: 0,
      nextFeedbackId: 1,
      projectiles: [],
      transientEffects: [],
    },
    stats: {
      currentPhase: createPhaseStats(),
    },
    modifiers: {
      ballCount: 1,
      goldMultiplier: 1,
      spawnExtraCount: 0,
      magicSpawnCopyBonus: 0,
      pendingSpawnCopies: 0,
      magicDamageMultiplier: 1,
      mechUpgradeEfficiency: 0,
      hiveExtraGrubCount: 0,
      nextPhaseSpawnLevelBonus: 0,
      queueReleaseSpeedBonus: 0,
      eliteExtraVeterancy: 0,
      basicUnitHpBonus: 0,
      basicUnitDamageBonus: 0,
    },
    unitLevels,
    unitSlotStates,
    settings: {
      magicEnabled: true,
    },
    recentFloatingTexts: [],
  };
}
