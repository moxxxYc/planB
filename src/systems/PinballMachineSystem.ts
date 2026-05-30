import type { LaunchOutcomeId } from '../types/game';
import { buildWeightedSlotLayouts } from './DecisionSlotLayoutSystem';

export const MAX_SPLITS_PER_ORIGINAL_LAUNCH_BALL = 2;

export const launchOutcomeSlotDefs: ReadonlyArray<{
  id: LaunchOutcomeId;
  label: string;
  color: number;
  widthWeight: number;
}> = [
  { id: 'standby', label: '战备', color: 0x93c5fd, widthWeight: 2 },
  { id: 'split', label: '分裂', color: 0x86efac, widthWeight: 1 },
  { id: 'spawn', label: '发兵', color: 0x4ade80, widthWeight: 2 },
];

export function getSweepingLauncherAngle(elapsedMs: number, cycleMs = 2400): number {
  const safeCycleMs = Math.max(1, cycleMs);
  const phase = ((elapsedMs % safeCycleMs) + safeCycleMs) % safeCycleMs;
  const halfCycle = safeCycleMs / 2;
  const ratio = phase <= halfCycle
    ? phase / halfCycle
    : 1 - (phase - halfCycle) / halfCycle;
  return -90 + ratio * 180;
}

export function getLauncherVelocity(elapsedMs: number, cycleMs = 2400, speed = 3) {
  const radians = getSweepingLauncherAngle(elapsedMs, cycleMs) * Math.PI / 180;
  const vx = Math.sin(radians) * speed;
  const vy = Math.cos(radians) * speed;
  return {
    vx: Math.abs(vx) < 0.000001 ? 0 : vx,
    vy: Math.abs(vy) < 0.000001 ? 0 : vy,
  };
}

export function buildLaunchSplitRelaunchPlan(value: number, extraBalls = 0) {
  return Array.from({ length: 2 + Math.max(0, extraBalls) }, () => ({ stage: 'launch' as const, value }));
}

export function buildLaunchOutcomeSlotLayouts(zoneX: number, zoneW: number, sidePadding = 9, innerGap = 4) {
  return buildWeightedSlotLayouts(launchOutcomeSlotDefs, zoneX, zoneW, sidePadding, innerGap);
}

export function resolveLaunchOutcomeWithSplitLimit(
  outcome: LaunchOutcomeId,
  currentSplitCount: number,
  maxSplits = MAX_SPLITS_PER_ORIGINAL_LAUNCH_BALL,
): { outcome: LaunchOutcomeId; nextSplitCount: number; limitReached: boolean } {
  const safeCount = Math.max(0, currentSplitCount);
  if (outcome !== 'split') {
    return { outcome, nextSplitCount: safeCount, limitReached: false };
  }
  if (safeCount >= maxSplits) {
    return { outcome: 'spawn', nextSplitCount: safeCount, limitReached: true };
  }
  return { outcome: 'split', nextSplitCount: safeCount + 1, limitReached: false };
}

export function getControlledGateBounceVelocity(velocity: { vx: number; vy: number }) {
  return {
    vx: clamp(velocity.vx, -4.8, 4.8),
    vy: -5.2,
  };
}

function clamp(value: number, min: number, max: number) {
  return Math.max(min, Math.min(max, value));
}
