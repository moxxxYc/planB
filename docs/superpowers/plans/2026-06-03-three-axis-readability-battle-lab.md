# Three-Axis Readability Battle Lab Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a fresh, scoped Battle Lab where target players can watch `Launch / Tuning / Unit` machine events turn into three distinct frontline pressure patterns, then answer blind causality questions after each battle.

**Architecture:** Create a new, isolated Godot 4.x prototype under `prototype/three_axis_readability_battle_lab/`. The prototype is data-driven enough to run exactly three hardcoded presets, but it must not become a shop, race, relic, economy, enemy-roster, or old Web MVP rebuild. The core chain is `Launch lane -> Tuning lane -> Unit lane -> Frontline result -> Result questions`, with deterministic event traces for playtest scoring.

**Tech Stack:** Godot 4.x, GDScript, Godot scenes, headless GDScript smoke tests, local JSON/CSV answer records. No npm, Vite, Phaser, backend, networking, telemetry service, Steam integration, or restored Web MVP source tree.

---

## Plan Boundary

This document is an implementation plan only. It intentionally does not create source files, scaffold the Godot project, or revive deleted implementation code.

The request for this planning turn says "do not write code", so the task steps below specify exact files, behavior, test assertions, commands, and acceptance checks without embedding implementation source listings. During execution, the implementing agent must write code test-first inside the paths named here.

## Source Inputs

- `AGENTS.md`: repo is docs-only; current implementation must start fresh; formal terms are `Launch`, `Tuning`, `Unit`; Tuning base slots are `Prime`, `Echo`, `Surge`; no PVP, networking, accounts, backend, matchmaking, Steam integration, free RTS map, or complex RTS pathfinding.
- `docs/gdd.md`: canonical formal design; readability before content breadth; `Overdrive` is build amplification; early build shapes are `Launch Flood`, `Tuning Echo`, and `Unit Queue Burst`.
- `docs/PROGRESS.md`: recent decision log; selected validation slice is `Mechanic Prototype: Three-Axis Readability Battle Lab`; no runnable app or automated validation currently exists.
- `docs/gstack-artifacts/yang-mvp-slice-plan-20260602-215006.md`: slice spec; one battle screen, three hardcoded presets, three 60-90s battles, one axis-bound `Overdrive` per battle, blind post-battle causality questions.
- `docs/gstack-artifacts/yang-mvp-plan-design-review-20260602-215729.md`: readability review; adds battle hierarchy, axis visual grammar, counter states, `Overdrive` directionality, event strip, and answer recording rules.
- `docs/gstack-artifacts/yang-mvp-handoff-20260603-111003.md`: build handoff; defines real vs placeholder systems, acceptance criteria, known risks, and test hooks.

## Scope Guard

Build these:

- One fresh Battle Lab prototype.
- One screen with all three axes visible at once.
- Three hardcoded battle presets:
  - `Launch Flood`
  - `Tuning Echo`
  - `Unit Queue Burst`
- Three deterministic 75-second battles, one preset per battle.
- One clear counter window per battle:
  - `Pool Polluter`
  - `Echo Breaker`
  - `Stagger Punisher`
- One axis-bound `Overdrive` opportunity per battle.
- Three frontline signatures:
  - sustained flow,
  - repeated heavy hit,
  - batch charge and release.
- Result freeze, four-lane event strip, blind answer form, confidence capture, observer notes, and two diagnostic flags.
- Headless tests plus manual playtest guide.

Do not build these:

- Shop.
- Race expansion, Hive, Mech, Arcane, formal unit roster, Guardian/base identity.
- Relics.
- Gold curve, post-battle settlement, economy.
- Node map, events, elites, Bosses, full enemy table.
- Save, meta progression, unlocks, full settings menu, production main menu.
- Backend, accounts, telemetry service, networking, matchmaking, Steam integration.
- Old `src/`, `public/`, `scripts/`, `package.json`, Vite, Phaser, or generated Web MVP assets.
- Free RTS battlefield, unit micro, complex pathfinding.

## Fresh Runtime Choice

Use Godot 4.x for the prototype.

Reason:

- It aligns with a future desktop-first game implementation better than restoring the deleted Web MVP.
- It is enough for 2D primitives, deterministic timelines, input, screenshot capture, and headless smoke tests.
- It avoids package-script continuity with the obsolete Vite/Phaser prototype.

Implementation root:

- `prototype/three_axis_readability_battle_lab/`

Important execution note:

- Before coding, run `git status --short`.
- Do not stage, revert, or mix unrelated existing docs-only cleanup changes.
- If execution starts while the worktree is still dirty, create or switch to a dedicated branch/worktree after the user confirms the current docs-only cleanup state.

## File Structure

Create:

- `prototype/three_axis_readability_battle_lab/project.godot`  
  Godot project file for the Battle Lab only.
- `prototype/three_axis_readability_battle_lab/README.md`  
  Local prototype scope, run commands, test commands, and out-of-scope warnings.
- `prototype/three_axis_readability_battle_lab/scenes/battle_lab.tscn`  
  Main single-screen scene.
- `prototype/three_axis_readability_battle_lab/scenes/machine/launch_lane.tscn`  
  Launch lane view: Forge, Pool, Launcher, return arrows, Junk occupancy.
- `prototype/three_axis_readability_battle_lab/scenes/machine/tuning_lane.tscn`  
  Tuning lane view: `Prime / Echo / Surge`, hot slot, copy afterimage, breaker state.
- `prototype/three_axis_readability_battle_lab/scenes/machine/unit_lane.tscn`  
  Unit lane view: slot fill chunks, queue stack, squad bracket.
- `prototype/three_axis_readability_battle_lab/scenes/frontline/frontline_view.tscn`  
  Abstract constrained frontline pressure view.
- `prototype/three_axis_readability_battle_lab/scenes/ui/overdrive_button.tscn`  
  Axis-bound `Overdrive` button.
- `prototype/three_axis_readability_battle_lab/scenes/ui/event_strip.tscn`  
  Four-lane post-battle event strip.
- `prototype/three_axis_readability_battle_lab/scenes/ui/result_screen.tscn`  
  Result freeze and blind answer form.
- `prototype/three_axis_readability_battle_lab/scripts/battle_lab_controller.gd`  
  Main orchestration for scene state, battle sequence, result flow, and playtest mode.
- `prototype/three_axis_readability_battle_lab/scripts/model/axis_ids.gd`  
  Canonical axis ids and labels: `launch`, `tuning`, `unit`.
- `prototype/three_axis_readability_battle_lab/scripts/model/preset_defs.gd`  
  Three hardcoded preset definitions and timing constants.
- `prototype/three_axis_readability_battle_lab/scripts/model/event_record.gd`  
  Event strip record shape and answer-scoring fields.
- `prototype/three_axis_readability_battle_lab/scripts/model/answer_record.gd`  
  Post-battle answer schema, confidence values, observer notes, and flags.
- `prototype/three_axis_readability_battle_lab/scripts/systems/battle_sequence.gd`  
  Three-battle ordering, seeded randomization, result transitions.
- `prototype/three_axis_readability_battle_lab/scripts/systems/battle_clock.gd`  
  Deterministic 75-second battle timer and scheduled windows.
- `prototype/three_axis_readability_battle_lab/scripts/systems/machine_simulator.gd`  
  Deterministic machine event production for all presets.
- `prototype/three_axis_readability_battle_lab/scripts/systems/counter_controller.gd`  
  Warning, active, and recovery states for all three counters.
- `prototype/three_axis_readability_battle_lab/scripts/systems/overdrive_controller.gd`  
  Axis-bound eligibility, activation, low-yield unrelated use, and event logging.
- `prototype/three_axis_readability_battle_lab/scripts/systems/frontline_model.gd`  
  Abstract frontline pressure model and three signature outputs.
- `prototype/three_axis_readability_battle_lab/scripts/ui/launch_lane_view.gd`  
  Launch lane primitive rendering and state binding.
- `prototype/three_axis_readability_battle_lab/scripts/ui/tuning_lane_view.gd`  
  Tuning lane primitive rendering and state binding.
- `prototype/three_axis_readability_battle_lab/scripts/ui/unit_lane_view.gd`  
  Unit lane primitive rendering and state binding.
- `prototype/three_axis_readability_battle_lab/scripts/ui/frontline_view.gd`  
  Frontline signature rendering and state binding.
- `prototype/three_axis_readability_battle_lab/scripts/ui/event_strip_view.gd`  
  Four-lane event strip rendering.
- `prototype/three_axis_readability_battle_lab/scripts/ui/result_screen_controller.gd`  
  Blind question flow, local record creation, answer export.
- `prototype/three_axis_readability_battle_lab/tests/test_runner.gd`  
  Headless test entrypoint.
- `prototype/three_axis_readability_battle_lab/tests/test_scope_guard.gd`  
  Fails on banned restored Web MVP paths or banned feature categories.
- `prototype/three_axis_readability_battle_lab/tests/test_preset_defs.gd`  
  Verifies exact preset and axis data.
- `prototype/three_axis_readability_battle_lab/tests/test_battle_sequence.gd`  
  Verifies battle ordering, duration, and result transitions.
- `prototype/three_axis_readability_battle_lab/tests/test_machine_events.gd`  
  Verifies each preset produces the right machine event trace before the frontline change.
- `prototype/three_axis_readability_battle_lab/tests/test_counter_states.gd`  
  Verifies counter warning, active, and recovery order.
- `prototype/three_axis_readability_battle_lab/tests/test_overdrive_directionality.gd`  
  Verifies axis-bound `Overdrive` and low-yield unrelated use.
- `prototype/three_axis_readability_battle_lab/tests/test_answer_records.gd`  
  Verifies answer schema and flags.
- `prototype/three_axis_readability_battle_lab/playtest/guide.md`  
  Observer script, one-minute briefing, scoring rules.
- `prototype/three_axis_readability_battle_lab/playtest/answer_sheet_template.csv`  
  Manual/local answer sheet template.
- `prototype/three_axis_readability_battle_lab/playtest/scoring_guide.md`  
  Correct-answer rules for the four questions.

Modify:

- `README.md` only if implementation actually begins and the repo needs a link to the prototype run instructions.
- `docs/PROGRESS.md` only after implementation or playtest results exist. Do not update it just because this plan exists.
- `.gitignore` only during implementation if Godot import/cache folders need ignoring.

Do not modify:

- `docs/gdd.md` during implementation unless playtest evidence reveals a design contradiction that the user explicitly accepts.
- `docs/gstack-artifacts/*`; treat these as source artifacts for this plan.

## Shared Constants

Use these ids consistently:

| Concept | Id | Label |
|---|---|---|
| Axis | `launch` | `Launch` |
| Axis | `tuning` | `Tuning` |
| Axis | `unit` | `Unit` |
| Tuning slot | `prime` | `Prime` |
| Tuning slot | `echo` | `Echo` |
| Tuning slot | `surge` | `Surge` |
| Preset | `launch_flood` | `Launch Flood` |
| Preset | `tuning_echo` | `Tuning Echo` |
| Preset | `unit_queue_burst` | `Unit Queue Burst` |
| Counter | `pool_polluter` | `Pool Polluter` |
| Counter | `echo_breaker` | `Echo Breaker` |
| Counter | `stagger_punisher` | `Stagger Punisher` |
| Frontline signature | `sustained_flow` | `Sustained flow` |
| Frontline signature | `repeated_heavy_hit` | `Repeated heavy hit` |
| Frontline signature | `batch_charge_release` | `Batch charge and release` |

Use these timings unless playtest evidence justifies a later plan revision:

| Timing | Value |
|---|---:|
| Battle duration | 75 seconds |
| Counter warning | 2.5 seconds |
| Counter active | 3.0 seconds |
| Counter recovery trace | 2.0 seconds |
| Launch first readable trace | by 10 seconds |
| Tuning first readable trace | by 15 seconds |
| Unit first readable trace | by 15 seconds |
| `Overdrive` visible response after click | within 250 ms |
| Result screen appears after battle end | within 5 seconds |

## Tasks

### Task 1: Fresh Godot Lab Scaffold And Scope Guard

**Files:**

- Create: `prototype/three_axis_readability_battle_lab/project.godot`
- Create: `prototype/three_axis_readability_battle_lab/README.md`
- Create: `prototype/three_axis_readability_battle_lab/tests/test_runner.gd`
- Create: `prototype/three_axis_readability_battle_lab/tests/test_scope_guard.gd`
- Modify: `.gitignore` only if Godot cache/import files appear during implementation

- [ ] **Step 1: Confirm current repo state**

Run:

```bash
git status --short
```

Expected:

- Existing docs-only cleanup changes may be present.
- Do not revert or stage unrelated changes.
- Stop and ask before execution if unrelated dirty files would be mixed with prototype files.

- [ ] **Step 2: Verify Godot is available**

Run:

```bash
godot --version
```

Expected:

- Prints Godot 4.x.
- If the command is missing, install or configure Godot before writing prototype code.

- [ ] **Step 3: Create a nested Godot project**

Create only under:

```text
prototype/three_axis_readability_battle_lab/
```

Expected:

- `project.godot` exists.
- No `package.json`, `src/`, `public/`, Vite config, Phaser dependency, or generated Web MVP asset directory is created.

- [ ] **Step 4: Write the scope guard test first**

In `tests/test_scope_guard.gd`, assert:

- repo root has no restored `package.json`,
- repo root has no restored `src/`,
- repo root has no restored `public/assets/generated/`,
- prototype scripts do not contain new feature-category directories named `shop`, `relic`, `economy`, `race`, `enemy_roster`, `network`, `backend`, `steam`, or `matchmaking`,
- allowed enemy work is only the three counter ids from this plan.

- [ ] **Step 5: Run the guard before feature work**

Run:

```bash
godot --headless --path prototype/three_axis_readability_battle_lab --script tests/test_runner.gd -- --filter test_scope_guard
```

Expected:

- PASS after the scaffold and guard are wired.
- FAIL if any banned Web MVP or out-of-scope feature path has been restored.

- [ ] **Step 6: Commit only scaffold and guard files**

Run:

```bash
git add prototype/three_axis_readability_battle_lab/project.godot prototype/three_axis_readability_battle_lab/README.md prototype/three_axis_readability_battle_lab/tests/test_runner.gd prototype/three_axis_readability_battle_lab/tests/test_scope_guard.gd
git commit -m "chore: scaffold three-axis battle lab"
```

Expected:

- Commit contains only the fresh Battle Lab scaffold and guard.
- No unrelated docs-only cleanup files are included unless the user explicitly asked to commit them.

### Task 2: Preset Data Contracts

**Files:**

- Create: `prototype/three_axis_readability_battle_lab/scripts/model/axis_ids.gd`
- Create: `prototype/three_axis_readability_battle_lab/scripts/model/preset_defs.gd`
- Create: `prototype/three_axis_readability_battle_lab/tests/test_preset_defs.gd`

- [ ] **Step 1: Write preset data tests first**

In `tests/test_preset_defs.gd`, assert:

- there are exactly three axes: `launch`, `tuning`, `unit`,
- there are exactly three Tuning slots: `prime`, `echo`, `surge`,
- there are exactly three presets: `launch_flood`, `tuning_echo`, `unit_queue_burst`,
- each preset has exactly one primary axis,
- each preset has exactly one matching counter,
- each preset has exactly one matching frontline signature,
- each preset has exactly one matching `Overdrive` label,
- every battle duration is exactly 75 seconds,
- no preset contains shop, race, relic, Gold, event, elite, Boss, or economy fields.

- [ ] **Step 2: Run preset tests and verify failure**

Run:

```bash
godot --headless --path prototype/three_axis_readability_battle_lab --script tests/test_runner.gd -- --filter test_preset_defs
```

Expected:

- FAIL because `axis_ids.gd` and `preset_defs.gd` do not exist yet.

- [ ] **Step 3: Implement axis ids and preset definitions**

In `axis_ids.gd`, define canonical ids and labels only.

In `preset_defs.gd`, define:

| Preset | Axis | Counter | Frontline signature | `Overdrive` label |
|---|---|---|---|---|
| `launch_flood` | `launch` | `pool_polluter` | `sustained_flow` | `Launch Overdrive` |
| `tuning_echo` | `tuning` | `echo_breaker` | `repeated_heavy_hit` | `Tuning Overdrive` |
| `unit_queue_burst` | `unit` | `stagger_punisher` | `batch_charge_release` | `Unit Overdrive` |

- [ ] **Step 4: Run preset tests and verify pass**

Run:

```bash
godot --headless --path prototype/three_axis_readability_battle_lab --script tests/test_runner.gd -- --filter test_preset_defs
```

Expected:

- PASS.

- [ ] **Step 5: Commit preset contracts**

Run:

```bash
git add prototype/three_axis_readability_battle_lab/scripts/model/axis_ids.gd prototype/three_axis_readability_battle_lab/scripts/model/preset_defs.gd prototype/three_axis_readability_battle_lab/tests/test_preset_defs.gd
git commit -m "test: lock battle lab preset contracts"
```

Expected:

- Commit contains only data contract files and their tests.

### Task 3: Battle Sequencing And Clock

**Files:**

- Create: `prototype/three_axis_readability_battle_lab/scripts/systems/battle_clock.gd`
- Create: `prototype/three_axis_readability_battle_lab/scripts/systems/battle_sequence.gd`
- Create: `prototype/three_axis_readability_battle_lab/tests/test_battle_sequence.gd`

- [ ] **Step 1: Write sequence tests first**

In `tests/test_battle_sequence.gd`, assert:

- internal default order is `launch_flood`, `tuning_echo`, `unit_queue_burst`,
- playtest mode can return a seeded randomized order that still contains each preset exactly once,
- each battle starts at `time = 0.0`,
- each battle ends at `time = 75.0`,
- result flow starts after battle end,
- battle sequence ends only after all three result flows are completed.

- [ ] **Step 2: Run sequence tests and verify failure**

Run:

```bash
godot --headless --path prototype/three_axis_readability_battle_lab --script tests/test_runner.gd -- --filter test_battle_sequence
```

Expected:

- FAIL because sequencing is not implemented.

- [ ] **Step 3: Implement clock and sequence**

Implement:

- a deterministic battle clock with manual tick support for tests,
- a sequence state machine with states `idle`, `battle_running`, `result_pending`, `result_recorded`, `complete`,
- fixed internal order for development,
- seeded randomization for playtest mode,
- no node map, menu campaign, save slot, or meta progression.

- [ ] **Step 4: Run sequence tests and verify pass**

Run:

```bash
godot --headless --path prototype/three_axis_readability_battle_lab --script tests/test_runner.gd -- --filter test_battle_sequence
```

Expected:

- PASS.

- [ ] **Step 5: Commit sequence work**

Run:

```bash
git add prototype/three_axis_readability_battle_lab/scripts/systems/battle_clock.gd prototype/three_axis_readability_battle_lab/scripts/systems/battle_sequence.gd prototype/three_axis_readability_battle_lab/tests/test_battle_sequence.gd
git commit -m "feat: sequence battle lab presets"
```

Expected:

- Commit contains sequencing and clock only.

### Task 4: Deterministic Machine Event Simulation

**Files:**

- Create: `prototype/three_axis_readability_battle_lab/scripts/systems/machine_simulator.gd`
- Create: `prototype/three_axis_readability_battle_lab/scripts/model/event_record.gd`
- Create: `prototype/three_axis_readability_battle_lab/tests/test_machine_events.gd`

- [ ] **Step 1: Write machine event tests first**

In `tests/test_machine_events.gd`, assert:

- `launch_flood` emits Pool refill, return-arrow, launcher-cadence, and sustained-flow precursor events before the first frontline flow event,
- `tuning_echo` emits Echo hot-slot, copy-afterimage, and repeated-hit precursor events before the first frontline stepped-impact event,
- `unit_queue_burst` emits slot-fill, queue-stack, and squad-bracket precursor events before the first frontline grouped-push event,
- first Launch trace happens by 10 seconds,
- first Tuning trace happens by 15 seconds,
- first Unit trace happens by 15 seconds,
- event records include `time`, `lane`, `event_type`, `preset_id`, `axis_id`, `counter_id`, `frontline_signature`, and `readability_tag`,
- no event record uses generic labels such as only `more_units` or `stronger`.

- [ ] **Step 2: Run machine tests and verify failure**

Run:

```bash
godot --headless --path prototype/three_axis_readability_battle_lab --script tests/test_runner.gd -- --filter test_machine_events
```

Expected:

- FAIL because machine event simulation is not implemented.

- [ ] **Step 3: Implement Launch Flood event script**

Implement deterministic Launch behavior:

- Forge signal roughly every 1.0 second.
- Launcher signal roughly every 1.3 seconds outside `Overdrive`.
- Pool capacity is 5.
- Pool head is always identifiable in emitted state.
- `Front Return` emits return-arrow events that feed near the Pool front.
- Frontline signal is `sustained_flow`, not one large impact or batch release.

- [ ] **Step 4: Implement Tuning Echo event script**

Implement deterministic Tuning behavior:

- `Prime / Echo / Surge` slots exist in emitted state.
- Echo hot-slot window appears before the copy.
- Echo copy-afterimage event occurs before repeated frontline impact.
- Surge chevrons appear only when that hit accelerates deployment caused by the triggering Unit result.
- Frontline signal is `repeated_heavy_hit`, not continuous flow.

- [ ] **Step 5: Implement Unit Queue Burst event script**

Implement deterministic Unit behavior:

- Unit slots fill in visible chunks.
- Same-unit queue entries stack.
- Squad bracket forms before release.
- A quiet charge gap exists before grouped push.
- Frontline signal is `batch_charge_release`, not a faster stream.

- [ ] **Step 6: Run machine tests and verify pass**

Run:

```bash
godot --headless --path prototype/three_axis_readability_battle_lab --script tests/test_runner.gd -- --filter test_machine_events
```

Expected:

- PASS.

- [ ] **Step 7: Commit machine simulation**

Run:

```bash
git add prototype/three_axis_readability_battle_lab/scripts/systems/machine_simulator.gd prototype/three_axis_readability_battle_lab/scripts/model/event_record.gd prototype/three_axis_readability_battle_lab/tests/test_machine_events.gd
git commit -m "feat: simulate three machine axis traces"
```

Expected:

- Commit contains deterministic machine simulation only.

### Task 5: Counter State Scripts

**Files:**

- Create: `prototype/three_axis_readability_battle_lab/scripts/systems/counter_controller.gd`
- Create: `prototype/three_axis_readability_battle_lab/tests/test_counter_states.gd`

- [ ] **Step 1: Write counter tests first**

In `tests/test_counter_states.gd`, assert:

- every counter has states `warning`, `active`, `recovery`, `complete`,
- warning lasts 2.5 seconds,
- active lasts 3.0 seconds,
- recovery trace lasts 2.0 seconds,
- `Pool Polluter` targets Pool slots and inserts 2-3 Junk balls,
- `Echo Breaker` targets an Echo hot slot or Echo window and weakens or swallows the next copy,
- `Stagger Punisher` targets a long no-deployment gap and marks a gap hit,
- warnings are component-local and not generic full-screen alerts.

- [ ] **Step 2: Run counter tests and verify failure**

Run:

```bash
godot --headless --path prototype/three_axis_readability_battle_lab --script tests/test_runner.gd -- --filter test_counter_states
```

Expected:

- FAIL because counter states are not implemented.

- [ ] **Step 3: Implement `Pool Polluter`**

Implement:

- 2.5-second ghost Junk warning on Pool slots,
- 2-3 active Junk balls occupying capacity,
- launcher rhythm stutter or wasted-shot effect,
- 2.0-second polluted-slot recovery trace after Junk fires and disappears.

- [ ] **Step 4: Implement `Echo Breaker`**

Implement:

- 2.5-second break mark on the Echo slot/window,
- active collapse or weakening of expected copy afterimage,
- 2.0-second recovery afterimage showing the repeated hit failed or shrank.

- [ ] **Step 5: Implement `Stagger Punisher`**

Implement:

- gap timer warning during long no-deployment window,
- active pressure during the charge gap,
- 2.0-second gap-hit marker,
- squad release can still answer after the hit if it arrives.

- [ ] **Step 6: Run counter tests and verify pass**

Run:

```bash
godot --headless --path prototype/three_axis_readability_battle_lab --script tests/test_runner.gd -- --filter test_counter_states
```

Expected:

- PASS.

- [ ] **Step 7: Commit counters**

Run:

```bash
git add prototype/three_axis_readability_battle_lab/scripts/systems/counter_controller.gd prototype/three_axis_readability_battle_lab/tests/test_counter_states.gd
git commit -m "feat: add readable counter states"
```

Expected:

- Commit contains counter scripts and tests only.

### Task 6: Axis-Bound Overdrive

**Files:**

- Create: `prototype/three_axis_readability_battle_lab/scripts/systems/overdrive_controller.gd`
- Create: `prototype/three_axis_readability_battle_lab/scenes/ui/overdrive_button.tscn`
- Create: `prototype/three_axis_readability_battle_lab/tests/test_overdrive_directionality.gd`

- [ ] **Step 1: Write `Overdrive` tests first**

In `tests/test_overdrive_directionality.gd`, assert:

- each preset exposes exactly one matching `Overdrive`,
- `Launch Overdrive` is eligible only when return balls, Pool pressure, or launcher throughput can be amplified,
- `Tuning Overdrive` is eligible only when Echo hot state or Echo window exists,
- `Unit Overdrive` is eligible only when a squad chain or same-unit queue buildup exists,
- activation logs the amplified axis and component,
- unrelated emergency activation is allowed only as low-yield and does not emit shield, heal, freeze, clear-screen, or rescue events,
- `Overdrive` events are attached to the affected lane, not base HP or a universal panic area.

- [ ] **Step 2: Run `Overdrive` tests and verify failure**

Run:

```bash
godot --headless --path prototype/three_axis_readability_battle_lab --script tests/test_runner.gd -- --filter test_overdrive_directionality
```

Expected:

- FAIL because `Overdrive` is not implemented.

- [ ] **Step 3: Implement axis-specific eligibility**

Implement:

- one `Overdrive` charge per battle,
- axis-specific label from preset data,
- lane-attached state,
- eligibility pulse only when matching axis state exists,
- low-yield unrelated use with a visibly weak lane effect and no survival wording.

- [ ] **Step 4: Implement axis-specific activation effects**

Implement:

- Launch: return arrows and Launcher cadence intensify.
- Tuning: Echo afterimages persist or repeat without consuming hot state.
- Unit: squad bracket releases or extends the chain.
- Every activation writes an event strip record with `axis_id`, `component_id`, and `overdrive_yield`.

- [ ] **Step 5: Run `Overdrive` tests and verify pass**

Run:

```bash
godot --headless --path prototype/three_axis_readability_battle_lab --script tests/test_runner.gd -- --filter test_overdrive_directionality
```

Expected:

- PASS.

- [ ] **Step 6: Commit `Overdrive` work**

Run:

```bash
git add prototype/three_axis_readability_battle_lab/scripts/systems/overdrive_controller.gd prototype/three_axis_readability_battle_lab/scenes/ui/overdrive_button.tscn prototype/three_axis_readability_battle_lab/tests/test_overdrive_directionality.gd
git commit -m "feat: bind overdrive to machine axes"
```

Expected:

- Commit contains `Overdrive` work only.

### Task 7: One-Screen Machine And Frontline Views

**Files:**

- Create: `prototype/three_axis_readability_battle_lab/scenes/battle_lab.tscn`
- Create: `prototype/three_axis_readability_battle_lab/scenes/machine/launch_lane.tscn`
- Create: `prototype/three_axis_readability_battle_lab/scenes/machine/tuning_lane.tscn`
- Create: `prototype/three_axis_readability_battle_lab/scenes/machine/unit_lane.tscn`
- Create: `prototype/three_axis_readability_battle_lab/scenes/frontline/frontline_view.tscn`
- Create: `prototype/three_axis_readability_battle_lab/scripts/battle_lab_controller.gd`
- Create: `prototype/three_axis_readability_battle_lab/scripts/ui/launch_lane_view.gd`
- Create: `prototype/three_axis_readability_battle_lab/scripts/ui/tuning_lane_view.gd`
- Create: `prototype/three_axis_readability_battle_lab/scripts/ui/unit_lane_view.gd`
- Create: `prototype/three_axis_readability_battle_lab/scripts/ui/frontline_view.gd`
- Create: `prototype/three_axis_readability_battle_lab/scripts/systems/frontline_model.gd`

- [ ] **Step 1: Add scene smoke checks to the existing tests**

Extend tests to assert:

- all three lanes are instantiated on the same battle screen,
- all three axes remain visible at once,
- lane order is `Launch -> Tuning -> Unit -> Frontline`,
- active axis is shown through shape, motion, and timing, not color alone,
- debug labels exist but are not the only source of readability.

- [ ] **Step 2: Run scene smoke checks and verify failure**

Run:

```bash
godot --headless --path prototype/three_axis_readability_battle_lab --script tests/test_runner.gd -- --filter scene_smoke
```

Expected:

- FAIL because scenes are not implemented.

- [ ] **Step 3: Implement Launch lane view**

Implement primitives and state binding for:

- round balls,
- FIFO Pool slots,
- highlighted Pool head,
- forward launch arrows,
- return arrows,
- Junk balls with shape or pattern distinction, not color alone.

- [ ] **Step 4: Implement Tuning lane view**

Implement primitives and state binding for:

- `Prime / Echo / Surge` plates,
- Prime value plaque,
- Echo copy afterimage,
- Echo hot-slot window,
- Surge chevrons tied to the triggering Unit result.

- [ ] **Step 5: Implement Unit lane view**

Implement primitives and state binding for:

- square slot tiles,
- fill chunks,
- queue stack,
- squad bracket,
- grouped release trace.

- [ ] **Step 6: Implement frontline view**

Implement the three signatures:

- `sustained_flow`: many small arrivals and smooth pressure-line movement,
- `repeated_heavy_hit`: fewer arrivals or waves with larger stepped jumps and double-impact afterimage,
- `batch_charge_release`: quiet charge gap followed by one grouped push.

- [ ] **Step 7: Run scene smoke checks and verify pass**

Run:

```bash
godot --headless --path prototype/three_axis_readability_battle_lab --script tests/test_runner.gd -- --filter scene_smoke
```

Expected:

- PASS.

- [ ] **Step 8: Run the prototype manually**

Run:

```bash
godot --path prototype/three_axis_readability_battle_lab
```

Expected:

- Opens directly to the Battle Lab screen.
- All three lanes and the frontline are visible without opening tabs.
- No menu, shop, race selector, relic panel, economy panel, or node map appears.

- [ ] **Step 9: Commit views**

Run:

```bash
git add prototype/three_axis_readability_battle_lab/scenes prototype/three_axis_readability_battle_lab/scripts/battle_lab_controller.gd prototype/three_axis_readability_battle_lab/scripts/ui prototype/three_axis_readability_battle_lab/scripts/systems/frontline_model.gd
git commit -m "feat: render battle lab causal chain"
```

Expected:

- Commit contains scene and UI work only.

### Task 8: Result Screen, Event Strip, And Answer Records

**Files:**

- Create: `prototype/three_axis_readability_battle_lab/scenes/ui/event_strip.tscn`
- Create: `prototype/three_axis_readability_battle_lab/scenes/ui/result_screen.tscn`
- Create: `prototype/three_axis_readability_battle_lab/scripts/ui/event_strip_view.gd`
- Create: `prototype/three_axis_readability_battle_lab/scripts/ui/result_screen_controller.gd`
- Create: `prototype/three_axis_readability_battle_lab/scripts/model/answer_record.gd`
- Create: `prototype/three_axis_readability_battle_lab/tests/test_answer_records.gd`

- [ ] **Step 1: Write answer-record tests first**

In `tests/test_answer_records.gd`, assert:

- result screen appears after each 75-second battle,
- battle result freezes before questions are shown,
- no answer key is shown before responses are recorded,
- event strip has exactly four lanes: axis events, counter warning/active/effect, `Overdrive`, frontline pressure changes,
- answer record includes all required fields:
  - `player_id`,
  - `battle_order`,
  - `hidden_preset`,
  - `answer_axis`,
  - `answer_counter`,
  - `answer_overdrive`,
  - `answer_frontline_cause`,
  - `confidence_axis_1_to_5`,
  - `confidence_counter_1_to_5`,
  - `confidence_overdrive_1_to_5`,
  - `confidence_frontline_1_to_5`,
  - `observer_notes`,
  - `correct_count_0_to_4`,
  - `unit_only_bias_flag`,
  - `overdrive_panic_flag`,
- confidence values reject anything outside 1-5,
- answer records can be exported locally without a backend.

- [ ] **Step 2: Run answer-record tests and verify failure**

Run:

```bash
godot --headless --path prototype/three_axis_readability_battle_lab --script tests/test_runner.gd -- --filter test_answer_records
```

Expected:

- FAIL because result flow is not implemented.

- [ ] **Step 3: Implement event strip**

Implement:

- axis events lane,
- counter lane,
- `Overdrive` lane,
- frontline lane,
- chronological markers with `time`, `lane`, `event_type`, and `axis_id`,
- no explanatory answer text before responses are recorded.

- [ ] **Step 4: Implement answer form**

Implement:

- axis selection: `Launch / Tuning / Unit / Unsure`,
- counter selection plus short text,
- `Overdrive` axis selection plus observed component,
- frontline cause text plus optional signature selection,
- four confidence controls from 1 to 5,
- observer notes,
- local record creation.

- [ ] **Step 5: Implement scoring flags**

Implement:

- `unit_only_bias_flag` when answer wording reduces causality to only "more units" or equivalent generic unit output,
- `overdrive_panic_flag` when answer wording treats `Overdrive` mainly as rescue, shield, heal, freeze, clear-screen, or panic button,
- `correct_count_0_to_4` set by observer scoring after response capture.

- [ ] **Step 6: Run answer-record tests and verify pass**

Run:

```bash
godot --headless --path prototype/three_axis_readability_battle_lab --script tests/test_runner.gd -- --filter test_answer_records
```

Expected:

- PASS.

- [ ] **Step 7: Commit result flow**

Run:

```bash
git add prototype/three_axis_readability_battle_lab/scenes/ui/event_strip.tscn prototype/three_axis_readability_battle_lab/scenes/ui/result_screen.tscn prototype/three_axis_readability_battle_lab/scripts/ui/event_strip_view.gd prototype/three_axis_readability_battle_lab/scripts/ui/result_screen_controller.gd prototype/three_axis_readability_battle_lab/scripts/model/answer_record.gd prototype/three_axis_readability_battle_lab/tests/test_answer_records.gd
git commit -m "feat: record battle lab causality answers"
```

Expected:

- Commit contains result screen and answer records only.

### Task 9: Playtest Protocol And Scoring Materials

**Files:**

- Create: `prototype/three_axis_readability_battle_lab/playtest/guide.md`
- Create: `prototype/three_axis_readability_battle_lab/playtest/answer_sheet_template.csv`
- Create: `prototype/three_axis_readability_battle_lab/playtest/scoring_guide.md`
- Modify: `prototype/three_axis_readability_battle_lab/README.md`

- [ ] **Step 1: Create the observer guide**

In `playtest/guide.md`, include:

- one-minute briefing,
- no strategy explanation beyond the goal briefing,
- instruction to run all three battles before answer-key discussion,
- instruction to record confidence and observer notes after every battle,
- target player definition:
  - systems roguelite players,
  - auto-battle optimizer players,
  - optional casual physics players only if they tolerate visual systems.

- [ ] **Step 2: Create answer sheet template**

In `playtest/answer_sheet_template.csv`, include columns:

```text
player_id,battle_order,hidden_preset,answer_axis,answer_counter,answer_overdrive,answer_frontline_cause,confidence_axis_1_to_5,confidence_counter_1_to_5,confidence_overdrive_1_to_5,confidence_frontline_1_to_5,observer_notes,correct_count_0_to_4,unit_only_bias_flag,overdrive_panic_flag
```

- [ ] **Step 3: Create scoring guide**

In `playtest/scoring_guide.md`, define correct answers:

- Axis question is correct if selected axis matches hidden preset and text does not reduce it to generic unit output.
- Counter question is correct if player names the targeted component and visible disruption:
  - Pool/Junk/capacity rhythm for `Pool Polluter`,
  - Echo slot/window/copy collapse for `Echo Breaker`,
  - no-deployment gap/gap hit for `Stagger Punisher`.
- `Overdrive` question is correct if player ties it to the axis component, not danger or rescue.
- Frontline cause question is correct if player links machine event to `sustained_flow`, `repeated_heavy_hit`, or `batch_charge_release`.

- [ ] **Step 4: Update local prototype README**

In `prototype/three_axis_readability_battle_lab/README.md`, include:

- run command,
- headless test command,
- scope guard command,
- playtest flow,
- hard success criteria:
  - at least 3/5 players answer at least 3 of 4 questions correctly,
  - at least 3/5 players can name a non-`Unit` axis as meaningful,
  - at least 3/5 players can explain why `Launch` or `Tuning` changed the frontline without reducing it to "more units",
  - at least 3/5 players can describe one enemy counter disrupting a specific machine component,
  - at least 3/5 players describe `Overdrive` as amplification,
  - no more than 2/5 describe `Overdrive` mainly as rescue or panic.

- [ ] **Step 5: Commit playtest docs**

Run:

```bash
git add prototype/three_axis_readability_battle_lab/playtest prototype/three_axis_readability_battle_lab/README.md
git commit -m "docs: add battle lab playtest protocol"
```

Expected:

- Commit contains only playtest materials and local prototype README updates.

### Task 10: Final Verification And Scope Audit

**Files:**

- Modify: no production docs unless implementation or playtest evidence exists
- Test: all files under `prototype/three_axis_readability_battle_lab/tests/`

- [ ] **Step 1: Run all headless tests**

Run:

```bash
godot --headless --path prototype/three_axis_readability_battle_lab --script tests/test_runner.gd
```

Expected:

- PASS for:
  - `test_scope_guard`,
  - `test_preset_defs`,
  - `test_battle_sequence`,
  - `test_machine_events`,
  - `test_counter_states`,
  - `test_overdrive_directionality`,
  - `scene_smoke`,
  - `test_answer_records`.

- [ ] **Step 2: Run whitespace diff check**

Run:

```bash
git diff --check
```

Expected:

- No trailing whitespace or patch formatting errors.

- [ ] **Step 3: Run manual full-flow smoke**

Run:

```bash
godot --path prototype/three_axis_readability_battle_lab
```

Expected:

- Three 75-second battles can be completed.
- Each battle reaches result screen.
- All three axes stay visible during battle.
- Every counter has warning, active, and recovery states.
- Every `Overdrive` is attached to the matching axis lane.
- Result form records all required fields.
- No shop, race, relic, Gold, node map, backend, networking, Steam, old Web MVP, or free RTS battlefield appears.

- [ ] **Step 4: Run one observer dry-run**

Use a developer or observer, not the author, for a dry-run if available.

Expected:

- Observer can answer the four questions without reading source code or preset titles.
- If observer can only say "more units", mark the build as not design-done.

- [ ] **Step 5: Commit final verification fixes only if needed**

Run only if Step 1-4 required fixes:

```bash
git add prototype/three_axis_readability_battle_lab
git commit -m "fix: complete battle lab verification"
```

Expected:

- Commit contains only fixes needed to pass this plan's verification.

## Acceptance Criteria

Engineering done:

- Three battles run for exactly 75 seconds each and reach the result screen.
- Each preset triggers its matching machine event, counter window, and axis-bound `Overdrive`.
- `Launch Flood` produces visible Pool rhythm and sustained frontline flow.
- `Tuning Echo` produces visible Echo copy behavior and repeated heavy-hit frontline changes.
- `Unit Queue Burst` produces visible queue buildup and grouped release.
- Each counter has warning, active, and effect states.
- Result screen records all required answer fields, confidence values, observer notes, `correct_count_0_to_4`, `unit_only_bias_flag`, and `overdrive_panic_flag`.
- Build contains no shop, race expansion, relic, economy, node map, backend, networking, Steam integration, or old Web MVP dependency.

Design done:

- At least 3/5 target players answer at least 3 of 4 questions correctly after each battle.
- At least 3/5 target players can name a non-`Unit` axis as meaningful after seeing all three battles.
- At least 3/5 target players can explain why `Launch` or `Tuning` changed the frontline without reducing the answer to "more units."
- At least 3/5 target players can describe how one enemy counter disrupted Pool, Echo slot/window, or charge gap.
- At least 3/5 target players describe `Overdrive` as amplification of the current axis.
- No more than 2/5 target players describe `Overdrive` mainly as rescue, shield, heal, clear-screen, or panic button.
- In grayscale or low-color read, an observer can still distinguish the three axes and three counter effects by shape, motion, and timing.

Not design-done until:

- someone other than the developer has played the build,
- at least three target players complete the full three-battle blind answer flow,
- answers are scored and both diagnostic flags are reviewed,
- "more units" and "panic button" failure modes are explicitly checked.

## Self-Review

Spec coverage:

- `AGENTS.md` boundaries are covered by Scope Guard, Fresh Runtime Choice, Task 1, and Task 10.
- `docs/gdd.md` machine-axis design is covered by Shared Constants and Tasks 2-7.
- The slice plan's three presets, three counters, one `Overdrive` per battle, and four questions are covered by Tasks 2-9.
- The design review's visual hierarchy, axis grammar, counter states, `Overdrive` directionality, and result flow are covered by Tasks 5-9.
- The handoff's functional and experiential acceptance criteria are covered by Acceptance Criteria and Task 10.

Placeholder scan:

- No planned implementation step relies on a future shop, race, relic, Gold curve, enemy table, backend, telemetry service, Steam integration, or old Web MVP system.
- Deferred systems are explicit out-of-scope boundaries, not missing implementation steps.

Type consistency:

- Axis ids are `launch`, `tuning`, `unit` throughout.
- Preset ids are `launch_flood`, `tuning_echo`, `unit_queue_burst` throughout.
- Counter ids are `pool_polluter`, `echo_breaker`, `stagger_punisher` throughout.
- Frontline signatures are `sustained_flow`, `repeated_heavy_hit`, `batch_charge_release` throughout.

## Execution Handoff

Plan complete when this Markdown file is saved. Do not begin implementation in the same turn if the user only requested planning.

Execution options after user approval:

1. Subagent-Driven: use `superpowers:subagent-driven-development`, dispatch one fresh subagent per task, review between tasks.
2. Inline Execution: use `superpowers:executing-plans`, execute tasks in this session with checkpoints.

In either mode, start by running `git status --short` and resolving how to isolate current docs-only cleanup changes before writing prototype files.
