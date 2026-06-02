import type { GameState } from '../types/game';

export type ArcaneRuneSource = 'magic' | 'upgrade' | 'gold';

export interface ArcaneRuneChange {
  status: 'inactive' | 'ignored' | 'granted' | 'capped' | 'spent' | 'empty';
  amount: number;
}

export const ARCANE_RUNE_COLOR = 0xa78bfa;

export function isArcaneSecondaryActive(state: GameState): boolean {
  return state.secondaryRaceId === 'arcane';
}

export function grantRuneFromStandby(state: GameState, source: ArcaneRuneSource): ArcaneRuneChange {
  if (!isArcaneSecondaryActive(state)) return { status: 'inactive', amount: 0 };
  if (source === 'gold') return { status: 'ignored', amount: 0 };

  if (state.arcaneRune.current >= state.arcaneRune.cap) {
    state.arcaneRune.cappedHits += 1;
    state.stats.currentPhase.runeCappedHits += 1;
    state.recentFloatingTexts.push({ label: 'Rune capped', color: ARCANE_RUNE_COLOR });
    return { status: 'capped', amount: 0 };
  }

  state.arcaneRune.current += 1;
  state.arcaneRune.totalGenerated += 1;
  state.stats.currentPhase.runeGenerated += 1;
  state.recentFloatingTexts.push({ label: `Rune +1: ${source === 'magic' ? 'Magic' : 'Upgrade'}`, color: ARCANE_RUNE_COLOR });
  return { status: 'granted', amount: 1 };
}

export function consumeRunesForUnitSpawnProgress(state: GameState): ArcaneRuneChange {
  if (!isArcaneSecondaryActive(state)) return { status: 'inactive', amount: 0 };
  if (state.arcaneRune.current <= 0) return { status: 'empty', amount: 0 };

  const spent = state.arcaneRune.current;
  state.arcaneRune.current = 0;
  state.arcaneRune.totalSpent += spent;
  state.arcaneRune.totalProgressGranted += spent;
  state.stats.currentPhase.runeSpent += spent;
  state.stats.currentPhase.runeProgressGranted += spent;
  recordNoSocketProgress(state, spent);
  state.recentFloatingTexts.push({ label: `Rune spent +${spent}`, color: ARCANE_RUNE_COLOR });
  return { status: 'spent', amount: spent };
}

export function buildRuneHudValue(state: GameState): string | undefined {
  if (!isArcaneSecondaryActive(state)) return undefined;
  return `Rune ${state.arcaneRune.current}/${state.arcaneRune.cap}`;
}

export function buildRunePhaseSummary(state: GameState): string | undefined {
  if (!isArcaneSecondaryActive(state)) return undefined;
  const stats = state.stats.currentPhase;
  return `秘仪 Rune 生成${stats.runeGenerated} 消耗${stats.runeSpent} 进度+${stats.runeProgressGranted} 满溢${stats.runeCappedHits} 空插槽${stats.runeNoSocketTriggers}`;
}

function recordNoSocketProgress(state: GameState, spent: number) {
  state.arcaneRune.socketChargeProgress += spent;
  while (state.arcaneRune.socketChargeProgress >= 3) {
    state.arcaneRune.socketChargeProgress -= 3;
    state.arcaneRune.noSocketTriggers += 1;
    state.stats.currentPhase.runeNoSocketTriggers += 1;
  }
}
