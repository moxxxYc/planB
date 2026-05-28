import type { SlotId, SlotState } from '../types/game';

export type WeightedSlotLayout = {
  id: SlotId | string;
  centerX: number;
  left: number;
  right: number;
  sensorWidth: number;
  plateWidth: number;
};

export function buildWeightedSlotLayouts(
  slots: ReadonlyArray<{ id: SlotId | string; widthWeight: SlotState['widthWeight'] }>,
  zoneX: number,
  zoneW: number,
  sidePadding: number,
  innerGap: number,
): WeightedSlotLayout[] {
  const totalGap = innerGap * Math.max(0, slots.length - 1);
  const usableW = Math.max(1, zoneW - sidePadding * 2 - totalGap);
  const totalWeight = slots.reduce((sum, slot) => sum + Math.max(0.1, slot.widthWeight), 0);
  let cursor = zoneX + sidePadding;

  return slots.map((slot) => {
    const slotW = usableW * (Math.max(0.1, slot.widthWeight) / totalWeight);
    const left = cursor;
    const right = left + slotW;
    cursor = right + innerGap;
    return {
      id: slot.id,
      centerX: left + slotW / 2,
      left,
      right,
      sensorWidth: Math.max(8, slotW),
      plateWidth: Math.max(8, slotW),
    };
  });
}
