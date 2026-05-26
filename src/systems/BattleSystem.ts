import { unitDefs } from '../data/units';
import { randomInt } from '../utils/random';
import type { BattleUnit, GameState, Side, UnitLifetime } from '../types/game';

const LANE_OFFSETS = {
  front: 18,
  mid: 0,
  back: -28,
};
const BASE_EXIT_OFFSET = 72;

export function spawnBattleUnit(
  state: GameState,
  side: Side,
  defId: string,
  level = 1,
  burst = false,
  options: { lifetime?: UnitLifetime; isElite?: boolean; tags?: string[] } = {},
): BattleUnit {
  const def = unitDefs[defId];
  const jitter = randomInt(state.seed, -12, 12);
  state.seed = jitter.seed;
  const base = state.battle.bases[side];
  const spawnX = side === 'player' ? base.x + BASE_EXIT_OFFSET + jitter.value * 0.1 : base.x - BASE_EXIT_OFFSET + jitter.value * 0.1;
  const tags = options.tags ?? [];
  const isElite = options.isElite ?? tags.includes('elite') ?? false;
  const lifetime = options.lifetime ?? (isElite ? 'elite' : 'standard');
  const isBasicPlayer = side === 'player' && def.costTier === 1 && lifetime === 'standard';
  const hpBonus = isBasicPlayer ? state.modifiers.basicUnitHpBonus : 0;
  const damageBonus = isBasicPlayer ? state.modifiers.basicUnitDamageBonus : 0;
  const maxHp = Math.round(def.maxHp * (1 + (level - 1) * 0.28) * (1 + hpBonus));
  const damage = Math.round((def.damage + (level - 1) * 3) * (1 + damageBonus));
  const unit: BattleUnit = {
    id: `${side}-${state.nextUnitId++}`,
    defId,
    side,
    hp: maxHp,
    maxHp,
    damage,
    x: spawnX,
    laneOffset: LANE_OFFSETS[def.lane] + jitter.value,
    attackTimerMs: 0,
    level,
    lifetime,
    isElite,
    veterancyXp: 0,
    veterancyLevel: isElite ? 1 : 0,
    phaseSpawned: state.phaseIndex,
    tags,
    damageDone: 0,
    kills: 0,
    burstUntilMs: burst ? state.battle.elapsedMs + 5000 : 0,
  };
  state.battle.units.push(unit);
  if (side === 'player') {
    state.stats.currentPhase.unitsSpawned += 1;
  }
  return unit;
}

export function dealMagicDamage(state: GameState, baseDamage: number) {
  const enemies = state.battle.units
    .filter((unit) => unit.side === 'enemy')
    .sort((a, b) => a.x - b.x)
    .slice(0, 3);

  for (const enemy of enemies) {
    const damage = Math.round(baseDamage * state.modifiers.magicDamageMultiplier);
    enemy.hp -= damage;
    state.stats.currentPhase.damageDealt += damage;
  }
  removeDeadUnits(state);
}

export function updateBattle(state: GameState, deltaMs: number) {
  state.battle.elapsedMs += deltaMs;
  state.phaseElapsedMs += deltaMs;
  const units = [...state.battle.units];

  for (const unit of units) {
    if (unit.hp <= 0) continue;
    const def = unitDefs[unit.defId];
    unit.attackTimerMs = Math.max(0, unit.attackTimerMs - deltaMs);
    const enemySide: Side = unit.side === 'player' ? 'enemy' : 'player';
    const target = findTarget(state, unit, enemySide);
    const enemyBase = state.battle.bases[enemySide];
    const baseDistance = Math.abs(enemyBase.x - unit.x);

    if (target && Math.abs(target.x - unit.x) <= def.attackRange) {
      attackUnit(state, unit, target);
      continue;
    }

    if (!target && baseDistance <= def.attackRange + 28) {
      attackBase(state, unit, enemyBase.side);
      continue;
    }

    if (target && Math.abs(target.x - unit.x) <= def.attackRange + 6) {
      attackUnit(state, unit, target);
      continue;
    }

    const direction = unit.side === 'player' ? 1 : -1;
    unit.x += direction * def.moveSpeed * (deltaMs / 1000);
  }

  removeDeadUnits(state);
}

function findTarget(state: GameState, unit: BattleUnit, enemySide: Side): BattleUnit | undefined {
  const def = unitDefs[unit.defId];
  const rangePad = def.role === 'ranged' ? 20 : 0;
  return state.battle.units
    .filter((candidate) => candidate.side === enemySide && candidate.hp > 0)
    .sort((a, b) => Math.abs(a.x - unit.x) - Math.abs(b.x - unit.x))
    .find((candidate) => Math.abs(candidate.x - unit.x) <= def.attackRange + rangePad)
    ?? state.battle.units
      .filter((candidate) => candidate.side === enemySide && candidate.hp > 0)
      .sort((a, b) => Math.abs(a.x - unit.x) - Math.abs(b.x - unit.x))[0];
}

function attackUnit(state: GameState, attacker: BattleUnit, target: BattleUnit) {
  const def = unitDefs[attacker.defId];
  if (attacker.attackTimerMs > 0) return;
  const targetDef = unitDefs[target.defId];
  const burstBonus = attacker.burstUntilMs > state.battle.elapsedMs ? 1.35 : 1;
  const damage = Math.max(1, Math.round(attacker.damage * burstBonus - targetDef.armor));
  target.hp -= damage;
  attacker.damageDone += damage;
  attacker.attackTimerMs = def.attackCooldownMs;
  if (attacker.side === 'player') {
    state.stats.currentPhase.damageDealt += damage;
  }
  if (target.hp <= 0) {
    attacker.kills += 1;
    if (attacker.side === 'player') {
      state.stats.currentPhase.kills += 1;
    }
  }
}

function attackBase(state: GameState, attacker: BattleUnit, side: Side) {
  const def = unitDefs[attacker.defId];
  if (attacker.attackTimerMs > 0) return;
  const burstBonus = attacker.burstUntilMs > state.battle.elapsedMs ? 1.35 : 1;
  const damage = Math.max(1, Math.round(attacker.damage * burstBonus));
  state.battle.bases[side].hp = Math.max(0, state.battle.bases[side].hp - damage);
  attacker.damageDone += damage;
  attacker.attackTimerMs = def.attackCooldownMs;
  if (attacker.side === 'player') {
    state.stats.currentPhase.enemyBaseDamage += damage;
    state.stats.currentPhase.damageDealt += damage;
  } else {
    state.stats.currentPhase.playerBaseDamage += damage;
  }
}

function removeDeadUnits(state: GameState) {
  state.battle.units = state.battle.units.filter((unit) => unit.hp > 0);
}
