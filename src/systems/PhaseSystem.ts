import { phaseDefs } from '../data/phases';
import { spawnBattleUnit } from './BattleSystem';
import { grantEliteVeterancy } from './EliteSystem';
import { applyReward } from './RewardSystem';
import { createPhaseStats } from './StatsSystem';
import type { GameState, PhaseCompleteReason } from '../types/game';

export function startPhase(state: GameState) {
  const phase = phaseDefs[state.phaseIndex];
  if (!phase) return;

  state.phaseActive = true;
  state.isBuildPause = false;
  state.phaseElapsedMs = 0;
  state.battle.bases.enemy.maxHp = phase.enemyObjectiveHp;
  state.battle.bases.enemy.hp = phase.enemyObjectiveHp;
  state.recentFloatingTexts.push({ label: `${phase.name} 开始`, color: 0xf8fafc });
}

export function updatePhaseEnemySpawns(state: GameState, previousPhaseElapsedMs: number) {
  const phase = phaseDefs[state.phaseIndex];
  if (!phase || !state.phaseActive || state.isBuildPause) return;
  for (const spawn of phase.enemySpawns) {
    if (spawn.atMs > previousPhaseElapsedMs && spawn.atMs <= state.phaseElapsedMs) {
      for (let count = 0; count < spawn.count; count += 1) {
        spawnBattleUnit(state, 'enemy', spawn.unitId, 1 + Math.floor(state.phaseIndex / 2));
      }
    }
  }
}

export function shouldCompletePhase(state: GameState): boolean {
  const phase = phaseDefs[state.phaseIndex];
  if (!phase) return true;
  if (state.battle.bases.player.hp <= 0) return true;
  if (phase.objectiveType === 'survive_pressure') return state.phaseElapsedMs >= phase.durationMs;
  return state.battle.bases.enemy.hp <= 0 || state.phaseElapsedMs >= phase.durationMs;
}

export function completePhase(state: GameState, reason: PhaseCompleteReason) {
  state.phaseActive = false;
  state.isBuildPause = true;
  cleanupForPhaseTransition(state);
  grantEliteVeterancy(state);
  state.stats.lastPhase = state.stats.currentPhase;
  state.recentFloatingTexts.push({
    label: reason === 'timer' ? '阶段完成：压力已扛住' : '阶段完成：战线继续推进',
    color: 0xf8fafc,
  });
}

export function resumeNextPhase(state: GameState, rewardId?: string) {
  if (rewardId) {
    applyReward(state, rewardId);
    state.selectedRewards.push(rewardId);
  }
  state.phaseIndex += 1;
  state.stats.currentPhase = createPhaseStats();
  startPhase(state);
}

export function isFinalPhaseComplete(state: GameState) {
  return state.phaseIndex >= phaseDefs.length - 1;
}

function cleanupForPhaseTransition(state: GameState) {
  state.battle.projectiles = [];
  state.battle.transientEffects = [];
  state.battle.units = state.battle.units.filter((unit) => {
    if (unit.hp <= 0) return false;
    return unit.lifetime !== 'temporary' && unit.lifetime !== 'summon';
  });
}
