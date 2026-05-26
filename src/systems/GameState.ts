import { raceDefs } from '../data/races';
import { createSlotState } from '../data/slots';
import { createPhaseStats } from './StatsSystem';
import type { GameState, RaceId, UnitSlotState } from '../types/game';

export function createInitialGameState(raceId: RaceId = 'hive', seed = 1): GameState {
  const unitLevels: Record<string, number> = {};
  for (const unitId of [...raceDefs.hive.unitPool, ...raceDefs.mech.unitPool]) {
    unitLevels[unitId] = 1;
  }
  const unitSlotStates: Record<RaceId, UnitSlotState[]> = {
    hive: raceDefs.hive.unitSlots.map((slot) => ({ ...slot, progress: 0 })),
    mech: raceDefs.mech.unitSlots.map((slot) => ({ ...slot, progress: 0 })),
  };

  return {
    seed,
    currentRaceId: raceId,
    phaseIndex: 0,
    phaseActive: false,
    isBuildPause: false,
    gold: 0,
    pendingSpawnLevelBonus: 0,
    upTriggerCountTowardElite: 0,
    nextSpawnCreatesElite: false,
    nextUnitId: 1,
    nextBallId: 1,
    nextQueueId: 1,
    phaseElapsedMs: 0,
    playerStandardUnitSoftCap: 50,
    eliteUnitCap: 8,
    spawnQueue: [],
    machineUpgrades: [],
    slotUpgrades: [],
    buildings: [],
    relics: [],
    selectedRewards: [],
    slots: createSlotState(),
    battle: {
      units: [],
      bases: {
        player: { side: 'player', hp: 500, maxHp: 500, x: 70, laneOffset: 0, lastHitAtMs: -9999 },
        enemy: { side: 'enemy', hp: 500, maxHp: 500, x: 1670, laneOffset: 0, lastHitAtMs: -9999 },
      },
      camera: {
        centerX: 710,
        viewportWorldWidth: 640,
        manualUntilMs: 0,
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
    recentFloatingTexts: [],
  };
}
