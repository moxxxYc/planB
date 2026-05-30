# Pinball Standby Launch Unit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework the top pinball flow so the launcher sits in the middle, routes left to Standby or right to Unit Spawn, and split is capped at two outcomes per original ball.

**Architecture:** Reuse the existing decision slot trigger path for the new Standby Zone's gold, magic, and upgrade effects. Rename and rewire launch outcomes to `standby / split / spawn`, then update the Phaser scene layout and routing so Unit Spawn receives launch-spawn balls directly.

**Tech Stack:** Vite, TypeScript, Phaser Matter physics, Vitest.

---

## File Structure

- Modify `src/types/game.ts`: change launch outcome ids from `split | fire | miss` to `standby | split | spawn`.
- Modify `src/systems/PinballMachineSystem.ts`: update launch slot definitions, labels, weights, split cap, and split-limit fallback.
- Modify `src/data/slots.ts`: expose only gold, magic, and upgrade as Standby visible slots while keeping `spawn` in slot state for stats/helper compatibility.
- Modify `src/scenes/PrototypeScene.ts`: reorder top zones, update labels/arrows, route launch standby left, route launch spawn right, and remove the old decision spawn transfer path.
- Modify `src/systems/prototypeRules.test.ts`: update expectations for launch outcomes, split cap, and visible Standby slots.
- Modify `README.md`, `docs/CURRENT_GAMEPLAY_DESIGN.md`, `docs/PROGRESS.md`: describe the new playable flow.

## Task 1: Rule Surface

**Files:**
- Modify: `src/types/game.ts`
- Modify: `src/systems/PinballMachineSystem.ts`
- Modify: `src/data/slots.ts`
- Test: `src/systems/prototypeRules.test.ts`

- [ ] **Step 1: Update tests first**

Expected test intent:

```ts
expect(decisionSlotDefs.map((slot) => slot.id)).toEqual(['gold', 'magic', 'upgrade']);
expect(buildLaunchOutcomeSlotLayouts(0, 500, 0, 0).map((slot) => slot.id)).toEqual(['standby', 'split', 'spawn']);
expect(resolveLaunchOutcomeWithSplitLimit('split', 2)).toEqual({
  outcome: 'spawn',
  nextSplitCount: 2,
  limitReached: true,
});
```

Run: `npm test -- src/systems/prototypeRules.test.ts`

- [ ] **Step 2: Implement the rule changes**

Expected rule shape:

```ts
export type LaunchOutcomeId = 'standby' | 'split' | 'spawn';
export const MAX_SPLITS_PER_ORIGINAL_LAUNCH_BALL = 2;
export const launchOutcomeSlotDefs = [
  { id: 'standby', label: '战备', color: 0x93c5fd, widthWeight: 1 },
  { id: 'split', label: '分裂', color: 0x86efac, widthWeight: 3 },
  { id: 'spawn', label: '发兵', color: 0x4ade80, widthWeight: 1 },
];
```

Run: `npm test -- src/systems/prototypeRules.test.ts`

## Task 2: Phaser Flow And Layout

**Files:**
- Modify: `src/scenes/PrototypeScene.ts`
- Modify: `src/systems/PrototypeLayoutSystem.ts` if width constants need central launch support

- [ ] **Step 1: Reorder the top zones**

Expected layout constants should map left-to-right as:

```ts
const STANDBY_X = TOP_ZONE_LAYOUT.decision.x;
const STANDBY_W = TOP_ZONE_LAYOUT.decision.w;
const LAUNCH_X = TOP_ZONE_LAYOUT.launch.x;
const LAUNCH_W = TOP_ZONE_LAYOUT.launch.w;
const UNIT_X = TOP_ZONE_LAYOUT.unit.x;
const UNIT_W = TOP_ZONE_LAYOUT.unit.w;
```

The actual implementation may keep internal `DECISION_X` names only if all player-facing labels say `战备区`.

- [ ] **Step 2: Route launch outcomes**

Expected behavior:

```ts
if (splitResolution.outcome === 'standby') {
  const drop = this.getTopBandDropPoint(DECISION_X, DECISION_W);
  this.spawnDecisionBall(ball.value, drop, ball.tags);
}
if (splitResolution.outcome === 'spawn') {
  const taggedPayload = applyDecisionSpawnTags(this.state, { value: ball.value, tags: ball.tags });
  const drop = this.getTopBandDropPoint(UNIT_X, UNIT_W);
  this.spawnUnitBall(consumeSpawnMarkBonus(this.state, taggedPayload.value), drop, taggedPayload.tags);
}
```

Decision/Standby `spawn` should no longer exist as a visible sensor path.

Run: `npm run typecheck`

## Task 3: Docs And Compatibility Text

**Files:**
- Modify: `README.md`
- Modify: `docs/CURRENT_GAMEPLAY_DESIGN.md`
- Modify: `docs/PROGRESS.md`

- [ ] **Step 1: Update player-facing descriptions**

Expected terms:

```md
- 三段式球机：战备区、发球区、出兵区。
- 发球区结果槽：战备 / 分裂 / 发兵。
- 战备区槽位：金币 / 法术 / 升级。
```

Keep descriptions of Unit Spawn behavior unchanged except for the upstream source now being Launch `发兵`.

Run: `rg -n "抉择区|fire|miss|落空|发射" README.md docs/CURRENT_GAMEPLAY_DESIGN.md src/scenes/PrototypeScene.ts src/systems/PinballMachineSystem.ts src/systems/prototypeRules.test.ts`

## Task 4: Validation And Local Preview

**Files:**
- No new files expected.

- [ ] **Step 1: Run focused and full relevant validation**

Run:

```bash
npm test -- src/systems/prototypeRules.test.ts
npm run typecheck
npm run build
```

- [ ] **Step 2: Start the local app for visual review**

Run: `npm run dev -- --host 0.0.0.0`

Expected: Vite prints a local URL. Open it and verify the top machine visually shows left Standby, middle Launch, right Unit Spawn with the new routing.
