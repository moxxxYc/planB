import { buildingDefs } from '../data/buildings';
import { doctrineTechDefs } from '../data/doctrineTechs';
import { raceDefs } from '../data/races';
import { relicDefs } from '../data/relics';
import { unitDefs } from '../data/units';
import type { BuildingChamber, GameState, PhaseStats } from '../types/game';

export interface BuildTelemetrySummary {
  dominantChamber: string;
  archetype: string;
  resourceReturnRate: number;
  lines: string[];
}

export interface BuildSurfaceHudSummaries {
  relics: string;
  techs: string;
  structures: string;
}

export type BuildChamberPanelSummaries = Record<BuildingChamber, string[]>;

export interface BuildIdentityChamberVisual {
  label: string;
  detail: string;
  iconKey: string;
}

export interface BuildIdentityStructureVisual {
  assetKey: string;
  label: string;
  intensity: number;
}

export interface BuildIdentityVisualSummary {
  archetype: string;
  badgeText: string;
  accentColor: number;
  zoneEmphasis: Record<BuildingChamber, number>;
  chambers: Record<BuildingChamber, BuildIdentityChamberVisual>;
  structures: Record<BuildingChamber, BuildIdentityStructureVisual[]>;
}

const chamberLabels: Record<BuildingChamber, string> = {
  launch: '发球区',
  decision: '战备区',
  unit: '出兵区',
};

const recoverySourceLabels: Record<string, string> = {
  baseline_fallback: '保底',
  research_return: '研究',
  doctrine_conversion: '科技',
  doctrine_launch_loss: '科技',
  building_launch_recycle: '建筑',
  building_coin_press: '建筑',
  building_arc_coil: '建筑',
  relic_spawn_mark: '遗物',
  relic_spell_echo: '遗物',
  ball_tag_recycle: '球标',
  ball_tag_spawn: '球标',
  phase_tool_spawn_beacon: '工具',
  phase_tool_hot_slot: '工具',
  phase_tool_queue_surge: '工具',
  phase_tool_marked_shot: '工具',
  phase_tool_repair: '工具',
  unknown: '未知',
};

export function getDominantBuildChamber(stats: PhaseStats): BuildingChamber {
  const chambers: BuildingChamber[] = ['launch', 'decision', 'unit'];
  return chambers.reduce((best, chamber) => (
    stats.buildingContributions[chamber] > stats.buildingContributions[best] ? chamber : best
  ), 'launch');
}

export function buildPhaseTelemetrySummary(state: GameState, stats: PhaseStats = state.stats.currentPhase): BuildTelemetrySummary {
  const dominant = getDominantBuildChamber(stats);
  const resourceReturnRate = getResourceReturnRate(stats);
  const archetype = inferBuildArchetype(state);
  const dominantLabel = chamberLabels[dominant];

  return {
    dominantChamber: dominantLabel,
    archetype,
    resourceReturnRate,
    lines: [
      `构筑 ${archetype}  主仓 ${dominantLabel}`,
      `发球 战备${stats.launchOutcomes.standby} 分裂${stats.launchOutcomes.split} 发兵${stats.launchOutcomes.spawn} 丢失${stats.launchOutcomes.miss}  战备 金${stats.slotTriggers.gold} 法${stats.slotTriggers.magic} 升${stats.slotTriggers.upgrade}  发兵${stats.slotTriggers.spawn}`,
      `回流工具 ${stats.phaseToolsPurchased}  标记 ${stats.spawnMarksCreated}/${stats.spawnMarksConsumed}  复制 ${stats.spawnCopiesCreated}  遗物 ${stats.relicTriggers}  研究 ${state.researchPoints}(${state.doctrineEvents.researchReturnProgress}/4)  保底 ${state.doctrineEvents.nonSpawnStreak}/3  回流效率 ${formatPercent(resourceReturnRate)}  最长非出兵 ${stats.nonSpawnStreakMax}  首次回流 ${formatRecoveryLatency(stats.timeToRecoverySpawnMs)}  来源 ${formatRecoverySources(stats.recoverySources)}`,
      `入队 ${formatUnitCounts(stats.unitsQueuedById)}  部署 ${formatUnitCounts(stats.unitsDeployedById)}  高阶 ${stats.advancedUnitsQueued}/${stats.unitsQueued}`,
      `建筑贡献 发${stats.buildingContributions.launch} 备${stats.buildingContributions.decision} 出${stats.buildingContributions.unit}  溢流${stats.overflowProgressGranted} 开门${stats.gateAccelerationEvents} 挡回 ${stats.gateBlockedEvents} 爆发${stats.queueBurstEvents}`,
    ],
  };
}

export function buildSurfaceHudSummaries(state: GameState): BuildSurfaceHudSummaries {
  return {
    relics: formatHudList(state.launchRelics.map((relic) => relicDefs.find((def) => def.id === relic.id)?.name ?? relic.id)),
    techs: formatHudList(state.decisionTechs.map((tech) => doctrineTechDefs.find((def) => def.id === tech.id)?.name ?? tech.id)),
    structures: formatHudList(state.unitStructures.filter((building) => building.chamber === 'unit').map((building) => {
      const def = buildingDefs.find((candidate) => candidate.id === building.id);
      return `${def?.name ?? building.id}L${building.level}`;
    })),
  };
}

export function buildChamberPanelSummaries(state: GameState): BuildChamberPanelSummaries {
  return {
    launch: [
      formatBuildingLine(state, 'launch'),
      formatSurfaceLine('遗物', state.launchRelics.map((relic) => relicDefs.find((def) => def.id === relic.id)?.name ?? relic.id)),
    ].filter(isPresent),
    decision: [
      formatBuildingLine(state, 'decision'),
      formatSurfaceLine('科技', state.decisionTechs.map((tech) => doctrineTechDefs.find((def) => def.id === tech.id)?.name ?? tech.id)),
    ].filter(isPresent),
    unit: [
      formatBuildingLine(state, 'unit'),
    ].filter(isPresent),
  };
}

export function buildIdentityVisualSummary(state: GameState): BuildIdentityVisualSummary {
  const archetype = inferBuildArchetype(state);
  const preset = identityVisualPresets[archetype] ?? identityVisualPresets['混合构筑'];
  return {
    archetype,
    badgeText: `构筑身份 ${archetype}`,
    accentColor: preset.accentColor,
    zoneEmphasis: preset.zoneEmphasis,
    chambers: preset.chambers,
    structures: preset.structures,
  };
}

function getResourceReturnRate(stats: PhaseStats): number {
  const nonSpawnTriggers = stats.slotTriggers.gold + stats.slotTriggers.magic + stats.slotTriggers.upgrade;
  if (nonSpawnTriggers <= 0) return stats.nonSpawnRecoveryEvents > 0 ? 1 : 0;
  return Math.min(1, stats.nonSpawnRecoveryEvents / nonSpawnTriggers);
}

function formatHudList(items: string[]): string {
  if (items.length === 0) return '无';
  const visible = items.slice(0, 2);
  const overflow = items.length - visible.length;
  return `${visible.join(' / ')}${overflow > 0 ? ` +${overflow}` : ''}`;
}

function formatBuildingLine(state: GameState, chamber: BuildingChamber): string {
  const label = chamber === 'unit' ? '工事' : '建筑';
  const emptySlots = chamber === 'unit' ? '空 / 空 / 空' : '空 / 空';
  const installed = state.buildings
    .filter((building) => building.chamber === chamber)
    .map((building) => {
      const def = buildingDefs.find((candidate) => candidate.id === building.id);
      return `${def?.name ?? building.id}L${building.level}`;
    });
  return `${label}: ${installed.length > 0 ? formatCompactList(installed, 2) : emptySlots}`;
}

function formatSurfaceLine(label: string, items: string[]): string | undefined {
  if (items.length === 0) return undefined;
  return `${label}: ${formatCompactList(items, 2)}`;
}

function formatCompactList(items: string[], visibleCount: number): string {
  const visible = items.slice(0, visibleCount);
  const overflow = items.length - visible.length;
  return `${visible.join(' / ')}${overflow > 0 ? ` / +${overflow}` : ''}`;
}

function isPresent(value: string | undefined): value is string {
  return Boolean(value);
}

function formatPercent(value: number): string {
  return `${Math.round(value * 100)}%`;
}

function formatRecoveryLatency(ms: number | undefined): string {
  return ms === undefined ? '未触发' : `${(ms / 1000).toFixed(1)}s`;
}

function formatRecoverySources(sources: Record<string, number>): string {
  const entries = Object.entries(sources).filter(([, count]) => count > 0);
  if (entries.length === 0) return '无';
  return entries
    .sort((left, right) => right[1] - left[1])
    .slice(0, 3)
    .map(([source, count]) => `${recoverySourceLabels[source] ?? source}x${count}`)
    .join(' / ');
}

function formatUnitCounts(counts: Record<string, number>): string {
  const entries = Object.entries(counts).filter(([, count]) => count > 0);
  if (entries.length === 0) return '无';
  return entries
    .sort((left, right) => right[1] - left[1])
    .slice(0, 3)
    .map(([unitId, count]) => `${unitDefs[unitId]?.name ?? unitId}x${count}`)
    .join(' / ');
}

function inferBuildArchetype(state: GameState): string {
  const buildingIds = new Set(state.buildings.map((building) => building.id));
  const doctrineIds = new Set(state.doctrineTechs.map((tech) => tech.id));
  const hasAdvancedMechLevel = raceDefs.mech.unitPool.some((unitId) => (state.unitLevels[unitId] ?? 1) > 1);
  const hasEconomyEngine = buildingIds.has('decision_coin_press')
    || doctrineIds.has('decision_conversion_matrix')
    || state.gold >= 80
    || state.modifiers.goldMultiplier > 1.1;
  const hasRecoveryEngine = buildingIds.has('launch_recycle_buffer')
    || doctrineIds.has('launch_loss_research')
    || state.pendingSpawnMarks > 0;
  const hasStrongEconomySignal = state.modifiers.goldMultiplier > 1.1
    || (state.gold >= 80 && !hasRecoveryEngine);

  if (buildingIds.has('unit_gate_actuator') || doctrineIds.has('unit_elite_escort') || state.nextSpawnCreatesElite || hasAdvancedMechLevel) return '机械精英';
  if (buildingIds.has('decision_arc_coil') || state.modifiers.magicSpawnCopyBonus > 0 || state.modifiers.pendingSpawnCopies > 0) return '法术复制';
  if (hasEconomyEngine && hasStrongEconomySignal) return '经济工业';
  if (hasRecoveryEngine) return '逆风修复';
  if (hasEconomyEngine) return '经济工业';
  if (buildingIds.has('unit_overflow_hatchery') || buildingIds.has('unit_queue_conveyor') || doctrineIds.has('launch_extra_launcher') || state.modifiers.spawnExtraCount > 0 || state.modifiers.ballCount > 1) return '虫群爆兵';
  return '混合构筑';
}

const identityVisualPresets: Record<string, Omit<BuildIdentityVisualSummary, 'archetype' | 'badgeText'>> = {
  虫群爆兵: {
    accentColor: 0x4ade80,
    zoneEmphasis: { launch: 2, decision: 1, unit: 3 },
    chambers: {
      launch: { label: '分裂增殖', detail: '多球/裂变', iconKey: 'icon_spawn' },
      decision: { label: '发兵扩张', detail: '路线导流', iconKey: 'icon_spawn' },
      unit: { label: '溢流输送', detail: '低阶密度', iconKey: 'icon_spawn' },
    },
    structures: {
      launch: [
        { assetKey: 'structure_swarm', label: '裂变巢', intensity: 2 },
        { assetKey: 'structure_swarm', label: '副投口', intensity: 2 },
      ],
      decision: [
        { assetKey: 'structure_swarm', label: '出兵漏斗', intensity: 1 },
      ],
      unit: [
        { assetKey: 'structure_swarm', label: '孵化列', intensity: 3 },
        { assetKey: 'structure_swarm', label: '输送列', intensity: 3 },
      ],
    },
  },
  法术复制: {
    accentColor: 0xc084fc,
    zoneEmphasis: { launch: 2, decision: 3, unit: 1 },
    chambers: {
      launch: { label: '棱镜弹匣', detail: '带标记球', iconKey: 'icon_special' },
      decision: { label: '法术复制', detail: 'MAGIC 连锁', iconKey: 'icon_magic' },
      unit: { label: '复制兑现', detail: '一球多队', iconKey: 'icon_spawn' },
    },
    structures: {
      launch: [
        { assetKey: 'structure_magic_copy', label: '棱镜仓', intensity: 2 },
      ],
      decision: [
        { assetKey: 'structure_magic_copy', label: '回声线圈', intensity: 3 },
        { assetKey: 'structure_magic_copy', label: '复制阀', intensity: 3 },
      ],
      unit: [
        { assetKey: 'structure_magic_copy', label: '镜像闸', intensity: 1 },
      ],
    },
  },
  机械精英: {
    accentColor: 0xf59e0b,
    zoneEmphasis: { launch: 1, decision: 2, unit: 3 },
    chambers: {
      launch: { label: '稳定供球', detail: '高价值入场', iconKey: 'icon_upgrade' },
      decision: { label: '升级校准', detail: '等级滚动', iconKey: 'icon_upgrade' },
      unit: { label: '高阶绞盘', detail: '早开精英', iconKey: 'icon_upgrade' },
    },
    structures: {
      launch: [
        { assetKey: 'structure_mech_elite', label: '稳压架', intensity: 1 },
      ],
      decision: [
        { assetKey: 'structure_mech_elite', label: '校准台', intensity: 2 },
      ],
      unit: [
        { assetKey: 'structure_mech_elite', label: '高阶绞盘', intensity: 3 },
        { assetKey: 'structure_mech_elite', label: '精英门架', intensity: 3 },
      ],
    },
  },
  经济工业: {
    accentColor: 0xfacc15,
    zoneEmphasis: { launch: 1, decision: 3, unit: 2 },
    chambers: {
      launch: { label: '回收供能', detail: '丢失转产', iconKey: 'icon_gold' },
      decision: { label: '金币工业', detail: '金币回流', iconKey: 'icon_gold' },
      unit: { label: '队列爆发', detail: '工事兑现', iconKey: 'icon_spawn' },
    },
    structures: {
      launch: [
        { assetKey: 'structure_economy_industry', label: '回收管', intensity: 1 },
      ],
      decision: [
        { assetKey: 'structure_economy_industry', label: '铸币机', intensity: 3 },
        { assetKey: 'structure_economy_industry', label: '工业阀', intensity: 3 },
      ],
      unit: [
        { assetKey: 'structure_economy_industry', label: '输送带', intensity: 2 },
      ],
    },
  },
  逆风修复: {
    accentColor: 0xfb7185,
    zoneEmphasis: { launch: 3, decision: 2, unit: 2 },
    chambers: {
      launch: { label: '丢失回收', detail: '落空补偿', iconKey: 'icon_special' },
      decision: { label: '金币保底', detail: '非出兵兜底', iconKey: 'icon_gold' },
      unit: { label: '修复输送', detail: '回流入队', iconKey: 'icon_spawn' },
    },
    structures: {
      launch: [
        { assetKey: 'structure_recovery', label: '回收翼', intensity: 3 },
        { assetKey: 'structure_recovery', label: '保险丝', intensity: 3 },
      ],
      decision: [
        { assetKey: 'structure_recovery', label: '保底阀', intensity: 2 },
      ],
      unit: [
        { assetKey: 'structure_recovery', label: '修复站', intensity: 2 },
      ],
    },
  },
  混合构筑: {
    accentColor: 0x93c5fd,
    zoneEmphasis: { launch: 1, decision: 1, unit: 1 },
    chambers: {
      launch: { label: '基础供球', detail: '待成型', iconKey: 'icon_spawn' },
      decision: { label: '基础分流', detail: '待成型', iconKey: 'icon_special' },
      unit: { label: '基础入队', detail: '待成型', iconKey: 'icon_spawn' },
    },
    structures: {
      launch: [
        { assetKey: 'structure_swarm', label: '基础座', intensity: 1 },
      ],
      decision: [
        { assetKey: 'structure_magic_copy', label: '基础阀', intensity: 1 },
      ],
      unit: [
        { assetKey: 'structure_economy_industry', label: '基础轨', intensity: 1 },
      ],
    },
  },
};
