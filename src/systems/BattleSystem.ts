import { unitDefs } from '../data/units';
import { randomInt } from '../utils/random';
import type { BattleLaneId, BattleLaneWeights, BattleUnit, GameState, Side, UnitLifetime } from '../types/game';

const BATTLE_LANE_OFFSETS: Record<BattleLaneId, number> = {
  top: -74,
  middle: 0,
  bottom: 74,
};
const BASE_EXIT_OFFSET = 72;

export function pickBattleLane(seed: number, weights: BattleLaneWeights): { lane: BattleLaneId; seed: number } {
  const total = Math.max(1, weights.top + weights.middle + weights.bottom);
  const pick = randomInt(seed, 1, total);
  if (pick.value <= weights.top) return { lane: 'top', seed: pick.seed };
  if (pick.value <= weights.top + weights.middle) return { lane: 'middle', seed: pick.seed };
  return { lane: 'bottom', seed: pick.seed };
}

export function getBattleLaneOffset(lane: BattleLaneId, jitter: number): number {
  return BATTLE_LANE_OFFSETS[lane] + jitter;
}

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
  const lanePick = pickBattleLane(jitter.seed, def.laneWeights);
  state.seed = lanePick.seed;
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
    battleLane: lanePick.lane,
    laneOffset: getBattleLaneOffset(lanePick.lane, jitter.value),
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
    spawnedAtMs: state.battle.elapsedMs,
    lastAttackAtMs: -9999,
    lastHitAtMs: -9999,
  };
  state.battle.units.push(unit);
  addEffect(state, 'spawn', side, unit.id, unit.x, unit.laneOffset, 420);
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
  cleanupFeedback(state);
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
  attacker.lastAttackAtMs = state.battle.elapsedMs;
  target.lastHitAtMs = state.battle.elapsedMs;
  addProjectile(state, attacker, target);
  addEffect(state, 'hit', attacker.side, target.id, target.x, target.laneOffset, 260);
  if (attacker.side === 'player') {
    state.stats.currentPhase.damageDealt += damage;
  }
  if (target.hp <= 0) {
    attacker.kills += 1;
    addEffect(state, 'death', target.side, target.id, target.x, target.laneOffset, 520);
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
  attacker.lastAttackAtMs = state.battle.elapsedMs;
  state.battle.bases[side].lastHitAtMs = state.battle.elapsedMs;
  addBaseProjectile(state, attacker, side);
  addEffect(state, 'base_hit', attacker.side, undefined, state.battle.bases[side].x, state.battle.bases[side].laneOffset, 300, side);
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

export function getBattleFrontlineRatio(state: GameState): number {
  const playerBaseX = state.battle.bases.player.x;
  const enemyBaseX = state.battle.bases.enemy.x;
  const span = Math.max(1, enemyBaseX - playerBaseX);
  const playerUnits = state.battle.units.filter((unit) => unit.side === 'player' && unit.hp > 0);
  const enemyUnits = state.battle.units.filter((unit) => unit.side === 'enemy' && unit.hp > 0);
  const playerFront = playerUnits.length > 0
    ? Math.max(...playerUnits.map((unit) => unit.x))
    : playerBaseX;
  const enemyFront = enemyUnits.length > 0
    ? Math.min(...enemyUnits.map((unit) => unit.x))
    : enemyBaseX;
  const frontlineX = playerUnits.length > 0 && enemyUnits.length > 0
    ? (playerFront + enemyFront) / 2
    : playerUnits.length > 0
      ? playerFront
      : enemyUnits.length > 0
        ? enemyFront
        : (playerBaseX + enemyBaseX) / 2;

  return Math.max(0, Math.min(1, (frontlineX - playerBaseX) / span));
}

function addProjectile(state: GameState, attacker: BattleUnit, target: BattleUnit) {
  const def = unitDefs[attacker.defId];
  if (!['ranged', 'caster', 'siege'].includes(def.role)) return;
  state.battle.projectiles.push({
    id: `projectile-${state.battle.nextFeedbackId++}`,
    side: attacker.side,
    fromUnitId: attacker.id,
    toUnitId: target.id,
    fromX: attacker.x,
    toX: target.x,
    fromLaneOffset: attacker.laneOffset,
    toLaneOffset: target.laneOffset,
    createdAtMs: state.battle.elapsedMs,
    impactAtMs: state.battle.elapsedMs + 260,
    color: attacker.side === 'player' ? 0x60a5fa : 0xfb923c,
  });
}

function addBaseProjectile(state: GameState, attacker: BattleUnit, side: Side) {
  const def = unitDefs[attacker.defId];
  if (!['ranged', 'caster', 'siege'].includes(def.role)) return;
  const base = state.battle.bases[side];
  state.battle.projectiles.push({
    id: `projectile-${state.battle.nextFeedbackId++}`,
    side: attacker.side,
    fromUnitId: attacker.id,
    toBaseSide: side,
    fromX: attacker.x,
    toX: base.x,
    fromLaneOffset: attacker.laneOffset,
    toLaneOffset: base.laneOffset,
    createdAtMs: state.battle.elapsedMs,
    impactAtMs: state.battle.elapsedMs + 300,
    color: attacker.side === 'player' ? 0x60a5fa : 0xfb923c,
  });
}

function addEffect(
  state: GameState,
  type: 'spawn' | 'hit' | 'death' | 'base_hit',
  side: Side,
  unitId: string | undefined,
  x: number,
  laneOffset: number,
  durationMs: number,
  baseSide?: Side,
) {
  state.battle.transientEffects.push({
    id: `effect-${state.battle.nextFeedbackId++}`,
    type,
    side,
    unitId,
    baseSide,
    x,
    laneOffset,
    createdAtMs: state.battle.elapsedMs,
    expiresAtMs: state.battle.elapsedMs + durationMs,
  });
}

function cleanupFeedback(state: GameState) {
  state.battle.projectiles = state.battle.projectiles.filter((projectile) => projectile.impactAtMs + 220 > state.battle.elapsedMs);
  state.battle.transientEffects = state.battle.transientEffects.filter((effect) => effect.expiresAtMs > state.battle.elapsedMs);
}
