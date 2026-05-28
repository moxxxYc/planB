import { raceDefs } from '../data/races';
import { unitDefs } from '../data/units';
import { randomInt } from '../utils/random';
import type { BattleLaneId, BattleLaneWeights, BattleUnit, GameState, Side, UnitLifetime } from '../types/game';

const BATTLE_LANE_OFFSETS: Record<BattleLaneId, number> = {
  top: -74,
  middle: 0,
  bottom: 74,
};
const BASE_EXIT_OFFSET = 72;
const BASE_DEFENSE_RANGE = 150;
const BASE_DEFENSE_DAMAGE = 6;
const BASE_DEFENSE_COOLDOWN_MS = 1300;
const BASE_DEFENSE_IMPACT_MS = 240;

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

export function spawnDebugRaceUnit(state: GameState, slotIndex: number): BattleUnit {
  const slots = raceDefs[state.currentRaceId].unitSlots;
  const slot = slots[Math.max(0, Math.min(slots.length - 1, slotIndex))];
  const level = state.unitLevels[slot.unitId] ?? 1;
  const unit = spawnBattleUnit(state, 'player', slot.unitId, level, false, { lifetime: 'standard', tags: ['debug'] });
  state.recentFloatingTexts.push({ label: `调试生成 Lv${level} ${unitDefs[slot.unitId].name}`, color: raceDefs[state.currentRaceId].color });
  return unit;
}

export function dealMagicDamage(state: GameState, baseDamage: number) {
  const enemies = state.battle.units
    .filter((unit) => unit.side === 'enemy')
    .sort((a, b) => a.x - b.x)
    .slice(0, 3);

  for (const enemy of enemies) {
    const damage = Math.round(baseDamage * state.modifiers.magicDamageMultiplier);
    enemy.hp = Math.max(0, enemy.hp - damage);
    enemy.lastHitAtMs = state.battle.elapsedMs;
    state.stats.currentPhase.damageDealt += damage;
    addEffect(state, 'hit', 'player', enemy.id, enemy.x, enemy.laneOffset, 260, undefined, damage);
    if (enemy.hp <= 0) {
      addEffect(state, 'death', enemy.side, enemy.id, enemy.x, enemy.laneOffset, 520);
    }
  }
  removeDeadUnits(state);
}

export function updateBattle(state: GameState, deltaMs: number) {
  state.battle.elapsedMs += deltaMs;
  state.phaseElapsedMs += deltaMs;
  resolveProjectileImpacts(state);
  cleanupFeedback(state);
  updateBaseDefense(state, deltaMs);
  const units = [...state.battle.units];

  for (const unit of units) {
    if (unit.hp <= 0) continue;
    const def = unitDefs[unit.defId];
    unit.attackTimerMs = Math.max(0, unit.attackTimerMs - deltaMs);
    const enemySide: Side = unit.side === 'player' ? 'enemy' : 'player';
    const target = findTarget(state, unit, enemySide);
    const enemyBase = state.battle.bases[enemySide];
    const baseDistance = Math.abs(enemyBase.x - unit.x);

    if (target && isInAttackRange(unit, target)) {
      attackUnit(state, unit, target);
      continue;
    }

    if (!target && baseDistance <= def.attackRange + 28) {
      attackBase(state, unit, enemyBase.side);
      continue;
    }

    const direction = unit.side === 'player' ? 1 : -1;
    unit.x += direction * def.moveSpeed * (deltaMs / 1000);
  }

  removeDeadUnits(state);
}

function findTarget(state: GameState, unit: BattleUnit, enemySide: Side): BattleUnit | undefined {
  return state.battle.units
    .filter((candidate) => candidate.side === enemySide && candidate.hp > 0 && isInAggroRange(unit, candidate))
    .sort((a, b) => getTargetDistance(unit, a) - getTargetDistance(unit, b))[0];
}

function getTargetDistance(attacker: BattleUnit, candidate: BattleUnit): number {
  const axisDistance = Math.abs(candidate.x - attacker.x);
  const laneDistance = Math.abs(candidate.laneOffset - attacker.laneOffset) * 0.72;
  return axisDistance + laneDistance;
}

function isInAggroRange(attacker: BattleUnit, candidate: BattleUnit): boolean {
  const def = unitDefs[attacker.defId];
  return getTargetDistance(attacker, candidate) <= def.aggroRange;
}

function isInAttackRange(attacker: BattleUnit, candidate: BattleUnit): boolean {
  const def = unitDefs[attacker.defId];
  return getTargetDistance(attacker, candidate) <= def.attackRange;
}

function attackUnit(state: GameState, attacker: BattleUnit, target: BattleUnit) {
  const def = unitDefs[attacker.defId];
  if (attacker.attackTimerMs > 0) return;
  const targetDef = unitDefs[target.defId];
  const burstBonus = attacker.burstUntilMs > state.battle.elapsedMs ? 1.35 : 1;
  const damage = Math.max(1, Math.round(attacker.damage * burstBonus - targetDef.armor));
  attacker.attackTimerMs = def.attackCooldownMs;
  attacker.lastAttackAtMs = state.battle.elapsedMs;
  if (usesProjectile(def.role)) {
    addProjectile(state, attacker, target, damage);
    return;
  }
  applyUnitDamage(state, attacker, target, damage);
}

function attackBase(state: GameState, attacker: BattleUnit, side: Side) {
  const def = unitDefs[attacker.defId];
  if (attacker.attackTimerMs > 0) return;
  const burstBonus = attacker.burstUntilMs > state.battle.elapsedMs ? 1.35 : 1;
  const damage = Math.max(1, Math.round(attacker.damage * burstBonus));
  attacker.attackTimerMs = def.attackCooldownMs;
  attacker.lastAttackAtMs = state.battle.elapsedMs;
  if (usesProjectile(def.role)) {
    addBaseProjectile(state, attacker, side, damage);
    return;
  }
  applyBaseDamage(state, attacker, side, damage);
}

function removeDeadUnits(state: GameState) {
  state.battle.units = state.battle.units.filter((unit) => unit.hp > 0);
}

function updateBaseDefense(state: GameState, deltaMs: number) {
  for (const side of ['player', 'enemy'] as const) {
    const base = state.battle.bases[side];
    if (base.hp <= 0) continue;
    base.attackTimerMs = Math.max(0, base.attackTimerMs - deltaMs);
    if (base.attackTimerMs > 0) continue;
    const target = findBaseDefenseTarget(state, side);
    if (!target) continue;
    addBaseDefenseProjectile(state, side, target, BASE_DEFENSE_DAMAGE);
    base.attackTimerMs = BASE_DEFENSE_COOLDOWN_MS;
    base.lastAttackAtMs = state.battle.elapsedMs;
  }
}

function findBaseDefenseTarget(state: GameState, side: Side): BattleUnit | undefined {
  const base = state.battle.bases[side];
  const enemySide: Side = side === 'player' ? 'enemy' : 'player';
  return state.battle.units
    .filter((unit) => unit.side === enemySide && unit.hp > 0 && getBaseDefenseDistance(base.x, base.laneOffset, unit) <= BASE_DEFENSE_RANGE)
    .sort((a, b) => getBaseDefenseDistance(base.x, base.laneOffset, a) - getBaseDefenseDistance(base.x, base.laneOffset, b))[0];
}

function getBaseDefenseDistance(baseX: number, baseLaneOffset: number, unit: BattleUnit): number {
  return Math.abs(unit.x - baseX) + Math.abs(unit.laneOffset - baseLaneOffset) * 0.5;
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

export function getBattleContactRatio(state: GameState): number | undefined {
  const playerBaseX = state.battle.bases.player.x;
  const enemyBaseX = state.battle.bases.enemy.x;
  const span = Math.max(1, enemyBaseX - playerBaseX);
  const playerUnits = state.battle.units.filter((unit) => unit.side === 'player' && unit.hp > 0);
  const enemyUnits = state.battle.units.filter((unit) => unit.side === 'enemy' && unit.hp > 0);
  let closestContact: { distance: number; midpointX: number } | undefined;

  for (const player of playerUnits) {
    for (const enemy of enemyUnits) {
      const distance = getTargetDistance(player, enemy);
      const playerRange = unitDefs[player.defId].attackRange;
      const enemyRange = unitDefs[enemy.defId].attackRange;
      const contactRange = Math.max(playerRange, enemyRange) + 12;
      if (distance > contactRange) continue;
      if (!closestContact || distance < closestContact.distance) {
        closestContact = {
          distance,
          midpointX: (player.x + enemy.x) / 2,
        };
      }
    }
  }

  if (!closestContact) return undefined;
  return Math.max(0, Math.min(1, (closestContact.midpointX - playerBaseX) / span));
}

function usesProjectile(role: string): boolean {
  return ['ranged', 'caster', 'siege'].includes(role);
}

function applyUnitDamage(state: GameState, attacker: BattleUnit | undefined, target: BattleUnit, damage: number) {
  const sourceSide = attacker?.side ?? (target.side === 'player' ? 'enemy' : 'player');
  target.hp = Math.max(0, target.hp - damage);
  if (attacker) attacker.damageDone += damage;
  target.lastHitAtMs = state.battle.elapsedMs;
  addEffect(state, 'hit', sourceSide, target.id, target.x, target.laneOffset, 260, undefined, damage);
  if (sourceSide === 'player') {
    state.stats.currentPhase.damageDealt += damage;
  }
  if (target.hp <= 0) {
    if (attacker) attacker.kills += 1;
    addEffect(state, 'death', target.side, target.id, target.x, target.laneOffset, 520);
    if (sourceSide === 'player') {
      state.stats.currentPhase.kills += 1;
    }
  }
}

function applyBaseDamage(state: GameState, attacker: BattleUnit | undefined, side: Side, damage: number) {
  const base = state.battle.bases[side];
  base.hp = Math.max(0, base.hp - damage);
  if (attacker) attacker.damageDone += damage;
  base.lastHitAtMs = state.battle.elapsedMs;
  addEffect(state, 'base_hit', attacker?.side ?? (side === 'player' ? 'enemy' : 'player'), undefined, base.x, base.laneOffset, 300, side);
  if (attacker?.side === 'player') {
    state.stats.currentPhase.enemyBaseDamage += damage;
    state.stats.currentPhase.damageDealt += damage;
  } else if (attacker?.side === 'enemy') {
    state.stats.currentPhase.playerBaseDamage += damage;
  }
}

function addProjectile(state: GameState, attacker: BattleUnit, target: BattleUnit, damage: number) {
  state.battle.projectiles.push({
    id: `projectile-${state.battle.nextFeedbackId++}`,
    side: attacker.side,
    fromUnitId: attacker.id,
    toUnitId: target.id,
    damage,
    applied: false,
    fromX: attacker.x,
    toX: target.x,
    fromLaneOffset: attacker.laneOffset,
    toLaneOffset: target.laneOffset,
    createdAtMs: state.battle.elapsedMs,
    impactAtMs: state.battle.elapsedMs + 260,
    color: attacker.side === 'player' ? 0x60a5fa : 0xfb923c,
  });
}

function addBaseProjectile(state: GameState, attacker: BattleUnit, side: Side, damage: number) {
  const base = state.battle.bases[side];
  state.battle.projectiles.push({
    id: `projectile-${state.battle.nextFeedbackId++}`,
    side: attacker.side,
    fromUnitId: attacker.id,
    toBaseSide: side,
    damage,
    applied: false,
    fromX: attacker.x,
    toX: base.x,
    fromLaneOffset: attacker.laneOffset,
    toLaneOffset: base.laneOffset,
    createdAtMs: state.battle.elapsedMs,
    impactAtMs: state.battle.elapsedMs + 300,
    color: attacker.side === 'player' ? 0x60a5fa : 0xfb923c,
  });
}

function addBaseDefenseProjectile(state: GameState, side: Side, target: BattleUnit, damage: number) {
  const base = state.battle.bases[side];
  state.battle.projectiles.push({
    id: `projectile-${state.battle.nextFeedbackId++}`,
    side,
    fromBaseSide: side,
    toUnitId: target.id,
    damage,
    applied: false,
    fromX: base.x,
    toX: target.x,
    fromLaneOffset: base.laneOffset,
    toLaneOffset: target.laneOffset,
    createdAtMs: state.battle.elapsedMs,
    impactAtMs: state.battle.elapsedMs + BASE_DEFENSE_IMPACT_MS,
    color: side === 'player' ? 0x93c5fd : 0xfca5a5,
  });
}

function resolveProjectileImpacts(state: GameState) {
  for (const projectile of state.battle.projectiles) {
    if (projectile.applied || state.battle.elapsedMs < projectile.impactAtMs) continue;
    projectile.applied = true;
    const attacker = projectile.fromUnitId
      ? state.battle.units.find((unit) => unit.id === projectile.fromUnitId && unit.hp > 0)
      : undefined;
    if (projectile.toUnitId) {
      const target = state.battle.units.find((unit) => unit.id === projectile.toUnitId && unit.hp > 0);
      if (!target) continue;
      applyUnitDamage(state, attacker, target, projectile.damage);
    } else if (projectile.toBaseSide) {
      applyBaseDamage(state, attacker, projectile.toBaseSide, projectile.damage);
    }
  }
  removeDeadUnits(state);
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
  damage?: number,
) {
  state.battle.transientEffects.push({
    id: `effect-${state.battle.nextFeedbackId++}`,
    type,
    side,
    unitId,
    baseSide,
    damage,
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
