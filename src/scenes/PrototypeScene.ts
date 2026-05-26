import Phaser from 'phaser';
import { phaseDefs } from '../data/phases';
import { raceDefs } from '../data/races';
import { slotDefs } from '../data/slots';
import { unitDefs } from '../data/units';
import { getEliteSummary } from '../systems/EliteSystem';
import { updateBattle } from '../systems/BattleSystem';
import { createInitialGameState } from '../systems/GameState';
import { completePhase, isFinalPhaseComplete, resumeNextPhase, shouldCompletePhase, startPhase, updatePhaseEnemySpawns } from '../systems/PhaseSystem';
import { buildRewardChoices } from '../systems/RewardSystem';
import { countQueuedUnits, updateSpawnQueue } from '../systems/SpawnQueueSystem';
import { triggerSlot } from '../systems/SlotTriggerSystem';
import {
  getCurrentRaceUnitSlots,
  getUnitGateOpenBoundaryRatio,
  resolveUnitBallToSlot,
} from '../systems/UnitSpawnProgressSystem';
import type { BallStage, BattleUnit, GameState, RaceId, RewardDef, SlotId, UnitSlotDef } from '../types/game';

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
  plate: Phaser.GameObjects.Rectangle;
  label: Phaser.GameObjects.Text;
  count?: Phaser.GameObjects.Text;
};

type UnitSlotVisual = {
  slot: UnitSlotDef;
  body: MatterJS.BodyType;
  plate: Phaser.GameObjects.Rectangle;
  icon: Phaser.GameObjects.Image;
  label: Phaser.GameObjects.Text;
  progressBack: Phaser.GameObjects.Rectangle;
  progressFill: Phaser.GameObjects.Rectangle;
  progressText: Phaser.GameObjects.Text;
};

type UnitVisual = {
  sprite: Phaser.GameObjects.Image;
  hpBack: Phaser.GameObjects.Rectangle;
  hpFill: Phaser.GameObjects.Rectangle;
  shadow: Phaser.GameObjects.Ellipse;
};

const GAME_W = 1280;
const GAME_H = 720;
const TOP_Y = 12;
const TOP_H = 225;
const HUD_H = 72;
const BATTLE_Y = TOP_Y + TOP_H + 8;
const BATTLE_H = GAME_H - BATTLE_Y - HUD_H - 8;
const HUD_TOP = GAME_H - HUD_H;

const LAUNCH_X = 14;
const LAUNCH_W = 250;
const DECISION_X = LAUNCH_X + LAUNCH_W + 10;
const DECISION_W = 350;
const UNIT_X = DECISION_X + DECISION_W + 10;
const UNIT_W = GAME_W - UNIT_X - 14;

const BALL_LABEL_PREFIX = 'ball:';
const SENSOR_LABEL_PREFIX = 'sensor:';

export class PrototypeScene extends Phaser.Scene {
  private state!: GameState;
  private balls = new Map<string, PinballBall>();
  private unitVisuals = new Map<string, UnitVisual>();
  private hudTexts: Phaser.GameObjects.Text[] = [];
  private decisionVisuals: OutcomeVisual[] = [];
  private unitSlotVisuals: UnitSlotVisual[] = [];
  private floatingGroup!: Phaser.GameObjects.Group;
  private rewardContainer?: Phaser.GameObjects.Container;
  private summaryContainer?: Phaser.GameObjects.Container;
  private unitGatePlate?: Phaser.GameObjects.Rectangle;
  private unitGateText?: Phaser.GameObjects.Text;
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
      if (shouldCompletePhase(this.state)) {
        this.endPhase();
      }
    }

    this.nudgeBalls();
    this.cleanupLostBalls();
    this.updateUnitGateVisual();
    this.updateUnitSlotVisuals();
    this.syncUnitVisuals();
    this.syncBases();
    this.syncSlotFeedback(time);
    this.flushFloatingTexts();
    this.updateHud();
  }

  private drawStaticLayout() {
    this.add.rectangle(0, 0, GAME_W, GAME_H, 0x111827).setOrigin(0);
    this.add.rectangle(0, 0, GAME_W, TOP_Y + TOP_H + 4, 0x0f172a).setOrigin(0);
    this.add.rectangle(0, HUD_TOP, GAME_W, HUD_H, 0x0b1120).setOrigin(0);

    this.drawBattlefieldBackdrop();
    this.add.text(28, BATTLE_Y + 14, '伪 2D 3/4 自动战场', this.textStyle(20, '#f8fafc')).setDepth(950);
    this.drawMiniMap();
  }

  private drawBattlefieldBackdrop() {
    const g = this.add.graphics();
    g.fillStyle(0x07111c, 1);
    g.fillRect(0, BATTLE_Y, GAME_W, BATTLE_H);

    g.fillStyle(0x0e1917, 0.96);
    g.fillRect(0, BATTLE_Y + 8, GAME_W, BATTLE_H - 16);
    g.fillStyle(0x111827, 0.36);
    g.fillRect(0, BATTLE_Y + BATTLE_H - 150, GAME_W, 150);

    this.drawPolygon(g, [
      [0, BATTLE_Y + 36], [230, BATTLE_Y + 12], [318, BATTLE_Y + 105], [196, BATTLE_Y + 176],
      [32, BATTLE_Y + 158],
    ], 0x17231f, 0.46, 0x304238, 0.22);
    this.drawPolygon(g, [
      [988, BATTLE_Y + 78], [1280, BATTLE_Y + 28], [1280, BATTLE_Y + BATTLE_H],
      [1060, BATTLE_Y + BATTLE_H - 6], [1010, BATTLE_Y + 226],
    ], 0x141b1c, 0.45, 0x334155, 0.18);
    this.drawPolygon(g, [
      [0, BATTLE_Y + BATTLE_H - 170], [270, BATTLE_Y + BATTLE_H - 238],
      [432, BATTLE_Y + BATTLE_H - 136], [268, BATTLE_Y + BATTLE_H - 28],
      [0, BATTLE_Y + BATTLE_H],
    ], 0x101b23, 0.52, 0x334155, 0.18);

    this.drawRoad(g);
    this.drawCliffsAndForest(g);
    this.drawBaseDistrict('player', 350, BATTLE_Y + BATTLE_H - 88);
    this.drawBaseDistrict('enemy', 1028, BATTLE_Y + 142);
    this.drawStaticBattleSquads();
  }

  private drawRoad(g: Phaser.GameObjects.Graphics) {
    for (let i = 0; i < 28; i += 1) {
      const t = (i + 0.5) / 28;
      const p = this.getRoadPoint(t);
      const next = this.getRoadPoint(Math.min(1, t + 0.025));
      const n = this.getRoadNormal(p, next);
      const tangent = this.getRoadTangent(p, next);
      for (let row = -2; row <= 2; row += 1) {
        if (Math.abs(row) === 2 && i % 3 === 0) continue;
        const rowOffset = row * Phaser.Math.Linear(30, 24, t) + Math.sin(i * 1.7 + row) * 4;
        const centerX = p.x + n.x * rowOffset + tangent.x * Math.sin(i + row * 2) * 8;
        const centerY = p.y + n.y * rowOffset + tangent.y * Math.sin(i + row * 2) * 8;
        const halfLength = 13 + ((i + row + 6) % 3) * 6;
        const halfWidth = row === 0 ? 12 : 9;
        this.drawPolygon(g, [
          [centerX - tangent.x * halfLength - n.x * halfWidth, centerY - tangent.y * halfLength - n.y * halfWidth],
          [centerX + tangent.x * halfLength - n.x * halfWidth, centerY + tangent.y * halfLength - n.y * halfWidth],
          [centerX + tangent.x * halfLength + n.x * halfWidth, centerY + tangent.y * halfLength + n.y * halfWidth],
          [centerX - tangent.x * halfLength + n.x * halfWidth, centerY - tangent.y * halfLength + n.y * halfWidth],
        ], (i + row) % 2 === 0 ? 0x41483b : 0x333b32, 0.34);
      }
    }

    for (let lane = -1; lane <= 1; lane += 1) {
      g.lineStyle(1, lane === 0 ? 0xb7c49d : 0x0c1115, lane === 0 ? 0.13 : 0.18);
      for (let i = 0; i < 12; i += 1) {
        const t0 = i / 12 + 0.015;
        const t1 = Math.min(1, t0 + 0.042);
        const p0 = this.getRoadPoint(t0);
        const p1 = this.getRoadPoint(t1);
        const n0 = this.getRoadNormal(p0, p1);
        const offset = lane * Phaser.Math.Linear(48, 38, t0);
        g.lineBetween(p0.x + n0.x * offset, p0.y + n0.y * offset, p1.x + n0.x * offset, p1.y + n0.y * offset);
      }
    }

    const edgeRubble = [
      [284, 526, 26], [416, 496, 18], [546, 458, 22], [700, 422, 18],
      [830, 390, 24], [936, 368, 18], [254, 414, 18], [470, 386, 22],
      [624, 352, 16], [812, 326, 20],
    ];
    for (const [x, y, s] of edgeRubble) this.drawRock(g, x, y, s);

    const cracks = [
      [366, 520, 458, 494], [550, 470, 628, 454], [707, 428, 790, 408],
      [440, 414, 520, 392], [770, 366, 838, 344], [300, 474, 370, 458],
    ];
    for (const [x1, y1, x2, y2] of cracks) {
      g.lineStyle(2, 0x0c1115, 0.18);
      g.lineBetween(x1, y1, x2, y2);
    }
  }

  private getRoadPoint(t: number) {
    return {
      x: Phaser.Math.Linear(238, 1030, t),
      y: Phaser.Math.Linear(BATTLE_Y + BATTLE_H - 92, BATTLE_Y + 118, t) - Math.sin(t * Math.PI) * 16,
    };
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
      [80, 312, 36], [126, 336, 28], [224, 296, 34], [302, 276, 30], [1036, 522, 32],
      [1130, 474, 36], [1192, 430, 28], [1044, 286, 24], [64, 590, 34], [988, 592, 32],
    ];
    for (const [x, y, s] of rocks) this.drawRock(g, x, y, s);

    const trees = [
      [62, 382, 0.82], [100, 404, 0.72], [258, 318, 0.74], [320, 306, 0.62],
      [938, 282, 0.62], [1006, 304, 0.72], [1152, 390, 0.7], [1210, 404, 0.62],
      [920, 582, 0.68], [1098, 572, 0.76], [1190, 540, 0.62],
    ];
    for (const [x, y, scale] of trees) this.drawPine(g, x, y, scale);

    g.lineStyle(4, 0x1f2937, 0.8);
    g.lineBetween(62, BATTLE_Y + BATTLE_H - 18, 280, BATTLE_Y + BATTLE_H - 92);
    g.lineBetween(946, BATTLE_Y + 92, 1228, BATTLE_Y + 40);
  }

  private drawBaseDistrict(side: 'player' | 'enemy', x: number, y: number) {
    const isPlayer = side === 'player';
    const color = isPlayer ? 0x3b82f6 : 0xef4444;
    const dark = isPlayer ? 0x0f2a4f : 0x4a1515;
    const mid = isPlayer ? 0xbfe8ff : 0xff9b7c;
    const stone = 0x263345;
    const trim = isPlayer ? 0xfbbf24 : 0xf97316;
    const g = this.add.graphics().setDepth(y - 28);

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
    const x = 20;
    const y = HUD_TOP - 128;
    const w = 202;
    const h = 104;
    const panel = this.add.graphics().setDepth(4700);
    panel.fillStyle(0x0b1118, 0.9);
    panel.fillRect(x, y, w, h);
    panel.lineStyle(2, 0x9ca3af, 0.55);
    panel.strokeRect(x, y, w, h);
    panel.fillStyle(0x17231f, 1);
    panel.fillRect(x + 10, y + 28, w - 20, h - 40);
    panel.lineStyle(7, 0x5f6f54, 0.55);
    panel.beginPath();
    panel.moveTo(x + 34, y + 88);
    panel.lineTo(x + 72, y + 72);
    panel.lineTo(x + 110, y + 58);
    panel.lineTo(x + 152, y + 40);
    panel.lineTo(x + 188, y + 28);
    panel.strokePath();
    for (let i = 0; i < 7; i += 1) {
      panel.fillStyle(0x60a5fa, 0.95);
      panel.fillCircle(x + 34 + i * 15, y + 88 - i * 7, 3);
      panel.fillStyle(0xf87171, 0.95);
      panel.fillCircle(x + 122 + i * 11, y + 52 - i * 4, 3);
    }
    this.add.text(x + 10, y + 8, '小地图', this.textStyle(15, '#f8fafc')).setDepth(4701);
    this.add.circle(x + w - 24, y + h - 28, 10, 0x111827, 0.9).setStrokeStyle(2, 0x9ca3af).setDepth(4701);
    this.add.text(x + w - 28, y + h - 36, '+', this.textStyle(18, '#dbeafe')).setDepth(4702);
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
    this.createZonePanel('抉择区', '出兵 / 金币 / 法术 / 升级 / 特殊', DECISION_X, TOP_Y, DECISION_W, TOP_H, 0x222f46);
    this.createZonePanel('出兵区', '5 槽进度 + 连续挡板', UNIT_X, TOP_Y, UNIT_W, TOP_H, 0x263044);

    this.createZoneBounds(LAUNCH_X, TOP_Y, LAUNCH_W, TOP_H);
    this.createZoneBounds(DECISION_X, TOP_Y, DECISION_W, TOP_H);
    this.createZoneBounds(UNIT_X, TOP_Y, UNIT_W, TOP_H);

    this.createPegs(LAUNCH_X, TOP_Y, LAUNCH_W, [[0.28, 0.34], [0.56, 0.30], [0.78, 0.42], [0.38, 0.58], [0.68, 0.64]]);
    this.createPegs(DECISION_X, TOP_Y, DECISION_W, [[0.18, 0.30], [0.42, 0.24], [0.66, 0.31], [0.84, 0.47], [0.30, 0.58], [0.55, 0.66], [0.76, 0.58]]);
    this.createPegs(UNIT_X, TOP_Y, UNIT_W, [[0.12, 0.28], [0.28, 0.35], [0.44, 0.27], [0.60, 0.38], [0.76, 0.30], [0.88, 0.52], [0.20, 0.58], [0.38, 0.65], [0.56, 0.56], [0.72, 0.66]]);

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

  private createLaunchSlots() {
    const slots = [
      ['split', '分裂', 0x86efac],
      ['fire', '发射', 0x93c5fd],
      ['miss', '落空', 0xfca5a5],
    ] as const;
    this.createOutcomeSlots('launch', LAUNCH_X, LAUNCH_W, slots, TOP_Y + TOP_H - 24);
  }

  private createDecisionSlots() {
    const slots = slotDefs.map((slot) => [slot.id, slot.label, slot.color] as const);
    this.decisionVisuals = this.createOutcomeSlots('decision', DECISION_X, DECISION_W, slots, TOP_Y + TOP_H - 24);
  }

  private createOutcomeSlots(stage: BallStage, zoneX: number, zoneW: number, slots: ReadonlyArray<readonly [string, string, number]>, y: number): OutcomeVisual[] {
    const visuals: OutcomeVisual[] = [];
    const slotW = (zoneW - 18) / slots.length;
    slots.forEach(([id, label, color], index) => {
      const x = zoneX + 9 + slotW * index + slotW / 2;
      this.matter.add.rectangle(x, y + 4, slotW - 4, 42, {
        isStatic: true,
        isSensor: true,
        label: `${SENSOR_LABEL_PREFIX}${stage}:${id}`,
      });
      const plate = this.add.rectangle(x, y + 4, slotW - 5, 42, color, 0.28).setStrokeStyle(2, color, 0.88);
      const text = this.add.text(x, y + 3, label, this.textStyle(12, '#f8fafc')).setOrigin(0.5);
      let count: Phaser.GameObjects.Text | undefined;
      if (stage === 'decision') {
        count = this.add.text(x, y + 18, '0', this.textStyle(10, '#d1d5db')).setOrigin(0.5);
      }
      visuals.push({ id, plate, label: text, count });
    });
    return visuals;
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

    const slots = getCurrentRaceUnitSlots(this.state);
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
    this.unitGatePlate = this.add.rectangle(UNIT_X + UNIT_W - 100, TOP_Y + 96, 200, 122, 0x6b7280, 0.35)
      .setOrigin(0, 0.5)
      .setStrokeStyle(3, 0xe5e7eb, 0.35)
      .setDepth(50);
    this.unitGateText = this.add.text(UNIT_X + UNIT_W - 90, TOP_Y + 48, '高阶挡板', this.textStyle(12, '#f8fafc')).setDepth(51);
    this.updateUnitGateVisual();
  }

  private createHud() {
    const labels = ['种族', '阶段', '我方基地', '敌方目标', '金币', '我方单位', '预备队/精英', '决策统计'];
    for (let index = 0; index < labels.length; index += 1) {
      const x = 22 + index * 155;
      this.add.text(x, HUD_TOP + 10, labels[index], this.textStyle(11, '#94a3b8'));
      this.hudTexts.push(this.add.text(x, HUD_TOP + 28, '', this.textStyle(15, '#f8fafc')));
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
  }

  private createButton(x: number, y: number, width: number, label: string, onClick: () => void) {
    const plate = this.add.rectangle(x, y, width, 26, 0x334155).setOrigin(0, 0.5).setStrokeStyle(2, 0x64748b);
    const text = this.add.text(x + width / 2, y, label, this.textStyle(12, '#f8fafc')).setOrigin(0.5);
    for (const item of [plate, text]) {
      item.setDepth(7999).setInteractive({ useHandCursor: true }).on('pointerdown', onClick);
    }
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
    };
  }

  private spawnLaunchBall(value = 1) {
    this.spawnBall('launch', LAUNCH_X + LAUNCH_W * 0.5, TOP_Y + 54, value, Phaser.Math.FloatBetween(-1.2, 1.2), 1.6);
    this.lastBallDropMs = this.time.now;
  }

  private spawnDecisionBall(value = 1) {
    this.spawnBall('decision', DECISION_X + DECISION_W * 0.5 + Phaser.Math.Between(-40, 40), TOP_Y + 54, value, Phaser.Math.FloatBetween(-1.1, 1.1), 1.5);
  }

  private spawnUnitBall(value = 1) {
    this.spawnBall('unit', UNIT_X + UNIT_W * 0.28 + Phaser.Math.Between(-70, 70), TOP_Y + 54, value, Phaser.Math.FloatBetween(-1.2, 1.2), 1.6);
  }

  private spawnBall(stage: BallStage, x: number, y: number, value: number, vx: number, vy: number) {
    const label = `${BALL_LABEL_PREFIX}${this.state.nextBallId++}`;
    const ball = this.matter.add.image(x, y, 'machine_ball', undefined, {
      label,
      restitution: 0.74,
      friction: 0.02,
      frictionAir: 0.008,
    });
    ball.setCircle(15).setScale(0.48).setBounce(0.75).setVelocity(vx, vy);
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
      if (!sensorLabel || !ballLabel) continue;
      const ball = this.balls.get(ballLabel);
      if (!ball) continue;
      const [, stage, outcome] = sensorLabel.split(':');
      if (stage === 'launch' && ball.stage === 'launch') {
        this.handleLaunchOutcome(ballLabel, ball, outcome);
      } else if (stage === 'decision' && ball.stage === 'decision') {
        this.handleDecisionOutcome(ballLabel, ball, outcome as SlotId);
      } else if (stage === 'unit' && ball.stage === 'unit') {
        this.handleUnitOutcome(ballLabel, ball, Number(outcome));
      }
    }
  }

  private handleLaunchOutcome(label: string, ball: PinballBall, outcome: string) {
    const x = ball.image.x;
    const y = ball.image.y;
    this.destroyBall(label);
    if (outcome === 'split') {
      this.spawnFloatingText(x, y - 26, '分裂 x2', 0x86efac);
      this.time.delayedCall(80, () => this.spawnDecisionBall(ball.value));
      this.time.delayedCall(180, () => this.spawnDecisionBall(ball.value));
    } else if (outcome === 'fire') {
      this.spawnFloatingText(x, y - 26, '发射', 0x93c5fd);
      this.spawnDecisionBall(ball.value);
    } else {
      this.spawnFloatingText(x, y - 26, '落空', 0xfca5a5);
    }
  }

  private handleDecisionOutcome(label: string, ball: PinballBall, slotId: SlotId) {
    this.destroyBall(label);
    triggerSlot(this.state, slotId);
    this.slotFlashUntil.set(slotId, this.time.now + 420);
    const visual = this.decisionVisuals.find((candidate) => candidate.id === slotId);
    if (visual) {
      this.spawnFloatingText(visual.plate.x, visual.plate.y - 44, this.state.recentFloatingTexts.at(-1)?.label ?? visual.id, visual.plate.fillColor);
    }
    if (slotId === 'spawn') {
      this.spawnUnitBall(ball.value);
    }
    if (slotId === 'magic') this.drawMagicFx();
  }

  private handleUnitOutcome(label: string, ball: PinballBall, slotIndex: number) {
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
    const labelText = result.spawnedCount > 0 ? `${unit.name} 入队` : `${result.remainingProgress}/${slot.slot.requirement}`;
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

  private getUnitSlotCenter(slotIndex: number) {
    const visual = this.unitSlotVisuals[Phaser.Math.Clamp(slotIndex, 0, this.unitSlotVisuals.length - 1)];
    return { x: visual?.plate.x ?? UNIT_X + 50, y: visual?.plate.y ?? TOP_Y + TOP_H - 24 };
  }

  private toggleRace() {
    this.state.currentRaceId = this.state.currentRaceId === 'hive' ? 'mech' : 'hive';
    this.createUnitSlots();
    this.spawnFloatingText(DECISION_X + DECISION_W - 64, TOP_Y + 58, `已切换：${raceDefs[this.state.currentRaceId].name}`, raceDefs[this.state.currentRaceId].color);
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
      `抉择 出兵:${stats.slotTriggers.spawn} 金币:${stats.slotTriggers.gold} 法术:${stats.slotTriggers.magic} 升级:${stats.slotTriggers.upgrade} 特殊:${stats.slotTriggers.special}`,
      `入队 ${stats.unitsQueued}  部署 ${stats.unitsSpawned}  老兵经验 ${stats.eliteXpGained}`,
      `伤害 ${stats.damageDealt}  击杀 ${stats.kills}  基地伤害 造成 ${stats.enemyBaseDamage}  承受 ${stats.playerBaseDamage}`,
    ];
    lines.forEach((line, index) => panel.add(this.add.text(-170, -30 + index * 24, line, this.textStyle(13, '#cbd5e1'))));
    this.summaryContainer = panel;
  }

  private showRewards() {
    this.rewardContainer?.destroy(true);
    const choices = buildRewardChoices(this.state);
    const panel = this.add.container(650, 355).setDepth(6000);
    panel.add(this.add.rectangle(0, 0, 560, 250, 0x101827, 0.96).setStrokeStyle(3, 0xf8fafc, 0.3));
    panel.add(this.add.text(-250, -104, '选择一个奖励', this.textStyle(22, '#f8fafc')));
    choices.forEach((reward, index) => {
      const cardX = -180 + index * 180;
      this.addRewardCard(panel, cardX, 25, reward);
    });
    this.rewardContainer = panel;
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
        visual.sprite.destroy();
        visual.hpBack.destroy();
        visual.hpFill.destroy();
        visual.shadow.destroy();
        this.unitVisuals.delete(id);
      }
    }

    for (const unit of this.state.battle.units) {
      let visual = this.unitVisuals.get(unit.id);
      if (!visual) {
        const def = unitDefs[unit.defId];
        const sprite = this.add.image(0, 0, def.assetKey).setScale(unit.isElite ? 0.5 : unit.side === 'player' ? 0.4 : 0.37);
        if (unit.isElite) sprite.setTint(0xfacc15);
        const shadow = this.add.ellipse(0, 0, 38, 12, 0x020617, 0.28);
        const hpBack = this.add.rectangle(0, 0, 42, 5, 0x111827);
        const hpFill = this.add.rectangle(0, 0, 40, 3, unit.side === 'player' ? 0x4ade80 : 0xfb7185);
        visual = { sprite, shadow, hpBack, hpFill };
        this.unitVisuals.set(unit.id, visual);
      }
      const pos = this.projectBattle(unit.x, unit.laneOffset);
      visual.sprite.setPosition(pos.x, pos.y + Math.sin((this.time.now + unit.x) / 180) * 2).setDepth(pos.depth + 3);
      visual.shadow.setPosition(pos.x, pos.y + 24).setDepth(pos.depth);
      visual.hpBack.setPosition(pos.x, pos.y - 36).setDepth(pos.depth + 4);
      visual.hpFill.setPosition(pos.x - 20 + 20 * Math.max(0, unit.hp / unit.maxHp), pos.y - 36).setDepth(pos.depth + 5);
      visual.hpFill.width = 40 * Math.max(0, unit.hp / unit.maxHp);
    }
  }

  private syncBases() {
    const playerRatio = this.state.battle.bases.player.hp / this.state.battle.bases.player.maxHp;
    const enemyRatio = this.state.battle.bases.enemy.hp / this.state.battle.bases.enemy.maxHp;
    this.drawBaseBar(350, BATTLE_Y + BATTLE_H - 30, playerRatio, 0x3b82f6, '我方');
    this.drawBaseBar(1028, BATTLE_Y + 222, enemyRatio, 0xef4444, '敌方');
  }

  private drawBaseBar(x: number, y: number, ratio: number, color: number, label: string) {
    const key = `bar-${x}-${y}`;
    const existing = this.children.getByName(key);
    existing?.destroy();
    const group = this.add.container(x, y).setName(key).setDepth(4800);
    group.add(this.add.rectangle(0, 0, 126, 20, 0x0f172a, 0.92).setStrokeStyle(2, color, 0.7));
    group.add(this.add.rectangle(12, 0, 76, 8, 0x111827, 1).setStrokeStyle(1, 0x94a3b8, 0.42));
    group.add(this.add.rectangle(-26, 0, 76 * ratio, 5, color, 0.92).setOrigin(0, 0.5));
    group.add(this.add.text(-54, -7, label, this.textStyle(10, '#dbeafe')));
    group.add(this.add.text(24, -7, `${Math.round(ratio * 100)}%`, this.textStyle(13, '#f8fafc')));
  }

  private projectBattle(worldX: number, laneOffset: number) {
    const x = 148 + worldX * 1.24;
    const y = BATTLE_Y + BATTLE_H - 92 - worldX * 0.27 + laneOffset * 0.72;
    return { x, y, depth: y };
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
      if (ball.stage === 'unit' && ball.image.x > boundaryX && this.time.now - ball.lastGateBounceAt > 500) {
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
    const openX = this.getOpenBoundaryX();
    const right = UNIT_X + UNIT_W - 10;
    const width = Math.max(0, right - openX);
    this.unitGatePlate.setVisible(width > 4);
    this.unitGateText.setVisible(width > 38);
    this.unitGatePlate.setPosition(openX, TOP_Y + 100);
    this.unitGatePlate.width = width;
    this.unitGateText.setPosition(openX + 10, TOP_Y + 48);
  }

  private updateUnitSlotVisuals() {
    const unlockedCount = this.getUnlockedUnitSlotCount();
    for (const visual of this.unitSlotVisuals) {
      const current = this.state.unitSlotProgress[visual.slot.unitId] ?? 0;
      const ratio = Phaser.Math.Clamp(current / visual.slot.requirement, 0, 1);
      visual.progressFill.width = visual.progressBack.width * ratio;
      visual.progressText.setText(`${current}/${visual.slot.requirement}`);
      const unlocked = visual.slot.index < unlockedCount;
      visual.plate.setAlpha(unlocked ? 0.62 : 0.26);
      visual.icon.setAlpha(unlocked ? 1 : 0.42);
      visual.label.setAlpha(unlocked ? 1 : 0.5);
    }
  }

  private getOpenBoundaryX() {
    const phase = phaseDefs[this.state.phaseIndex] ?? phaseDefs.at(-1);
    const ratio = getUnitGateOpenBoundaryRatio(this.state.phaseElapsedMs, phase?.durationMs ?? 60000);
    return UNIT_X + UNIT_W * ratio;
  }

  private getUnlockedUnitSlotCount() {
    const phase = phaseDefs[this.state.phaseIndex] ?? phaseDefs.at(-1);
    const ratio = getUnitGateOpenBoundaryRatio(this.state.phaseElapsedMs, phase?.durationMs ?? 60000);
    return Phaser.Math.Clamp(Math.floor(ratio * 5 + 0.00001), 1, 5);
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

  private drawMagicFx() {
    const fx = this.add.graphics().setDepth(4500);
    fx.lineStyle(5, 0xd8b4fe, 0.95);
    fx.beginPath();
    fx.moveTo(720, BATTLE_Y + 160);
    fx.lineTo(780, BATTLE_Y + 128);
    fx.lineTo(840, BATTLE_Y + 174);
    fx.lineTo(905, BATTLE_Y + 132);
    fx.strokePath();
    this.tweens.add({ targets: fx, alpha: 0, duration: 420, onComplete: () => fx.destroy() });
  }

  private updateHud() {
    if (this.hudTexts.length < 8) return;
    const race = raceDefs[this.state.currentRaceId];
    const phase = phaseDefs[this.state.phaseIndex];
    const eliteSummary = getEliteSummary(this.state);
    this.hudTexts[0].setText(race.name).setColor(`#${race.color.toString(16).padStart(6, '0')}`);
    this.hudTexts[1].setText(`${this.state.phaseIndex + 1}/${phaseDefs.length} ${this.state.phaseActive ? '推进中' : this.state.isBuildPause ? '构筑暂停' : '暂停'}`);
    this.hudTexts[2].setText(`${Math.ceil(this.state.battle.bases.player.hp)}/${this.state.battle.bases.player.maxHp}`);
    this.hudTexts[3].setText(`${Math.ceil(this.state.battle.bases.enemy.hp)}/${this.state.battle.bases.enemy.maxHp}`);
    this.hudTexts[4].setText(String(this.state.gold));
    this.hudTexts[5].setText(String(this.state.battle.units.filter((unit) => unit.side === 'player' && unit.hp > 0).length));
    this.hudTexts[6].setText(`队${countQueuedUnits(this.state)} 精${eliteSummary.count} Lv${eliteSummary.maxLevel}`);
    this.hudTexts[7].setText(`出${this.state.stats.currentPhase.slotTriggers.spawn} 金${this.state.stats.currentPhase.slotTriggers.gold} 法${this.state.stats.currentPhase.slotTriggers.magic} 升${this.state.stats.currentPhase.slotTriggers.upgrade} 特${this.state.stats.currentPhase.slotTriggers.special}`);
    if (!phase) this.hudTexts[1].setText('已完成');
  }

  private textStyle(size: number, color: string): Phaser.Types.GameObjects.Text.TextStyle {
    return {
      color,
      fontFamily: '"PingFang SC", "Microsoft YaHei", Arial, sans-serif',
      fontSize: `${size}px`,
    };
  }
}
