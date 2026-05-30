import type { BuildingChamber, BuildingDef } from '../types/game';

export const BUILDING_SLOTS_PER_CHAMBER = 2;
export const BUILDING_SLOT_CAPACITY_BY_CHAMBER: Record<BuildingChamber, number> = {
  launch: BUILDING_SLOTS_PER_CHAMBER,
  decision: BUILDING_SLOTS_PER_CHAMBER,
  unit: 3,
};

export function getBuildingSlotCapacity(chamber: BuildingChamber): number {
  return BUILDING_SLOT_CAPACITY_BY_CHAMBER[chamber];
}

export const buildingDefs: BuildingDef[] = [
  {
    id: 'launch_splitter_rack',
    chamber: 'launch',
    name: '分裂联箱',
    tag: '发球建筑',
    icon: 'icon_spawn',
    description: '分裂槽额外再投 1 颗同值球。',
    maxLevel: 3,
  },
  {
    id: 'launch_recycle_buffer',
    chamber: 'launch',
    name: '回收缓冲',
    tag: '发球建筑',
    icon: 'icon_special',
    description: '落空时储存 1 个出兵标记，下一颗出兵球 +1 value。',
    maxLevel: 3,
  },
  {
    id: 'decision_coin_press',
    chamber: 'decision',
    name: '铸币导槽',
    tag: '抉择建筑',
    icon: 'icon_gold',
    description: '每 3 次金币命中，储存 1 个出兵标记。',
    maxLevel: 3,
  },
  {
    id: 'decision_arc_coil',
    chamber: 'decision',
    name: '电弧回声',
    tag: '抉择建筑',
    icon: 'icon_magic',
    description: '法术命中后，额外复制下一次出兵。',
    maxLevel: 3,
  },
  {
    id: 'unit_overflow_hatchery',
    chamber: 'unit',
    name: '溢流孵化器',
    tag: '出兵建筑',
    icon: 'icon_spawn',
    description: '任一单位入队时，右侧相邻单位槽 +1 进度。',
    maxLevel: 3,
  },
  {
    id: 'unit_gate_actuator',
    chamber: 'unit',
    name: '高阶绞盘',
    tag: '出兵建筑',
    icon: 'icon_upgrade',
    description: '加快高阶挡板开放，让高阶单位槽更早可用。',
    maxLevel: 3,
  },
  {
    id: 'unit_queue_conveyor',
    chamber: 'unit',
    name: '队列输送带',
    tag: '出兵建筑',
    icon: 'icon_spawn',
    description: '单位入队时，本批单位进入短释放间隔的部署 burst。',
    maxLevel: 3,
  },
];
