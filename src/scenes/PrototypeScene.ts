import Phaser from 'phaser';
import { phaseDefs } from '../data/phases';
import { raceDefs } from '../data/races';
import { decisionSlotDefs } from '../data/slots';
import { unitDefs } from '../data/units';
import { getEliteSummary } from '../systems/EliteSystem';
import { getBattleContactRatio, getBattleFrontlineRatio, spawnDebugRaceUnit, updateBattle } from '../systems/BattleSystem';
import {
  buildBattleHeatBands,
  clampBattleProjectionToBounds,
  clampBattleCameraCenter,
  getBattleCameraViewport,
  getBattleHotspotCameraCenter,
  getBattleHotspotRatio,
  getNextBattleCameraCenter,
  getPannedBattleCameraCenter,
  projectBattlePoint,
} from '../systems/BattlefieldViewSystem';
import { createInitialGameState } from '../systems/GameState';
import { completePhase, isFinalPhaseComplete, resumeNextPhase, shouldCompletePhase, startPhase, updatePhaseEnemySpawns } from '../systems/PhaseSystem';
import {
  buildLaunchSplitRelaunchPlan,
  getControlledGateBounceVelocity,
  getLauncherVelocity,
  getSweepingLauncherAngle,
} from '../systems/PinballMachineSystem';
import { buildRewardChoices, rerollRewardChoices } from '../systems/RewardSystem';
import { countQueuedUnits, updateSpawnQueue } from '../systems/SpawnQueueSystem';
import { triggerSlot } from '../systems/SlotTriggerSystem';
import { buildWeightedSlotLayouts } from '../systems/DecisionSlotLayoutSystem';
import {
  getFirstSpawnAssistPlan,
  markFirstSpawnLoopSeen,
  markFirstSpawnOutcomeForced,
  markFirstUnitSlotForced,
} from '../systems/FirstSpawnLoopAssistSystem';
import {
  getCurrentRaceUnitSlotStates,
  getUnitGateState,
  resolveUnitBallToSlot,
} from '../systems/UnitSpawnProgressSystem';
import type { BallStage, BattleUnit, GameState, RaceId, RewardDef, SlotId, UnitSlotState } from '../types/game';

type PinballBall = {
  image: Phaser.Physics.Matter.Image;
  stage: BallStage;
  value: number;
  blockedGateHits: number;
  createdAt: number;
  lastGateBounceAt: number;
};

type OutcomeVisual = {
  id: string;
  body: MatterJS.BodyType;
  plate: Phaser.GameObjects.Rectangle;
  label: Phaser.GameObjects.Text;
  count?: Phaser.GameObjects.Text;
};

type UnitSlotVisual = {
  slot: UnitSlotState;
  body: MatterJS.BodyType;
  plate: Phaser.GameObjects.Rectangle;
  icon: Phaser.GameObjects.Image;
  label: Phaser.GameObjects.Text;
  progressBack: Phaser.GameObjects.Rectangle;
  progressFill: Phaser.GameObjects.Rectangle;
  progressText: Phaser.GameObjects.Text;
};

type UnitVisual = {
  outline: Phaser.GameObjects.Image;
  sprite: Phaser.GameObjects.Image;
  sideRing: Phaser.GameObjects.Ellipse;
  hpBack: Phaser.GameObjects.Rectangle;
  hpFill: Phaser.GameObjects.Rectangle;
  hpText: Phaser.GameObjects.Text;
  shadow: Phaser.GameObjects.Ellipse;
};

const GAME_W = 1280;
const GAME_H = 720;
const TOP_Y = 12;
const TOP_H = 196;
const HUD_H = 72;
const BATTLE_Y = TOP_Y + TOP_H + 8;
const BATTLE_H = GAME_H - BATTLE_Y - HUD_H - 8;
const HUD_TOP = GAME_H - HUD_H;
const MINIMAP_X = 20;
const MINIMAP_Y = HUD_TOP - 128;
const MINIMAP_W = 202;
const MINIMAP_H = 104;

const LAUNCH_X = 14;
const LAUNCH_W = 225;
const DECISION_X = LAUNCH_X + LAUNCH_W + 10;
const DECISION_W = 350;
const UNIT_X = DECISION_X + DECISION_W + 10;
const UNIT_W = GAME_W - UNIT_X - 14;
const BATTLE_SCREEN_START = { x: 300, y: BATTLE_Y + BATTLE_H - 88 };
const BATTLE_SCREEN_END = { x: 1110, y: BATTLE_Y + 44 };

const BALL_LABEL_PREFIX = 'ball:';
const SENSOR_LABEL_PREFIX = 'sensor:';
const PINBALL_BALL_RADIUS = 5;
const PINBALL_BALL_SCALE = 0.16;
const LAUNCHER_SWEEP_CYCLE_MS = 2400;
const LAUNCHER_SPEED = 3.2;
const UNIT_GATE_HEIGHT = 12.2;
const UNIT_GATE_RESTITUTION = 1.35;
const UNIT_SLOT_CENTER_Y = TOP_Y + TOP_H - 20;
const UNIT_SLOT_TOP_Y = UNIT_SLOT_CENTER_Y - 24;
const UNIT_GATE_Y = UNIT_SLOT_TOP_Y - UNIT_GATE_HEIGHT / 2;
const BATTLE_UNIT_TOP_PADDING = 52;
const BATTLE_UNIT_BOTTOM_PADDING = 32;
const BATTLE_UNIT_HORIZONTAL_PADDING = 36;

export class PrototypeScene extends Phaser.Scene {
  private state!: GameState;
  private balls = new Map<string, PinballBall>();
  private unitVisuals = new Map<string, UnitVisual>();
  private renderedEffectIds = new Set<string>();
  private hudTexts: Phaser.GameObjects.Text[] = [];
  private decisionVisuals: OutcomeVisual[] = [];
  private unitSlotVisuals: UnitSlotVisual[] = [];
  private floatingGroup!: Phaser.GameObjects.Group;
  private rewardContainer?: Phaser.GameObjects.Container;
  private currentRewardChoices: RewardDef[] = [];
  private rewardRerollUsed = false;
  private summaryContainer?: Phaser.GameObjects.Container;
  private unitGatePlate?: Phaser.GameObjects.Rectangle;
  private unitGateText?: Phaser.GameObjects.Text;
  private unitGateBody?: MatterJS.BodyType;
  private unitGateBodyWidth = 1;
  private unitGateBodyHeight = UNIT_GATE_HEIGHT;
  private battlefieldTerrain!: Phaser.GameObjects.Graphics;
  private battlefieldDynamic!: Phaser.GameObjects.Graphics;
  private battlefieldMask?: Phaser.Display.Masks.GeometryMask;
  private minimapDynamic!: Phaser.GameObjects.Graphics;
  private frontlineButton?: Phaser.GameObjects.Rectangle;
  private frontlineButtonText?: Phaser.GameObjects.Text;
  private cameraFollowButton?: Phaser.GameObjects.Rectangle;
  private cameraFollowButtonText?: Phaser.GameObjects.Text;
  private magicToggleButton?: Phaser.GameObjects.Rectangle;
  private magicToggleText?: Phaser.GameObjects.Text;
  private debugUnitButtons: Array<{ plate: Phaser.GameObjects.Rectangle; text: Phaser.GameObjects.Text; slotIndex: number }> = [];
  private baseVisuals: Phaser.GameObjects.GameObject[] = [];
  private launcherTurret!: Phaser.GameObjects.Graphics;
  private battlePanStartPointerX = 0;
  private battlePanStartCenterX = 0;
  private lastBallDropMs = 0;
  private slotFlashUntil = new Map<string, number>();
  private lastRecentTextIndex = 0;
  private gameOver = false;

  constructor() {
    super('PrototypeScene');
  }

  create() {
    this.state = createInitialGameState('hive', 24391);
    this.floatingGroup = this.add.group();
    this.matter.world.setBounds(0, 0, GAME_W, TOP_Y + TOP_H, 28, true, true, true, true);
    this.cameras.main.setBackgroundColor('#111827');
    this.drawStaticLayout();
    this.createPinballPipeline();
    this.createHud();
    this.createDebugControls();
    this.bindDomControls();
    startPhase(this.state);
    this.spawnLaunchBall();
    this.matter.world.on('collisionstart', (event: any) => this.handleMatterCollision(event));
  }

  update(time: number, delta: number) {
    if (!this.state || this.gameOver) return;
    if (this.state.phaseActive) {
      const previousPhaseElapsed = this.state.phaseElapsedMs;
      if (time - this.lastBallDropMs > 1300) {
        for (let index = 0; index < this.state.modifiers.ballCount; index += 1) {
          this.time.delayedCall(index * 140, () => this.spawnLaunchBall());
        }
        this.lastBallDropMs = time;
      }
      updateBattle(this.state, delta);
      updateSpawnQueue(this.state, delta);
      updatePhaseEnemySpawns(this.state, previousPhaseElapsed);
      this.runFirstSpawnLoopAssist();
      this.updateBattleCamera(delta);
      if (shouldCompletePhase(this.state)) {
        this.endPhase();
      }
    }

    this.drawBattlefieldBackdrop();
    this.nudgeBalls();
    this.cleanupLostBalls();
    this.syncLauncherTurret();
    this.updateUnitGateVisual();
    this.updateUnitSlotVisuals();
    this.syncUnitVisuals();
    this.syncCombatFeedback();
    this.syncMiniMap();
    this.syncBases();
    this.syncSlotFeedback(time);
    this.flushFloatingTexts();
    this.updateHud();
  }

  private drawStaticLayout() {
    this.add.rectangle(0, 0, GAME_W, GAME_H, 0x111827).setOrigin(0);
    this.add.rectangle(0, 0, GAME_W, TOP_Y + TOP_H + 4, 0x0f172a).setOrigin(0);
    this.add.rectangle(0, HUD_TOP, GAME_W, HUD_H, 0x0b1120).setOrigin(0);

    this.battlefieldTerrain = this.add.graphics().setDepth(100);
    const battlefieldMaskShape = this.make.graphics({ x: 0, y: 0 }, false);
    battlefieldMaskShape.fillStyle(0xffffff, 1);
    battlefieldMaskShape.fillRect(0, BATTLE_Y, GAME_W, BATTLE_H);
    this.battlefieldMask = battlefieldMaskShape.createGeometryMask();
    this.battlefieldTerrain.setMask(this.battlefieldMask);
    this.drawBattlefieldBackdrop();
    this.battlefieldDynamic = this.add.graphics().setDepth(4600);
    this.battlefieldDynamic.setMask(this.battlefieldMask);
    this.add.text(28, BATTLE_Y + 14, '伪 2D 3/4 自动战场', this.textStyle(20, '#f8fafc')).setDepth(950);
    this.createBattlefieldPanInput();
    this.createBattlefieldCameraControls();
    this.drawMiniMap();
  }

  private createBattlefieldPanInput() {
    const hit = this.add.rectangle(GAME_W / 2, BATTLE_Y + BATTLE_H / 2, GAME_W, BATTLE_H, 0x000000, 0.001)
      .setDepth(900)
      .setInteractive({ draggable: true, useHandCursor: true });
    this.input.setDraggable(hit);
    const startDrag = (pointer: Phaser.Input.Pointer) => {
      this.battlePanStartPointerX = pointer.x;
      this.battlePanStartCenterX = this.state.battle.camera.centerX;
    };
    hit.on('pointerdown', startDrag);
    hit.on('dragstart', startDrag);
    hit.on('drag', (pointer: Phaser.Input.Pointer) => this.panBattlefieldCamera(pointer.x - this.battlePanStartPointerX));
  }

  private createBattlefieldCameraControls() {
    const x = 274;
    const y = BATTLE_Y + 26;
    this.cameraFollowButton = this.add.rectangle(x, y, 88, 26, 0x12322b, 0.9)
      .setDepth(4705)
      .setStrokeStyle(1, 0x86efac, 0.76)
      .setInteractive({ useHandCursor: true });
    this.cameraFollowButtonText = this.add.text(x, y, '回前线', this.textStyle(13, '#dcfce7'))
      .setOrigin(0.5)
      .setDepth(4706);
    this.cameraFollowButton.on('pointerdown', () => this.restoreBattleCameraFollow());
  }

  private drawBattlefieldBackdrop() {
    const g = this.battlefieldTerrain;
    g.clear();
    this.clearBaseVisuals();
    g.fillStyle(0x07111c, 1);
    g.fillRect(0, BATTLE_Y, GAME_W, BATTLE_H);

    g.fillStyle(0x0c1519, 0.96);
    g.fillRect(0, BATTLE_Y + 8, GAME_W, BATTLE_H - 16);
    g.fillStyle(0x111827, 0.22);
    g.fillRect(0, BATTLE_Y + BATTLE_H - 98, GAME_W, 98);

    this.drawBattlefieldSurroundings(g);

    this.drawPolygon(g, [
      [0, BATTLE_Y + 42], [250, BATTLE_Y + 24], [344, BATTLE_Y + 112], [168, BATTLE_Y + 184],
      [0, BATTLE_Y + 150],
    ], 0x14211e, 0.36, 0x304238, 0.16);
    this.drawPolygon(g, [
      [990, BATTLE_Y + 78], [1280, BATTLE_Y + 32], [1280, BATTLE_Y + BATTLE_H],
      [1094, BATTLE_Y + BATTLE_H - 12], [1018, BATTLE_Y + 238],
    ], 0x12191b, 0.34, 0x334155, 0.14);
    this.drawPolygon(g, [
      [0, BATTLE_Y + BATTLE_H - 126], [246, BATTLE_Y + BATTLE_H - 206],
      [448, BATTLE_Y + BATTLE_H - 124], [260, BATTLE_Y + BATTLE_H - 28],
      [0, BATTLE_Y + BATTLE_H],
    ], 0x101b23, 0.34, 0x334155, 0.14);

    this.drawRoad(g);
    this.drawCliffsAndForest(g);
    const playerBase = this.projectBattle(this.state.battle.bases.player.x, 0);
    const enemyBase = this.projectBattle(this.state.battle.bases.enemy.x, 0);
    if (this.isProjectionVisible(playerBase, 0.24)) this.drawBaseDistrict('player', playerBase.x, playerBase.y - 20);
    if (this.isProjectionVisible(enemyBase, 0.24)) this.drawBaseDistrict('enemy', enemyBase.x, enemyBase.y - 20);
  }

  private drawBattlefieldSurroundings(g: Phaser.GameObjects.Graphics) {
    const top = BATTLE_Y;
    const bottom = BATTLE_Y + BATTLE_H;
    const wastelandPatches = [
      [[0, top + 18], [210, top + 22], [342, top + 88], [214, top + 170], [0, top + 132], [0, top + 18], 0x10261f, 0.7],
      [[28, top + 202], [248, top + 154], [424, top + 206], [346, top + 332], [118, top + 356], [0, top + 284], 0x172d2a, 0.5],
      [[934, top + 44], [1280, top + 18], [1280, top + 170], [1044, top + 188], [910, top + 122], [934, top + 44], 0x182833, 0.62],
      [[960, top + 246], [1280, top + 176], [1280, bottom - 18], [1088, bottom - 8], [1012, bottom - 130], [960, top + 246], 0x182d26, 0.58],
      [[0, bottom - 116], [196, bottom - 190], [392, bottom - 126], [252, bottom - 28], [0, bottom - 18], [0, bottom - 116], 0x1f2a2f, 0.54],
    ] as const;

    for (const patch of wastelandPatches) {
      const points = patch.slice(0, -2) as Array<[number, number]>;
      const fill = patch[patch.length - 2] as number;
      const alpha = patch[patch.length - 1] as number;
      this.drawPolygon(g, points, fill, alpha, 0x6b7c63, 0.08);
    }

    const contourLines = [
      [[22, top + 78], [160, top + 58], [278, top + 96], [368, top + 140]],
      [[28, top + 238], [190, top + 204], [360, top + 238], [476, top + 294]],
      [[818, top + 84], [986, top + 62], [1178, top + 84], [1270, top + 126]],
      [[890, bottom - 58], [1038, bottom - 116], [1198, bottom - 92], [1260, bottom - 46]],
      [[20, bottom - 58], [156, bottom - 96], [312, bottom - 72], [438, bottom - 114]],
    ] as const;
    for (const line of contourLines) {
      g.lineStyle(3, 0x4b6154, 0.16);
      g.beginPath();
      g.moveTo(line[0][0], line[0][1]);
      for (let i = 1; i < line.length; i += 1) g.lineTo(line[i][0], line[i][1]);
      g.strokePath();
      g.lineStyle(1, 0xa3ad8d, 0.08);
      g.strokePath();
    }

    const serviceRoads = [
      [44, top + 338, 342, top + 232],
      [878, top + 96, 1218, top + 44],
      [878, bottom - 72, 1218, bottom - 146],
      [76, top + 44, 272, top + 94],
    ] as const;
    for (const [x1, y1, x2, y2] of serviceRoads) {
      g.lineStyle(8, 0x394437, 0.18);
      g.lineBetween(x1, y1, x2, y2);
      g.lineStyle(2, 0xc3c9a7, 0.12);
      g.lineBetween(x1, y1, x2, y2);
    }

    const ruins = [
      [102, top + 118, 0.9, 0x334155], [190, top + 78, 0.72, 0x273542],
      [1108, top + 136, 0.82, 0x3a3f3a], [1198, top + 322, 0.96, 0x273542],
      [972, bottom - 54, 0.78, 0x334155], [286, bottom - 68, 0.82, 0x3a3f3a],
    ] as const;
    for (const [x, y, scale, color] of ruins) this.drawDistantRuin(g, x, y, scale, color);

    const hazeBands = [
      [218, top + 108, 310, 42], [1060, top + 238, 380, 48],
      [650, bottom - 74, 520, 34], [118, bottom - 176, 250, 38],
    ] as const;
    g.fillStyle(0xb6c2aa, 0.035);
    for (const [x, y, w, h] of hazeBands) g.fillEllipse(x, y, w, h);
  }

  private drawRoad(g: Phaser.GameObjects.Graphics) {
    this.drawRoadBand(g, 474, 0x020617, 0.34, 0x0f172a, 0.36, 16, 12);
    this.drawRoadBand(g, 410, 0x1c2a25, 0.92, 0x73816b, 0.4);
    this.drawRoadBand(g, 310, 0x344232, 0.78, 0xb7c49d, 0.16);
    this.drawRoadBand(g, 180, 0x42503b, 0.3, 0xd7ddb7, 0.08);

    for (const lane of [-1, 0, 1]) {
      g.lineStyle(lane === 0 ? 3 : 2, lane === 0 ? 0xd4dfba : 0x101820, lane === 0 ? 0.32 : 0.36);
      for (let i = 0; i < 16; i += 1) {
        const t0 = i / 16 + 0.012;
        const t1 = Math.min(1, t0 + 0.04);
        const p0 = this.getRoadPoint(this.getVisibleWorldX(t0));
        const p1 = this.getRoadPoint(this.getVisibleWorldX(t1));
        const n0 = this.getRoadNormal(p0, p1);
        const centerBias = 1 + Math.sin(t0 * Math.PI) * 0.5;
        const offset = lane * Phaser.Math.Linear(106, 86, t0) * centerBias;
        g.lineBetween(p0.x + n0.x * offset, p0.y + n0.y * offset, p1.x + n0.x * offset, p1.y + n0.y * offset);
      }
    }

    for (let i = 0; i < 18; i += 1) {
      const t = (i + 0.5) / 18;
      const p = this.getRoadPoint(this.getVisibleWorldX(t));
      const next = this.getRoadPoint(this.getVisibleWorldX(Math.min(1, t + 0.03)));
      const n = this.getRoadNormal(p, next);
      const tangent = this.getRoadTangent(p, next);
      const offset = (i % 2 === 0 ? -1 : 1) * Phaser.Math.Linear(152, 124, t);
      const centerX = p.x + n.x * offset;
      const centerY = p.y + n.y * offset;
      const halfLength = 18 + (i % 3) * 5;
      const halfWidth = 9;
      this.drawPolygon(g, [
        [centerX - tangent.x * halfLength - n.x * halfWidth, centerY - tangent.y * halfLength - n.y * halfWidth],
        [centerX + tangent.x * halfLength - n.x * halfWidth, centerY + tangent.y * halfLength - n.y * halfWidth],
        [centerX + tangent.x * halfLength + n.x * halfWidth, centerY + tangent.y * halfLength + n.y * halfWidth],
        [centerX - tangent.x * halfLength + n.x * halfWidth, centerY - tangent.y * halfLength + n.y * halfWidth],
      ], i % 2 === 0 ? 0x4a5143 : 0x2d372e, 0.34);
    }

    const edgeRubble = [
      [284, BATTLE_Y + BATTLE_H - 74, 18], [476, BATTLE_Y + BATTLE_H - 134, 14],
      [704, BATTLE_Y + BATTLE_H - 206, 15], [930, BATTLE_Y + 152, 17],
      [324, BATTLE_Y + BATTLE_H - 214, 14], [590, BATTLE_Y + 160, 13], [856, BATTLE_Y + 114, 16],
    ];
    for (const [x, y, s] of edgeRubble) this.drawRock(g, x, y, s);

    const playerGate = this.projectBattle(this.state.battle.bases.player.x + 72, 0);
    const enemyGate = this.projectBattle(this.state.battle.bases.enemy.x - 72, 0);
    if (this.isProjectionVisible(playerGate, 0.16)) this.drawSpawnGate(g, 'player', playerGate.x, playerGate.y);
    if (this.isProjectionVisible(enemyGate, 0.16)) this.drawSpawnGate(g, 'enemy', enemyGate.x, enemyGate.y);
  }

  private drawRoadBand(
    g: Phaser.GameObjects.Graphics,
    width: number,
    fill: number,
    alpha: number,
    stroke: number,
    strokeAlpha: number,
    offsetX = 0,
    offsetY = 0,
  ) {
    const left: Array<[number, number]> = [];
    const right: Array<[number, number]> = [];
    for (let i = 0; i <= 28; i += 1) {
      const t = i / 28;
      const p = this.getRoadPoint(this.getVisibleWorldX(t));
      const next = this.getRoadPoint(this.getVisibleWorldX(Math.min(1, t + 0.03)));
      const n = this.getRoadNormal(p, next);
      const halfWidth = Phaser.Math.Linear(width * 0.54, width * 0.46, t);
      left.push([p.x + n.x * halfWidth + offsetX, p.y + n.y * halfWidth + offsetY]);
      right.push([p.x - n.x * halfWidth + offsetX, p.y - n.y * halfWidth + offsetY]);
    }
    this.drawPolygon(g, [...left, ...right.reverse()], fill, alpha, stroke, strokeAlpha);
  }

  private drawSpawnGate(g: Phaser.GameObjects.Graphics, side: 'player' | 'enemy', x: number, y: number) {
    const color = side === 'player' ? 0x60a5fa : 0xf87171;
    const dark = side === 'player' ? 0x0f2a4f : 0x4a1515;
    g.fillStyle(dark, 0.78);
    g.fillEllipse(x, y + 8, 94, 30);
    g.lineStyle(3, color, 0.56);
    g.strokeEllipse(x, y + 2, 82, 24);
    g.fillStyle(color, 0.24);
    g.fillEllipse(x, y + 2, 58, 14);
  }

  private getRoadPoint(worldX: number) {
    const projection = this.projectBattle(worldX, 0);
    return { x: projection.x, y: projection.y };
  }

  private getRoadNormal(a: { x: number; y: number }, b: { x: number; y: number }) {
    const dx = b.x - a.x;
    const dy = b.y - a.y;
    const len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
    return { x: -dy / len, y: dx / len };
  }

  private getRoadTangent(a: { x: number; y: number }, b: { x: number; y: number }) {
    const dx = b.x - a.x;
    const dy = b.y - a.y;
    const len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
    return { x: dx / len, y: dy / len };
  }

  private drawCliffsAndForest(g: Phaser.GameObjects.Graphics) {
    const rocks = [
      [82, BATTLE_Y + 116, 28], [224, BATTLE_Y + 90, 26],
      [1128, BATTLE_Y + BATTLE_H - 166, 30], [1190, BATTLE_Y + BATTLE_H - 214, 24],
      [986, BATTLE_Y + BATTLE_H - 52, 24],
    ];
    for (const [x, y, s] of rocks) this.drawRock(g, x, y, s);

    const trees = [
      [70, BATTLE_Y + 176, 0.66], [118, BATTLE_Y + 196, 0.58], [1008, BATTLE_Y + 88, 0.58],
      [1160, BATTLE_Y + BATTLE_H - 244, 0.6], [1102, BATTLE_Y + BATTLE_H - 68, 0.6],
    ];
    for (const [x, y, scale] of trees) this.drawPine(g, x, y, scale);

    g.lineStyle(4, 0x1f2937, 0.52);
    g.lineBetween(72, BATTLE_Y + BATTLE_H - 24, 270, BATTLE_Y + BATTLE_H - 78);
    g.lineBetween(968, BATTLE_Y + 92, 1218, BATTLE_Y + 48);
  }

  private drawBaseDistrict(side: 'player' | 'enemy', x: number, y: number) {
    const isPlayer = side === 'player';
    const color = isPlayer ? 0x3b82f6 : 0xef4444;
    const dark = isPlayer ? 0x0f2a4f : 0x4a1515;
    const mid = isPlayer ? 0xbfe8ff : 0xff9b7c;
    const stone = 0x263345;
    const trim = isPlayer ? 0xfbbf24 : 0xf97316;
    const g = this.add.graphics().setDepth(y - 28);
    if (this.battlefieldMask) g.setMask(this.battlefieldMask);
    this.baseVisuals.push(g);

    g.fillStyle(0x020617, 0.46);
    g.fillEllipse(x, y + 56, 256, 54);
    this.drawPolygon(g, [
      [x - 124, y + 24], [x - 54, y - 18], [x + 78, y - 14],
      [x + 128, y + 22], [x + 104, y + 62], [x - 96, y + 64],
    ], dark, 0.82, color, 0.62);
    this.drawPolygon(g, [
      [x - 84, y + 20], [x - 24, y - 14], [x + 58, y - 10],
      [x + 88, y + 18], [x + 42, y + 44], [x - 62, y + 42],
    ], stone, 0.96, 0x9fb2c8, 0.5);
    this.drawPolygon(g, [
      [x - 36, y + 26], [x + 2, y + 6], [x + 42, y + 20],
      [x + 30, y + 42], [x - 18, y + 48], [x - 50, y + 36],
    ], mid, 0.92, dark, 0.88);

    const towers = [-66, -18, 32, 76];
    for (let i = 0; i < towers.length; i += 1) {
      const tx = x + towers[i];
      const ty = y + 8 - Math.abs(i - 1.5) * 3;
      g.fillStyle(0x111827, 1);
      g.fillRect(tx - 9, ty - 20, 18, 30);
      g.fillStyle(color, 0.78);
      g.fillTriangle(tx - 14, ty - 20, tx, ty - 35, tx + 14, ty - 20);
      g.lineStyle(2, color, 0.28);
      g.lineBetween(tx - 8, ty + 4, tx + 8, ty + 4);
    }
    g.fillStyle(color, 0.32);
    g.fillCircle(x + 18, y + 20, 17);
    g.lineStyle(2, trim, 0.72);
    g.lineBetween(x - 88, y + 46, x + 92, y + 44);
    g.fillStyle(trim, 0.86);
    g.fillTriangle(x - 78, y + 38, x - 64, y + 20, x - 50, y + 40);
    g.fillTriangle(x + 82, y + 36, x + 68, y + 20, x + 54, y + 40);

    const image = this.add.image(x + (isPlayer ? -8 : 8), y + 2, isPlayer ? 'base_player' : 'base_enemy')
      .setScale(0.44)
      .setAlpha(0.86)
      .setDepth(y + 18);
    if (this.battlefieldMask) image.setMask(this.battlefieldMask);
    this.baseVisuals.push(image);
  }

  private drawStaticBattleSquads() {
    const squads = [
      ['unit_mech_drone', 360, BATTLE_Y + 318, 0x60a5fa, 0.26],
      ['unit_mech_gunner', 460, BATTLE_Y + 292, 0x60a5fa, 0.24],
      ['unit_hive_grub', 642, BATTLE_Y + 232, 0xf87171, 0.24],
      ['unit_enemy_raider', 758, BATTLE_Y + 204, 0xf87171, 0.25],
      ['unit_enemy_brute', 870, BATTLE_Y + 174, 0xf87171, 0.23],
    ] as const;
    for (const [key, x, y, tint, alpha] of squads) {
      const sprite = this.add.image(x, y, key).setScale(0.25).setAlpha(alpha).setTint(tint).setDepth(y);
      this.add.ellipse(x, y + 18, 34, 10, 0x020617, 0.28).setDepth(y - 1);
      this.add.rectangle(x, y - 28, 36, 3, tint, 0.45).setDepth(y + 1);
      sprite.setAngle(Phaser.Math.Between(-4, 4));
    }
  }

  private drawMiniMap() {
    const x = MINIMAP_X;
    const y = MINIMAP_Y;
    const w = MINIMAP_W;
    const h = MINIMAP_H;
    const panel = this.add.graphics().setDepth(4700);
    panel.fillStyle(0x0b1118, 0.92);
    panel.fillRoundedRect(x, y, w, h, 6);
    panel.lineStyle(2, 0x9ca3af, 0.55);
    panel.strokeRoundedRect(x, y, w, h, 6);
    panel.fillStyle(0x263a2c, 1);
    panel.fillRoundedRect(x + 18, y + 48, w - 36, 28, 14);
    panel.fillStyle(0x60a5fa, 0.95);
    panel.fillCircle(x + 18, y + 62, 6);
    panel.fillStyle(0xf87171, 0.95);
    panel.fillCircle(x + w - 18, y + 62, 6);
    this.add.text(x + 10, y + 8, '战线', this.textStyle(15, '#f8fafc')).setDepth(4701);
    this.frontlineButton = this.add.rectangle(x + w - 45, y + 19, 74, 22, 0x172554, 0.88)
      .setDepth(4703)
      .setStrokeStyle(1, 0x93c5fd, 0.72)
      .setInteractive({ useHandCursor: true });
    this.frontlineButtonText = this.add.text(x + w - 45, y + 19, '回前线', this.textStyle(11, '#f8fafc'))
      .setOrigin(0.5)
      .setDepth(4704);
    this.frontlineButton.on('pointerdown', () => this.restoreBattleCameraFollow());
    this.minimapDynamic = this.add.graphics().setDepth(4702);
    const hit = this.add.rectangle(x + w / 2, y + 66, w - 20, 56, 0x000000, 0.001)
      .setDepth(4703)
      .setInteractive({ draggable: true, useHandCursor: true });
    this.input.setDraggable(hit);
    hit.on('pointerdown', (pointer: Phaser.Input.Pointer) => this.setCameraFromMiniMap(pointer.x));
    hit.on('drag', (pointer: Phaser.Input.Pointer) => this.setCameraFromMiniMap(pointer.x));
  }

  private drawRock(g: Phaser.GameObjects.Graphics, x: number, y: number, size: number) {
    this.drawPolygon(g, [
      [x - size, y + size * 0.4], [x - size * 0.45, y - size * 0.45],
      [x + size * 0.28, y - size * 0.64], [x + size, y + size * 0.24],
      [x + size * 0.28, y + size * 0.74],
    ], 0x26313b, 0.8, 0x465564, 0.42);
  }

  private drawPine(g: Phaser.GameObjects.Graphics, x: number, y: number, scale: number) {
    g.fillStyle(0x17231b, 1);
    g.fillRect(x - 3 * scale, y + 18 * scale, 6 * scale, 18 * scale);
    g.fillStyle(0x1f3b2a, 0.96);
    g.fillTriangle(x, y - 34 * scale, x - 20 * scale, y + 12 * scale, x + 20 * scale, y + 12 * scale);
    g.fillTriangle(x, y - 14 * scale, x - 24 * scale, y + 28 * scale, x + 24 * scale, y + 28 * scale);
    g.lineStyle(1, 0x5b7d57, 0.28);
    g.lineBetween(x, y - 24 * scale, x + 14 * scale, y + 12 * scale);
  }

  private drawDistantRuin(g: Phaser.GameObjects.Graphics, x: number, y: number, scale: number, color: number) {
    g.fillStyle(0x020617, 0.18);
    g.fillEllipse(x + 8 * scale, y + 24 * scale, 74 * scale, 18 * scale);
    g.fillStyle(color, 0.48);
    g.fillRect(x - 30 * scale, y - 4 * scale, 20 * scale, 34 * scale);
    g.fillRect(x + 10 * scale, y - 24 * scale, 18 * scale, 54 * scale);
    g.fillRect(x - 8 * scale, y + 4 * scale, 52 * scale, 12 * scale);
    g.lineStyle(2, 0x94a3b8, 0.12);
    g.lineBetween(x - 28 * scale, y - 4 * scale, x + 38 * scale, y + 18 * scale);
    g.fillStyle(0xfacc15, 0.28);
    g.fillRect(x + 16 * scale, y - 12 * scale, 5 * scale, 6 * scale);
  }

  private drawPolygon(
    g: Phaser.GameObjects.Graphics,
    points: Array<[number, number]>,
    fill: number,
    alpha: number,
    stroke?: number,
    strokeAlpha = 1,
  ) {
    g.fillStyle(fill, alpha);
    if (stroke !== undefined) g.lineStyle(2, stroke, strokeAlpha);
    g.beginPath();
    g.moveTo(points[0][0], points[0][1]);
    for (let i = 1; i < points.length; i += 1) {
      g.lineTo(points[i][0], points[i][1]);
    }
    g.closePath();
    g.fillPath();
    if (stroke !== undefined) g.strokePath();
  }

  private createPinballPipeline() {
    this.createZonePanel('发球区', '分裂 / 发射 / 落空', LAUNCH_X, TOP_Y, LAUNCH_W, TOP_H, 0x1f332e);
    this.createZonePanel('抉择区', '金币 / 法术 / 出兵 / 升级', DECISION_X, TOP_Y, DECISION_W, TOP_H, 0x222f46);
    this.createZonePanel('出兵区', '5 槽进度 + 连续挡板', UNIT_X, TOP_Y, UNIT_W, TOP_H, 0x263044);

    this.createZoneBounds(LAUNCH_X, TOP_Y, LAUNCH_W, TOP_H);
    this.createZoneBounds(DECISION_X, TOP_Y, DECISION_W, TOP_H);
    this.createZoneBounds(UNIT_X, TOP_Y, UNIT_W, TOP_H);

    this.createPegs(LAUNCH_X, TOP_Y, LAUNCH_W, [
      [0.18, 0.24], [0.42, 0.22], [0.66, 0.25], [0.84, 0.34],
      [0.28, 0.42], [0.54, 0.40], [0.76, 0.50],
      [0.18, 0.61], [0.42, 0.58], [0.66, 0.66], [0.86, 0.72],
    ]);
    this.createPegs(DECISION_X, TOP_Y, DECISION_W, [
      [0.12, 0.22], [0.31, 0.25], [0.50, 0.20], [0.69, 0.27], [0.88, 0.24],
      [0.20, 0.42], [0.39, 0.48], [0.58, 0.40], [0.78, 0.48], [0.92, 0.58],
      [0.12, 0.66], [0.30, 0.60], [0.48, 0.68], [0.66, 0.62], [0.84, 0.70],
    ]);
    this.createPegs(UNIT_X, TOP_Y, UNIT_W, [
      [0.08, 0.22], [0.22, 0.29], [0.36, 0.22], [0.50, 0.31], [0.64, 0.24], [0.78, 0.32], [0.92, 0.24],
      [0.12, 0.46], [0.26, 0.40], [0.40, 0.50], [0.54, 0.42], [0.68, 0.52], [0.82, 0.44], [0.94, 0.58],
      [0.10, 0.68], [0.24, 0.62], [0.38, 0.72], [0.52, 0.64], [0.66, 0.74], [0.80, 0.66],
    ]);

    this.createPipelineArrows();
    this.createLauncherTurret();
    this.createLaunchSlots();
    this.createDecisionSlots();
    this.createUnitSlots();
  }

  private createZonePanel(title: string, subtitle: string, x: number, y: number, w: number, h: number, color: number) {
    this.add.rectangle(x, y, w, h, color, 0.92).setOrigin(0).setStrokeStyle(3, 0x94a3b8, 0.42);
    this.add.text(x + 12, y + 9, title, this.textStyle(17, '#f8fafc'));
    this.add.text(x + 12, y + 31, subtitle, this.textStyle(11, '#b6c2d2'));
  }

  private createZoneBounds(x: number, y: number, w: number, h: number) {
    const wall = 12;
    this.matter.add.rectangle(x + w / 2, y + wall / 2, w, wall, { isStatic: true });
    this.matter.add.rectangle(x + wall / 2, y + h / 2, wall, h, { isStatic: true });
    this.matter.add.rectangle(x + w - wall / 2, y + h / 2, wall, h, { isStatic: true });
  }

  private createPegs(zoneX: number, zoneY: number, zoneW: number, points: Array<[number, number]>) {
    for (const [px, py] of points) {
      const peg = this.matter.add.image(zoneX + zoneW * px, zoneY + TOP_H * py, 'machine_peg', undefined, { isStatic: true });
      peg.setCircle(15).setStatic(true).setScale(0.55);
    }
  }

  private createPipelineArrows() {
    this.drawPipelineArrow(LAUNCH_X + LAUNCH_W + 3, TOP_Y + 108, DECISION_X - 3, TOP_Y + 108, 0x93c5fd);
    this.drawPipelineArrow(DECISION_X + DECISION_W + 3, TOP_Y + 108, UNIT_X - 3, TOP_Y + 108, 0x4ade80);
  }

  private drawPipelineArrow(x1: number, y1: number, x2: number, y2: number, color: number) {
    const g = this.add.graphics().setDepth(55);
    g.lineStyle(3, color, 0.7);
    g.lineBetween(x1, y1, x2, y2);
    g.fillStyle(color, 0.7);
    g.fillTriangle(x2, y2, x2 - 10, y2 - 7, x2 - 10, y2 + 7);
  }

  private createLauncherTurret() {
    this.launcherTurret = this.add.graphics().setDepth(70);
    this.syncLauncherTurret();
  }

  private syncLauncherTurret() {
    if (!this.launcherTurret) return;
    const baseX = LAUNCH_X + LAUNCH_W / 2;
    const baseY = TOP_Y + 14;
    const barrelLength = 36;
    const angleDeg = getSweepingLauncherAngle(this.time.now, LAUNCHER_SWEEP_CYCLE_MS);
    const radians = angleDeg * Math.PI / 180;
    const tipX = baseX + Math.sin(radians) * barrelLength;
    const tipY = baseY + Math.cos(radians) * barrelLength;

    this.launcherTurret.clear();
    this.launcherTurret.fillStyle(0x0f172a, 0.96);
    this.launcherTurret.fillRoundedRect(baseX - 29, TOP_Y + 2, 58, 16, 5);
    this.launcherTurret.lineStyle(2, 0x93c5fd, 0.72);
    this.launcherTurret.strokeRoundedRect(baseX - 29, TOP_Y + 2, 58, 16, 5);
    this.launcherTurret.lineStyle(8, 0x1e3a5f, 1);
    this.launcherTurret.lineBetween(baseX, baseY, tipX, tipY);
    this.launcherTurret.lineStyle(4, 0x93c5fd, 0.95);
    this.launcherTurret.lineBetween(baseX, baseY, tipX, tipY);
    this.launcherTurret.fillStyle(0xe0f2fe, 0.95);
    this.launcherTurret.fillCircle(tipX, tipY, 5);
    this.launcherTurret.fillStyle(0x0f172a, 1);
    this.launcherTurret.fillCircle(baseX, baseY, 9);
    this.launcherTurret.lineStyle(2, 0xbfdbfe, 0.9);
    this.launcherTurret.strokeCircle(baseX, baseY, 9);
  }

  private createLaunchSlots() {
    const slots = [
      ['split', '分裂', 0x86efac],
      ['fire', '发射', 0x93c5fd],
      ['miss', '落空', 0xfca5a5],
    ] as const;
    this.createOutcomeSlots('launch', LAUNCH_X, LAUNCH_W, slots, TOP_Y + TOP_H - 24);
  }

  private createDecisionSlots() {
    this.destroyOutcomeVisuals(this.decisionVisuals);
    this.decisionVisuals = [];
    const slots = decisionSlotDefs.map((slot) => [slot.id, slot.label, slot.color] as const);
    this.decisionVisuals = this.createOutcomeSlots('decision', DECISION_X, DECISION_W, slots, TOP_Y + TOP_H - 24);
  }

  private createOutcomeSlots(stage: BallStage, zoneX: number, zoneW: number, slots: ReadonlyArray<readonly [string, string, number]>, y: number): OutcomeVisual[] {
    const visuals: OutcomeVisual[] = [];
    const layouts = buildWeightedSlotLayouts(
      slots.map(([id]) => ({
        id,
        widthWeight: stage === 'decision' ? this.state.slots[id as SlotId].widthWeight : 1,
      })),
      zoneX,
      zoneW,
      9,
      4,
    );
    slots.forEach(([id, label, color], index) => {
      const layout = layouts[index];
      const x = layout.centerX;
      const displayLabel = stage === 'decision'
        ? `${label} x${this.state.slots[id as SlotId].widthWeight.toFixed(1)}`
        : label;
      const body = this.matter.add.rectangle(x, y + 4, layout.sensorWidth, 42, {
        isStatic: true,
        isSensor: true,
        label: `${SENSOR_LABEL_PREFIX}${stage}:${id}`,
      });
      const plate = this.add.rectangle(x, y + 4, layout.plateWidth, 42, color, 0.28).setStrokeStyle(2, color, 0.88);
      const text = this.add.text(x, y + 3, displayLabel, this.textStyle(12, '#f8fafc')).setOrigin(0.5);
      let count: Phaser.GameObjects.Text | undefined;
      if (stage === 'decision') {
        count = this.add.text(x, y + 18, '0', this.textStyle(10, '#d1d5db')).setOrigin(0.5);
      }
      visuals.push({ id, body, plate, label: text, count });
    });
    return visuals;
  }

  private destroyOutcomeVisuals(visuals: OutcomeVisual[]) {
    for (const visual of visuals) {
      this.matter.world.remove(visual.body);
      visual.plate.destroy();
      visual.label.destroy();
      visual.count?.destroy();
    }
  }

  private createUnitSlots() {
    for (const visual of this.unitSlotVisuals) {
      this.matter.world.remove(visual.body);
      visual.plate.destroy();
      visual.icon.destroy();
      visual.label.destroy();
      visual.progressBack.destroy();
      visual.progressFill.destroy();
      visual.progressText.destroy();
    }
    this.unitSlotVisuals = [];

    const slots = getCurrentRaceUnitSlotStates(this.state);
    const slotW = (UNIT_W - 20) / slots.length;
    const y = TOP_Y + TOP_H - 24;
    slots.forEach((slot, index) => {
      const x = UNIT_X + 10 + slotW * index + slotW / 2;
      const body = this.matter.add.rectangle(x, y + 4, slotW - 5, 42, {
        isStatic: true,
        isSensor: true,
        label: `${SENSOR_LABEL_PREFIX}unit:${index}`,
      });
      const unit = unitDefs[slot.unitId];
      const plate = this.add.rectangle(x, y + 4, slotW - 5, 48, 0x111827, 0.52).setStrokeStyle(2, raceDefs[this.state.currentRaceId].color, 0.75);
      const icon = this.add.image(x - slotW * 0.28, y + 3, unit.assetKey).setScale(0.2);
      const label = this.add.text(x, y - 10, slot.label, this.textStyle(11, '#f8fafc')).setOrigin(0.5);
      const progressBack = this.add.rectangle(x + slotW * 0.12, y + 10, slotW * 0.42, 5, 0x020617, 0.9);
      const progressFill = this.add.rectangle(x + slotW * 0.12 - slotW * 0.21, y + 10, 0, 4, raceDefs[this.state.currentRaceId].color, 0.95).setOrigin(0, 0.5);
      const progressText = this.add.text(x + slotW * 0.12, y + 21, `0/${slot.requirement}`, this.textStyle(10, '#dbeafe')).setOrigin(0.5);
      this.unitSlotVisuals.push({ slot, body, plate, icon, label, progressBack, progressFill, progressText });
    });

    this.unitGatePlate?.destroy();
    this.unitGateText?.destroy();
    if (this.unitGateBody) {
      this.matter.world.remove(this.unitGateBody);
      this.unitGateBody = undefined;
    }
    this.unitGatePlate = this.add.rectangle(UNIT_X + UNIT_W - 100, UNIT_GATE_Y, 200, UNIT_GATE_HEIGHT, 0x6b7280, 0.35)
      .setOrigin(0, 0.5)
      .setStrokeStyle(3, 0xe5e7eb, 0.35)
      .setDepth(50);
    this.unitGateText = this.add.text(UNIT_X + UNIT_W - 90, UNIT_GATE_Y - 28, '高阶挡板', this.textStyle(12, '#f8fafc')).setDepth(51);
    this.unitGateBodyWidth = 200;
    this.unitGateBodyHeight = UNIT_GATE_HEIGHT;
    this.unitGateBody = this.matter.add.rectangle(UNIT_X + UNIT_W - 100, UNIT_GATE_Y, this.unitGateBodyWidth, UNIT_GATE_HEIGHT, {
      isStatic: true,
      label: 'unit-high-tier-blocker',
      restitution: UNIT_GATE_RESTITUTION,
      friction: 0.02,
    });
    this.updateUnitGateVisual();
  }

  private createHud() {
    const labels = ['种族', '阶段', '我方基地', '敌方目标', '金币', '我方单位', '升级加成', '预备队', '决策统计'];
    for (let index = 0; index < labels.length; index += 1) {
      const x = 22 + index * 138;
      this.add.text(x, HUD_TOP + 10, labels[index], this.textStyle(11, '#94a3b8'));
      this.hudTexts.push(this.add.text(x, HUD_TOP + 28, '', this.textStyle(index >= 6 ? 12 : 14, '#f8fafc')));
    }
  }

  private createDebugControls() {
    const y = HUD_TOP + 54;
    this.createButton(22, y, 88, '投球', () => this.spawnLaunchBall());
    this.createButton(118, y, 98, '进抉择', () => this.spawnDecisionBall());
    this.createButton(224, y, 98, '进出兵', () => this.spawnUnitBall());
    this.createButton(330, y, 88, '切种族', () => this.toggleRace());
    this.createButton(426, y, 108, '继续阶段', () => this.startPhaseFromDebug());
    this.createButton(542, y, 108, '跳过阶段', () => this.skipPhase());
    this.createMagicToggle(658, y);
    this.createDebugUnitButtons(792, y);
  }

  private createButton(x: number, y: number, width: number, label: string, onClick: () => void) {
    const plate = this.add.rectangle(x, y, width, 26, 0x334155).setOrigin(0, 0.5).setStrokeStyle(2, 0x64748b);
    const text = this.add.text(x + width / 2, y, label, this.textStyle(12, '#f8fafc')).setOrigin(0.5);
    for (const item of [plate, text]) {
      item.setDepth(7999).setInteractive({ useHandCursor: true }).on('pointerdown', onClick);
    }
  }

  private createMagicToggle(x: number, y: number) {
    this.magicToggleButton = this.add.rectangle(x, y, 126, 26, 0x312e81).setOrigin(0, 0.5).setStrokeStyle(2, 0xc4b5fd);
    this.magicToggleText = this.add.text(x + 63, y, '', this.textStyle(12, '#f5f3ff')).setOrigin(0.5);
    for (const item of [this.magicToggleButton, this.magicToggleText]) {
      item.setDepth(7999).setInteractive({ useHandCursor: true }).on('pointerdown', () => this.toggleMagic());
    }
    this.syncMagicToggle();
  }

  private createDebugUnitButtons(x: number, y: number) {
    const buttonW = 86;
    const gap = 7;
    for (let index = 0; index < 5; index += 1) {
      const bx = x + index * (buttonW + gap);
      const plate = this.add.rectangle(bx, y, buttonW, 26, 0x12322b).setOrigin(0, 0.5).setStrokeStyle(2, 0x86efac);
      const text = this.add.text(bx + buttonW / 2, y, '', this.textStyle(11, '#dcfce7')).setOrigin(0.5);
      const spawn = () => this.spawnDebugUnit(index);
      for (const item of [plate, text]) {
        item.setDepth(7999).setInteractive({ useHandCursor: true }).on('pointerdown', spawn);
      }
      this.debugUnitButtons.push({ plate, text, slotIndex: index });
    }
    this.syncDebugUnitButtons();
  }

  private bindDomControls() {
    (window as Window & { planBAction?: (action: string) => void }).planBAction = (action: string) => {
      if (this.rewardContainer) return;
      if (action === 'drop') this.spawnLaunchBall();
      if (action === 'decision') this.spawnDecisionBall();
      if (action === 'spawn') this.spawnUnitBall();
      if (action === 'race') this.toggleRace();
      if (action === 'start') this.startPhaseFromDebug();
      if (action === 'skip') this.skipPhase();
      if (action === 'frontline') this.restoreBattleCameraFollow();
      if (action === 'magic') this.toggleMagic();
      if (action.startsWith('unit-')) this.spawnDebugUnit(Number(action.slice(5)));
    };
  }

  private spawnLaunchBall(value = 1) {
    const origin = this.getLauncherMuzzlePoint();
    const velocity = getLauncherVelocity(this.time.now, LAUNCHER_SWEEP_CYCLE_MS, LAUNCHER_SPEED);
    this.spawnBall('launch', origin.x, origin.y, value, velocity.vx, velocity.vy);
    this.lastBallDropMs = this.time.now;
  }

  private spawnLiftedLaunchBall(value = 1, point = this.getTopBandDropPoint(LAUNCH_X, LAUNCH_W)) {
    this.spawnBall('launch', point.x, point.y, value, Phaser.Math.FloatBetween(-0.55, 0.55), 1.35);
  }

  private spawnDecisionBall(value = 1, point = this.getTopBandDropPoint(DECISION_X, DECISION_W)) {
    this.spawnBall('decision', point.x, point.y, value, Phaser.Math.FloatBetween(-1.1, 1.1), 1.5);
  }

  private spawnUnitBall(value = 1, point = this.getTopBandDropPoint(UNIT_X, UNIT_W)) {
    this.spawnBall('unit', point.x, point.y, value, Phaser.Math.FloatBetween(-1.2, 1.2), 1.6);
  }

  private getLauncherMuzzlePoint() {
    const baseX = LAUNCH_X + LAUNCH_W / 2;
    const baseY = TOP_Y + 14;
    const radians = getSweepingLauncherAngle(this.time.now, LAUNCHER_SWEEP_CYCLE_MS) * Math.PI / 180;
    return {
      x: baseX + Math.sin(radians) * 42,
      y: baseY + Math.cos(radians) * 42,
    };
  }

  private getTopBandDropPoint(zoneX: number, zoneW: number) {
    return {
      x: Phaser.Math.Between(Math.round(zoneX + zoneW * 0.12), Math.round(zoneX + zoneW * 0.88)),
      y: Phaser.Math.Between(Math.round(TOP_Y + 24), Math.round(TOP_Y + TOP_H * 0.2)),
    };
  }

  private spawnBall(stage: BallStage, x: number, y: number, value: number, vx: number, vy: number) {
    const label = `${BALL_LABEL_PREFIX}${this.state.nextBallId++}`;
    const ball = this.matter.add.image(x, y, 'machine_ball', undefined, {
      label,
      restitution: 0.74,
      friction: 0.02,
      frictionAir: 0.008,
    });
    ball.setCircle(PINBALL_BALL_RADIUS).setScale(PINBALL_BALL_SCALE).setBounce(0.75).setVelocity(vx, vy);
    ball.setAngularVelocity(Phaser.Math.FloatBetween(-0.08, 0.08));
    (ball.body as MatterJS.BodyType).label = label;
    this.balls.set(label, {
      image: ball,
      stage,
      value,
      blockedGateHits: 0,
      createdAt: this.time.now,
      lastGateBounceAt: 0,
    });
  }

  private handleMatterCollision(event: any) {
    for (const pair of event.pairs ?? []) {
      const labels = [pair.bodyA?.label, pair.bodyB?.label].filter(Boolean);
      const sensorLabel = labels.find((label: string) => label.startsWith(SENSOR_LABEL_PREFIX));
      const ballLabel = labels.find((label: string) => label.startsWith(BALL_LABEL_PREFIX));
      if (!ballLabel) continue;
      const ball = this.balls.get(ballLabel);
      if (!ball) continue;
      if (sensorLabel) {
        const [, stage, outcome] = sensorLabel.split(':');
        if (stage === 'launch' && ball.stage === 'launch') {
          this.handleLaunchOutcome(ballLabel, ball, outcome);
        } else if (stage === 'decision' && ball.stage === 'decision') {
          this.handleDecisionOutcome(ballLabel, ball, outcome as SlotId);
        } else if (stage === 'unit' && ball.stage === 'unit') {
          this.handleUnitOutcome(ballLabel, ball, Number(outcome));
        }
      }
      if (this.balls.has(ballLabel) && labels.includes('unit-high-tier-blocker') && ball.stage === 'unit') {
        this.applyControlledGateBounce(ball);
      }
    }
  }

  private handleLaunchOutcome(label: string, ball: PinballBall, outcome: string) {
    const x = ball.image.x;
    const y = ball.image.y;
    this.destroyBall(label);
    if (outcome === 'split') {
      this.spawnFloatingText(x, y - 26, '分裂 x2', 0x86efac);
      const relaunches = buildLaunchSplitRelaunchPlan(ball.value).map((item) => ({
        ...item,
        point: this.getTopBandDropPoint(LAUNCH_X, LAUNCH_W),
      }));
      for (const [index, relaunch] of relaunches.entries()) {
        this.drawTransferTrail(x, y, relaunch.point.x, relaunch.point.y, 0x86efac);
        this.time.delayedCall(80 + index * 100, () => this.spawnLiftedLaunchBall(relaunch.value, relaunch.point));
      }
    } else if (outcome === 'fire') {
      this.spawnFloatingText(x, y - 26, '发射', 0x93c5fd);
      const drop = this.getTopBandDropPoint(DECISION_X, DECISION_W);
      this.drawTransferTrail(x, y, drop.x, drop.y, 0x93c5fd);
      this.spawnDecisionBall(ball.value, drop);
    } else {
      this.spawnFloatingText(x, y - 26, '落空', 0xfca5a5);
    }
  }

  private handleDecisionOutcome(label: string, ball: PinballBall, slotId: SlotId) {
    this.destroyBall(label);
    const assist = getFirstSpawnAssistPlan(this.state);
    if (assist.forceDecisionSpawn) {
      slotId = 'spawn';
      markFirstSpawnOutcomeForced(this.state);
    }
    const triggerResult = triggerSlot(this.state, slotId);
    this.slotFlashUntil.set(slotId, this.time.now + 420);
    const visual = this.decisionVisuals.find((candidate) => candidate.id === slotId);
    if (visual) {
      this.spawnFloatingText(visual.plate.x, visual.plate.y - 44, this.state.recentFloatingTexts.at(-1)?.label ?? visual.id, visual.plate.fillColor);
    }
    if (triggerResult.status === 'disabled') return;
    if (slotId === 'spawn') {
      const unitAssist = getFirstSpawnAssistPlan(this.state);
      const drop = unitAssist.forceUnitSlotIndex === undefined
        ? this.getTopBandDropPoint(UNIT_X, UNIT_W)
        : this.getUnitSlotDropPoint(unitAssist.forceUnitSlotIndex);
      this.drawTransferTrail(visual?.plate.x ?? DECISION_X + DECISION_W / 2, visual?.plate.y ?? TOP_Y + TOP_H - 20, drop.x, drop.y, 0x4ade80);
      this.spawnUnitBall(ball.value, drop);
    }
    if (slotId === 'magic') this.drawMagicFx();
  }

  private handleUnitOutcome(label: string, ball: PinballBall, slotIndex: number) {
    const assist = getFirstSpawnAssistPlan(this.state);
    if (assist.forceUnitSlotIndex !== undefined) {
      slotIndex = assist.forceUnitSlotIndex;
      markFirstUnitSlotForced(this.state);
    }
    const result = resolveUnitBallToSlot(this.state, slotIndex, ball.value, {
      elapsedMs: this.state.phaseElapsedMs,
      durationMs: phaseDefs[this.state.phaseIndex]?.durationMs,
      blockedGateHits: ball.blockedGateHits,
    });

    if (result.status === 'blocked') {
      ball.blockedGateHits = result.blockedGateHits;
      this.bounceUnitBallFromGate(ball, result.redirectSlotIndex);
      this.spawnFloatingText(ball.image.x, ball.image.y - 34, '未开放 / 弹回', 0xe5e7eb);
      return;
    }

    this.destroyBall(label);
    const slot = this.unitSlotVisuals[result.slotIndex];
    const unit = unitDefs[result.unitId];
    const recentQueueText = this.state.recentFloatingTexts.at(-1)?.label;
    const labelText = result.spawnedCount > 0 && recentQueueText?.includes('入队')
      ? recentQueueText
      : result.spawnedCount > 0 ? `${unit.name} 入队` : `${result.remainingProgress}/${slot.slot.requirement}`;
    this.spawnFloatingText(slot.plate.x, slot.plate.y - 50, labelText, raceDefs[this.state.currentRaceId].color);
  }

  private destroyBall(label: string) {
    const ball = this.balls.get(label);
    if (!ball) return;
    this.balls.delete(label);
    ball.image.destroy();
  }

  private bounceUnitBallFromGate(ball: PinballBall, redirectSlotIndex: number) {
    const target = this.getUnitSlotCenter(redirectSlotIndex);
    const forceHardRedirect = ball.blockedGateHits >= 3;
    if (forceHardRedirect) {
      ball.image.setPosition(target.x, TOP_Y + 92);
      ball.blockedGateHits = 0;
      this.spawnFloatingText(target.x, TOP_Y + 78, '导向开放槽', 0xfacc15);
    }
    const dx = (target.x - ball.image.x) * 0.02;
    ball.image.setVelocity(Phaser.Math.Clamp(dx, -4.2, -1.2), -3.4);
    ball.lastGateBounceAt = this.time.now;
  }

  private applyControlledGateBounce(ball: PinballBall) {
    const body = ball.image.body as MatterJS.BodyType | null;
    if (!body) return;
    const velocity = getControlledGateBounceVelocity({
      vx: body.velocity.x,
      vy: body.velocity.y,
    });
    ball.image.setVelocity(velocity.vx, velocity.vy);
    ball.lastGateBounceAt = this.time.now;
  }

  private getUnitSlotCenter(slotIndex: number) {
    const visual = this.unitSlotVisuals[Phaser.Math.Clamp(slotIndex, 0, this.unitSlotVisuals.length - 1)];
    return { x: visual?.plate.x ?? UNIT_X + 50, y: visual?.plate.y ?? TOP_Y + TOP_H - 24 };
  }

  private getUnitSlotDropPoint(slotIndex: number) {
    const center = this.getUnitSlotCenter(slotIndex);
    return {
      x: center.x,
      y: Phaser.Math.Between(Math.round(TOP_Y + 24), Math.round(TOP_Y + TOP_H * 0.2)),
    };
  }

  private toggleRace() {
    this.state.currentRaceId = this.state.currentRaceId === 'hive' ? 'mech' : 'hive';
    this.createUnitSlots();
    this.syncDebugUnitButtons();
    this.spawnFloatingText(DECISION_X + DECISION_W - 64, TOP_Y + 58, `已切换：${raceDefs[this.state.currentRaceId].name}`, raceDefs[this.state.currentRaceId].color);
  }

  private spawnDebugUnit(slotIndex: number) {
    const unit = spawnDebugRaceUnit(this.state, slotIndex);
    const pos = this.projectBattle(unit.x, unit.laneOffset);
    if (this.isProjectionVisible(pos, 0.24)) {
      this.spawnFloatingText(pos.x, pos.y - 56, this.state.recentFloatingTexts.at(-1)?.label ?? unitDefs[unit.defId].name, raceDefs[this.state.currentRaceId].color);
    }
  }

  private syncDebugUnitButtons() {
    const slots = raceDefs[this.state.currentRaceId].unitSlots;
    const color = raceDefs[this.state.currentRaceId].color;
    for (const button of this.debugUnitButtons) {
      const slot = slots[button.slotIndex];
      const unit = unitDefs[slot.unitId];
      const label = unit.name.length > 4 ? unit.name.slice(0, 4) : unit.name;
      button.plate.setFillStyle(0x12322b, 0.94).setStrokeStyle(2, color, 0.78);
      button.text.setText(label).setColor('#dcfce7');
    }
  }

  private toggleMagic() {
    this.state.settings.magicEnabled = !this.state.settings.magicEnabled;
    this.syncMagicToggle();
    this.spawnFloatingText(
      720,
      HUD_TOP - 18,
      this.state.settings.magicEnabled ? '法术已启用' : '法术已关闭',
      this.state.settings.magicEnabled ? 0xc084fc : 0x94a3b8,
    );
  }

  private syncMagicToggle() {
    if (!this.magicToggleButton || !this.magicToggleText) return;
    const enabled = this.state.settings.magicEnabled;
    this.magicToggleButton
      .setFillStyle(enabled ? 0x312e81 : 0x1f2937, 0.96)
      .setStrokeStyle(2, enabled ? 0xc4b5fd : 0x64748b);
    this.magicToggleText
      .setText(enabled ? '法术 开' : '法术 关')
      .setColor(enabled ? '#f5f3ff' : '#cbd5e1');
  }

  private skipPhase() {
    if (!this.state.phaseActive || this.rewardContainer || this.gameOver) return;
    this.endPhase();
  }

  private startPhaseFromDebug() {
    if (this.state.phaseActive || this.rewardContainer || this.gameOver) return;
    startPhase(this.state);
    this.spawnLaunchBall();
  }

  private endPhase() {
    completePhase(this.state, this.state.battle.bases.enemy.hp <= 0 ? 'objective' : 'timer');
    const won = this.state.battle.bases.player.hp > 0;
    if (!won || isFinalPhaseComplete(this.state)) {
      this.gameOver = true;
      this.showSummary(won ? '原型通关：核心已摧毁' : '失败：我方基地被摧毁');
      return;
    }
    this.showSummary(`阶段完成：${phaseDefs[this.state.phaseIndex].name}`);
    this.showRewards();
  }

  private showSummary(title: string) {
    this.summaryContainer?.destroy(true);
    const stats = this.state.stats.currentPhase;
    const panel = this.add.container(810, 560).setDepth(5000);
    panel.add(this.add.rectangle(0, 0, 380, 150, 0x0f172a, 0.94).setStrokeStyle(2, 0x94a3b8));
    panel.add(this.add.text(-170, -62, title, this.textStyle(17, '#f8fafc')));
    const lines = [
      `抉择 金币:${stats.slotTriggers.gold} 法术:${stats.slotTriggers.magic} 出兵:${stats.slotTriggers.spawn} 升级:${stats.slotTriggers.upgrade}`,
      `入队 ${stats.unitsQueued}  部署 ${stats.unitsSpawned}  老兵经验 ${stats.eliteXpGained}`,
      `伤害 ${stats.damageDealt}  击杀 ${stats.kills}  基地伤害 造成 ${stats.enemyBaseDamage}  承受 ${stats.playerBaseDamage}`,
    ];
    lines.forEach((line, index) => panel.add(this.add.text(-170, -30 + index * 24, line, this.textStyle(13, '#cbd5e1'))));
    this.summaryContainer = panel;
  }

  private showRewards() {
    this.rewardContainer?.destroy(true);
    this.currentRewardChoices = buildRewardChoices(this.state);
    this.rewardRerollUsed = false;
    this.renderRewardPanel();
  }

  private renderRewardPanel() {
    this.rewardContainer?.destroy(true);
    const panel = this.add.container(650, 355).setDepth(6000);
    panel.add(this.add.rectangle(0, 0, 590, 280, 0x101827, 0.96).setStrokeStyle(3, 0xf8fafc, 0.3));
    panel.add(this.add.text(-250, -104, '选择一个奖励', this.textStyle(22, '#f8fafc')));
    this.currentRewardChoices.forEach((reward, index) => {
      const cardX = -180 + index * 180;
      this.addRewardCard(panel, cardX, 25, reward);
    });
    this.addRewardRerollButton(panel);
    this.rewardContainer = panel;
  }

  private addRewardRerollButton(panel: Phaser.GameObjects.Container) {
    const cost = 10;
    const canReroll = !this.rewardRerollUsed && this.state.gold >= cost;
    const label = this.rewardRerollUsed ? '已刷新' : canReroll ? `刷新奖励 ${cost}金` : `金币不足 ${this.state.gold}/${cost}`;
    const fill = canReroll ? 0x374151 : 0x1f2937;
    const stroke = canReroll ? 0xfacc15 : 0x64748b;
    const button = this.add.rectangle(0, 116, 160, 28, fill, 0.96).setStrokeStyle(2, stroke, 0.8);
    const text = this.add.text(0, 116, label, this.textStyle(12, canReroll ? '#fef3c7' : '#94a3b8')).setOrigin(0.5);
    if (canReroll) {
      const reroll = () => {
        if (this.rewardRerollUsed) return;
        const result = rerollRewardChoices(this.state, this.currentRewardChoices, { cost });
        if (result.status !== 'rerolled') return;
        this.currentRewardChoices = result.choices;
        this.rewardRerollUsed = true;
        this.renderRewardPanel();
      };
      button.setInteractive({ useHandCursor: true }).on('pointerdown', reroll);
      text.setInteractive({ useHandCursor: true }).on('pointerdown', reroll);
    }
    panel.add(button);
    panel.add(text);
  }

  private addRewardCard(panel: Phaser.GameObjects.Container, x: number, y: number, reward: RewardDef) {
    const card = this.add.rectangle(x, y, 158, 170, 0x1e293b).setStrokeStyle(2, 0x94a3b8);
    const icon = this.add.image(x, y - 52, reward.icon).setScale(0.38);
    const name = this.add.text(x, y - 16, reward.name, this.textStyle(14, '#f8fafc')).setOrigin(0.5).setWordWrapWidth(135);
    const tag = this.add.text(x, y + 16, reward.tag, this.textStyle(12, '#facc15')).setOrigin(0.5);
    const desc = this.add.text(x, y + 42, reward.description, this.textStyle(11, '#cbd5e1')).setOrigin(0.5, 0).setWordWrapWidth(132).setAlign('center');
    const choose = () => {
      this.rewardContainer?.destroy(true);
      this.rewardContainer = undefined;
      this.summaryContainer?.destroy(true);
      this.summaryContainer = undefined;
      resumeNextPhase(this.state, reward.id);
      this.createDecisionSlots();
      this.spawnLaunchBall();
    };
    for (const item of [card, icon, name, tag, desc]) {
      item.setInteractive({ useHandCursor: true }).on('pointerdown', choose);
      panel.add(item);
    }
  }

  private syncUnitVisuals() {
    const liveIds = new Set(this.state.battle.units.map((unit) => unit.id));
    for (const [id, visual] of this.unitVisuals.entries()) {
      if (!liveIds.has(id)) {
        visual.outline.destroy();
        visual.sprite.destroy();
        visual.sideRing.destroy();
        visual.hpBack.destroy();
        visual.hpFill.destroy();
        visual.hpText.destroy();
        visual.shadow.destroy();
        this.unitVisuals.delete(id);
      }
    }

    for (const unit of this.state.battle.units) {
      let visual = this.unitVisuals.get(unit.id);
      if (!visual) {
        const def = unitDefs[unit.defId];
        const scale = this.getUnitSpriteScale(unit);
        const outline = this.add.image(0, 0, def.assetKey).setScale(scale * 1.13).setTint(0x020617).setAlpha(0.88);
        const sprite = this.add.image(0, 0, def.assetKey).setScale(scale);
        const sideRing = this.add.ellipse(0, 0, 52, 16, unit.side === 'player' ? 0x2563eb : 0xb91c1c, 0.22);
        const shadow = this.add.ellipse(0, 0, 50, 15, 0x020617, 0.32);
        const hpBack = this.add.rectangle(0, 0, 42, 5, 0x111827);
        const hpFill = this.add.rectangle(0, 0, 40, 3, unit.side === 'player' ? 0x4ade80 : 0xfb7185);
        const hpText = this.add.text(0, 0, '', this.textStyle(10, '#f8fafc')).setOrigin(0.5).setStroke('#020617', 3);
        if (this.battlefieldMask) {
          for (const item of [outline, sprite, sideRing, shadow, hpBack, hpFill, hpText]) {
            item.setMask(this.battlefieldMask);
          }
        }
        visual = { outline, sprite, sideRing, shadow, hpBack, hpFill, hpText };
        this.unitVisuals.set(unit.id, visual);
      }
      const pos = this.projectBattleUnit(unit);
      const visible = this.isProjectionVisible(pos, 0.18);
      visual.outline.setVisible(visible);
      visual.sprite.setVisible(visible);
      visual.sideRing.setVisible(visible);
      visual.shadow.setVisible(visible);
      visual.hpBack.setVisible(visible);
      visual.hpFill.setVisible(visible);
      visual.hpText.setVisible(visible);
      if (!visible) continue;
      const scale = this.getUnitSpriteScale(unit);
      const bob = Math.sin((this.time.now + unit.x) / 180) * 2;
      const hitFlash = stateTimeSince(this.state.battle.elapsedMs, unit.lastHitAtMs) < 140;
      const attackFlash = stateTimeSince(this.state.battle.elapsedMs, unit.lastAttackAtMs) < 120;
      const sideColor = unit.side === 'player' ? 0x93c5fd : 0xfca5a5;
      visual.outline.setPosition(pos.x, pos.y + bob).setScale(scale * 1.13).setDepth(pos.depth + 2);
      visual.sprite
        .setPosition(pos.x, pos.y + bob)
        .setScale(attackFlash ? scale * 1.08 : scale)
        .setTint(hitFlash ? 0xffffff : unit.isElite ? 0xfacc15 : sideColor)
        .setDepth(pos.depth + 3);
      visual.sideRing
        .setPosition(pos.x, pos.y + 24)
        .setSize(this.getUnitRingWidth(unit), 16)
        .setFillStyle(unit.side === 'player' ? 0x2563eb : 0xb91c1c, attackFlash ? 0.44 : 0.24)
        .setDepth(pos.depth + 1);
      visual.shadow.setPosition(pos.x, pos.y + 24).setDepth(pos.depth);
      visual.hpBack.setPosition(pos.x, pos.y - 36).setDepth(pos.depth + 4);
      visual.hpFill.setPosition(pos.x - 20 + 20 * Math.max(0, unit.hp / unit.maxHp), pos.y - 36).setDepth(pos.depth + 5);
      visual.hpFill.width = 40 * Math.max(0, unit.hp / unit.maxHp);
      visual.hpText
        .setText(`${Math.ceil(Math.max(0, unit.hp))}/${unit.maxHp}`)
        .setPosition(pos.x, pos.y - 48)
        .setDepth(pos.depth + 6);
    }
  }

  private getUnitSpriteScale(unit: BattleUnit) {
    const role = unitDefs[unit.defId].role;
    const roleBonus = role === 'giant' ? 0.18 : role === 'siege' ? 0.12 : role === 'frontline' ? 0.08 : 0;
    const eliteBonus = unit.isElite ? 0.1 : 0;
    return (unit.side === 'player' ? 0.51 : 0.49) + roleBonus + eliteBonus;
  }

  private getUnitRingWidth(unit: BattleUnit) {
    const role = unitDefs[unit.defId].role;
    if (role === 'giant') return 72;
    if (role === 'siege' || role === 'frontline') return 62;
    return 52;
  }

  private syncCombatFeedback() {
    this.battlefieldDynamic.clear();
    this.drawFrontlineMarker(this.battlefieldDynamic);
    this.drawBaseHitFlashes(this.battlefieldDynamic);
    this.drawActiveProjectiles(this.battlefieldDynamic);
    this.spawnNewTransientEffects();
  }

  private drawFrontlineMarker(g: Phaser.GameObjects.Graphics) {
    const ratio = getBattleContactRatio(this.state);
    if (ratio === undefined) return;
    const worldX = Phaser.Math.Linear(this.state.battle.bases.player.x, this.state.battle.bases.enemy.x, ratio);
    const p = this.getRoadPoint(worldX);
    const next = this.getRoadPoint(worldX + this.state.battle.camera.viewportWorldWidth * 0.03);
    const projected = this.projectBattle(worldX, 0);
    if (!this.isProjectionVisible(projected, 0.12)) return;
    const n = this.getRoadNormal(p, next);
    const pulse = 0.55 + Math.sin(this.time.now / 180) * 0.16;
    g.lineStyle(5, 0xf8fafc, 0.16);
    g.lineBetween(p.x - n.x * 160, p.y - n.y * 160, p.x + n.x * 160, p.y + n.y * 160);
    g.lineStyle(3, 0xfacc15, pulse);
    g.lineBetween(p.x - n.x * 132, p.y - n.y * 132, p.x + n.x * 132, p.y + n.y * 132);
    g.fillStyle(0xfacc15, 0.32);
    g.fillEllipse(p.x, p.y, 144, 30);
    g.fillStyle(0x0f172a, 0.72);
    g.fillRoundedRect(p.x - 34, p.y - 36, 68, 20, 5);
    g.lineStyle(1, 0xfacc15, 0.58);
    g.strokeRoundedRect(p.x - 34, p.y - 36, 68, 20, 5);
  }

  private drawBaseHitFlashes(g: Phaser.GameObjects.Graphics) {
    const basePoints = [
      ['player', this.state.battle.bases.player.x, 0x60a5fa],
      ['enemy', this.state.battle.bases.enemy.x, 0xf87171],
    ] as const;
    for (const [side, worldX, color] of basePoints) {
      const base = this.state.battle.bases[side];
      const age = this.state.battle.elapsedMs - base.lastHitAtMs;
      if (age > 260) continue;
      const pos = this.projectBattle(worldX, 0);
      if (!this.isProjectionVisible(pos, 0.18)) continue;
      const alpha = 1 - age / 260;
      g.lineStyle(5, color, alpha * 0.72);
      g.strokeEllipse(pos.x, pos.y + 6, 242 + age * 0.18, 66 + age * 0.05);
    }
  }

  private drawActiveProjectiles(g: Phaser.GameObjects.Graphics) {
    for (const projectile of this.state.battle.projectiles) {
      const duration = Math.max(1, projectile.impactAtMs - projectile.createdAtMs);
      const ratio = Phaser.Math.Clamp((this.state.battle.elapsedMs - projectile.createdAtMs) / duration, 0, 1);
      const from = this.projectBattle(projectile.fromX, projectile.fromLaneOffset);
      const to = this.projectBattle(projectile.toX, projectile.toLaneOffset);
      if (!this.isProjectionVisible(from, 0.2) && !this.isProjectionVisible(to, 0.2)) continue;
      const headX = Phaser.Math.Linear(from.x, to.x, ratio);
      const headY = Phaser.Math.Linear(from.y - 18, to.y - 20, ratio);
      const tailRatio = Math.max(0, ratio - 0.16);
      const tailX = Phaser.Math.Linear(from.x, to.x, tailRatio);
      const tailY = Phaser.Math.Linear(from.y - 18, to.y - 20, tailRatio);
      g.lineStyle(4, projectile.color, 0.78);
      g.lineBetween(tailX, tailY, headX, headY);
      g.fillStyle(projectile.color, 0.95);
      g.fillCircle(headX, headY, 5);
      g.lineStyle(2, 0xf8fafc, 0.34);
      g.strokeCircle(headX, headY, 7);
    }
  }

  private spawnNewTransientEffects() {
    const liveEffectIds = new Set(this.state.battle.transientEffects.map((effect) => effect.id));
    for (const id of this.renderedEffectIds) {
      if (!liveEffectIds.has(id)) this.renderedEffectIds.delete(id);
    }

    for (const effect of this.state.battle.transientEffects) {
      if (this.renderedEffectIds.has(effect.id)) continue;
      this.renderedEffectIds.add(effect.id);
      const pos = this.projectBattle(effect.x, effect.laneOffset);
      if (!this.isProjectionVisible(pos, 0.2)) continue;
      if (effect.type === 'spawn') {
        this.spawnSpawnEffect(pos.x, pos.y, effect.side);
        if (effect.side === 'player') {
          const gate = this.projectBattle(this.state.battle.bases.player.x + 72, 0);
          if (this.isProjectionVisible(gate, 0.18)) {
            this.drawTransferTrail(UNIT_X + UNIT_W * 0.32, TOP_Y + TOP_H - 26, gate.x, gate.y, 0x60a5fa);
          }
        }
      } else if (effect.type === 'hit') {
        this.spawnHitEffect(pos.x, pos.y, effect.side);
        if (effect.damage !== undefined) {
          this.spawnDamageText(pos.x, pos.y - 44, effect.damage, effect.side);
        }
      } else if (effect.type === 'death') {
        this.spawnDeathEffect(pos.x, pos.y, effect.side);
      } else {
        this.spawnHitEffect(pos.x, pos.y, effect.side);
      }
    }
  }

  private spawnSpawnEffect(x: number, y: number, side: 'player' | 'enemy') {
    const color = side === 'player' ? 0x60a5fa : 0xf87171;
    const ring = this.add.ellipse(x, y + 24, 28, 10, color, 0.5).setDepth(y + 80);
    const pillar = this.add.rectangle(x, y - 8, 12, 44, color, 0.28).setDepth(y + 79);
    this.tweens.add({ targets: ring, scaleX: 2.1, scaleY: 1.8, alpha: 0, duration: 420, onComplete: () => ring.destroy() });
    this.tweens.add({ targets: pillar, alpha: 0, y: y - 20, duration: 360, onComplete: () => pillar.destroy() });
  }

  private spawnHitEffect(x: number, y: number, side: 'player' | 'enemy') {
    const color = side === 'player' ? 0x93c5fd : 0xfb923c;
    const spark = this.add.star(x, y - 18, 6, 4, 15, color, 0.82).setDepth(y + 90);
    this.tweens.add({ targets: spark, scale: 1.8, angle: 45, alpha: 0, duration: 220, onComplete: () => spark.destroy() });
  }

  private spawnDeathEffect(x: number, y: number, side: 'player' | 'enemy') {
    const color = side === 'player' ? 0x93c5fd : 0xf87171;
    const smoke = this.add.ellipse(x, y + 8, 42, 18, 0x020617, 0.5).setDepth(y + 88);
    const burst = this.add.star(x, y - 10, 7, 8, 22, color, 0.62).setDepth(y + 89);
    this.tweens.add({ targets: smoke, scaleX: 1.8, scaleY: 1.4, alpha: 0, duration: 500, onComplete: () => smoke.destroy() });
    this.tweens.add({ targets: burst, scale: 1.5, alpha: 0, duration: 360, onComplete: () => burst.destroy() });
  }

  private syncMiniMap() {
    this.minimapDynamic.clear();
    const g = this.minimapDynamic;
    const stripX = MINIMAP_X + 18;
    const stripY = MINIMAP_Y + 48;
    const stripW = MINIMAP_W - 36;
    const stripH = 28;
    const bands = buildBattleHeatBands(this.state.battle.units, this.state.battle.bases.player.x, this.state.battle.bases.enemy.x, 24);
    for (const band of bands) {
      const bx = stripX + band.ratioStart * stripW;
      const bw = Math.max(2, (band.ratioEnd - band.ratioStart) * stripW);
      if (band.player > 0) {
        g.fillStyle(0x60a5fa, Math.min(0.82, 0.22 + band.player * 0.16));
        g.fillRect(bx, stripY + 4, bw, 8);
      }
      if (band.enemy > 0) {
        g.fillStyle(0xf87171, Math.min(0.82, 0.22 + band.enemy * 0.16));
        g.fillRect(bx, stripY + 16, bw, 8);
      }
      if (band.player > 0 && band.enemy > 0) {
        g.fillStyle(0xfacc15, 0.34);
        g.fillRoundedRect(bx, stripY - 5, bw, stripH + 10, 4);
      }
    }
    const contact = getBattleContactRatio(this.state);
    if (contact !== undefined) {
      g.fillStyle(0xfacc15, 0.72);
      g.fillRect(stripX + contact * stripW - 2, stripY - 8, 4, stripH + 16);
    }
    const viewport = this.getCurrentBattleViewport();
    const fullWidth = this.state.battle.bases.enemy.x - this.state.battle.bases.player.x;
    const viewStartRatio = (viewport.startX - this.state.battle.bases.player.x) / fullWidth;
    const viewWidthRatio = viewport.width / fullWidth;
    g.lineStyle(3, 0xf8fafc, 0.9);
    g.strokeRoundedRect(stripX + viewStartRatio * stripW, stripY - 9, viewWidthRatio * stripW, stripH + 18, 5);
    this.syncFrontlineButton();
  }

  private setCameraFromMiniMap(pointerX: number) {
    const stripX = MINIMAP_X + 18;
    const stripW = MINIMAP_W - 36;
    const ratio = Phaser.Math.Clamp((pointerX - stripX) / stripW, 0, 1);
    const playerBaseX = this.state.battle.bases.player.x;
    const enemyBaseX = this.state.battle.bases.enemy.x;
    this.setManualBattleCamera(clampBattleCameraCenter(
      Phaser.Math.Linear(playerBaseX, enemyBaseX, ratio),
      playerBaseX,
      enemyBaseX,
      this.state.battle.camera.viewportWorldWidth,
    ));
  }

  private panBattlefieldCamera(pointerDeltaX: number) {
    const camera = this.state.battle.camera;
    this.setManualBattleCamera(getPannedBattleCameraCenter({
      startCenterX: this.battlePanStartCenterX,
      pointerDeltaX,
      screenPixelWidth: Math.abs(BATTLE_SCREEN_END.x - BATTLE_SCREEN_START.x),
      playerBaseX: this.state.battle.bases.player.x,
      enemyBaseX: this.state.battle.bases.enemy.x,
      viewportWorldWidth: camera.viewportWorldWidth,
    }));
  }

  private setManualBattleCamera(centerX: number) {
    const camera = this.state.battle.camera;
    camera.centerX = centerX;
    camera.manualOverride = true;
    camera.manualUntilMs = Number.POSITIVE_INFINITY;
    this.drawBattlefieldBackdrop();
    this.syncMiniMap();
  }

  private restoreBattleCameraFollow() {
    const camera = this.state.battle.camera;
    camera.manualOverride = false;
    camera.manualUntilMs = 0;
    camera.centerX = getBattleHotspotCameraCenter({
      hotspotRatio: getBattleHotspotRatio(this.state),
      playerBaseX: this.state.battle.bases.player.x,
      enemyBaseX: this.state.battle.bases.enemy.x,
      viewportWorldWidth: camera.viewportWorldWidth,
    });
    this.drawBattlefieldBackdrop();
    this.syncMiniMap();
  }

  private syncFrontlineButton() {
    if (!this.frontlineButton || !this.frontlineButtonText || !this.cameraFollowButton || !this.cameraFollowButtonText) return;
    if (this.state.battle.camera.manualOverride) {
      this.frontlineButton.setFillStyle(0x78350f, 0.92).setStrokeStyle(1, 0xfacc15, 0.9);
      this.frontlineButtonText.setText('回前线').setColor('#fef3c7');
      this.cameraFollowButton.setFillStyle(0x78350f, 0.94).setStrokeStyle(1, 0xfacc15, 0.96);
      this.cameraFollowButtonText.setText('回前线').setColor('#fef3c7');
    } else {
      this.frontlineButton.setFillStyle(0x12322b, 0.88).setStrokeStyle(1, 0x86efac, 0.68);
      this.frontlineButtonText.setText('回前线').setColor('#dcfce7');
      this.cameraFollowButton.setFillStyle(0x12322b, 0.9).setStrokeStyle(1, 0x86efac, 0.76);
      this.cameraFollowButtonText.setText('回前线').setColor('#dcfce7');
    }
    this.syncDomCameraControls();
  }

  private syncDomCameraControls() {
    const controls = document.getElementById('camera-controls');
    const mode = document.getElementById('camera-mode');
    const follow = document.getElementById('camera-follow');
    if (!controls || !mode || !follow) return;
    controls.classList.toggle('manual', this.state.battle.camera.manualOverride);
    mode.textContent = this.state.battle.camera.manualOverride ? '手动镜头' : '自动跟随';
    follow.textContent = '回前线';
  }

  private worldXToFrontlineRatio(worldX: number) {
    const playerBaseX = this.state.battle.bases.player.x;
    const enemyBaseX = this.state.battle.bases.enemy.x;
    return (worldX - playerBaseX) / Math.max(1, enemyBaseX - playerBaseX);
  }

  private getCurrentBattleViewport() {
    return getBattleCameraViewport(
      this.state.battle.camera.centerX,
      this.state.battle.bases.player.x,
      this.state.battle.bases.enemy.x,
      this.state.battle.camera.viewportWorldWidth,
    );
  }

  private getVisibleWorldX(ratio: number) {
    const viewport = this.getCurrentBattleViewport();
    return Phaser.Math.Linear(viewport.startX, viewport.endX, ratio);
  }

  private isProjectionVisible(pos: { visibleRatio: number }, pad = 0) {
    return pos.visibleRatio >= -pad && pos.visibleRatio <= 1 + pad;
  }

  private clearBaseVisuals() {
    for (const visual of this.baseVisuals) visual.destroy();
    this.baseVisuals = [];
  }

  private updateBattleCamera(delta: number) {
    const camera = this.state.battle.camera;
    const playerBaseX = this.state.battle.bases.player.x;
    const enemyBaseX = this.state.battle.bases.enemy.x;
    camera.centerX = getNextBattleCameraCenter({
      currentCenterX: camera.centerX,
      hotspotRatio: getBattleHotspotRatio(this.state),
      playerBaseX,
      enemyBaseX,
      viewportWorldWidth: camera.viewportWorldWidth,
      deltaMs: delta,
      manualOverride: camera.manualOverride,
      manualUntilMs: camera.manualUntilMs,
      nowMs: this.time.now,
    });
  }

  private syncBases() {
    const playerRatio = this.state.battle.bases.player.hp / this.state.battle.bases.player.maxHp;
    const enemyRatio = this.state.battle.bases.enemy.hp / this.state.battle.bases.enemy.maxHp;
    this.children.getByName('bar-我方')?.destroy();
    this.children.getByName('bar-敌方')?.destroy();
    const playerPos = this.projectBattle(this.state.battle.bases.player.x, 0);
    const enemyPos = this.projectBattle(this.state.battle.bases.enemy.x, 0);
    if (this.isProjectionVisible(playerPos, 0.1)) {
      this.drawBaseBar(playerPos.x, playerPos.y + 56, playerRatio, 0x3b82f6, '我方');
    }
    if (this.isProjectionVisible(enemyPos, 0.1)) {
      this.drawBaseBar(enemyPos.x, enemyPos.y + 68, enemyRatio, 0xef4444, '敌方');
    }
  }

  private drawBaseBar(x: number, y: number, ratio: number, color: number, label: string) {
    const key = `bar-${label}`;
    const existing = this.children.getByName(key);
    existing?.destroy();
    const safeRatio = Phaser.Math.Clamp(ratio, 0, 1);
    const warning = safeRatio <= 0.25;
    const barColor = warning ? 0xfacc15 : color;
    const group = this.add.container(x, y).setName(key).setDepth(4800);
    group.add(this.add.rectangle(0, 0, 126, 20, 0x0f172a, 0.92).setStrokeStyle(2, barColor, warning ? 0.95 : 0.7));
    group.add(this.add.rectangle(12, 0, 76, 8, 0x111827, 1).setStrokeStyle(1, 0x94a3b8, 0.42));
    group.add(this.add.rectangle(-26, 0, 76 * safeRatio, 5, barColor, 0.92).setOrigin(0, 0.5));
    group.add(this.add.text(-54, -7, label, this.textStyle(10, '#dbeafe')));
    group.add(this.add.text(24, -7, `${Math.round(safeRatio * 100)}%`, this.textStyle(13, '#f8fafc')));
  }

  private projectBattle(worldX: number, laneOffset: number) {
    return projectBattlePoint({
      worldX,
      laneOffset,
      cameraCenterX: this.state.battle.camera.centerX,
      playerBaseX: this.state.battle.bases.player.x,
      enemyBaseX: this.state.battle.bases.enemy.x,
      screenStart: BATTLE_SCREEN_START,
      screenEnd: BATTLE_SCREEN_END,
      viewportWorldWidth: this.state.battle.camera.viewportWorldWidth,
    });
  }

  private projectBattleUnit(unit: BattleUnit) {
    return clampBattleProjectionToBounds(this.projectBattle(unit.x, unit.laneOffset), {
      left: 0,
      right: GAME_W,
      top: BATTLE_Y,
      bottom: BATTLE_Y + BATTLE_H,
      topPadding: BATTLE_UNIT_TOP_PADDING,
      bottomPadding: BATTLE_UNIT_BOTTOM_PADDING,
      horizontalPadding: BATTLE_UNIT_HORIZONTAL_PADDING,
    });
  }

  private cleanupLostBalls() {
    for (const [label, ball] of this.balls.entries()) {
      const img = ball.image;
      if (img.y > TOP_Y + TOP_H + 44 || img.x < -60 || img.x > GAME_W + 60) {
        if (ball.stage === 'launch') this.handleLaunchOutcome(label, ball, 'miss');
        else this.destroyBall(label);
      }
    }
  }

  private nudgeBalls() {
    const boundaryX = this.getOpenBoundaryX();
    for (const ball of this.balls.values()) {
      const body = ball.image.body as MatterJS.BodyType | null;
      if (!body) continue;
      const age = this.time.now - ball.createdAt;
      const stillInBlockerLane = ball.image.y < UNIT_SLOT_TOP_Y + PINBALL_BALL_RADIUS * 3;
      if (ball.stage === 'unit' && stillInBlockerLane && ball.image.x > boundaryX && this.time.now - ball.lastGateBounceAt > 500) {
        ball.blockedGateHits += 1;
        this.bounceUnitBallFromGate(ball, this.getUnlockedUnitSlotCount() - 1);
      }
      const stuck = age > 1600 && Math.abs(body.velocity.y) < 0.25;
      const late = age > 4300 && ball.image.y < TOP_Y + TOP_H - 72;
      if (stuck || late) {
        const zoneCenter = this.getStageZoneCenter(ball.stage);
        const drift = ball.image.x < zoneCenter ? 0.012 : -0.012;
        ball.image.applyForce(new Phaser.Math.Vector2(drift, 0.024));
      }
      if (age > 7200 && ball.image.y < TOP_Y + TOP_H - 62) {
        ball.image.setVelocity(Phaser.Math.FloatBetween(-1.2, 1.2), 3.6);
      }
    }
  }

  private getStageZoneCenter(stage: BallStage) {
    if (stage === 'launch') return LAUNCH_X + LAUNCH_W / 2;
    if (stage === 'decision') return DECISION_X + DECISION_W / 2;
    return UNIT_X + UNIT_W / 2;
  }

  private runFirstSpawnLoopAssist() {
    if (this.state.battle.units.some((unit) => unit.side === 'player' && unit.hp > 0)) {
      markFirstSpawnLoopSeen(this.state);
      return;
    }
    const assist = getFirstSpawnAssistPlan(this.state);
    if (!assist.forceDecisionSpawn) return;
    const activeDecisionBall = [...this.balls.values()].some((ball) => ball.stage === 'decision');
    const activeUnitBall = [...this.balls.values()].some((ball) => ball.stage === 'unit');
    if (activeDecisionBall || activeUnitBall || this.state.phaseElapsedMs < 1200) return;
    const spawnVisual = this.decisionVisuals.find((visual) => visual.id === 'spawn');
    this.spawnDecisionBall(1, {
      x: spawnVisual?.plate.x ?? DECISION_X + DECISION_W / 2,
      y: TOP_Y + 28,
    });
    this.spawnFloatingText(spawnVisual?.plate.x ?? DECISION_X + DECISION_W / 2, TOP_Y + 62, '开局闭环助推', 0x4ade80);
  }

  private syncSlotFeedback(time: number) {
    for (const visual of this.decisionVisuals) {
      const slotId = visual.id as SlotId;
      visual.count?.setText(String(this.state.slots[slotId].triggerCount));
      const active = (this.slotFlashUntil.get(visual.id) ?? 0) > time;
      visual.plate.setAlpha(active ? 0.82 : 0.28);
    }
  }

  private updateUnitGateVisual() {
    if (!this.unitGatePlate || !this.unitGateText) return;
    const gate = this.getCurrentUnitGateState();
    const openX = UNIT_X + UNIT_W * gate.openBoundaryRatio;
    const right = UNIT_X + UNIT_W - 10;
    const width = Math.max(0, right - openX);
    this.unitGatePlate.setVisible(width > 4);
    this.unitGateText.setVisible(width > 38);
    this.unitGatePlate.setPosition(openX, UNIT_GATE_Y);
    this.unitGatePlate.width = width;
    this.unitGateText.setPosition(openX + 10, UNIT_GATE_Y - 28);
    this.unitGateText.setText(`高阶挡板\n开放 1-${gate.openSlotCount}/5`);
    this.updateUnitGateBody(openX, width);
  }

  private updateUnitGateBody(openX: number, width: number) {
    if (!this.unitGateBody) return;
    const body = this.unitGateBody;
    const MatterBody = this.matter.body;
    if (width <= 4) {
      const scaleX = 4 / Math.max(1, this.unitGateBodyWidth);
      MatterBody.scale(body, scaleX, 1);
      MatterBody.setPosition(body, { x: GAME_W + 80, y: UNIT_GATE_Y });
      this.unitGateBodyWidth = 4;
      return;
    }
    const scaleX = width / Math.max(1, this.unitGateBodyWidth);
    MatterBody.scale(body, scaleX, 1);
    MatterBody.setPosition(body, { x: openX + width / 2, y: UNIT_GATE_Y });
    this.unitGateBodyWidth = width;
  }

  private updateUnitSlotVisuals() {
    const unlockedCount = this.getCurrentUnitGateState().openSlotCount;
    const slotStates = getCurrentRaceUnitSlotStates(this.state);
    for (const visual of this.unitSlotVisuals) {
      const current = slotStates[visual.slot.index]?.progress ?? visual.slot.progress;
      const level = this.state.unitLevels[visual.slot.unitId] ?? 1;
      const ratio = Phaser.Math.Clamp(current / visual.slot.requirement, 0, 1);
      visual.progressFill.width = visual.progressBack.width * ratio;
      visual.progressText.setText(`${current}/${visual.slot.requirement}`);
      visual.label.setText(`${visual.slot.label} Lv${level}`);
      const unlocked = visual.slot.index < unlockedCount;
      visual.plate.setAlpha(unlocked ? 0.62 : 0.26);
      visual.icon.setAlpha(unlocked ? 1 : 0.42);
      visual.label.setAlpha(unlocked ? 1 : 0.5);
    }
  }

  private getOpenBoundaryX() {
    return UNIT_X + UNIT_W * this.getCurrentUnitGateState().openBoundaryRatio;
  }

  private getUnlockedUnitSlotCount() {
    return this.getCurrentUnitGateState().openSlotCount;
  }

  private getCurrentUnitGateState() {
    const phase = phaseDefs[this.state.phaseIndex] ?? phaseDefs.at(-1);
    return getUnitGateState(this.state.phaseElapsedMs, phase?.durationMs ?? 60000);
  }

  private flushFloatingTexts() {
    while (this.lastRecentTextIndex < this.state.recentFloatingTexts.length) {
      const item = this.state.recentFloatingTexts[this.lastRecentTextIndex++];
      this.spawnFloatingText(DECISION_X + DECISION_W + 16, TOP_Y + 54 + (this.lastRecentTextIndex % 5) * 24, item.label, item.color);
    }
  }

  private spawnFloatingText(x: number, y: number, label: string, color: number) {
    const text = this.add.text(x, y, label, this.textStyle(14, Phaser.Display.Color.IntegerToColor(color).rgba))
      .setOrigin(0.5)
      .setDepth(7000);
    this.tweens.add({
      targets: text,
      y: y - 30,
      alpha: 0,
      duration: 900,
      onComplete: () => text.destroy(),
    });
  }

  private spawnDamageText(x: number, y: number, damage: number, sourceSide: 'player' | 'enemy') {
    const color = sourceSide === 'player' ? '#fef08a' : '#fca5a5';
    const text = this.add.text(x, y, `-${damage}`, this.textStyle(15, color))
      .setOrigin(0.5)
      .setStroke('#020617', 4)
      .setDepth(7100);
    this.tweens.add({
      targets: text,
      y: y - 36,
      x: x + Phaser.Math.Between(-10, 10),
      alpha: 0,
      duration: 760,
      ease: 'Quad.easeOut',
      onComplete: () => text.destroy(),
    });
  }

  private drawMagicFx() {
    const fx = this.add.graphics().setDepth(4500);
    const centerWorldX = Phaser.Math.Linear(this.state.battle.bases.player.x, this.state.battle.bases.enemy.x, 0.58);
    const center = this.getRoadPoint(centerWorldX);
    const next = this.getRoadPoint(centerWorldX + this.state.battle.camera.viewportWorldWidth * 0.06);
    const n = this.getRoadNormal(center, next);
    fx.lineStyle(5, 0xd8b4fe, 0.95);
    fx.beginPath();
    fx.moveTo(center.x - n.x * 118, center.y - n.y * 118);
    fx.lineTo(center.x - n.x * 48, center.y - n.y * 48 - 34);
    fx.lineTo(center.x + n.x * 52, center.y + n.y * 52 + 20);
    fx.lineTo(center.x + n.x * 126, center.y + n.y * 126 - 24);
    fx.strokePath();
    this.tweens.add({ targets: fx, alpha: 0, duration: 420, onComplete: () => fx.destroy() });
  }

  private drawTransferTrail(x1: number, y1: number, x2: number, y2: number, color: number) {
    const trail = this.add.graphics().setDepth(6500);
    trail.lineStyle(4, color, 0.76);
    trail.beginPath();
    trail.moveTo(x1, y1);
    trail.lineTo((x1 + x2) / 2, Math.min(y1, y2) - 30);
    trail.lineTo(x2, y2);
    trail.strokePath();
    this.tweens.add({ targets: trail, alpha: 0, duration: 520, onComplete: () => trail.destroy() });
  }

  private updateHud() {
    if (this.hudTexts.length < 9) return;
    const race = raceDefs[this.state.currentRaceId];
    const phase = phaseDefs[this.state.phaseIndex];
    const eliteSummary = getEliteSummary(this.state);
    this.hudTexts[0].setText(race.name).setColor(`#${race.color.toString(16).padStart(6, '0')}`);
    this.hudTexts[1].setText(`${this.state.phaseIndex + 1}/${phaseDefs.length} ${this.state.phaseActive ? '推进中' : this.state.isBuildPause ? '构筑暂停' : '暂停'}`);
    this.hudTexts[2].setText(`${Math.ceil(this.state.battle.bases.player.hp)}/${this.state.battle.bases.player.maxHp}`);
    this.hudTexts[3].setText(`${Math.ceil(this.state.battle.bases.enemy.hp)}/${this.state.battle.bases.enemy.maxHp}`);
    this.hudTexts[4].setText(String(this.state.gold));
    this.hudTexts[5].setText(String(this.state.battle.units.filter((unit) => unit.side === 'player' && unit.hp > 0).length));
    this.hudTexts[6].setText(this.state.pendingSpawnLevelBonus > 0 ? `下次出兵 Lv+${this.state.pendingSpawnLevelBonus}` : '下次出兵 Lv+0');
    this.hudTexts[7].setText(`${this.getReservePreview()} 精${eliteSummary.count} Lv${eliteSummary.maxLevel}`);
    this.hudTexts[8].setText(`金${this.state.stats.currentPhase.slotTriggers.gold} 法${this.state.stats.currentPhase.slotTriggers.magic} 出${this.state.stats.currentPhase.slotTriggers.spawn} 升${this.state.stats.currentPhase.slotTriggers.upgrade}`);
    this.syncMagicToggle();
    if (!phase) this.hudTexts[1].setText('已完成');
  }

  private getReservePreview() {
    if (countQueuedUnits(this.state) === 0) return '空';
    return this.state.spawnQueue
      .filter((item) => item.side === 'player' && item.count > 0)
      .slice(0, 3)
      .map((item) => {
        const unit = unitDefs[item.unitId];
        const elite = item.isElite ? '精' : '';
        return `${unit.name}Lv${item.level}${elite}x${item.count}`;
      })
      .join(' ');
  }

  private textStyle(size: number, color: string): Phaser.Types.GameObjects.Text.TextStyle {
    return {
      color,
      fontFamily: '"PingFang SC", "Microsoft YaHei", Arial, sans-serif',
      fontSize: `${size}px`,
    };
  }
}

function stateTimeSince(nowMs: number, thenMs: number) {
  return nowMs - thenMs;
}
