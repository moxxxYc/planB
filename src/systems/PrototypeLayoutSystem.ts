export interface PrototypeLayoutInput {
  gameW: number;
  gameH: number;
  topY: number;
  hudH: number;
  panelGap?: number;
}

export interface PrototypeLayout {
  gameW: number;
  gameH: number;
  topY: number;
  topH: number;
  hudH: number;
  hudTop: number;
  battleY: number;
  battleH: number;
  outcomeSlotH: number;
  unitSlotH: number;
  outcomeSlotCenterY: number;
  unitSlotCenterY: number;
}

export interface RightAlignedButtonRowInput {
  rightEdge: number;
  leadingButtonWidth: number;
  leadingGap: number;
  itemCount: number;
  itemWidth: number;
  gap: number;
}

export interface RightAlignedButtonRow {
  leadingX: number;
  itemXs: number[];
}

export interface TopZoneLayoutInput {
  gameW: number;
  sideMargin: number;
  gap: number;
  launchW: number;
  decisionW: number;
  unitW: number;
  unitWidthScale: number;
}

export interface TopZoneLayout {
  launch: { x: number; w: number };
  decision: { x: number; w: number };
  unit: { x: number; w: number };
}

const BASELINE_TOP_H = 196;
const BASELINE_OUTCOME_SLOT_H = 42;
const BASELINE_UNIT_SLOT_H = 48;

export function buildPrototypeLayout(input: PrototypeLayoutInput): PrototypeLayout {
  const panelGap = input.panelGap ?? 8;
  const outcomeSlotH = Math.ceil(BASELINE_OUTCOME_SLOT_H / 3);
  const unitSlotH = Math.ceil(BASELINE_UNIT_SLOT_H / 3);
  const reclaimedSlotHeight = BASELINE_UNIT_SLOT_H - unitSlotH;
  const topH = BASELINE_TOP_H - reclaimedSlotHeight;
  const hudTop = input.gameH - input.hudH;
  const battleY = input.topY + topH + panelGap;
  const battleH = input.gameH - battleY - input.hudH - panelGap;

  return {
    gameW: input.gameW,
    gameH: input.gameH,
    topY: input.topY,
    topH,
    hudH: input.hudH,
    hudTop,
    battleY,
    battleH,
    outcomeSlotH,
    unitSlotH,
    outcomeSlotCenterY: input.topY + topH - outcomeSlotH / 2,
    unitSlotCenterY: input.topY + topH - unitSlotH / 2,
  };
}

export function buildRightAlignedButtonRow(input: RightAlignedButtonRowInput): RightAlignedButtonRow {
  const safeItemCount = Math.max(0, input.itemCount);
  const itemXs = Array.from({ length: safeItemCount }, (_, index) => {
    const totalItemWidth = safeItemCount * input.itemWidth + Math.max(0, safeItemCount - 1) * input.gap;
    const startX = input.rightEdge - totalItemWidth;
    return startX + index * (input.itemWidth + input.gap);
  });
  const firstItemX = itemXs[0] ?? input.rightEdge;
  return {
    leadingX: firstItemX - input.leadingGap - input.leadingButtonWidth,
    itemXs,
  };
}

export function buildTopZoneLayout(input: TopZoneLayoutInput): TopZoneLayout {
  const unitW = input.unitW * input.unitWidthScale;
  const launchW = input.launchW + (input.unitW - unitW);
  const decisionX = input.sideMargin;
  const launchX = decisionX + input.decisionW + input.gap;
  const unitX = launchX + launchW + input.gap;
  return {
    launch: { x: launchX, w: launchW },
    decision: { x: decisionX, w: input.decisionW },
    unit: { x: unitX, w: input.gameW - input.sideMargin - unitX },
  };
}

export const PROTOTYPE_LAYOUT = buildPrototypeLayout({
  gameW: 1280,
  gameH: 720,
  topY: 12,
  hudH: 104,
});
