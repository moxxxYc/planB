import type { BattleUnit, GameState } from '../types/game';
import { getBattleFrontlineRatio } from './BattleSystem';

export type BattlePoint = { x: number; y: number };

export type BattleProjectionInput = {
  worldX: number;
  laneOffset: number;
  cameraCenterX: number;
  playerBaseX: number;
  enemyBaseX: number;
  screenStart: BattlePoint;
  screenEnd: BattlePoint;
  viewportWorldWidth: number;
};

export type BattleProjection = {
  x: number;
  y: number;
  depth: number;
  visibleRatio: number;
};

export type HeatBand = {
  index: number;
  ratioStart: number;
  ratioEnd: number;
  player: number;
  enemy: number;
};

export function clampBattleCameraCenter(centerX: number, playerBaseX: number, enemyBaseX: number, viewportWorldWidth: number): number {
  const half = viewportWorldWidth / 2;
  const min = playerBaseX + half;
  const max = enemyBaseX - half;
  if (max <= min) return (playerBaseX + enemyBaseX) / 2;
  return Math.max(min, Math.min(max, centerX));
}

export function getBattleCameraViewport(centerX: number, playerBaseX: number, enemyBaseX: number, viewportWorldWidth: number) {
  const safeCenter = clampBattleCameraCenter(centerX, playerBaseX, enemyBaseX, viewportWorldWidth);
  return {
    startX: safeCenter - viewportWorldWidth / 2,
    endX: safeCenter + viewportWorldWidth / 2,
    width: viewportWorldWidth,
  };
}

export function projectBattlePoint(input: BattleProjectionInput): BattleProjection {
  const visibleRatio = (input.worldX - (input.cameraCenterX - input.viewportWorldWidth / 2)) / input.viewportWorldWidth;
  const axisX = input.screenStart.x + (input.screenEnd.x - input.screenStart.x) * visibleRatio;
  const axisY = input.screenStart.y + (input.screenEnd.y - input.screenStart.y) * visibleRatio;
  const tangentX = input.screenEnd.x - input.screenStart.x;
  const tangentY = input.screenEnd.y - input.screenStart.y;
  const len = Math.max(1, Math.sqrt(tangentX * tangentX + tangentY * tangentY));
  const normalX = -tangentY / len;
  const normalY = tangentX / len;
  const worldRatio = (input.worldX - input.playerBaseX) / Math.max(1, input.enemyBaseX - input.playerBaseX);
  const spread = 0.82 + Math.sin(Math.max(0, Math.min(1, worldRatio)) * Math.PI) * 0.62;
  const x = axisX + normalX * input.laneOffset * spread;
  const y = axisY + normalY * input.laneOffset * spread * 0.94;
  return { x, y, depth: y, visibleRatio };
}

export function buildBattleHeatBands(units: BattleUnit[], playerBaseX: number, enemyBaseX: number, bandCount: number): HeatBand[] {
  const bands = Array.from({ length: bandCount }, (_, index) => ({
    index,
    ratioStart: index / bandCount,
    ratioEnd: (index + 1) / bandCount,
    player: 0,
    enemy: 0,
  }));
  for (const unit of units) {
    if (unit.hp <= 0) continue;
    const ratio = Math.max(0, Math.min(0.999, (unit.x - playerBaseX) / Math.max(1, enemyBaseX - playerBaseX)));
    const index = Math.min(bandCount - 1, Math.floor(ratio * bandCount));
    bands[index][unit.side] += unit.isElite ? 2 : 1;
  }
  return bands;
}

export function getBattleHotspotRatio(state: GameState): number {
  return getBattleFrontlineRatio(state);
}
