import { rewardDefs } from '../data/rewards';
import { randomInt } from '../utils/random';
import type { GameState, RewardDef } from '../types/game';

export function buildRewardChoices(state: GameState): RewardDef[] {
  const available = [...rewardDefs];
  const choices: RewardDef[] = [];
  while (choices.length < 3 && available.length > 0) {
    const pick = randomInt(state.seed, 0, available.length - 1);
    state.seed = pick.seed;
    choices.push(available.splice(pick.value, 1)[0]);
  }
  return choices;
}

export function applyReward(state: GameState, rewardId: string) {
  if (rewardId === 'wide_spawn') state.slots.spawn.widthWeight *= 1.2;
  if (rewardId === 'spawn_slot_widen') state.slots.spawn.widthWeight *= 1.1;
  if (rewardId === 'reinforcement_drums') state.modifiers.queueReleaseSpeedBonus += 0.25;
  if (rewardId === 'mass_reserves') state.modifiers.spawnExtraCount += 1;
  if (rewardId === 'elite_training') state.modifiers.eliteExtraVeterancy += 1;
  if (rewardId === 'elite_promotion') state.nextSpawnCreatesElite = true;
  if (rewardId === 'extra_ball_interval') state.modifiers.ballCount += 1;
  if (rewardId === 'basic_unit_drill') {
    state.modifiers.basicUnitHpBonus += 0.1;
    state.modifiers.basicUnitDamageBonus += 0.1;
  }
  if (rewardId === 'double_drop') state.modifiers.ballCount += 1;
  if (rewardId === 'training_order') state.modifiers.nextPhaseSpawnLevelBonus += 1;
  if (rewardId === 'elite_protocol') state.pendingSpawnLevelBonus = Math.min(3, state.pendingSpawnLevelBonus + 1);
  if (rewardId === 'wide_gold') state.slots.gold.widthWeight *= 1.2;
  if (rewardId === 'war_savings') {
    state.modifiers.goldMultiplier *= 1.5;
    state.slots.spawn.widthWeight *= 0.9;
  }
  if (rewardId === 'magic_overload') state.modifiers.magicDamageMultiplier *= 1.5;
  if (rewardId === 'spell_copy') state.modifiers.magicSpawnCopyBonus += 1;
  if (rewardId === 'mech_calibration') state.modifiers.mechUpgradeEfficiency += 1;
  if (rewardId === 'hive_hatching') state.modifiers.hiveExtraGrubCount += 1;
}
