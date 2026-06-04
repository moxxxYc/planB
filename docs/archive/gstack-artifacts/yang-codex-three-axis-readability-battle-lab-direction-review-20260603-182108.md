# Direction Review: Three-Axis Readability Battle Lab Recalibration

Game: planB
Branch: codex/three-axis-readability-battle-lab
Date: 2026-06-03
Status: DONE_WITH_CONCERNS
Supersedes: N/A

## Trigger

The current Godot prototype screenshot reads as a four-column explanatory dashboard:

```text
Launch panel | Tuning panel | Unit panel | Frontline panel
```

That layout makes the three axes visible, but it does not deliver the accepted machine-to-frontline fantasy from `docs/gdd.md`: a ball machine event visibly becomes frontline pressure.

This review treats the current build as a direction-drift sample, not as a polish target.

## Premise Challenge

The Battle Lab premise still passes:

> Prove that `Launch / Tuning / Unit` can become readable frontline pressure before building shop, race, relic, economy, or map breadth.

The current implementation expression does not pass. It shows concepts beside each other instead of showing causal conversion through one machine.

If this prototype continues as a dashboard, it will optimize for label comprehension, not for the actual game promise.

## Direction Call

Next prototype target:

> A single visible ball-machine cutaway where balls flow through `Launch`, get modified by `Tuning`, fill `Unit`, and push the `Frontline`.

Do not build the next version as four equal UI panels.

The player should read one left-to-right physical chain:

```text
Forge / Pool / Launcher -> Prime / Echo / Surge -> Unit slots / queue -> Frontline pressure
```

The axes are still distinct, but they are parts of one machine, not separate dashboards.

## What To Keep

| Element | Decision | Rationale |
|---|---|---|
| `Launch / Tuning / Unit` formal terms | Keep | They are canonical and match the GDD. |
| Three presets: `Launch Flood`, `Tuning Echo`, `Unit Queue Burst` | Keep | They are still the cheapest informative failure test. |
| Three counters: `Pool Polluter`, `Echo Breaker`, `Stagger Punisher` | Keep | They pressure the correct machine components. |
| Axis-bound `Overdrive` | Keep | The screenshot already moved away from a global panic button, but feedback must move from button text into machine behavior. |
| 75 second battle duration target | Keep for now | Short enough for iteration, long enough for a counter and one power moment. |
| Primitive art | Keep | Final art is still not the question. Shape, timing, and cause are the question. |

## What To Discard

| Element | Decision | Rationale |
|---|---|---|
| Four equal columns as the primary composition | Cut | It reads as a design explainer, not a machine producing battle pressure. |
| Frontline as a chart-only result box | Cut | It does not feel like a battle line being affected by the machine. |
| Inactive frontline signatures visible during battle | Cut | They compete with the current result and make the screen look like a legend. Keep comparison for debug only. |
| Bilingual labels everywhere as primary readability | Cut | Labels can orient, but the prototype must pass through motion, shape, and timing. |
| Current `Tuning` as a static settings panel | Cut | `Prime / Echo / Surge` must be hit, charged, copied, or pulsed by passing balls. |
| Current `Unit` as a warehouse inventory display | Cut | Unit should read as slot filling, queue pressure, and release timing. |

## What To Rewrite

### 1. Screen Composition

Rewrite the battle screen as one machine silhouette or cutaway.

`Launch`, `Tuning`, and `Unit` should occupy connected zones on the same object. Boundaries can be drawn, but the ball path must cross those boundaries.

Expected read:

> "The ball came from here, got changed here, filled this, then that group pushed the line."

Current read:

> "There are four labeled panels."

That current read is not enough.

### 2. Frontline

Rewrite the frontline from chart panel to battle result strip.

Minimum version:

- one pressure line,
- one enemy pressure side,
- friendly arrivals from the Unit queue,
- pressure movement that changes differently for flow, repeated hit, and batch release.

The frontline can stay abstract. It cannot stay as only a labeled graph.

### 3. Tuning

`Tuning` must stop looking like menu state.

Each slot needs a visible relation to a ball:

- `Prime`: a passing ball gets a larger value marker before reaching Unit.
- `Echo`: a hit leaves a ghost copy that repeats.
- `Surge`: the caused queue batch gets speed chevrons.

No hidden math. No passive plaques as the main read.

### 4. Overdrive

The button can exist, but it is not the payoff.

On activation, the relevant machine zone must change for at least 1-2 seconds:

- `Launch Overdrive`: Pool head, return path, and launcher cadence surge.
- `Tuning Overdrive`: Echo ghost copies persist or multiply around the slot.
- `Unit Overdrive`: squad bracket releases or extends a visible group push.

If only the button glows, the design fails.

### 5. Counter Warnings

Counters must live on the component they attack:

- `Pool Polluter`: ghost Junk reserves Pool slots before entering.
- `Echo Breaker`: breaker mark appears on the Echo window before the copy collapses.
- `Stagger Punisher`: gap timer appears because no squad has deployed.

Do not use generic red alert language.

## Scope Change Log

| Feature | Decision | Rationale | Person-weeks freed/added |
|---|---|---|---:|
| Four-panel dashboard layout | Cut | Direction drift from game prototype into explainer UI. | -0.5 |
| Single machine cutaway battle screen | Add | Needed to express machine-to-frontline cause. | +1.0 |
| Chart-only frontline | Cut | Does not carry battle payoff. | -0.5 |
| Abstract pressure battle strip | Add | Keeps scope small while restoring combat read. | +0.75 |
| Tutorial-first fix | Defer | Tutorial cannot repair a wrong first screen. | -0.25 |
| External target-player validation as current blocker | Defer | Solo developer constraint. Use self-check until the screen direction is corrected. | -0.25 |
| Shop, races, relics, enemy roster | Keep cut | Still outside this prototype. | 0 |

Estimated scope delta: about +0.25 to +0.75 person-weeks if the current prototype is rewritten in place. Starting a separate narrow scene may be cheaper than trying to preserve the four-column layout.

## Risk Register

| Risk | Severity | Probability | Impact | Mitigation |
|---|---|---|---|---|
| Prototype remains an explainer dashboard | Critical | High | Validates whether labels are understandable, not whether the game works. | Replace four equal panels with one connected machine cutaway. |
| Frontline still reads as graph output | High | High | Player cannot feel machine events becoming pressure. | Use a pressure battle strip with arrivals and line movement. |
| `Tuning` remains hidden math | High | Medium | `Tuning Echo` becomes unreadable or reads as generic stronger output. | Make `Prime / Echo / Surge` physical events on passing balls and queue beats. |
| `Unit` dominates all readable feedback | High | Medium | Primary slice risk remains unresolved. | Keep Unit release visible but make Launch and Tuning traces visibly precede it. |
| Overdrive reads as a button state | High | Medium | It becomes UI action, not build amplification. | Activation must animate the affected machine zone and then the frontline consequence. |
| Solo validation becomes self-confirming | Medium | Medium | Developer may learn the screen instead of seeing it fresh. | Use fixed self-check captures and written answers before changing the build again. |

## Solo Developer Gate

Because external target players are not currently available, replace blind target-player validation with a solo gate for this iteration only.

Run each preset once after the rewrite. For each preset, capture:

1. before-axis event,
2. counter warning,
3. `Overdrive` activation,
4. frontline consequence.

Then answer before reading any debug log:

1. Which axis caused the current pressure?
2. Which component did the counter attack?
3. What did `Overdrive` amplify?
4. Why did the frontline move?

Failure rule:

> If the answer depends on labels or memory of the code instead of the captured motion, rewrite the screen again.

This is not a replacement for future player validation. It is a cheaper gate before asking anyone else to look.

## Completion Summary

```text
Direction Review:
  Premise Challenge: PASSED_WITH_CONCERNS
  Mode: FOCUSED
  Strategic Alignment:
    Patterns checked: 6/10
    Critical findings: 1
    High findings: 4
  Scope Review:
    Added: 2
    Kept: 6
    Deferred: 2
    Cut: 4
    Scope gap: +0.25 to +0.75 person-weeks
  Risk Assessment:
    Critical risks: 1
    High risks: 4
    Medium risks: 1
    Low risks: 0
    Unmitigated: 0
  Milestone:
    Current: Battle Lab direction recalibration
    Next gate: one connected machine-to-frontline scene replaces the four-column dashboard
    Critical path: rewrite composition first, then re-run feel-pass
  Next Step:
    PRIMARY: /implementation-handoff - write a replacement build package for a single-machine cutaway prototype
    AFTER BUILD EXISTS: /feel-pass - verify the causal trace from motion, not labels

  STATUS: DONE_WITH_CONCERNS
```
