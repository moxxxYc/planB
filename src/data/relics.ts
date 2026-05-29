import type { RelicDef } from '../types/game';

export const relicDefs: RelicDef[] = [
  {
    id: 'entropy_fuse',
    name: '逆熵保险丝',
    tag: '事件遗物',
    icon: 'icon_special',
    description: '每 3 次落空，储存 1 个出兵标记。',
  },
  {
    id: 'prism_magazine',
    name: '棱镜弹匣',
    tag: '发球遗物',
    icon: 'icon_spawn',
    description: '每阶段开始时，下一颗发球带 split+ 和 spawn-mark 标签。',
  },
  {
    id: 'gate_momentum',
    name: '挡板动量芯',
    tag: '事件遗物',
    icon: 'icon_upgrade',
    description: '高阶挡板弹回时，储存 1 个出兵标记。',
  },
  {
    id: 'spell_echo_relic',
    name: '法术回声石',
    tag: '事件遗物',
    icon: 'icon_magic',
    description: '法术命中后，复制下一次出兵。',
  },
  {
    id: 'upgrade_cache',
    name: '校准存储芯',
    tag: '事件遗物',
    icon: 'icon_upgrade',
    description: '基础单位吃掉升级时，保留 1 层给后续出兵。',
  },
];
