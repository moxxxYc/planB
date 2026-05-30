import { rewardDefs } from '../data/rewards';
import { randomInt } from '../utils/random';
import { getAvailableBuildingRewardDefs, installOrUpgradeBuilding, isBuildingReward } from './BuildingSystem';
import { getAvailableRelicRewardDefs, installRelic, isRelicReward } from './RelicSystem';
import { getAvailableDoctrineTechRewardDefs, isDoctrineTechReward, unlockDoctrineTech } from './DoctrineSystem';
import type {
  BuildingChamber,
  BuildingDef,
  DoctrineTechDef,
  GameState,
  RelicDef,
  RewardChamber,
  RewardDef,
  RewardSourceType,
} from '../types/game';

export const rewardChambers: RewardChamber[] = ['launch', 'decision', 'unit'];

const rewardChamberLabels: Record<RewardChamber, string> = {
  launch: '发球区蓝图',
  decision: '战备区蓝图',
  unit: '出兵区蓝图',
};

const relicChambers: Record<string, RewardChamber> = {
  entropy_fuse: 'launch',
  prism_magazine: 'launch',
  gate_momentum: 'unit',
  spell_echo_relic: 'decision',
  upgrade_cache: 'unit',
};

export function buildRewardChoices(state: GameState): RewardDef[] {
  return rewardChambers
    .map((chamber) => pickChamberBlueprint(state, chamber))
    .filter((reward): reward is RewardDef => Boolean(reward));
}

export function buildBlueprintRewardPools(state: GameState): Record<RewardChamber, RewardDef[]> {
  return {
    launch: buildChamberBlueprintPool(state, 'launch'),
    decision: buildChamberBlueprintPool(state, 'decision'),
    unit: buildChamberBlueprintPool(state, 'unit'),
  };
}

export function getRewardChamberLabel(chamber: RewardChamber): string {
  return rewardChamberLabels[chamber];
}

export type RewardRerollResult =
  | { status: 'rerolled'; choices: RewardDef[] }
  | { status: 'insufficient_gold'; choices: RewardDef[] };

export function rerollRewardChoices(
  state: GameState,
  previousChoices: RewardDef[],
  options: { cost: number },
): RewardRerollResult {
  if (state.gold < options.cost) {
    return { status: 'insufficient_gold', choices: previousChoices };
  }

  state.gold -= options.cost;
  const previousIds = previousChoices.map((reward) => reward.id).join('|');
  let choices = buildRewardChoices(state);
  for (let attempt = 0; attempt < 5 && choices.map((reward) => reward.id).join('|') === previousIds; attempt += 1) {
    choices = buildRewardChoices(state);
  }

  return { status: 'rerolled', choices };
}

export function applyReward(state: GameState, rewardId: string) {
  if (isBuildingReward(rewardId)) {
    installOrUpgradeBuilding(state, rewardId);
    return;
  }
  if (isRelicReward(rewardId)) {
    installRelic(state, rewardId);
    return;
  }
  if (isDoctrineTechReward(rewardId)) {
    unlockDoctrineTech(state, rewardId);
    return;
  }

  if (rewardId === 'wide_spawn') state.slots.spawn.widthWeight *= 1.2;
  if (rewardId === 'spawn_slot_widen') state.slots.spawn.widthWeight *= 1.1;
  if (rewardId === 'reinforcement_drums') state.modifiers.queueReleaseSpeedBonus += 0.25;
  if (rewardId === 'mass_reserves') state.modifiers.spawnExtraCount += 1;
  if (rewardId === 'elite_training') state.modifiers.eliteExtraVeterancy += 1;
  if (rewardId === 'elite_promotion') state.nextSpawnCreatesElite = true;
  if (rewardId === 'extra_ball_interval') state.modifiers.ballCount += 1;
  if (rewardId === 'basic_unit_drill') {
    state.modifiers.basicUnitHpBonus += 0.1;
    state.modifiers.basicUnitDamageBonus += 0.1;
  }
  if (rewardId === 'double_drop') state.modifiers.ballCount += 1;
  if (rewardId === 'training_order') state.modifiers.nextPhaseSpawnLevelBonus += 1;
  if (rewardId === 'elite_protocol') state.pendingSpawnLevelBonus = Math.min(3, state.pendingSpawnLevelBonus + 1);
  if (rewardId === 'wide_gold') state.slots.gold.widthWeight *= 1.2;
  if (rewardId === 'war_savings') {
    state.modifiers.goldMultiplier *= 1.5;
    state.slots.spawn.widthWeight *= 0.9;
  }
  if (rewardId === 'magic_overload') state.modifiers.magicDamageMultiplier *= 1.5;
  if (rewardId === 'spell_copy') state.modifiers.magicSpawnCopyBonus += 1;
  if (rewardId === 'mech_calibration') state.modifiers.mechUpgradeEfficiency += 1;
  if (rewardId === 'hive_hatching') state.modifiers.hiveExtraGrubCount += 1;
}

function pickChamberBlueprint(state: GameState, chamber: RewardChamber): RewardDef | undefined {
  const pool = buildChamberBlueprintPool(state, chamber);
  if (pool.length <= 0) return undefined;

  const pick = randomInt(state.seed, 0, pool.length - 1);
  state.seed = pick.seed;
  return pool[pick.value];
}

function buildChamberBlueprintPool(state: GameState, chamber: RewardChamber): RewardDef[] {
  const buildingChoices = getAvailableBuildingRewardDefs(state)
    .filter((building) => building.chamber === chamber)
    .map(toBuildingBlueprint);
  if (buildingChoices.length > 0) return buildingChoices;

  const surfaceChoices = [
    ...getAvailableRelicRewardDefs(state)
      .filter((relic) => getRelicChamber(relic.id) === chamber)
      .map(toRelicBlueprint),
    ...getAvailableDoctrineTechRewardDefs(state)
      .filter((tech) => tech.path === chamber)
      .map(toDoctrineBlueprint),
  ];
  if (surfaceChoices.length > 0) return surfaceChoices;

  return rewardDefs.filter((reward) => reward.chamber === chamber);
}

function toBuildingBlueprint(building: BuildingDef): RewardDef {
  return {
    id: building.id,
    name: building.name,
    tag: `${getRewardChamberLabel(building.chamber)} · ${building.tag}`,
    icon: building.icon,
    description: describeBuildingBlueprint(building),
    chamber: building.chamber,
    sourceType: 'building',
  };
}

function toRelicBlueprint(relic: RelicDef): RewardDef {
  const chamber = getRelicChamber(relic.id);
  return {
    id: relic.id,
    name: relic.name,
    tag: `${getRewardChamberLabel(chamber)} · ${relic.tag}`,
    icon: relic.icon,
    description: describeRelicBlueprint(relic, chamber),
    chamber,
    sourceType: 'relic',
  };
}

function toDoctrineBlueprint(tech: DoctrineTechDef): RewardDef {
  return {
    id: tech.id,
    name: tech.name,
    tag: `${getRewardChamberLabel(tech.path)} · ${tech.tag}`,
    icon: tech.icon,
    description: describeDoctrineBlueprint(tech),
    chamber: tech.path,
    sourceType: 'doctrine',
  };
}

function getRelicChamber(id: string): RewardChamber {
  return relicChambers[id] ?? 'decision';
}

function describeBuildingBlueprint(building: BuildingDef): string {
  if (building.id === 'launch_splitter_rack') return '发球区 split 会额外再投球，适合爆兵/多球流。';
  if (building.id === 'launch_recycle_buffer') return '发球落空会储存出兵标记，把坏球回流成下一次出兵价值。';
  if (building.id === 'decision_coin_press') return '金币命中会逐步转成出兵标记，适合经济工业流。';
  if (building.id === 'decision_arc_coil') return '法术命中会复制后续出兵，适合法术复制流。';
  if (building.id === 'unit_overflow_hatchery') return '低阶出兵会向右侧槽扩散进度，适合虫群爆兵/中阶过渡。';
  if (building.id === 'unit_gate_actuator') return '高阶挡板更早打开，让高级单位更容易进入出兵队列。';
  if (building.id === 'unit_queue_conveyor') return '单位入队后更快部署，适合把出兵压力立刻推到战场。';
  return building.description;
}

function describeRelicBlueprint(relic: RelicDef, chamber: BuildingChamber): string {
  if (relic.id === 'prism_magazine') return '发球区预装棱镜弹匣，让下一颗球带分裂和出兵标记。';
  if (relic.id === 'entropy_fuse') return '发球落空会累积保险丝，连续坏球回流成出兵标记。';
  if (relic.id === 'gate_momentum') return '出兵区挡板把高阶球弹回时，额外储存出兵标记。';
  if (relic.id === 'upgrade_cache') return '出兵区保留低阶单位吃掉的升级，让后续单位继续受益。';
  if (relic.id === 'spell_echo_relic') return '战备区法术命中后复制下一次出兵，降低非出兵负反馈。';
  return `${getRewardChamberLabel(chamber)}改造：${relic.description}`;
}

function describeDoctrineBlueprint(tech: DoctrineTechDef): string {
  if (tech.id === 'launch_extra_launcher') return '发球区增加副投射逻辑，每轮自动投球 +1。';
  if (tech.id === 'launch_loss_research') return '发球落空会回收为研究与出兵标记，适合逆风修复。';
  if (tech.id === 'decision_slot_calibration') return '战备区校准会强化发兵路线，让发兵更容易兑现。';
  if (tech.id === 'decision_conversion_matrix') return '战备区非出兵结果会积累研究并回流出兵标记。';
  if (tech.id === 'unit_mobilization_links') return '出兵区动员链路加速预备队释放，缩短入队到部署时间。';
  if (tech.id === 'unit_elite_escort') return '出兵区保送低阶单位吃掉的升级，帮助精英路线成型。';
  return tech.description;
}
