# Plan Design Review: Three-Axis Readability Battle Lab

Game: planB
Branch: mvp
Date: 2026-06-02
Plan file: `docs/gstack-artifacts/yang-mvp-slice-plan-20260602-215006.md`
Scope: narrow readability design review only
Status: DONE_WITH_CONCERNS

## Scope

Reviewed only the Three-Axis Readability Battle Lab:

1. How `Launch / Tuning / Unit` are visually distinguished.
2. How the three frontline results read at a glance: sustained flow, repeated heavy hit, batch charge.
3. How `Pool Polluter / Echo Breaker / Stagger Punisher` warn, hit, and leave readable effects.
4. How `Overdrive` reads as amplification of the current axis.
5. How the four post-battle questions are presented and recorded.

## Evidence Used

- `AGENTS.md`: repo is docs-only, formal terms are `Launch / Tuning / Unit`, Tuning slots are `Prime / Echo / Surge`, no old Web MVP assumptions.
- `docs/gdd.md`: canonical design says readability comes before content breadth, `Overdrive` is build amplification, and early build shapes are `Launch Flood`, `Tuning Echo`, and `Unit Queue Burst`.
- `docs/PROGRESS.md`: recent log records the docs-only cleanup and the selected validation slice.
- `docs/gstack-artifacts/yang-mvp-slice-plan-20260602-215006.md`: current slice plan names the Battle Lab, three presets, three counters, one `Overdrive` per battle, and four post-battle questions.

## What Already Exists

- The formal design already names the correct axes and counters.
- The slice already has the right validation target: players must distinguish the three pressure patterns, and `Unit` must not become the only understandable axis.
- The slice already uses 3-5 target players and asks four causality questions after each battle.
- No `docs/DESIGN.md` exists.
- No implementation, UI components, local validation commands, or old Web MVP source truth exists in this repo state.

## NOT In Scope

- No implementation work.
- No race expansion.
- No shop, relic, Gold curve, or event expansion.
- No full enemy table.
- No PVP, networking, accounts, backend, matchmaking, Steam integration, or telemetry backend.
- No free RTS battlefield or complex RTS pathfinding.
- No restoration of deleted Web MVP assumptions.

## Step 0: Design Scope Assessment

UI scope exists. The plan defines a battle screen, machine zones, frontline read, `Overdrive`, counters, and a question screen.

Initial design completeness: 4.2/10.

The plan says what must be readable, but not enough about how the screen makes it readable. A 10 for this narrow plan would specify:

- Battle-screen priority for a 1-second glance.
- Axis-specific shape, motion, timing, and trace language.
- Warning, active, and recovery states for each counter.
- `Overdrive` eligibility and activation feedback tied to the current axis.
- A result-screen answer flow that records causality without revealing the answer key.

## Pass Scores

| Pass | Before | After | Finding |
|---|---:|---:|---|
| Information Architecture | 5/10 | 8/10 | The plan had one screen and a result screen, but no combat glance hierarchy. Added P0-P4 hierarchy and left-to-right causal chain. |
| Interaction States | 4/10 | 8/10 | Counters were named, but warning, active, and effect states were missing. Added state rules for all three counters. |
| Player Journey | 5/10 | 7/10 | The post-battle questions existed, but the result flow did not protect the test signal. Added freeze, event strip, response, and delayed answer reveal. |
| AI Slop Risk | 6/10 | 8/10 | The nouns are game-specific, but "colored primitives" could still become generic. Added axis-specific shape, motion, and result signatures. |
| Design System Alignment | 2/10 | 5/10 | No design system exists. Added a local visual grammar for this prototype only. Full `docs/DESIGN.md` remains deferred. |
| Input and Accessibility | 3/10 | 7/10 | Mouse input was implied, but colorblind and grayscale readability were unspecified. Added no-color-only rules and answer confidence capture. |
| Unresolved Decisions | 4/10 | 8/10 | The major battle-lab readability decisions are now specified. Full production art direction remains outside scope. |

Weighted score: 4.2/10 -> 7.4/10.

## Main Findings

### HIGH: The original plan could still produce Unit-dominant UI

Evidence:

- The GDD states the core question is whether players can identify which machine axis the run wants to amplify and see it become frontline pressure.
- The slice plan names the risk directly: `Unit` may become the only axis players understand or value.
- Before this review, the plan specified a left machine and right frontline, but did not specify axis visual hierarchy or axis-specific trace language.

Medium confidence. This is based on docs and plan text, not playtest data. Verify with 3-5 target players.

Fix added:

- `Launch` gets Pool rhythm, return arrows, round balls, and smooth flow pressure.
- `Tuning` gets slot plates, copy afterimages, `Prime / Echo / Surge` local feedback, and stepped repeat impacts.
- `Unit` gets square slot tiles, queue stack, squad bracket, and grouped charge release.

### HIGH: Counter readability needed state coverage

Evidence:

- GDD says special enemy mechanics must be visible and warned before they affect Pool or slots.
- The slice plan says `Pool Polluter`, `Echo Breaker`, and `Stagger Punisher` must visibly disrupt their axes.
- Before this review, the plan did not define warning, active, or recovery visuals.

Fix added:

- `Pool Polluter`: ghost Junk warning, active Junk occupancy, rhythm stutter after-effect.
- `Echo Breaker`: marked Echo window, collapsed copy, recovery afterimage.
- `Stagger Punisher`: gap timer warning, pressure during no-deployment time, gap-hit marker.

### MEDIUM: `Overdrive` needed anti-panic affordances

Evidence:

- GDD says `Overdrive` is build amplification, not a universal panic button.
- The slice plan lists diagnostic failure if most players save `Overdrive` for danger or cannot say what axis it amplified.
- Before this review, the plan named three `Overdrive` variants, but not the visual rules that stop it from reading as a generic rescue.

Fix added:

- Axis-specific control label and placement.
- Pulse only when the matching axis has something to amplify.
- Activation overlays only the affected axis components.
- Unrelated emergency use is visibly low-yield and not presented as heal, shield, freeze, or rescue.

### MEDIUM: Post-battle questions needed recording rules

Evidence:

- The slice plan already requires four questions after each battle and a 3/5 player success gate.
- It did not specify how to avoid revealing the answer key, how to record confidence, or how to flag Unit-only and panic-button failure modes.

Fix added:

- Freeze result, show event strip, ask questions, record responses, reveal answers only after all three battles.
- Added minimum answer fields and flags for `unit_only_bias_flag` and `overdrive_panic_flag`.

## Interaction State Matrix

| Feature | Idle or baseline | Warning | Active | Resolved | Failure signal |
|---|---|---|---|---|---|
| Axis lanes | All axes visible, active lane strongest only when producing effect. | N/A | Axis lane motion intensifies during effect. | Event trace remains briefly. | Player answers only "more units." |
| `Pool Polluter` | Clean FIFO Pool, highlighted head. | Ghost Junk occupies future slots. | Junk enters Pool and occupies capacity. | Junk fires and disappears, rhythm returns. | Player cannot name Pool or Junk. |
| `Echo Breaker` | Echo hot slot has readable copy window. | Break mark appears on Echo slot/window. | Copy collapses or weakens. | Slot returns to normal. | Player cannot tell Echo was swallowed. |
| `Stagger Punisher` | Queue charge is readable. | Gap timer appears during long no-deployment window. | Punisher pressure hits during charge gap. | Squad release can answer after the hit. | Player reads it as random damage. |
| `Overdrive` | Axis-specific control attached to active lane. | Control pulses only when eligible axis state exists. | Affected components intensify. | Event strip marks amplified axis. | Player calls it rescue, shield, heal, or panic button. |
| Result questions | No answer key shown. | N/A | Player answers with confidence. | Observer records correctness after response. | Form reveals too much or only records selections, not causal text. |

## Design Decisions Added To Plan

1. Battle screen hierarchy with P0 current axis effect, P1 counter state, P2 frontline result, P3 `Overdrive`, and P4 debug labels.
2. Axis visual grammar:
   - `Launch`: Pool rhythm, return arrows, round balls, smooth flow.
   - `Tuning`: slot plates, copy afterimages, repeated impact.
   - `Unit`: square slot tiles, queue stack, squad bracket.
3. Frontline result signatures:
   - `Launch Flood`: sustained small-flow pressure.
   - `Tuning Echo`: fewer high-value repeated waves.
   - `Unit Queue Burst`: quiet charge, then grouped push.
4. Counter warning, active, and effect states.
5. Axis-bound `Overdrive` rules.
6. Post-battle question flow and recording schema.

## Deferred Decisions

1. Full `docs/DESIGN.md`: deferred because the user requested a narrow Battle Lab readability review, not a full UI design-system pass.
2. Exact palette, typography, and animation timings: deferred until a full design-system or implementation-handoff pass.
3. Final art direction: deferred because this slice allows colored primitives and simple icons.

## Completion Summary

```text
+====================================================================+
|         GAME DESIGN PLAN REVIEW - COMPLETION SUMMARY               |
+====================================================================+
| Game:                | planB                                      |
| Branch:              | mvp                                        |
| Plan file:           | docs/gstack-artifacts/yang-mvp-slice-plan-20260602-215006.md |
| Design system:       | not found                                  |
+--------------------------------------------------------------------+
| Step 0  (Scope)      | 4.2/10, narrow Battle Lab readability       |
| Pass 1  (Info Arch)  | 5/10 -> 8/10 after fixes                   |
| Pass 2  (States)     | 4/10 -> 8/10 after fixes                   |
| Pass 3  (Journey)    | 5/10 -> 7/10 after fixes                   |
| Pass 4  (AI Slop)    | 6/10 -> 8/10 after fixes                   |
| Pass 5  (Design Sys) | 2/10 -> 5/10 after fixes                   |
| Pass 6  (Input/A11y) | 3/10 -> 7/10 after fixes                   |
| Pass 7  (Decisions)  | 6 resolved, 3 deferred                     |
+--------------------------------------------------------------------+
| NOT in scope         | written (7 items)                          |
| What already exists  | written                                    |
| Decisions made       | 6 added to plan                            |
| Decisions deferred   | 3 listed in artifact                       |
| Overall design score | 4.2/10 -> 7.4/10                           |
+====================================================================+
| Status: DONE_WITH_CONCERNS                                         |
+====================================================================+

Next Step:
  PRIMARY: /implementation-handoff - convert this accepted readability spec into a build package
  (if full UI art direction is needed first): /plan-design-review - run a full design-system pass
  (if implementation exists): /game-ux-review - validate built UI against this readability spec
```
