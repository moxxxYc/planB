import type { PhaseToolDef, PhaseToolId } from '../types/game';

export const phaseToolDefs: PhaseToolDef[] = [
  {
    id: 'spawn_beacon',
    name: '出兵信标',
    shortLabel: '信标',
    tag: '回流',
    cost: 20,
    description: '立刻获得 2 个出兵标记，把阶段内金币转成下一次出兵价值。',
  },
  {
    id: 'hot_slot_calibrator',
    name: '热槽校准器',
    shortLabel: '热槽',
    tag: '出兵',
    cost: 25,
    description: '给当前种族第一个兵种槽灌入 2 点进度，快速验证队列回流。',
  },
  {
    id: 'queue_surge',
    name: '队列脉冲',
    shortLabel: '脉冲',
    tag: '动员',
    cost: 18,
    description: '本 run 预备队释放速度提高，让已入队单位更快上场。',
  },
  {
    id: 'field_repair',
    name: '战地修复',
    shortLabel: '修复',
    tag: '保底',
    cost: 15,
    description: '修复我方基地，给逆风局一个阶段内止损工具。',
  },
  {
    id: 'marked_shot',
    name: '标记投球',
    shortLabel: '标投',
    tag: '球种',
    cost: 22,
    description: '下一颗发球带 split+、spawn-mark 和 copy-mark 标签。',
  },
];

export function getPhaseToolDef(id: string): PhaseToolDef | undefined {
  return phaseToolDefs.find((tool) => tool.id === id);
}

export function buildPhaseToolStock(seed: number, phaseIndex: number, count = 3): PhaseToolId[] {
  const stock: PhaseToolId[] = [];
  const start = Math.abs(seed + phaseIndex * 2) % phaseToolDefs.length;
  for (let offset = 0; stock.length < count && offset < phaseToolDefs.length; offset += 1) {
    stock.push(phaseToolDefs[(start + offset) % phaseToolDefs.length].id);
  }
  return stock;
}
