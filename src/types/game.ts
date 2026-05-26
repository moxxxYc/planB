export type RaceId = 'hive' | 'mech';
export type Side = 'player' | 'enemy';
export type SlotId = 'spawn' | 'gold' | 'magic' | 'upgrade' | 'special';
export type UnitRole = 'frontline' | 'melee' | 'ranged' | 'caster' | 'siege' | 'giant';
export type LaneName = 'front' | 'mid' | 'back';
export type BattleLaneId = 'top' | 'middle' | 'bottom';
export type UnitLifetime = 'standard' | 'elite' | 'temporary' | 'summon';
export type PhaseObjectiveType = 'destroy_gate' | 'survive_pressure' | 'mini_boss' | 'destroy_core';
export type PhaseCompleteReason = 'objective' | 'timer' | 'boss_defeated' | 'debug_skip';
export type BallStage = 'launch' | 'decision' | 'unit';

export interface UnitSlotDef {
  index: number;
  unitId: string;
  label: string;
  requirement: number;
}

export interface UnitSlotState extends UnitSlotDef {
  progress: number;
}

export interface UnitGateState {
  elapsedMs: number;
  durationMs: number;
  openBoundaryRatio: number;
  openSlotCount: number;
  openUnitIndex: number;
}

export interface BattleLaneWeights {
  top: number;
  middle: number;
  bottom: number;
}

export interface RaceDef {
  id: RaceId;
  name: string;
  color: number;
  unitPool: string[];
  unitSlots: UnitSlotDef[];
  passive: 'extra_grub_chance' | 'upgrade_efficiency';
}

export interface UnitDef {
  id: string;
  raceId: RaceId | 'enemy';
  name: string;
  role: UnitRole;
  maxHp: number;
  damage: number;
  aggroRange: number;
  attackRange: number;
  attackCooldownMs: number;
  moveSpeed: number;
  armor: number;
  spawnWeight: number;
  costTier: 1 | 2 | 3;
  assetKey: string;
  lane: LaneName;
  laneWeights: BattleLaneWeights;
}

export interface SlotState {
  id: SlotId;
  label: string;
  color: number;
  widthWeight: number;
  triggerCount: number;
  level: number;
  lastTriggeredAtMs: number;
}

export interface BattleUnit {
  id: string;
  defId: string;
  side: Side;
  hp: number;
  maxHp: number;
  damage: number;
  x: number;
  battleLane: BattleLaneId;
  laneOffset: number;
  targetId?: string;
  attackTimerMs: number;
  level: number;
  lifetime: UnitLifetime;
  isElite: boolean;
  veterancyXp: number;
  veterancyLevel: number;
  phaseSpawned: number;
  tags: string[];
  damageDone: number;
  kills: number;
  burstUntilMs: number;
  spawnedAtMs: number;
  lastAttackAtMs: number;
  lastHitAtMs: number;
}

export interface BaseState {
  side: Side;
  hp: number;
  maxHp: number;
  x: number;
  laneOffset: number;
  lastHitAtMs: number;
}

export interface BattleProjectile {
  id: string;
  side: Side;
  fromUnitId: string;
  toUnitId?: string;
  toBaseSide?: Side;
  fromX: number;
  toX: number;
  fromLaneOffset: number;
  toLaneOffset: number;
  createdAtMs: number;
  impactAtMs: number;
  color: number;
}

export type BattleEffectType = 'spawn' | 'hit' | 'death' | 'base_hit';

export interface BattleEffect {
  id: string;
  type: BattleEffectType;
  side: Side;
  unitId?: string;
  baseSide?: Side;
  x: number;
  laneOffset: number;
  createdAtMs: number;
  expiresAtMs: number;
}

export interface BattleState {
  units: BattleUnit[];
  bases: Record<Side, BaseState>;
  elapsedMs: number;
  nextFeedbackId: number;
  projectiles: BattleProjectile[];
  transientEffects: BattleEffect[];
}

export interface PhaseStats {
  slotTriggers: Record<SlotId, number>;
  unitsSpawned: number;
  unitsQueued: number;
  damageDealt: number;
  kills: number;
  eliteXpGained: number;
  enemyBaseDamage: number;
  playerBaseDamage: number;
}

export interface GameStats {
  currentPhase: PhaseStats;
  lastPhase?: PhaseStats;
}

export interface GameModifiers {
  ballCount: number;
  goldMultiplier: number;
  spawnExtraCount: number;
  magicSpawnCopyBonus: number;
  pendingSpawnCopies: number;
  magicDamageMultiplier: number;
  mechUpgradeEfficiency: number;
  hiveExtraGrubCount: number;
  nextPhaseSpawnLevelBonus: number;
  queueReleaseSpeedBonus: number;
  eliteExtraVeterancy: number;
  basicUnitHpBonus: number;
  basicUnitDamageBonus: number;
}

export interface SpawnQueueItem {
  id: string;
  unitId: string;
  side: Side;
  count: number;
  lane: LaneName;
  releaseIntervalMs: number;
  nextReleaseInMs: number;
  level: number;
  lifetime: UnitLifetime;
  isElite: boolean;
  tags: string[];
}

export interface PersistentRunItem {
  id: string;
}

export interface GameState {
  seed: number;
  currentRaceId: RaceId;
  phaseIndex: number;
  phaseActive: boolean;
  isBuildPause: boolean;
  gold: number;
  pendingSpawnLevelBonus: number;
  upTriggerCountTowardElite: number;
  nextSpawnCreatesElite: boolean;
  nextUnitId: number;
  nextBallId: number;
  nextQueueId: number;
  phaseElapsedMs: number;
  playerStandardUnitSoftCap: number;
  eliteUnitCap: number;
  spawnQueue: SpawnQueueItem[];
  machineUpgrades: PersistentRunItem[];
  slotUpgrades: PersistentRunItem[];
  buildings: PersistentRunItem[];
  relics: PersistentRunItem[];
  selectedRewards: string[];
  slots: Record<SlotId, SlotState>;
  battle: BattleState;
  stats: GameStats;
  modifiers: GameModifiers;
  unitLevels: Record<string, number>;
  unitSlotStates: Record<RaceId, UnitSlotState[]>;
  recentFloatingTexts: Array<{ label: string; color: number }>;
}

export interface RewardDef {
  id: string;
  name: string;
  tag: string;
  icon: string;
  description: string;
}

export interface PhaseDef {
  id: string;
  name: string;
  objectiveType: PhaseObjectiveType;
  durationMs: number;
  enemyPressureLevel: number;
  enemyObjectiveHp: number;
  enemySpawns: Array<{ atMs: number; unitId: string; count: number }>;
}
