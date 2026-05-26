import type { SlotId, SlotState } from '../types/game';

export const slotDefs: Array<Pick<SlotState, 'id' | 'label' | 'color'>> = [
  { id: 'spawn', label: '出兵', color: 0x4ade80 },
  { id: 'gold', label: '金币', color: 0xfacc15 },
  { id: 'magic', label: '法术', color: 0xc084fc },
  { id: 'upgrade', label: '升级', color: 0x60a5fa },
  { id: 'special', label: '特殊', color: 0xfb7185 },
];

export function createSlotState(): Record<SlotId, SlotState> {
  return Object.fromEntries(
    slotDefs.map((slot) => [
      slot.id,
      {
        ...slot,
        widthWeight: 1,
        triggerCount: 0,
        level: 1,
        lastTriggeredAtMs: -10000,
      },
    ]),
  ) as Record<SlotId, SlotState>;
}
