import type { RewardDef } from '../types/game';

export const rewardDefs: RewardDef[] = [
  { id: 'spawn_slot_widen', name: '扩宽发兵路线', tag: '战备区蓝图 · 爆兵', icon: 'icon_spawn', description: '强化战备区向出兵区的回流价值，让更多收益转成出兵压力。', chamber: 'decision', sourceType: 'legacy' },
  { id: 'reinforcement_drums', name: '增援鼓点', tag: '出兵区蓝图 · 爆兵', icon: 'icon_spawn', description: '加快预备队输送速度，让已入队单位更快部署到战场。', chamber: 'unit', sourceType: 'legacy' },
  { id: 'mass_reserves', name: '爆兵储备', tag: '出兵区蓝图 · 爆兵', icon: 'icon_spawn', description: '强化出兵仓装填，每次 SPAWN 额外加入 1 个基础单位。', chamber: 'unit', sourceType: 'legacy' },
  { id: 'elite_training', name: '老兵训练', tag: '出兵区蓝图 · 精英', icon: 'icon_upgrade', description: '强化出兵仓老兵保养，精英跨阶段存活时获得更多经验。', chamber: 'unit', sourceType: 'legacy' },
  { id: 'elite_promotion', name: '精英晋升', tag: '出兵区蓝图 · 精英', icon: 'icon_upgrade', description: '给出兵仓预装精英名额，下一次高级出兵变为精英。', chamber: 'unit', sourceType: 'legacy' },
  { id: 'extra_ball_interval', name: '副投球器', tag: '发球区蓝图 · 连锁', icon: 'icon_spawn', description: '改造发球区副投口，每轮投球额外掉落 1 颗球。', chamber: 'launch', sourceType: 'legacy' },
  { id: 'basic_unit_drill', name: '基础训练', tag: '出兵区蓝图 · 训练', icon: 'icon_upgrade', description: '提高出兵仓基础训练规格，基础单位生命和伤害提升。', chamber: 'unit', sourceType: 'legacy' },
  { id: 'wide_spawn', name: '扩大发兵路线', tag: '战备区蓝图 · 爆兵', icon: 'icon_spawn', description: '强化发兵路线权重，让球路更容易把战备收益转进出兵仓。', chamber: 'decision', sourceType: 'legacy' },
  { id: 'double_drop', name: '双球投放', tag: '发球区蓝图 · 连锁', icon: 'icon_spawn', description: '改造发球区双投机构，每轮投球额外掉落 1 颗球。', chamber: 'launch', sourceType: 'legacy' },
  { id: 'training_order', name: '训练指令', tag: '出兵区蓝图 · 精英', icon: 'icon_upgrade', description: '让出兵仓预载训练指令，下一波出兵单位等级 +1。', chamber: 'unit', sourceType: 'legacy' },
  { id: 'elite_protocol', name: '精英协议', tag: '出兵区蓝图 · 精英', icon: 'icon_upgrade', description: '升级能量回灌出兵仓，额外保留 1 层下次出兵等级。', chamber: 'unit', sourceType: 'legacy' },
  { id: 'wide_gold', name: '黄金槽扩张', tag: '战备区蓝图 · 经济', icon: 'icon_gold', description: '扩宽战备区 GOLD 槽口，提高经济路线的球路占比。', chamber: 'decision', sourceType: 'legacy' },
  { id: 'war_savings', name: '战争储蓄', tag: '战备区蓝图 · 经济', icon: 'icon_gold', description: '把战备区收益偏向金币，换取更强经济但略收窄发兵路线。', chamber: 'decision', sourceType: 'legacy' },
  { id: 'magic_overload', name: '魔法过载', tag: '战备区蓝图 · 法术', icon: 'icon_magic', description: '强化战备区 MAGIC 回路，让法术命中造成更高伤害。', chamber: 'decision', sourceType: 'legacy' },
  { id: 'spell_copy', name: '法术复制', tag: '战备区蓝图 · 法术', icon: 'icon_magic', description: '让战备区法术结果回流到出兵仓，下一次出兵复制 1 个单位。', chamber: 'decision', sourceType: 'legacy' },
  { id: 'mech_calibration', name: '机械校准', tag: '出兵区蓝图 · 机械', icon: 'icon_upgrade', description: '校准出兵仓升级传动，提高机械单位的升级效率。', chamber: 'unit', sourceType: 'legacy' },
  { id: 'hive_hatching', name: '虫群孵化', tag: '出兵区蓝图 · 虫群', icon: 'icon_spawn', description: '给出兵仓接入孵化囊，虫群出兵额外生成 1 个幼虫兵。', chamber: 'unit', sourceType: 'legacy' },
];
