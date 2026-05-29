import { debugBuildPresets } from '../data/debugPresets';
import { raceDefs } from '../data/races';
import { createSlotState } from '../data/slots';
import { applyReward } from './RewardSystem';
import { setBallTags } from './RelicSystem';
import type { DebugBuildPresetId, GameModifiers, GameState, RaceId } from '../types/game';

export { debugBuildPresets } from '../data/debugPresets';

export type DebugBuildPresetResult =
  | { status: 'applied'; id: DebugBuildPresetId }
  | { status: 'unknown_preset'; id: string };

export function applyDebugBuildPreset(state: GameState, id: DebugBuildPresetId): DebugBuildPresetResult {
  const preset = debugBuildPresets.find((candidate) => candidate.id === id);
  if (!preset) return { status: 'unknown_preset', id };

  resetDebugBuildState(state);
  state.currentRaceId = preset.raceId;

  for (const buildingId of preset.buildingIds) applyReward(state, buildingId);
  for (const rewardId of preset.rewardIds) applyReward(state, rewardId);

  if (preset.gold !== undefined) state.gold = Math.max(state.gold, preset.gold);
  if (preset.pendingSpawnMarks !== undefined) state.pendingSpawnMarks = preset.pendingSpawnMarks;
  if (preset.pendingSpawnLevelBonus !== undefined) state.pendingSpawnLevelBonus = preset.pendingSpawnLevelBonus;
  if (preset.nextSpawnCreatesElite !== undefined) state.nextSpawnCreatesElite = preset.nextSpawnCreatesElite;
  for (const [unitId, boost] of Object.entries(preset.unitLevelBoosts ?? {})) {
    state.unitLevels[unitId] = Math.max(state.unitLevels[unitId] ?? 1, 1 + boost);
  }

  state.recentFloatingTexts.push({ label: `调试预设：${preset.name}`, color: 0xf8fafc });
  return { status: 'applied', id };
}

function resetDebugBuildState(state: GameState) {
  state.gold = 0;
  state.pendingSpawnLevelBonus = 0;
  state.pendingSpawnMarks = 0;
  setBallTags(state, []);
  state.upTriggerCountTowardElite = 0;
  state.nextSpawnCreatesElite = false;
  state.spawnQueue = [];
  state.machineUpgrades = [];
  state.slotUpgrades = [];
  state.buildings = [];
  state.unitStructures = [];
  state.relics = [];
  state.launchRelics = state.relics;
  state.doctrineTechs = [];
  state.decisionTechs = state.doctrineTechs;
  state.selectedRewards = [];
  state.buildingEvents = {
    coinPressGoldHits: 0,
  };
  state.relicEvents = {
    entropyCharges: 0,
  };
  state.doctrineEvents = {
    conversionHits: 0,
    launchLosses: 0,
    researchReturnProgress: 0,
    nonSpawnStreak: 0,
  };
  state.researchPoints = 0;
  state.slots = createSlotState();
  state.modifiers = createDefaultModifiers();

  for (const unitId of [...raceDefs.hive.unitPool, ...raceDefs.mech.unitPool]) {
    state.unitLevels[unitId] = 1;
  }
  for (const raceId of Object.keys(raceDefs) as RaceId[]) {
    state.unitSlotStates[raceId] = raceDefs[raceId].unitSlots.map((slot) => ({ ...slot, progress: 0 }));
  }
}

function createDefaultModifiers(): GameModifiers {
  return {
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
  };
}
