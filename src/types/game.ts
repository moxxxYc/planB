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
export type BallTagId = 'split+' | 'spawn-mark' | 'copy-mark' | 'heavy' | 'recycle';
export type LaunchOutcomeId = 'split' | 'fire' | 'miss';
export type BuildingChamber = 'launch' | 'decision' | 'unit';
export type DoctrinePath = 'launch' | 'decision' | 'unit';
export type PhaseToolId = 'spawn_beacon' | 'hot_slot_calibrator' | 'queue_surge' | 'field_repair' | 'marked_shot';

export interface BallPayload {
  value: number;
  tags: BallTagId[];
}

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
  attackTimerMs: number;
  lastAttackAtMs: number;
  lastHitAtMs: number;
}

export interface BattleProjectile {
  id: string;
  side: Side;
  fromUnitId?: string;
  fromBaseSide?: Side;
  toUnitId?: string;
  toBaseSide?: Side;
  damage: number;
  applied: boolean;
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
  damage?: number;
  x: number;
  laneOffset: number;
  createdAtMs: number;
  expiresAtMs: number;
}

export interface BattleCameraState {
  centerX: number;
  viewportWorldWidth: number;
  manualUntilMs: number;
  manualOverride: boolean;
}

export interface BattleState {
  units: BattleUnit[];
  bases: Record<Side, BaseState>;
  camera: BattleCameraState;
  elapsedMs: number;
  nextFeedbackId: number;
  projectiles: BattleProjectile[];
  transientEffects: BattleEffect[];
}

export interface PhaseStats {
  slotTriggers: Record<SlotId, number>;
  launchOutcomes: Record<LaunchOutcomeId, number>;
  buildingContributions: Record<BuildingChamber, number>;
  spawnMarksCreated: number;
  spawnMarksConsumed: number;
  spawnCopiesCreated: number;
  nonSpawnRecoveryEvents: number;
  currentNonSpawnStreak: number;
  nonSpawnStreakMax: number;
  nonSpawnStreakStartedAtMs?: number;
  timeToRecoverySpawnMs?: number;
  recoverySources: Record<string, number>;
  phaseToolsPurchased: number;
  relicTriggers: number;
  overflowProgressGranted: number;
  gateAccelerationEvents: number;
  gateBlockedEvents: number;
  queueBurstEvents: number;
  unitsQueuedById: Record<string, number>;
  unitsDeployedById: Record<string, number>;
  unitsSpawned: number;
  unitsQueued: number;
  advancedUnitsQueued: number;
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

export interface PhaseChainHistoryEntry {
  phaseIndex: number;
  phaseId: string;
  phaseName: string;
  reason: PhaseCompleteReason;
  archetype: string;
  dominantChamber: string;
  resourceReturnRate: number;
  summaryLines: string[];
  completedAtMs: number;
  unitsQueued: number;
  unitsDeployed: number;
  advancedUnitsQueued: number;
  gateBlockedEvents: number;
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

export interface BuildingDef {
  id: string;
  chamber: BuildingChamber;
  name: string;
  tag: string;
  icon: string;
  description: string;
  maxLevel: number;
}

export interface BuildingInstance {
  id: string;
  chamber: BuildingChamber;
  level: number;
}

export interface BuildingEventState {
  coinPressGoldHits: number;
}

export interface RelicDef {
  id: string;
  name: string;
  tag: string;
  icon: string;
  description: string;
}

export interface RelicEventState {
  entropyCharges: number;
}

export interface DoctrineTechDef {
  id: string;
  path: DoctrinePath;
  name: string;
  tag: string;
  icon: string;
  researchCost: number;
  description: string;
}

export interface DoctrineEventState {
  conversionHits: number;
  launchLosses: number;
  researchReturnProgress: number;
  nonSpawnStreak: number;
}

export interface PhaseToolDef {
  id: PhaseToolId;
  name: string;
  shortLabel: string;
  tag: string;
  cost: number;
  description: string;
}

export type DebugBuildPresetId = 'swarm' | 'magic_copy' | 'mech_elite' | 'economy_industry' | 'recovery';

export interface DebugBuildPreset {
  id: DebugBuildPresetId;
  name: string;
  shortLabel: string;
  description: string;
  raceId: RaceId;
  buildingIds: string[];
  rewardIds: string[];
  gold?: number;
  pendingSpawnMarks?: number;
  pendingSpawnLevelBonus?: number;
  nextSpawnCreatesElite?: boolean;
  unitLevelBoosts?: Record<string, number>;
}

export interface GameSettings {
  magicEnabled: boolean;
}

export interface GameState {
  seed: number;
  currentRaceId: RaceId;
  phaseIndex: number;
  phaseActive: boolean;
  isBuildPause: boolean;
  gold: number;
  pendingSpawnLevelBonus: number;
  hasSeenFirstSpawnLoop: boolean;
  firstLoopAssistActive: boolean;
  firstSpawnOutcomeForced: boolean;
  firstUnitSlotForced: boolean;
  upTriggerCountTowardElite: number;
  nextSpawnCreatesElite: boolean;
  pendingSpawnMarks: number;
  pendingLaunchBallTags: BallTagId[];
  ballTags: BallTagId[];
  buildingEvents: BuildingEventState;
  relicEvents: RelicEventState;
  doctrineEvents: DoctrineEventState;
  researchPoints: number;
  nextUnitId: number;
  nextBallId: number;
  nextQueueId: number;
  phaseElapsedMs: number;
  playerStandardUnitSoftCap: number;
  eliteUnitCap: number;
  spawnQueue: SpawnQueueItem[];
  machineUpgrades: PersistentRunItem[];
  slotUpgrades: PersistentRunItem[];
  buildings: BuildingInstance[];
  relics: PersistentRunItem[];
  doctrineTechs: PersistentRunItem[];
  launchRelics: PersistentRunItem[];
  decisionTechs: PersistentRunItem[];
  unitStructures: BuildingInstance[];
  phaseToolStock: PhaseToolId[];
  usedPhaseTools: PhaseToolId[];
  selectedRewards: string[];
  chainHistory: PhaseChainHistoryEntry[];
  buildArchetypeHint: string;
  slots: Record<SlotId, SlotState>;
  battle: BattleState;
  stats: GameStats;
  modifiers: GameModifiers;
  unitLevels: Record<string, number>;
  unitSlotStates: Record<RaceId, UnitSlotState[]>;
  settings: GameSettings;
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
