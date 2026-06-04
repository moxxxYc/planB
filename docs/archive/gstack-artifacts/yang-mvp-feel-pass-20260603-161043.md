# Feel Pass: Three-Axis Readability Battle Lab

Game: planB
Branch: mvp
Date: 2026-06-03
Build: `prototype/three_axis_readability_battle_lab`
Handoff: `docs/gstack-artifacts/yang-mvp-handoff-20260603-111003.md`
Status: DONE_WITH_CONCERNS

## Target Feel

Accepted target feel for this pass:

- Overall: `Readable / Telegraphed`
- `Launch Flood`: `Flowing`
- `Tuning Echo`: `Staccato / Readable`
- `Unit Queue Burst`: `Charged / Released`
- `Overdrive`: `Snappy / Readable`
- Counter windows: `Telegraphed`

The soul is the machine-to-frontline causal trace. The player must see a machine-axis event happen before the matching frontline change.

## Evidence

Commands:

```bash
godot --version
godot --headless --path prototype/three_axis_readability_battle_lab --script tests/test_runner.gd
godot --path prototype/three_axis_readability_battle_lab
```

Observed:

- Godot version: `4.6.2.stable.official.71f334935`
- Headless tests: `PASS: 50 tests, 0 failures`
- Live run screenshots captured from the `godot` runtime window at approximately t0, t8, t28, t45, t50, and t80.
- Supporting code inspection: `battle_lab.tscn` does not instance `overdrive_button.tscn`; `overdrive_activation` is scheduled by controller logic instead of player input.

Headless tests prove the functional chain exists. They do not prove feel. The score below is based on live visual observation plus the missing input channel.

## Phase Findings

### Phase 1: Input To Response

Core `Overdrive` input is missing.

- Channel: input.
- Timing: cannot measure input to first visual change because the main scene has no clickable `Overdrive` button.
- Vocabulary: `disconnected`.

The build has an `overdrive_button.tscn`, but it is not part of the main Battle Lab scene. At t45 and t50, the scheduled `Overdrive` moment did not produce a visible button press, axis pulse, or clear lane amplification in the runtime window.

Result-answer input exists, but it is not the core mechanic feel. It cannot compensate for missing `Overdrive` input.

### Phase 2: Feedback Chain Completeness

`Launch` has a partial visual chain.

```text
ANTICIPATION: Pool / Forge / route visible.
ACTION: ball positions move between screenshots.
IMPACT: frontline does not clearly switch into one dominant Launch result.
RESOLUTION: no clear event trace or release beat before result.
```

- Channels: visual only.
- Timing: t0 to t8 shows ball motion and route/return movement.
- Vocabulary: `readable` but thin.

`Tuning` and `Unit` are present visually, but their chains are not isolated in this first battle sample.

- Channels: visual only.
- Timing: t0 through t50, Tuning plates and Unit queue are always visible and lightly moving.
- Vocabulary: `obscured`.

`Overdrive` feedback chain is broken.

```text
ANTICIPATION: no visible eligible button pulse observed.
ACTION: no player action.
IMPACT: no visible axis-bound amplification observed at t45/t50.
RESOLUTION: no clear axis event strip before result.
```

- Channels: visual absent for the critical moment, no audio, no haptic, no camera.
- Timing: scheduled window sampled at t45 and t50.
- Vocabulary: `cryptic` and `hollow`.

### Phase 3: Rhythm And Pacing

The loop is `monotonous`.

- Channels: visual.
- Timing: t0, t8, t28, t45, and t50 all show the same four columns with small local motion and no strong tension/release beat.
- The battle lasts 75 seconds, but observed intensity does not build into a clear counter, `Overdrive`, or frontline release moment.

There is motion, so this is not pure dead time. The problem is that the motion does not form a readable rhythm arc.

### Phase 4: Clarity And Readability

The screen is partially `readable`, then becomes `obscured`.

What works:

- The three axes are visible at once.
- `Launch` uses balls, FIFO Pool, route, and return arrows.
- `Tuning` uses slot plates and copy afterimages.
- `Unit` uses square slots, queue stack, and squad bracket.

What fails:

- The Frontline panel shows all three signatures at once, with no dominant current battle signature.
- Debug bilingual labels help orientation, but they are doing too much of the readability work.
- t80 result screen overlays answer fields directly over the battle view. Text and controls overlap the machine lanes, event strip, and frontline. This is `obscured`.

### Phase 5: Payoff And Energy

Payoff is `flat`.

- Channels: visual only.
- Timing: no visible payoff spike at t45/t50 for `Overdrive`; t80 result overlay appears, but it does not present a clean released moment.
- The player can see a lab screen, but not a strong "I caused that frontline change" release.

## Forcing Questions

Q1: Close your eyes and describe the mechanic from sound alone.

Answer: impossible. No audio feedback was observed. From sound alone, the player cannot distinguish Launch rhythm, Echo copy, Unit charge, counter warning, or `Overdrive`.

Q2: What is the first thing the player does, and how many milliseconds until something changes on screen?

Answer: for the core mechanic, there is no first player action. `Overdrive` is scheduled, not clicked. The required `Snappy / Readable` input-to-response target cannot be evaluated and should be treated as failed for this pass.

Q3: Play the core action 20 times in a row. On which repetition does it stop holding up?

Answer: cannot repeat `Overdrive` as a player action because the action is not exposed. For the passive battle loop, the issue appears before repetition 1: t0 through t50 already reads as a static lab with small looping movement.

Q4: Remove all visual effects. Is the action still readable?

Answer: the build is already mostly primitives and labels. The base shapes identify the three axes, but the active axis and payoff are not readable enough without labels.

## Score

```text
Feel Pass: Three-Axis Readability Battle Lab
═══════════════════════════════════════════
Target feel: Readable / Telegraphed causal trace, Flowing Launch, Staccato Tuning, Charged/Released Unit, Snappy/Readable Overdrive

  Responsiveness:     0/2  — core Overdrive input is missing; input→response timing cannot be measured
  Clarity:            1/2  — axes are readable, but active signature and result overlay are obscured
  Impact:             0/2  — Overdrive and counters have no observed impact beat; visual-only chain feels hollow
  Rhythm:             1/2  — motion exists, but t0-t50 is monotonous with weak tension/release
  Payoff:             0/2  — no clear released moment after Overdrive or frontline change
  Dead Time:          1/2  — not empty, but 75s loop has long passive stretches without strong events
  Overload:           1/2  — low visual noise, but all frontline signatures and result overlay compete for attention
  ─────────────────────────
  TOTAL:              4/14 — MUDDY

Top 3 Feel Blockers:
  1. Input/visual, t45-t50: Overdrive is disconnected. No player input and no visible axis-bound response.
  2. Visual, t0-t50: Frontline is obscured. All three signatures show at once instead of one active payoff.
  3. Visual, t80: Result screen is obscured. Answer UI overlaps battle lanes and event strip.
═══════════════════════════════════════════
```

## Required Feel Fix Targets

These are symptoms and target channels, not implementation instructions:

1. `Overdrive` needs a real input channel and a visible first response within 250ms.
2. The active frontline signature needs to become P0 during a battle. The inactive signatures should not compete equally.
3. Counter windows need a visible `Telegraphed` moment in the runtime view, not only tests.
4. Result flow needs readable separation between event strip, frozen battle view, and answer fields.
5. Audio is currently absent. At minimum, counter warning, `Overdrive`, and frontline payoff need distinct audio channels before this can score above `FLAT`.

## Completion Summary

```text
/feel-pass complete

Mechanic: Three-Axis Readability Battle Lab
Target feel: Readable / Telegraphed causal trace
Score: 4/14 — MUDDY
Delta from prior: first run

Top blocker: Overdrive is disconnected. The core action has no player input and no visible axis-bound response at the scheduled moment.

Status: DONE_WITH_CONCERNS

Next Step:
  PRIMARY: /implementation-handoff — rework the build package around the missing Overdrive input, active frontline P0, and result-screen readability
  (after fixes exist): /feel-pass — rerun against the same target feel and compare score delta
```
