# PlanB Battle UI Flow Session Notes

**Date:** 2026-06-10  
**Status:** Draft session notes, not canonical design  
**Purpose:** Record the current UI flow discussion so a new Codex session can continue without losing context.

## Scope Of This Note

This note records what was discussed, what was tentatively accepted, what was corrected, and what still needs discussion for the formal player-facing UI flow.

This note is not a formal update to `docs/gdd.md`, `docs/DESIGN.md`, `docs/deploy-lane-ui.md`, `docs/guardian-system.md`, or `docs/mvp-scope.md`.

## Hard Constraint Confirmed

- Do not design, propose, implement, or preserve `debug-only` UI, debug overlay, development sliders, debug panels, implementation-state messages, or test-only controls unless the user explicitly asks for them.
- Current work is formal player-facing UI design.
- The screenshot shown in the session should be treated as a mixed-information current battle screen, not as a target design.

## Skills Used / Routing

- `game-ux-review` was used for the initial page-level UX review.
- `game-direction` was used to clarify page intent.
- The review direction shifted after the user clarified that the screenshot is the main battlefield, not primarily a Guardian selection page.
- Future Godot implementation should not begin from these notes without a confirmed design and explicit user approval.

## Confirmed Flow Direction

Proposed formal MVP v0 player flow:

1. `Main Menu`
2. `Guardian Contract`
3. `Battle Screen`
4. `Battle Result`
5. `Reward / Rest`
6. Repeat battle loop as needed
7. `Final Result`
8. Return to `Main Menu` or start a new run

Pages that are currently not part of the first pass:

- Complex save / continue page
- Codex / glossary page
- Standalone enemy preview page
- Multi-Guardian team editor
- Long-term progression pages
- Any debug UI

## Page 1 Confirmed: Main Menu

Purpose:

- Cold-start entry into a short run.
- Do not teach the full machine, Guardian, or Deploy Lane systems here.
- Do not show battle UI here.

Recommended structure:

```text
PlanB

[开始新短局]

设置
退出
```

Suggested tagline:

```text
把一台不稳定的出兵机器，推成前线优势。
```

Confirmed behavior:

- `开始新短局` enters `Guardian Contract`.
- `设置` opens settings.
- `退出` exits the game.
- Do not show disabled `继续游戏` unless save / continue exists.

## Page 2 Confirmed: Guardian Contract

Purpose:

- Let the player choose the current run's Guardian.
- Frame the choice as machine bias plus base fallback, not as a directly controlled hero.

Recommended title:

```text
选择守护者契约
```

Recommended subtitle:

```text
选择本局机器偏向与基地兜底方式
```

Recommended structure:

```text
选择守护者契约
选择本局机器偏向与基地兜底方式

[巢脉母 契约卡]        [酸冠母 契约卡]

所选契约预览
- 影响机器轴
- 战场触发方式
- 适合打法
- 风险提醒

[签订契约，开始 Battle 1]
[返回主菜单]
```

Guardian cards should include:

- Guardian name
- Portrait / silhouette
- Machine contract
- Battlefield contract
- Suitable play tendency
- What this Guardian will not solve

Current Guardian framing:

- `巢脉母`: biased toward `Launch / Recycle`, stabilizes machine cycling through recycle return.
- `酸冠母`: biased toward `Tuning / Gate -> Prime`, converts repeated Gate misses into Prime opportunity.

Important wording decision:

- Prefer `守护者契约` over `选择 Player Guardian` to avoid implying direct hero control.

## Page 3 In Progress: Battle Screen

The battle screen is the core page and still needs more design work.

Current direction:

- The battle screen should use three major zones:
  - Three-warehouse machine area
  - Queue / Deploy Bridge
  - Battlefield area
- The bridge must explicitly connect machine output to battlefield deployment.
- The current screenshot mixes too many concerns and should not be treated as final layout.

Current tentative overall horizontal ratio:

```text
三仓机器 38% | Queue / Deploy Bridge 14% | 战场 48%
```

Rationale:

- The three warehouses need vertical clarity more than extreme width.
- The battlefield now needs more width because Guardian is an in-world base entity, not a separate HUD panel.
- The bridge should not disappear, because it explains machine result -> queue -> lane deployment.

Earlier ratio candidates that were discussed and rejected / revised:

- `48 / 12 / 40`: too wide for the three warehouses.
- `46 / 12 / 42`: still too wide for the three warehouses and did not make Guardian visible enough.
- `40 / 14 / 46`: closer, but revised after Guardian was clarified as an in-world base entity.

## Major Correction: Guardian Placement

The user corrected the Guardian model:

- Guardian is not a bottom HUD card.
- Guardian is not just an icon or detached HP display.
- Guardian attacks.
- Guardian exists as a battlefield unit / base entity.
- The overall battlefield should feel closer to a `澄海 3C` style map where the Guardian is effectively the base.

Current corrected Guardian model:

- Player Guardian is the player's base entity.
- Enemy Guardian / Endpoint is the enemy base entity.
- Both should be placed inside the battlefield space.
- HP bars and state can attach to the entities, but should not replace the entities.
- Guardian attack, hit, skill trigger, and pressure feedback should happen around the in-world entity.

Current corrected battlefield concept:

```text
玩家侧                                             敌方侧
┌──────────┐                              ┌──────────┐
│ Player   │── 左路 ────────────────────▶│ Enemy    │
│ Guardian │── 中路 ────────────────────▶│ Guardian │
│          │── 右路 ────────────────────▶│          │
└──────────┘                              └──────────┘
```

Battlefield should no longer reserve a separate bottom Guardian panel. Guardian belongs inside the battlefield.

## Battle Screen Elements To Keep

Battle screen should keep formal player-facing elements only:

- `Launch / Tuning / Unit` three-warehouse machine.
- Queue / next unit / deploy bridge.
- Current Deploy Lane.
- Three battlefield lanes.
- Player Guardian as battlefield base entity.
- Enemy Guardian / Endpoint as battlefield base entity.
- Guardian HP attached to battlefield entities.
- Lane danger / pressure indication.
- Battle number.
- Gold, if it is relevant during battle.
- Short high-value event feedback.

## Battle Screen Elements To Remove From Formal UI

Remove or do not carry forward:

- Guardian selection list inside battle screen.
- Development readability panel.
- Flow explanation panel.
- Event panel if it is just implementation/debug text.
- Ball radius controls.
- Peg radius controls.
- Size reset button.
- Text such as `结算页会在 Endpoint 后显示`.
- Any battle screen text that says the current phase is `守护者选择` after the player is already in battle.
- Any implementation-state or debug-state message.

## Battle Screen Still Needs Discussion

Open design questions for the next session:

1. Exact battlefield layout:
   - How large are Player Guardian and Enemy Guardian relative to lanes?
   - Are lanes perfectly horizontal, slightly arced, or arranged with vertical offsets like a MOBA / 3C lane map?

2. Lane geometry:
   - Do all three lanes connect directly from Player Guardian to Enemy Guardian?
   - Are there lane gates near each Guardian?
   - How are lane entrances shown when Deploy Lane changes?

3. Guardian combat display:
   - How to show Guardian attack range without clutter?
   - When does range appear: always, on pressure, on hover, on attack?
   - How to show tactical skill cooldown / readiness while keeping Guardian as an in-world entity?

4. Queue / Deploy Bridge:
   - What exact information appears in the bridge?
   - Does it show only queue head, or several upcoming units?
   - How does it animate deployment from queue into the selected lane?

5. Three-warehouse area:
   - What is the minimum readable width for the physical machine?
   - Should the three warehouses be stacked vertically or partially compacted?
   - How much warehouse detail belongs in battle, versus simplified state?

6. Top status bar:
   - Whether Gold should appear during battle or only after battle / rest.
   - Whether current Guardian contract appears as text, icon, or not at all.
   - Whether Battle number and phase need constant display.

7. Bottom event feedback:
   - Whether a bottom event strip is needed.
   - If yes, it should only show formal player-facing high-value messages.

## Next Recommended Continuation

Start the next session from:

```text
Continue from docs/gstack-artifacts/planb-battle-ui-flow-session-20260610.md.
We confirmed Main Menu and Guardian Contract. We are currently designing Battle Screen. Guardian is an in-world attacking base entity like 澄海 3C, not a HUD panel. Debug UI is out of scope unless explicitly requested.
```

Recommended next design task:

- Draw and compare 2-3 candidate battlefield layouts with Guardian as in-world base entity.
- Then choose one battlefield structure before returning to full Battle Screen proportions.

