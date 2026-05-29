import { buildingDefs, getBuildingSlotCapacity } from '../data/buildings';
import { getUnitGateState } from './UnitSpawnProgressSystem';
import {
  recordBuildingContribution,
  recordNonSpawnRecovery,
  recordSpawnCopiesCreated,
  recordSpawnMarksConsumed,
  recordSpawnMarksCreated,
} from './StatsSystem';
import type { BuildingChamber, BuildingDef, BuildingInstance, GameState, UnitGateState } from '../types/game';

export type BuildingInstallResult =
  | { status: 'installed'; building: BuildingInstance }
  | { status: 'upgraded'; building: BuildingInstance }
  | { status: 'chamber_full'; chamber: BuildingChamber }
  | { status: 'max_level'; building: BuildingInstance }
  | { status: 'unknown_building'; id: string };

export type UnitStructurePurchaseResult =
  | { status: 'purchased'; id: string; cost: number; building: BuildingInstance }
  | { status: 'upgraded'; id: string; cost: number; building: BuildingInstance }
  | { status: 'insufficient_gold'; id: string; cost: number; gold: number }
  | { status: 'not_unit_structure'; id: string }
  | { status: 'chamber_full'; id: string; cost: number }
  | { status: 'max_level'; id: string; cost: number }
  | { status: 'unknown_building'; id: string };

const UNIT_STRUCTURE_BASE_COST = 24;
const UNIT_STRUCTURE_LEVEL_COST = 18;

const chamberLabels: Record<BuildingChamber, string> = {
  launch: '发球区',
  decision: '抉择区',
  unit: '出兵区',
};

export function getBuildingDef(id: string): BuildingDef | undefined {
  return buildingDefs.find((building) => building.id === id);
}

export function isBuildingReward(id: string): boolean {
  return Boolean(getBuildingDef(id));
}

export function getBuildingLevel(state: GameState, id: string): number {
  return state.buildings.find((building) => building.id === id)?.level ?? 0;
}

export function hasBuilding(state: GameState, id: string): boolean {
  return getBuildingLevel(state, id) > 0;
}

export function syncUnitStructures(state: GameState) {
  state.unitStructures = state.buildings.filter((building) => building.chamber === 'unit');
}

export function installOrUpgradeBuilding(state: GameState, id: string): BuildingInstallResult {
  const def = getBuildingDef(id);
  if (!def) return { status: 'unknown_building', id };

  const existing = state.buildings.find((building) => building.id === id);
  if (existing) {
    if (existing.level >= def.maxLevel) return { status: 'max_level', building: existing };
    existing.level += 1;
    syncUnitStructures(state);
    state.recentFloatingTexts.push({ label: `${def.name} Lv${existing.level}`, color: 0x93c5fd });
    return { status: 'upgraded', building: existing };
  }

  const chamberCount = state.buildings.filter((building) => building.chamber === def.chamber).length;
  if (chamberCount >= getBuildingSlotCapacity(def.chamber)) return { status: 'chamber_full', chamber: def.chamber };

  const building = { id, chamber: def.chamber, level: 1 };
  state.buildings.push(building);
  syncUnitStructures(state);
  state.recentFloatingTexts.push({ label: `${def.name} 已建造`, color: 0x86efac });
  return { status: 'installed', building };
}

export function getUnitStructureGoldCost(state: GameState, id: string): number {
  const level = getBuildingLevel(state, id);
  return UNIT_STRUCTURE_BASE_COST + level * UNIT_STRUCTURE_LEVEL_COST;
}

export function buyUnitStructureWithGold(state: GameState, id: string): UnitStructurePurchaseResult {
  const def = getBuildingDef(id);
  if (!def) return { status: 'unknown_building', id };
  if (def.chamber !== 'unit') return { status: 'not_unit_structure', id };

  const cost = getUnitStructureGoldCost(state, id);
  if (state.gold < cost) return { status: 'insufficient_gold', id, cost, gold: state.gold };

  const result = installOrUpgradeBuilding(state, id);
  if (result.status === 'installed') {
    state.gold -= cost;
    return { status: 'purchased', id, cost, building: result.building };
  }
  if (result.status === 'upgraded') {
    state.gold -= cost;
    return { status: 'upgraded', id, cost, building: result.building };
  }
  if (result.status === 'chamber_full') return { status: 'chamber_full', id, cost };
  if (result.status === 'max_level') return { status: 'max_level', id, cost };
  return { status: 'unknown_building', id };
}

export function getExtraSplitBallCount(state: GameState): number {
  return getBuildingLevel(state, 'launch_splitter_rack');
}

export function recordLaunchMiss(state: GameState): number {
  const level = getBuildingLevel(state, 'launch_recycle_buffer');
  if (level <= 0) return 0;

  state.pendingSpawnMarks += level;
  recordBuildingContribution(state.stats.currentPhase, 'launch', level);
  recordSpawnMarksCreated(state.stats.currentPhase, level);
  recordNonSpawnRecovery(state.stats.currentPhase, 'building_launch_recycle', state.phaseElapsedMs);
  state.recentFloatingTexts.push({ label: `回收缓冲：出兵标记 +${level}`, color: 0x86efac });
  return level;
}

export function consumeSpawnMarkBonus(state: GameState, baseValue: number): number {
  const bonus = state.pendingSpawnMarks;
  if (bonus <= 0) return baseValue;

  state.pendingSpawnMarks = 0;
  recordSpawnMarksConsumed(state.stats.currentPhase, bonus);
  state.recentFloatingTexts.push({ label: `出兵标记兑现 +${bonus}`, color: 0x4ade80 });
  return baseValue + bonus;
}

export function recordGoldHitForBuildings(state: GameState): number {
  const level = getBuildingLevel(state, 'decision_coin_press');
  if (level <= 0) return 0;

  state.buildingEvents.coinPressGoldHits += 1;
  const threshold = Math.max(1, 4 - level);
  if (state.buildingEvents.coinPressGoldHits < threshold) return 0;

  state.buildingEvents.coinPressGoldHits = 0;
  state.pendingSpawnMarks += 1;
  recordBuildingContribution(state.stats.currentPhase, 'decision');
  recordSpawnMarksCreated(state.stats.currentPhase, 1);
  recordNonSpawnRecovery(state.stats.currentPhase, 'building_coin_press', state.phaseElapsedMs);
  state.recentFloatingTexts.push({ label: '铸币导槽：出兵标记 +1', color: 0xfacc15 });
  return 1;
}

export function recordMagicHitForBuildings(state: GameState): number {
  const level = getBuildingLevel(state, 'decision_arc_coil');
  if (level <= 0) return 0;

  state.modifiers.pendingSpawnCopies += level;
  recordBuildingContribution(state.stats.currentPhase, 'decision', level);
  recordSpawnCopiesCreated(state.stats.currentPhase, level);
  recordNonSpawnRecovery(state.stats.currentPhase, 'building_arc_coil', state.phaseElapsedMs);
  state.recentFloatingTexts.push({ label: `电弧回声：复制 +${level}`, color: 0xc084fc });
  return level;
}

export function getOverflowSpillAmount(state: GameState): number {
  return getBuildingLevel(state, 'unit_overflow_hatchery');
}

export function getEffectiveUnitGateState(state: GameState, elapsedMs: number, durationMs: number): UnitGateState {
  const gateActuatorLevel = getBuildingLevel(state, 'unit_gate_actuator');
  if (gateActuatorLevel <= 0) return getUnitGateState(elapsedMs, durationMs);

  const effectiveDuration = durationMs * Math.max(0.28, 0.8 - (gateActuatorLevel - 1) * 0.1);
  return getUnitGateState(elapsedMs, effectiveDuration);
}

export function getBuildingSummary(state: GameState): string {
  if (state.buildings.length === 0) return '建筑: 无';

  return (['launch', 'decision', 'unit'] as const)
    .map((chamber) => {
      const entries = state.buildings
        .filter((building) => building.chamber === chamber)
        .map((building) => {
          const def = getBuildingDef(building.id);
          return `${def?.name ?? building.id} Lv${building.level}`;
        });
      return entries.length > 0 ? `${chamberLabels[chamber]}: ${entries.join(' / ')}` : `${chamberLabels[chamber]}: 空`;
    })
    .join('  ');
}

export function getBuildingRewardDefs(): BuildingDef[] {
  return buildingDefs;
}

export function getAvailableBuildingRewardDefs(state: GameState): BuildingDef[] {
  return buildingDefs.filter((def) => {
    const existing = state.buildings.find((building) => building.id === def.id);
    if (existing) return existing.level < def.maxLevel;

    const chamberCount = state.buildings.filter((building) => building.chamber === def.chamber).length;
    return chamberCount < getBuildingSlotCapacity(def.chamber);
  });
}

export function getAvailableUnitStructureDefs(state: GameState): BuildingDef[] {
  return getAvailableBuildingRewardDefs(state).filter((def) => def.chamber === 'unit');
}
