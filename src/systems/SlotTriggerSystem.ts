import { raceDefs } from '../data/races';
import { unitDefs } from '../data/units';
import { pickWeighted, randomInt } from '../utils/random';
import { dealMagicDamage } from './BattleSystem';
import { recordGoldHitForBuildings, recordMagicHitForBuildings } from './BuildingSystem';
import {
  recordBaselineNonSpawnDecision,
  recordBaselineResearchHit,
  recordDoctrineNonSpawnDecision,
  resetBaselineNonSpawnStreak,
} from './DoctrineSystem';
import { recordRelicMagicHit } from './RelicSystem';
import { recordSlot } from './StatsSystem';
import type { GameState, SlotId } from '../types/game';

export type SlotTriggerResult = {
  status: 'triggered' | 'disabled';
  slotId: SlotId;
};

export function triggerSlot(state: GameState, slotId: SlotId): SlotTriggerResult {
  if (slotId === 'magic' && !state.settings.magicEnabled) {
    state.recentFloatingTexts.push({ label: '法术已关闭', color: 0x94a3b8 });
    return { status: 'disabled', slotId };
  }

  const slot = state.slots[slotId];
  slot.triggerCount += 1;
  slot.lastTriggeredAtMs = state.battle.elapsedMs;
  recordSlot(state.stats.currentPhase, slotId, state.phaseElapsedMs);

  if (slotId === 'spawn') triggerSpawn(state);
  if (slotId === 'upgrade') triggerUpgrade(state);
  if (slotId === 'gold') triggerGold(state);
  if (slotId === 'magic') triggerMagic(state);
  if (slotId === 'special') triggerSpecial(state);
  return { status: 'triggered', slotId };
}

export function triggerSpawn(state: GameState) {
  resetBaselineNonSpawnStreak(state);
  state.recentFloatingTexts.push({ label: '出兵球进入出兵区', color: 0x4ade80 });
}

function triggerUpgrade(state: GameState) {
  const race = raceDefs[state.currentRaceId];
  const bonus = 1 + (state.currentRaceId === 'mech' ? state.modifiers.mechUpgradeEfficiency + 1 : 0);
  state.pendingSpawnLevelBonus = Math.min(3, state.pendingSpawnLevelBonus + bonus);
  if (state.currentRaceId === 'mech') {
    const pick = pickWeighted(
      state.seed,
      race.unitPool,
      (unitId) => unitDefs[unitId].spawnWeight,
    );
    state.seed = pick.seed;
    state.unitLevels[pick.item] += 1;
  }
  state.upTriggerCountTowardElite += 1;
  if (state.upTriggerCountTowardElite >= 3) {
    state.upTriggerCountTowardElite = 0;
    state.nextSpawnCreatesElite = true;
    state.recentFloatingTexts.push({ label: '下一次高级出兵：精英晋升', color: 0xfacc15 });
  }
  state.recentFloatingTexts.push({ label: `升级 +${bonus}`, color: 0x60a5fa });
  recordBaselineNonSpawnDecision(state);
  recordBaselineResearchHit(state, '升级');
  recordDoctrineNonSpawnDecision(state);
}

function triggerGold(state: GameState) {
  const amount = Math.round((15 + state.phaseIndex * 2) * state.modifiers.goldMultiplier);
  state.gold += amount;
  state.recentFloatingTexts.push({ label: `金币 +${amount}`, color: 0xfacc15 });
  recordBaselineNonSpawnDecision(state);
  recordGoldHitForBuildings(state);
  recordDoctrineNonSpawnDecision(state);
}

function triggerMagic(state: GameState) {
  if (!state.settings.magicEnabled) {
    state.recentFloatingTexts.push({ label: '法术已关闭', color: 0x94a3b8 });
    return;
  }
  dealMagicDamage(state, 26 + state.phaseIndex * 4);
  state.modifiers.pendingSpawnCopies += state.modifiers.magicSpawnCopyBonus;
  state.recentFloatingTexts.push({ label: '电弧法术', color: 0xc084fc });
  recordBaselineNonSpawnDecision(state);
  recordMagicHitForBuildings(state);
  recordRelicMagicHit(state);
  recordBaselineResearchHit(state, '法术');
  recordDoctrineNonSpawnDecision(state);
}

function triggerSpecial(state: GameState) {
  const pick = randomInt(state.seed, 0, 2);
  state.seed = pick.seed;
  if (pick.value === 0) triggerGold(state);
  if (pick.value === 1) triggerUpgrade(state);
  if (pick.value === 2) triggerMagic(state);
  state.recentFloatingTexts.push({ label: '特殊触发', color: 0xfb7185 });
}
