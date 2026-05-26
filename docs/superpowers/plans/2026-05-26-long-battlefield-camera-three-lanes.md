# Long Battlefield Camera And Soft Three Lanes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a longer diagonal battlefield with camera viewport, a horizontal minimap battle-line strip, and deterministic soft three-lane auto-combat.

**Architecture:** Keep battle simulation deterministic and mostly one-dimensional, but add a soft lane identifier and lane-aware targeting. Put camera, projection, minimap heat, and viewport math in a small pure system file so Phaser rendering can stay focused on drawing and input. `PrototypeScene` will consume these helpers to draw a longer battlefield segment and an interactive minimap strip.

**Tech Stack:** Vite, TypeScript, Phaser, Vitest.

---

## File Structure

- Modify `src/types/game.ts`: add `BattleLaneId`, `BattleLaneWeights`, lane-aware unit fields, and `BattleCameraState`.
- Modify `src/data/units.ts`: add `aggroRange` and `laneWeights` to each unit.
- Modify `src/systems/BattleSystem.ts`: deterministic lane selection, lane offsets, lane-aware target choice, hotspot/frontline helpers.
- Create `src/systems/BattlefieldViewSystem.ts`: pure camera clamp, projection, minimap heat, and viewport conversion helpers.
- Modify `src/systems/GameState.ts`: initialize longer battlefield base positions and camera state.
- Modify `src/scenes/PrototypeScene.ts`: draw long battlefield through camera projection, replace minimap rectangle with battle-line strip, add click/drag camera input.
- Modify `src/systems/prototypeRules.test.ts`: tests for lane weights, lane-aware targeting, camera math, heat map, and existing behavior.
- Modify `docs/PROGRESS.md`: add a checkpoint entry after implementation.

## Task 1: Add Battle Lane Data Model

**Files:**
- Modify: `src/types/game.ts`
- Modify: `src/data/units.ts`
- Test: `src/systems/prototypeRules.test.ts`

- [ ] **Step 1: Write the failing test**

Add this test in the `battle simulation` describe block:

```ts
it('defines lane weights and aggro ranges for every battle unit', () => {
  for (const unit of Object.values(unitDefs)) {
    expect(unit.aggroRange).toBeGreaterThanOrEqual(unit.attackRange);
    expect(unit.laneWeights.top + unit.laneWeights.middle + unit.laneWeights.bottom).toBeGreaterThan(0);
  }
  expect(unitDefs.hive_grub.laneWeights.middle).toBeGreaterThan(0);
  expect(unitDefs.hive_behemoth.laneWeights.middle).toBeGreaterThan(unitDefs.hive_behemoth.laneWeights.top);
  expect(unitDefs.mech_gunner.aggroRange).toBeGreaterThan(unitDefs.mech_gunner.attackRange);
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `npm test -- src/systems/prototypeRules.test.ts`

Expected: FAIL because `aggroRange` and `laneWeights` do not exist on `UnitDef`.

- [ ] **Step 3: Add lane types and fields**

In `src/types/game.ts`, add:

```ts
export type BattleLaneId = 'top' | 'middle' | 'bottom';

export interface BattleLaneWeights {
  top: number;
  middle: number;
  bottom: number;
}
```

Extend `UnitDef` with:

```ts
  aggroRange: number;
  laneWeights: BattleLaneWeights;
```

Extend `BattleUnit` with:

```ts
  battleLane: BattleLaneId;
```

- [ ] **Step 4: Add unit data**

In `src/data/units.ts`, add `aggroRange` and `laneWeights` to every unit. Use these first-pass values:

```ts
// hive_grub
aggroRange: 70,
laneWeights: { top: 3, middle: 4, bottom: 3 },

// hive_spitter
aggroRange: 150,
laneWeights: { top: 4, middle: 2, bottom: 4 },

// hive_carapace
aggroRange: 78,
laneWeights: { top: 2, middle: 6, bottom: 2 },

// hive_brood_guard
aggroRange: 84,
laneWeights: { top: 2, middle: 7, bottom: 2 },

// hive_behemoth
aggroRange: 100,
laneWeights: { top: 1, middle: 8, bottom: 1 },

// mech_drone
aggroRange: 76,
laneWeights: { top: 3, middle: 4, bottom: 3 },

// mech_gunner
aggroRange: 160,
laneWeights: { top: 4, middle: 2, bottom: 4 },

// mech_walker
aggroRange: 88,
laneWeights: { top: 2, middle: 6, bottom: 2 },

// mech_siege_crawler
aggroRange: 146,
laneWeights: { top: 2, middle: 7, bottom: 2 },

// mech_titan
aggroRange: 112,
laneWeights: { top: 1, middle: 8, bottom: 1 },

// enemy_raider
aggroRange: 70,
laneWeights: { top: 3, middle: 4, bottom: 3 },

// enemy_shooter
aggroRange: 142,
laneWeights: { top: 4, middle: 2, bottom: 4 },

// enemy_brute
aggroRange: 86,
laneWeights: { top: 2, middle: 6, bottom: 2 },
```

- [ ] **Step 5: Run test to verify it passes**

Run: `npm test -- src/systems/prototypeRules.test.ts`

Expected: PASS for the new lane data test.

## Task 2: Implement Deterministic Soft-Lane Spawning

**Files:**
- Modify: `src/systems/BattleSystem.ts`
- Modify: `src/types/game.ts`
- Test: `src/systems/prototypeRules.test.ts`

- [ ] **Step 1: Write the failing test**

Add this test in `battle simulation`:

```ts
it('assigns a deterministic soft battle lane when units spawn', () => {
  const first = createInitialGameState('hive', 101);
  const second = createInitialGameState('hive', 101);

  const firstUnits = Array.from({ length: 8 }, () => spawnBattleUnit(first, 'player', 'hive_grub').battleLane);
  const secondUnits = Array.from({ length: 8 }, () => spawnBattleUnit(second, 'player', 'hive_grub').battleLane);

  expect(firstUnits).toEqual(secondUnits);
  expect(new Set(firstUnits).size).toBeGreaterThan(1);

  const behemoth = spawnBattleUnit(createInitialGameState('hive', 12), 'player', 'hive_behemoth');
  expect(['top', 'middle', 'bottom']).toContain(behemoth.battleLane);
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `npm test -- src/systems/prototypeRules.test.ts`

Expected: FAIL because spawned units do not have `battleLane`.

- [ ] **Step 3: Add lane selection helpers**

In `src/systems/BattleSystem.ts`, import `BattleLaneId` and `BattleLaneWeights`, then add:

```ts
const BATTLE_LANE_OFFSETS: Record<BattleLaneId, number> = {
  top: -74,
  middle: 0,
  bottom: 74,
};

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
```

Replace the old `LaneName`-based `getBattleLaneOffset()` body with this new version.

- [ ] **Step 4: Use lane selection in spawn**

In `spawnBattleUnit()`, after calculating jitter:

```ts
const lanePick = pickBattleLane(jitter.seed, def.laneWeights);
state.seed = lanePick.seed;
```

Set unit fields:

```ts
battleLane: lanePick.lane,
laneOffset: getBattleLaneOffset(lanePick.lane, jitter.value),
```

- [ ] **Step 5: Run test to verify it passes**

Run: `npm test -- src/systems/prototypeRules.test.ts`

Expected: PASS for deterministic soft battle lane spawning.

## Task 3: Make Targeting Lane-Aware

**Files:**
- Modify: `src/systems/BattleSystem.ts`
- Test: `src/systems/prototypeRules.test.ts`

- [ ] **Step 1: Write the failing test**

Add this test in `battle simulation`:

```ts
it('uses aggro range and lane distance when choosing targets', () => {
  const state = createInitialGameState('mech', 202);
  const attacker = spawnBattleUnit(state, 'player', 'mech_drone');
  const farSameLane = spawnBattleUnit(state, 'enemy', 'enemy_raider');
  const nearAdjacentLane = spawnBattleUnit(state, 'enemy', 'enemy_raider');

  attacker.x = 400;
  attacker.battleLane = 'middle';
  attacker.laneOffset = 0;
  farSameLane.x = 455;
  farSameLane.battleLane = 'middle';
  farSameLane.laneOffset = 0;
  nearAdjacentLane.x = 430;
  nearAdjacentLane.battleLane = 'top';
  nearAdjacentLane.laneOffset = -74;
  nearAdjacentLane.hp = 12;

  updateBattle(state, 100);

  expect(nearAdjacentLane.hp).toBeLessThan(12);
  expect(farSameLane.hp).toBe(farSameLane.maxHp);
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `npm test -- src/systems/prototypeRules.test.ts`

Expected: FAIL because targeting currently uses only `x` distance and prefers same-axis ordering.

- [ ] **Step 3: Add lane-aware distance helpers**

In `src/systems/BattleSystem.ts`, add:

```ts
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
```

- [ ] **Step 4: Update target selection and attack checks**

Replace `findTarget()` with:

```ts
function findTarget(state: GameState, unit: BattleUnit, enemySide: Side): BattleUnit | undefined {
  return state.battle.units
    .filter((candidate) => candidate.side === enemySide && candidate.hp > 0 && isInAggroRange(unit, candidate))
    .sort((a, b) => getTargetDistance(unit, a) - getTargetDistance(unit, b))[0];
}
```

In `updateBattle()`, replace target attack range checks with:

```ts
if (target && isInAttackRange(unit, target)) {
  attackUnit(state, unit, target);
  continue;
}
```

Do not keep the old `attackRange + 6` fallback.

- [ ] **Step 5: Run test to verify it passes**

Run: `npm test -- src/systems/prototypeRules.test.ts`

Expected: PASS for lane-aware target choice.

## Task 4: Add Battlefield Camera And Minimap Math

**Files:**
- Create: `src/systems/BattlefieldViewSystem.ts`
- Modify: `src/types/game.ts`
- Modify: `src/systems/GameState.ts`
- Test: `src/systems/prototypeRules.test.ts`

- [ ] **Step 1: Write the failing tests**

Add imports:

```ts
import {
  buildBattleHeatBands,
  clampBattleCameraCenter,
  getBattleCameraViewport,
  getBattleHotspotRatio,
  projectBattlePoint,
} from './BattlefieldViewSystem';
```

Add tests:

```ts
describe('battlefield view rules', () => {
  it('clamps camera viewport inside the long battle axis', () => {
    expect(clampBattleCameraCenter(0, 70, 1670, 640)).toBe(390);
    expect(clampBattleCameraCenter(1700, 70, 1670, 640)).toBe(1350);
    expect(getBattleCameraViewport(710, 70, 1670, 640)).toEqual({ startX: 390, endX: 1030, width: 640 });
  });

  it('projects world points relative to camera center', () => {
    const center = projectBattlePoint({
      worldX: 710,
      laneOffset: 0,
      cameraCenterX: 710,
      playerBaseX: 70,
      enemyBaseX: 1670,
      screenStart: { x: 170, y: 620 },
      screenEnd: { x: 1110, y: 260 },
      viewportWorldWidth: 640,
    });
    const right = projectBattlePoint({
      worldX: 1030,
      laneOffset: 0,
      cameraCenterX: 710,
      playerBaseX: 70,
      enemyBaseX: 1670,
      screenStart: { x: 170, y: 620 },
      screenEnd: { x: 1110, y: 260 },
      viewportWorldWidth: 640,
    });
    expect(center.x).toBeCloseTo(640, 0);
    expect(right.x).toBeGreaterThan(center.x);
  });

  it('builds minimap heat bands and hotspot ratio from live units', () => {
    const state = createInitialGameState('hive', 303);
    const player = spawnBattleUnit(state, 'player', 'hive_grub');
    const enemy = spawnBattleUnit(state, 'enemy', 'enemy_raider');
    player.x = 700;
    enemy.x = 730;

    const bands = buildBattleHeatBands(state.battle.units, state.battle.bases.player.x, state.battle.bases.enemy.x, 12);
    expect(bands.some((band) => band.player > 0)).toBe(true);
    expect(bands.some((band) => band.enemy > 0)).toBe(true);
    expect(getBattleHotspotRatio(state)).toBeGreaterThan(0);
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `npm test -- src/systems/prototypeRules.test.ts`

Expected: FAIL because `BattlefieldViewSystem` does not exist.

- [ ] **Step 3: Add camera state type**

In `src/types/game.ts`, add:

```ts
export interface BattleCameraState {
  centerX: number;
  viewportWorldWidth: number;
  manualUntilMs: number;
}
```

Add to `BattleState`:

```ts
  camera: BattleCameraState;
```

- [ ] **Step 4: Initialize long world and camera**

In `src/systems/GameState.ts`, set bases:

```ts
player: { side: 'player', hp: 500, maxHp: 500, x: 70, laneOffset: 0, lastHitAtMs: -9999 },
enemy: { side: 'enemy', hp: 500, maxHp: 500, x: 1670, laneOffset: 0, lastHitAtMs: -9999 },
```

Add camera:

```ts
camera: {
  centerX: 710,
  viewportWorldWidth: 640,
  manualUntilMs: 0,
},
```

- [ ] **Step 5: Create view system implementation**

Create `src/systems/BattlefieldViewSystem.ts`:

```ts
import type { BattleUnit, GameState } from '../types/game';
import { getBattleFrontlineRatio } from './BattleSystem';

export type BattlePoint = { x: number; y: number };

export type BattleProjectionInput = {
  worldX: number;
  laneOffset: number;
  cameraCenterX: number;
  playerBaseX: number;
  enemyBaseX: number;
  screenStart: BattlePoint;
  screenEnd: BattlePoint;
  viewportWorldWidth: number;
};

export type HeatBand = {
  index: number;
  ratioStart: number;
  ratioEnd: number;
  player: number;
  enemy: number;
};

export function clampBattleCameraCenter(centerX: number, playerBaseX: number, enemyBaseX: number, viewportWorldWidth: number): number {
  const half = viewportWorldWidth / 2;
  const min = playerBaseX + half;
  const max = enemyBaseX - half;
  if (max <= min) return (playerBaseX + enemyBaseX) / 2;
  return Math.max(min, Math.min(max, centerX));
}

export function getBattleCameraViewport(centerX: number, playerBaseX: number, enemyBaseX: number, viewportWorldWidth: number) {
  const safeCenter = clampBattleCameraCenter(centerX, playerBaseX, enemyBaseX, viewportWorldWidth);
  return {
    startX: safeCenter - viewportWorldWidth / 2,
    endX: safeCenter + viewportWorldWidth / 2,
    width: viewportWorldWidth,
  };
}

export function projectBattlePoint(input: BattleProjectionInput) {
  const visibleRatio = (input.worldX - (input.cameraCenterX - input.viewportWorldWidth / 2)) / input.viewportWorldWidth;
  const axisX = input.screenStart.x + (input.screenEnd.x - input.screenStart.x) * visibleRatio;
  const axisY = input.screenStart.y + (input.screenEnd.y - input.screenStart.y) * visibleRatio;
  const tangentX = input.screenEnd.x - input.screenStart.x;
  const tangentY = input.screenEnd.y - input.screenStart.y;
  const len = Math.max(1, Math.sqrt(tangentX * tangentX + tangentY * tangentY));
  const normalX = -tangentY / len;
  const normalY = tangentX / len;
  const worldRatio = (input.worldX - input.playerBaseX) / Math.max(1, input.enemyBaseX - input.playerBaseX);
  const spread = 0.82 + Math.sin(Math.max(0, Math.min(1, worldRatio)) * Math.PI) * 0.62;
  const x = axisX + normalX * input.laneOffset * spread;
  const y = axisY + normalY * input.laneOffset * spread * 0.94;
  return { x, y, depth: y, visibleRatio };
}

export function buildBattleHeatBands(units: BattleUnit[], playerBaseX: number, enemyBaseX: number, bandCount: number): HeatBand[] {
  const bands = Array.from({ length: bandCount }, (_, index) => ({
    index,
    ratioStart: index / bandCount,
    ratioEnd: (index + 1) / bandCount,
    player: 0,
    enemy: 0,
  }));
  for (const unit of units) {
    if (unit.hp <= 0) continue;
    const ratio = Math.max(0, Math.min(0.999, (unit.x - playerBaseX) / Math.max(1, enemyBaseX - playerBaseX)));
    const index = Math.min(bandCount - 1, Math.floor(ratio * bandCount));
    bands[index][unit.side] += unit.isElite ? 2 : 1;
  }
  return bands;
}

export function getBattleHotspotRatio(state: GameState): number {
  return getBattleFrontlineRatio(state);
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `npm test -- src/systems/prototypeRules.test.ts`

Expected: PASS for camera and heat map tests.

## Task 5: Integrate Long Battlefield Rendering

**Files:**
- Modify: `src/scenes/PrototypeScene.ts`
- Test: `src/systems/prototypeRules.test.ts`

- [ ] **Step 1: Write the failing render-math test**

Add a focused test that protects offscreen projection:

```ts
it('marks points outside the camera viewport by visible ratio', () => {
  const left = projectBattlePoint({
    worldX: 200,
    laneOffset: 0,
    cameraCenterX: 710,
    playerBaseX: 70,
    enemyBaseX: 1670,
    screenStart: { x: 170, y: 620 },
    screenEnd: { x: 1110, y: 260 },
    viewportWorldWidth: 640,
  });
  expect(left.visibleRatio).toBeLessThan(0);
});
```

- [ ] **Step 2: Run the test to verify it passes or fails for the right reason**

Run: `npm test -- src/systems/prototypeRules.test.ts`

Expected: PASS if Task 4 already exposed `visibleRatio`; FAIL if it was not returned. Add `visibleRatio` as shown in Task 4 if needed.

- [ ] **Step 3: Import view helpers**

In `src/scenes/PrototypeScene.ts`, import:

```ts
import {
  buildBattleHeatBands,
  clampBattleCameraCenter,
  getBattleCameraViewport,
  getBattleHotspotRatio,
  projectBattlePoint,
} from '../systems/BattlefieldViewSystem';
```

- [ ] **Step 4: Replace battlefield anchor constants**

Keep screen constants, but change battle endpoints to viewport anchors:

```ts
const BATTLE_SCREEN_START = { x: 170, y: BATTLE_Y + BATTLE_H - 32 };
const BATTLE_SCREEN_END = { x: 1110, y: BATTLE_Y + 44 };
```

Keep base art positions derived from projection rather than hard-coded `PLAYER_BASE_X` and `ENEMY_BASE_X`.

- [ ] **Step 5: Update `getRoadPoint()`**

Replace `getRoadPoint(t)` with a world-aware helper:

```ts
private getRoadPoint(worldX: number) {
  const projection = this.projectBattle(worldX, 0);
  return { x: projection.x, y: projection.y };
}
```

Update loops that previously passed `t` to instead compute world positions from the current camera viewport:

```ts
const viewport = this.getCurrentBattleViewport();
const worldX = Phaser.Math.Linear(viewport.startX, viewport.endX, t);
const p = this.getRoadPoint(worldX);
```

- [ ] **Step 6: Update `projectBattle()`**

Replace the body with:

```ts
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
```

- [ ] **Step 7: Add camera update**

Add:

```ts
private updateBattleCamera(delta: number) {
  const camera = this.state.battle.camera;
  if (this.time.now < camera.manualUntilMs) return;
  const playerBaseX = this.state.battle.bases.player.x;
  const enemyBaseX = this.state.battle.bases.enemy.x;
  const targetX = Phaser.Math.Linear(playerBaseX, enemyBaseX, getBattleHotspotRatio(this.state));
  camera.centerX = clampBattleCameraCenter(
    Phaser.Math.Linear(camera.centerX, targetX, Math.min(1, delta / 900)),
    playerBaseX,
    enemyBaseX,
    camera.viewportWorldWidth,
  );
}
```

Call it in `update()` after `updateBattle()`.

- [ ] **Step 8: Hide offscreen units**

In `syncUnitVisuals()`, after projecting:

```ts
const visible = pos.visibleRatio >= -0.18 && pos.visibleRatio <= 1.18;
visual.outline.setVisible(visible);
visual.sprite.setVisible(visible);
visual.sideRing.setVisible(visible);
visual.shadow.setVisible(visible);
visual.hpBack.setVisible(visible);
visual.hpFill.setVisible(visible);
if (!visible) continue;
```

- [ ] **Step 9: Run typecheck**

Run: `npm run typecheck`

Expected: PASS.

## Task 6: Replace Minimap With Battle-Line Strip

**Files:**
- Modify: `src/scenes/PrototypeScene.ts`
- Test: `src/systems/prototypeRules.test.ts`

- [ ] **Step 1: Write the minimap heat test**

Add:

```ts
it('keeps heat bands stable when there are no units', () => {
  const state = createInitialGameState('mech', 404);
  const bands = buildBattleHeatBands(state.battle.units, state.battle.bases.player.x, state.battle.bases.enemy.x, 16);
  expect(bands).toHaveLength(16);
  expect(bands.every((band) => band.player === 0 && band.enemy === 0)).toBe(true);
});
```

- [ ] **Step 2: Run test**

Run: `npm test -- src/systems/prototypeRules.test.ts`

Expected: PASS if Task 4 is complete.

- [ ] **Step 3: Redraw minimap panel as a strip**

In `drawMiniMap()`, replace the old map polygon with:

```ts
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
```

- [ ] **Step 4: Render heat, hotspot, and viewport**

In `syncMiniMap()`, replace current point map drawing with:

```ts
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
const hotspot = getBattleHotspotRatio(this.state);
g.fillStyle(0xfacc15, 0.72);
g.fillRect(stripX + hotspot * stripW - 2, stripY - 8, 4, stripH + 16);
const viewport = this.getCurrentBattleViewport();
const fullWidth = this.state.battle.bases.enemy.x - this.state.battle.bases.player.x;
const viewStartRatio = (viewport.startX - this.state.battle.bases.player.x) / fullWidth;
const viewWidthRatio = viewport.width / fullWidth;
g.lineStyle(3, 0xf8fafc, 0.9);
g.strokeRoundedRect(stripX + viewStartRatio * stripW, stripY - 9, viewWidthRatio * stripW, stripH + 18, 5);
```

- [ ] **Step 5: Add click/drag input**

Attach interaction to an invisible rectangle in `drawMiniMap()`:

```ts
const hit = this.add.rectangle(x + w / 2, y + 62, w - 20, 70, 0x000000, 0.001)
  .setDepth(4703)
  .setInteractive({ draggable: true, useHandCursor: true });
hit.on('pointerdown', (pointer: Phaser.Input.Pointer) => this.setCameraFromMiniMap(pointer.x));
hit.on('drag', (pointer: Phaser.Input.Pointer) => this.setCameraFromMiniMap(pointer.x));
```

Add:

```ts
private setCameraFromMiniMap(pointerX: number) {
  const stripX = MINIMAP_X + 18;
  const stripW = MINIMAP_W - 36;
  const ratio = Phaser.Math.Clamp((pointerX - stripX) / stripW, 0, 1);
  const playerBaseX = this.state.battle.bases.player.x;
  const enemyBaseX = this.state.battle.bases.enemy.x;
  this.state.battle.camera.centerX = clampBattleCameraCenter(
    Phaser.Math.Linear(playerBaseX, enemyBaseX, ratio),
    playerBaseX,
    enemyBaseX,
    this.state.battle.camera.viewportWorldWidth,
  );
  this.state.battle.camera.manualUntilMs = this.time.now + 4200;
}
```

- [ ] **Step 6: Run typecheck**

Run: `npm run typecheck`

Expected: PASS.

## Task 7: Visual Polish, Progress Log, And Verification

**Files:**
- Modify: `src/scenes/PrototypeScene.ts`
- Modify: `docs/PROGRESS.md`
- Optional create: `docs/long-battlefield-smoke.png`

- [ ] **Step 1: Adjust labels and base bars**

In `syncBases()`, project base positions before drawing bars:

```ts
const playerPos = this.projectBattle(this.state.battle.bases.player.x, 0);
const enemyPos = this.projectBattle(this.state.battle.bases.enemy.x, 0);
if (playerPos.visibleRatio >= -0.1 && playerPos.visibleRatio <= 1.1) {
  this.drawBaseBar(playerPos.x, playerPos.y + 76, playerRatio, 0x3b82f6, '我方');
}
if (enemyPos.visibleRatio >= -0.1 && enemyPos.visibleRatio <= 1.1) {
  this.drawBaseBar(enemyPos.x, enemyPos.y + 88, enemyRatio, 0xef4444, '敌方');
}
```

- [ ] **Step 2: Update progress log**

Add this bullet to `docs/PROGRESS.md`:

```md
- Added a long battlefield camera pass with soft three-lane spawning, lane-aware aggro targeting, and a horizontal minimap battle-line strip with unit heat and viewport framing.
```

- [ ] **Step 3: Run full tests**

Run: `npm test`

Expected: all tests pass.

- [ ] **Step 4: Run typecheck**

Run: `npm run typecheck`

Expected: exit code 0.

- [ ] **Step 5: Run build**

Run: `npm run build`

Expected: exit code 0. The existing Vite chunk-size warning is acceptable.

- [ ] **Step 6: Browser smoke**

Run the local dev server with `npm run dev` if it is not running. Open the local URL in the browser and verify:

- The battlefield reads as a longer route segment.
- Bases can be offscreen depending on camera position.
- Units appear in top/middle/bottom soft lanes.
- Minimap is a horizontal battle-line strip.
- Blue/red heat, yellow hotspot, and white viewport frame are visible.
- Clicking or dragging the strip moves the battle camera.

Save a screenshot to `docs/long-battlefield-smoke.png` if browser screenshot capture is available.

## Plan Self-Review

- Spec coverage: long battlefield, camera viewport, minimap strip, heat/hotspot, soft three lanes, lane-aware aggro, and non-RTS constraints are covered by Tasks 1-7.
- Placeholder scan: no `TBD`, `TODO`, or unspecified implementation steps remain.
- Type consistency: `BattleLaneId`, `BattleLaneWeights`, `BattleCameraState`, `battleLane`, `aggroRange`, and `laneWeights` are introduced before use.
