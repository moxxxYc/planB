import type { PhaseStats, SlotId } from '../types/game';

export function createPhaseStats(): PhaseStats {
  return {
    slotTriggers: {
      spawn: 0,
      upgrade: 0,
      gold: 0,
      magic: 0,
      special: 0,
    },
    unitsSpawned: 0,
    unitsQueued: 0,
    damageDealt: 0,
    kills: 0,
    eliteXpGained: 0,
    enemyBaseDamage: 0,
    playerBaseDamage: 0,
  };
}

export function recordSlot(stats: PhaseStats, slotId: SlotId) {
  stats.slotTriggers[slotId] += 1;
}
