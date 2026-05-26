import type { BattleUnit, GameState } from '../types/game';

const BASE_PHASE_SURVIVAL_XP = 1;
const XP_PER_VETERANCY_LEVEL = 2;

export function grantEliteVeterancy(state: GameState) {
  for (const unit of state.battle.units) {
    if (!shouldGainVeterancy(unit)) continue;
    const gained = BASE_PHASE_SURVIVAL_XP + state.modifiers.eliteExtraVeterancy;
    unit.veterancyXp += gained;
    state.stats.currentPhase.eliteXpGained += gained;
    state.recentFloatingTexts.push({ label: `精英存活 +${gained} 老兵经验`, color: 0xfacc15 });

    while (unit.veterancyXp >= getXpRequiredForNextVeterancy(unit)) {
      unit.veterancyXp -= getXpRequiredForNextVeterancy(unit);
      unit.veterancyLevel += 1;
      unit.level += 1;
      unit.maxHp = Math.round(unit.maxHp * 1.12);
      unit.hp = Math.min(unit.maxHp, Math.round(unit.hp + unit.maxHp * 0.25));
      unit.damage = Math.round(unit.damage * 1.1);
      state.recentFloatingTexts.push({ label: `精英升级 Lv.${unit.veterancyLevel}`, color: 0xfef3c7 });
    }
  }
}

export function getEliteSummary(state: GameState) {
  const elites = state.battle.units.filter((unit) => unit.side === 'player' && unit.isElite && unit.hp > 0);
  return {
    count: elites.length,
    maxLevel: elites.reduce((max, unit) => Math.max(max, unit.veterancyLevel), 0),
  };
}

function shouldGainVeterancy(unit: BattleUnit): boolean {
  return unit.side === 'player' && unit.isElite && unit.hp > 0;
}

function getXpRequiredForNextVeterancy(unit: BattleUnit): number {
  return XP_PER_VETERANCY_LEVEL + Math.max(0, unit.veterancyLevel - 1);
}
