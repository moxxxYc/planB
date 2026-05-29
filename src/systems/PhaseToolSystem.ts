import { phaseDefs } from '../data/phases';
import { activePacingPreset } from '../data/pacing';
import { buildPhaseToolStock, getPhaseToolDef } from '../data/phaseTools';
import { raceDefs } from '../data/races';
import { setBallTags } from './RelicSystem';
import { addUnitSlotProgress } from './UnitSpawnProgressSystem';
import {
  recordNonSpawnRecovery,
  recordPhaseToolPurchase,
  recordSpawnMarksCreated,
} from './StatsSystem';
import type { GameState, PhaseToolId } from '../types/game';

export type PhaseToolPurchaseResult =
  | { status: 'purchased'; id: PhaseToolId }
  | { status: 'window_closed'; id: PhaseToolId; opensAtMs: number }
  | { status: 'window_used'; id: PhaseToolId }
  | { status: 'unknown_tool'; id: string }
  | { status: 'not_in_stock'; id: string }
  | { status: 'already_used'; id: PhaseToolId }
  | { status: 'insufficient_gold'; id: PhaseToolId; cost: number };

export interface PhaseToolWindowState {
  isOpen: boolean;
  opensAtMs: number;
  elapsedMs: number;
  progressRatio: number;
}

export function refreshPhaseToolStock(state: GameState) {
  state.phaseToolStock = buildPhaseToolStock(state.seed, state.phaseIndex);
  state.usedPhaseTools = [];
}

export function getPhaseToolWindowState(state: GameState): PhaseToolWindowState {
  const durationMs = phaseDefs[state.phaseIndex]?.durationMs ?? activePacingPreset.phaseDurationsMs.at(-1) ?? 45000;
  const opensAtMs = durationMs * activePacingPreset.phaseToolWindowOpenRatio;
  const elapsedMs = Math.max(0, state.phaseElapsedMs);
  return {
    isOpen: state.phaseActive && !state.isBuildPause && elapsedMs >= opensAtMs,
    opensAtMs,
    elapsedMs,
    progressRatio: durationMs <= 0 ? 1 : Math.min(1, elapsedMs / durationMs),
  };
}

export function buyPhaseTool(state: GameState, id: PhaseToolId): PhaseToolPurchaseResult {
  const def = getPhaseToolDef(id);
  if (!def) return { status: 'unknown_tool', id };
  const window = getPhaseToolWindowState(state);
  if (!window.isOpen) return { status: 'window_closed', id, opensAtMs: window.opensAtMs };
  if (state.usedPhaseTools.includes(id)) return { status: 'already_used', id };
  if (state.stats.currentPhase.phaseToolsPurchased > 0) return { status: 'window_used', id };
  if (!state.phaseToolStock.includes(id)) return { status: 'not_in_stock', id };
  if (state.gold < def.cost) return { status: 'insufficient_gold', id, cost: def.cost };

  state.gold -= def.cost;
  state.phaseToolStock = state.phaseToolStock.filter((toolId) => toolId !== id);
  state.usedPhaseTools.push(id);
  recordPhaseToolPurchase(state.stats.currentPhase);
  applyPhaseTool(state, id);
  return { status: 'purchased', id };
}

function applyPhaseTool(state: GameState, id: PhaseToolId) {
  if (id === 'spawn_beacon') {
    state.pendingSpawnMarks += 2;
    recordSpawnMarksCreated(state.stats.currentPhase, 2);
    recordNonSpawnRecovery(state.stats.currentPhase, 'phase_tool_spawn_beacon', state.phaseElapsedMs);
    state.recentFloatingTexts.push({ label: '出兵信标：出兵标记 +2', color: 0x4ade80 });
    return;
  }

  if (id === 'hot_slot_calibrator') {
    const firstSlot = raceDefs[state.currentRaceId].unitSlots[0];
    addUnitSlotProgress(state, firstSlot.unitId, 2);
    recordNonSpawnRecovery(state.stats.currentPhase, 'phase_tool_hot_slot', state.phaseElapsedMs);
    state.recentFloatingTexts.push({ label: `热槽校准：${firstSlot.label} +2`, color: 0x86efac });
    return;
  }

  if (id === 'queue_surge') {
    state.modifiers.queueReleaseSpeedBonus += 0.35;
    recordNonSpawnRecovery(state.stats.currentPhase, 'phase_tool_queue_surge', state.phaseElapsedMs);
    state.recentFloatingTexts.push({ label: '队列脉冲：释放速度 +35%', color: 0x93c5fd });
    return;
  }

  if (id === 'marked_shot') {
    setBallTags(state, ['split+', 'spawn-mark', 'copy-mark']);
    recordNonSpawnRecovery(state.stats.currentPhase, 'phase_tool_marked_shot', state.phaseElapsedMs);
    state.recentFloatingTexts.push({ label: '标记投球：下一球带构筑标签', color: 0xc084fc });
    return;
  }

  const base = state.battle.bases.player;
  base.hp = Math.min(base.maxHp, base.hp + 80);
  recordNonSpawnRecovery(state.stats.currentPhase, 'phase_tool_repair', state.phaseElapsedMs);
  state.recentFloatingTexts.push({ label: '战地修复：基地 +80', color: 0xfacc15 });
}
