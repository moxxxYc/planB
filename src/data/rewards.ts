import type { RewardDef } from '../types/game';

export const rewardDefs: RewardDef[] = [
  { id: 'spawn_slot_widen', name: '扩宽出兵槽', tag: '爆兵', icon: 'icon_spawn', description: 'SPAWN 槽命中权重 +10%。' },
  { id: 'reinforcement_drums', name: '增援鼓点', tag: '爆兵', icon: 'icon_spawn', description: '预备队释放速度 +25%。' },
  { id: 'mass_reserves', name: '爆兵储备', tag: '爆兵', icon: 'icon_spawn', description: '每次 SPAWN 额外加入 1 个基础单位。' },
  { id: 'elite_training', name: '老兵训练', tag: '精英', icon: 'icon_upgrade', description: '精英存活过阶段时额外获得 1 点经验。' },
  { id: 'elite_promotion', name: '精英晋升', tag: '精英', icon: 'icon_upgrade', description: '下一次高级出兵变为精英。' },
  { id: 'extra_ball_interval', name: '副投球器', tag: '连锁', icon: 'icon_spawn', description: '每轮投球额外掉落 1 颗球。' },
  { id: 'basic_unit_drill', name: '基础训练', tag: '训练', icon: 'icon_upgrade', description: '基础单位生命和伤害 +10%。' },
  { id: 'wide_spawn', name: '扩大出兵槽', tag: '爆兵', icon: 'icon_spawn', description: '出兵槽宽度 +20%。' },
  { id: 'double_drop', name: '双球投放', tag: '连锁', icon: 'icon_spawn', description: '每轮投球额外掉落 1 颗球。' },
  { id: 'training_order', name: '训练指令', tag: '精英', icon: 'icon_upgrade', description: '下一波出兵单位等级 +1。' },
  { id: 'elite_protocol', name: '精英协议', tag: '精英', icon: 'icon_upgrade', description: '升级槽额外提供 1 层下次出兵等级。' },
  { id: 'wide_gold', name: '黄金槽扩张', tag: '经济', icon: 'icon_gold', description: '金币槽宽度 +20%。' },
  { id: 'war_savings', name: '战争储蓄', tag: '经济', icon: 'icon_gold', description: '金币 +50%，出兵槽宽度 -10%。' },
  { id: 'magic_overload', name: '魔法过载', tag: '法术', icon: 'icon_magic', description: '法术伤害 +50%。' },
  { id: 'spell_copy', name: '法术复制', tag: '法术', icon: 'icon_magic', description: '法术后，下一次出兵复制 1 个单位。' },
  { id: 'mech_calibration', name: '机械校准', tag: '机械', icon: 'icon_upgrade', description: '机械升级效率 +1。' },
  { id: 'hive_hatching', name: '虫群孵化', tag: '虫群', icon: 'icon_spawn', description: '虫群出兵额外生成 1 个幼虫兵。' },
];
