import { doctrineTechDefs } from '../data/doctrineTechs';
import { unitDefs } from '../data/units';
import {
  recordNonSpawnRecovery,
  recordSpawnMarksCreated,
} from './StatsSystem';
import type { DoctrineTechDef, GameState } from '../types/game';

const RESEARCH_RETURN_THRESHOLD = 4;
const NON_SPAWN_STREAK_THRESHOLD = 3;

export type DoctrineUnlockResult =
  | { status: 'unlocked'; id: string }
  | { status: 'already_unlocked'; id: string }
  | { status: 'unknown_tech'; id: string };

export type DoctrineResearchPurchaseResult =
  | { status: 'unlocked'; id: string; cost: number }
  | { status: 'already_unlocked'; id: string }
  | { status: 'insufficient_research'; id: string; cost: number; researchPoints: number }
  | { status: 'unknown_tech'; id: string };

export function getDoctrineTechDef(id: string): DoctrineTechDef | undefined {
  return doctrineTechDefs.find((tech) => tech.id === id);
}

export function getAvailableDoctrineTechRewardDefs(state: GameState): DoctrineTechDef[] {
  return doctrineTechDefs.filter((tech) => !hasDoctrineTech(state, tech.id));
}

export function isDoctrineTechReward(id: string): boolean {
  return Boolean(getDoctrineTechDef(id));
}

export function hasDoctrineTech(state: GameState, id: string): boolean {
  return state.doctrineTechs.some((tech) => tech.id === id);
}

export function unlockDoctrineTech(state: GameState, id: string): DoctrineUnlockResult {
  const tech = getDoctrineTechDef(id);
  if (!tech) return { status: 'unknown_tech', id };
  if (hasDoctrineTech(state, id)) return { status: 'already_unlocked', id };

  state.doctrineTechs.push({ id });
  if (id === 'launch_extra_launcher') state.modifiers.ballCount += 1;
  if (id === 'decision_slot_calibration') state.slots.spawn.widthWeight *= 1.15;
  if (id === 'unit_mobilization_links') state.modifiers.queueReleaseSpeedBonus += 0.2;
  state.recentFloatingTexts.push({ label: `${tech.name} 已研究`, color: 0x93c5fd });
  return { status: 'unlocked', id };
}

export function buyDoctrineTechWithResearch(state: GameState, id: string): DoctrineResearchPurchaseResult {
  const tech = getDoctrineTechDef(id);
  if (!tech) return { status: 'unknown_tech', id };
  if (hasDoctrineTech(state, id)) return { status: 'already_unlocked', id };
  if (state.researchPoints < tech.researchCost) {
    return {
      status: 'insufficient_research',
      id,
      cost: tech.researchCost,
      researchPoints: state.researchPoints,
    };
  }

  state.researchPoints -= tech.researchCost;
  unlockDoctrineTech(state, id);
  return { status: 'unlocked', id, cost: tech.researchCost };
}

export function recordDoctrineLaunchMiss(state: GameState): number {
  if (!hasDoctrineTech(state, 'launch_loss_research')) return 0;

  state.doctrineEvents.launchLosses += 1;
  state.researchPoints += 1;
  if (state.doctrineEvents.launchLosses < 2) return 0;

  state.doctrineEvents.launchLosses = 0;
  state.pendingSpawnMarks += 1;
  recordSpawnMarksCreated(state.stats.currentPhase, 1);
  recordNonSpawnRecovery(state.stats.currentPhase, 'doctrine_launch_loss', state.phaseElapsedMs);
  state.recentFloatingTexts.push({ label: '损失回收学：出兵标记 +1', color: 0x93c5fd });
  return 1;
}

export function recordDoctrineNonSpawnDecision(state: GameState): number {
  if (!hasDoctrineTech(state, 'decision_conversion_matrix')) return 0;

  state.doctrineEvents.conversionHits += 1;
  state.researchPoints += 1;
  if (state.doctrineEvents.conversionHits < 3) return 0;

  state.doctrineEvents.conversionHits = 0;
  state.pendingSpawnMarks += 1;
  recordSpawnMarksCreated(state.stats.currentPhase, 1);
  recordNonSpawnRecovery(state.stats.currentPhase, 'doctrine_conversion', state.phaseElapsedMs);
  state.recentFloatingTexts.push({ label: '转译矩阵：出兵标记 +1', color: 0x93c5fd });
  return 1;
}

export function recordBaselineResearchHit(state: GameState, sourceLabel: string): number {
  state.researchPoints += 1;
  state.doctrineEvents.researchReturnProgress += 1;
  state.recentFloatingTexts.push({ label: `${sourceLabel}：研究 +1`, color: 0x93c5fd });

  if (state.doctrineEvents.researchReturnProgress < RESEARCH_RETURN_THRESHOLD) return 0;

  state.doctrineEvents.researchReturnProgress = 0;
  state.pendingSpawnMarks += 1;
  recordSpawnMarksCreated(state.stats.currentPhase, 1);
  recordNonSpawnRecovery(state.stats.currentPhase, 'research_return', state.phaseElapsedMs);
  state.recentFloatingTexts.push({ label: '研究回流：出兵标记 +1', color: 0x93c5fd });
  return 1;
}

export function recordBaselineNonSpawnDecision(state: GameState): number {
  state.doctrineEvents.nonSpawnStreak += 1;
  if (state.doctrineEvents.nonSpawnStreak < NON_SPAWN_STREAK_THRESHOLD) return 0;

  state.doctrineEvents.nonSpawnStreak = 0;
  state.pendingSpawnMarks += 1;
  recordSpawnMarksCreated(state.stats.currentPhase, 1);
  recordNonSpawnRecovery(state.stats.currentPhase, 'baseline_fallback', state.phaseElapsedMs);
  state.recentFloatingTexts.push({ label: '非出兵保底：出兵标记 +1', color: 0x93c5fd });
  return 1;
}

export function resetBaselineNonSpawnStreak(state: GameState) {
  state.doctrineEvents.nonSpawnStreak = 0;
}

export function getDoctrineUpgradeCarry(state: GameState, unitId: string, consumedLevelBonus: number): number {
  if (!hasDoctrineTech(state, 'unit_elite_escort')) return 0;
  if (consumedLevelBonus <= 0) return 0;
  if (unitDefs[unitId]?.costTier !== 1) return 0;
  return 1;
}

export function getDoctrineSummary(state: GameState): string {
  if (state.doctrineTechs.length === 0) return '科技: 无';
  return state.doctrineTechs
    .map((tech) => getDoctrineTechDef(tech.id)?.name ?? tech.id)
    .join(' / ');
}
