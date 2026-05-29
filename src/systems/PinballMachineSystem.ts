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

export function getControlledGateBounceVelocity(velocity: { vx: number; vy: number }) {
  return {
    vx: clamp(velocity.vx, -4.8, 4.8),
    vy: -5.2,
  };
}

function clamp(value: number, min: number, max: number) {
  return Math.max(min, Math.min(max, value));
}
