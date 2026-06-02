import { phaseDefs } from '../data/phases';
import { raceDefs } from '../data/races';
import { secondaryRaceDefs } from '../data/secondaryRaces';
import { unitDefs } from '../data/units';
import { buildRuneHudValue } from './ArcaneSecondarySystem';
import type { GameState } from '../types/game';

export type UiMode = 'play' | 'debug';

export interface UiDrawerState {
  mode: UiMode;
  buildShopOpen: boolean;
}

export interface UiDensityPlan {
  showDebugControls: boolean;
  showBuildShopPanel: boolean;
  showTopChamberSummaries: boolean;
  showTopExplanatoryText: boolean;
  showBuildIdentityOverlay: boolean;
  showTransferTrails: boolean;
  visibleEventFeedRows: number;
}

export interface EventFeedSlot {
  x: number;
  y: number;
  row: number;
  align: 'right';
}

export interface CompactHudBlock {
  label: string;
  value: string;
  detail?: string;
  color?: string;
}

const playPlan: UiDensityPlan = {
  showDebugControls: false,
  showBuildShopPanel: false,
  showTopChamberSummaries: false,
  showTopExplanatoryText: false,
  showBuildIdentityOverlay: false,
  showTransferTrails: false,
  visibleEventFeedRows: 3,
};

const debugPlan: UiDensityPlan = {
  showDebugControls: true,
  showBuildShopPanel: false,
  showTopChamberSummaries: true,
  showTopExplanatoryText: true,
  showBuildIdentityOverlay: true,
  showTransferTrails: true,
  visibleEventFeedRows: 5,
};

export function getUiDensityPlan(mode: UiMode): UiDensityPlan {
  return mode === 'debug' ? debugPlan : playPlan;
}

export function toggleDebugDrawerState(state: UiDrawerState): UiDrawerState {
  const openingDebug = state.mode !== 'debug';
  return {
    mode: openingDebug ? 'debug' : 'play',
    buildShopOpen: openingDebug ? false : state.buildShopOpen,
  };
}

export function toggleBuildShopDrawerState(state: UiDrawerState): UiDrawerState {
  const buildShopOpen = !state.buildShopOpen;
  return {
    mode: buildShopOpen ? 'play' : state.mode,
    buildShopOpen,
  };
}

export function getEventFeedSlot(index: number, visibleRows = playPlan.visibleEventFeedRows): EventFeedSlot {
  const row = positiveModulo(index, visibleRows);
  return {
    x: 1242,
    y: 242 + row * 24,
    row,
    align: 'right',
  };
}

export function buildCompactHudBlocks(state: GameState): CompactHudBlock[] {
  const race = raceDefs[state.currentRaceId];
  const phase = phaseDefs[state.phaseIndex];
  const phaseState = !phase
    ? '已完成'
    : state.phaseActive
      ? '推进中'
      : state.isBuildPause
        ? '构筑暂停'
        : '暂停';
  const playerUnits = state.battle.units.filter((unit) => unit.side === 'player' && unit.hp > 0).length;
  const runeHud = buildRuneHudValue(state);
  const secondaryRace = state.secondaryRaceId ? secondaryRaceDefs[state.secondaryRaceId] : undefined;
  const nextSpawnValue = runeHud
    ? `Lv+${state.pendingSpawnLevelBonus} / ${runeHud}`
    : `Lv+${state.pendingSpawnLevelBonus}`;

  return [
    {
      label: '战况',
      value: `${race.name} ${Math.min(state.phaseIndex + 1, phaseDefs.length)}/${phaseDefs.length}`,
      detail: phaseState,
      color: toCssHex(race.color),
    },
    {
      label: '副族',
      value: secondaryRace?.name ?? '无',
      detail: runeHud,
      color: secondaryRace ? '#c4b5fd' : '#cbd5e1',
    },
    {
      label: '基地',
      value: `我 ${Math.ceil(state.battle.bases.player.hp)}/${state.battle.bases.player.maxHp}`,
      detail: `敌 ${Math.ceil(state.battle.bases.enemy.hp)}/${state.battle.bases.enemy.maxHp}`,
    },
    {
      label: '资源',
      value: `金 ${state.gold} / 研 ${state.researchPoints}`,
    },
    {
      label: '部队',
      value: `场 ${playerUnits} / 预 ${formatReservePreview(state)}`,
    },
    {
      label: '下次出兵',
      value: nextSpawnValue,
    },
    {
      label: '战备',
      value: `金${state.stats.currentPhase.slotTriggers.gold} 法${state.stats.currentPhase.slotTriggers.magic} 出${state.stats.currentPhase.slotTriggers.spawn} 升${state.stats.currentPhase.slotTriggers.upgrade}`,
    },
  ];
}

function formatReservePreview(state: GameState): string {
  const items = state.spawnQueue
    .filter((item) => item.side === 'player' && item.count > 0)
    .slice(0, 2)
    .map((item) => {
      const unit = unitDefs[item.unitId];
      const elite = item.isElite ? '精' : '';
      return `${unit.name}Lv${item.level}${elite}x${item.count}`;
    });
  const overflow = state.spawnQueue.filter((item) => item.side === 'player' && item.count > 0).length - items.length;
  if (items.length === 0) return '空';
  return `${items.join(' ')}${overflow > 0 ? ` +${overflow}` : ''}`;
}

function positiveModulo(value: number, divisor: number): number {
  return ((value % divisor) + divisor) % divisor;
}

function toCssHex(color: number): string {
  return `#${color.toString(16).padStart(6, '0')}`;
}
