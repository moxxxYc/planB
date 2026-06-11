# Implementation Handoff: PlanB MVP v0 Reset

Slice plan: N/A. User selected full MVP 6-battle handoff in-session.
Branch: `codex/implementation-design-gap-repair`
Date: 2026-06-11
Status: Reset handoff artifact. Not implementation approval by itself.

## 0. Authority And Reset Rules

This handoff is written for the post-archive reset state.

Use as current inputs:

- `README.md`
- `AGENTS.md`
- `docs/concept.md`
- `docs/gdd.md`
- `docs/machine-warehouses.md`
- `docs/battlefield-rules.md`
- `docs/enemy-rules.md`
- `docs/deploy-lane-ui.md`
- `docs/guardian-system.md`
- `docs/mvp-learning-checkpoints.md`
- `docs/mvp-scope.md`
- `docs/mvp-hive-loadout.md`
- `docs/rewards-economy.md`
- `docs/DESIGN.md`
- `docs/PROGRESS.md`

Use as MVP v0 implementation input, not long-term canon:

- `docs/ball-machine-physical.md`

Do not use as current implementation source:

- `docs/archive/`
- `docs/archive/implementations/godot-mvp-v0-20260611/`
- old `mvp/` verification scripts
- old Web MVP
- old Battle Lab
- archived generated assets

No code, Godot project, build script, asset, or verification script should be created until the user explicitly confirms an implementation plan.

## 1. Build Target

What this build produces in one sentence:

> A complete PlanB MVP v0 Godot short-run implementation target: `Main Menu -> Guardian Contract -> Battle 1 -> Reward 1 -> Battle 2 -> Shop / Rest -> Battle 3 -> Rest -> Battle 4 -> Reward 2 -> Battle 5 -> Endpoint Prep -> Endpoint -> Final Result`, proving that `Launch / Tuning / Unit` machine choices become readable three-lane battlefield outcomes across a 15-20 minute run.

Hypothesis:

> Players can finish or fail a 6-battle short run and explain whether the run was mainly won or lost through `Launch` sustained flow, `Tuning` high-value hits, `Unit` batch / anchor value, enemy counter pressure, `Deploy Lane` placement, or Guardian HP pressure.

Soul of this build:

1. The machine-to-frontline chain must be visible: physical ball result -> Unit progress -> Queue -> selected spawn port -> lane state.
2. Rewards, shop items, Guardian contracts, and enemy counters must read as machine component changes, not generic buffs or random punishment.
3. `Deploy Lane` must remain deployment placement. If it becomes the main game, this MVP fails.

If those fail, a complete 6-battle run may still "work", but it does not test PlanB.

## 2. Scope

### In Scope

- [ ] MUST: New Godot 4.6 GDScript project target using Compatibility / `gl_compatibility`, defined as a fresh implementation path, not restored from archive.
- [ ] MUST: Full player-facing run flow from Main Menu through Final Result.
- [ ] MUST: Guardian Contract before Battle 1 with two Hive Player Guardians: `巢脉母` and `酸冠母`.
- [ ] MUST: Six battle nodes: Battle 1, Battle 2, Battle 3, Battle 4, Battle 5, Endpoint.
- [ ] MUST: Battle Screen layout follows `三仓机器 38% | Queue / Deploy Bridge 14% | 战场 48%`.
- [ ] MUST: Three stacked machine boards: `Launch`, `Tuning`, `Unit`.
- [ ] MUST: Physical-ball presentation for machine boards based on `docs/ball-machine-physical.md`, with true physical landing as the MVP v0 implementation assumption.
- [ ] MUST: `Launch` includes Forge, Pool, Launcher, Route Board, Split, Recycle, Waste, Junk handling.
- [ ] MUST: `Tuning` includes `Gate / Prime / Echo / Surge` with visible result feedback.
- [ ] MUST: `Unit` includes 4 slots, `progress_required = 3 / 5 / 8 / 12`, Exposure Gate timing, progress, overflow, Queue.
- [ ] MUST: Queue deploys FIFO entries every 0.5s maximum, reading current `Deploy Lane`.
- [ ] MUST: `Deploy Lane` is selected by clicking battlefield lanes directly. No primary three-button lane panel.
- [ ] MUST: Three-lane battlefield with fixed `Left / Mid / Right` paths, Lane Gates, base circles, spawn ports, Player Guardian, Endpoint Guardian.
- [ ] MUST: Player units spawn from selected lane spawn port, not from Guardian.
- [ ] MUST: Hive unit loadout: `短牙虫`, `盾壳虫`, `酸囊虫`, `碾壳兽`.
- [ ] MUST: Enemy templates: `Enemy Grunt`, `Enemy Raider`, `Enemy Brute`.
- [ ] MUST: Battle 3 counter selects one family from `Pool Polluter`, `Echo Breaker`, `Stagger Punisher` based on current strongest / most exposed axis.
- [ ] MUST: Battle 5 applies one or two stronger counter triggers, preferably retesting the same family or adjacent weakness.
- [ ] MUST: Endpoint includes Endpoint Guardian behavior with telegraphed sweep and one counter family.
- [ ] MUST: Reward 1 is fixed 3-choice axis anchor: `Pool Pocket`, `Prime Charge`, `Slot Primer`.
- [ ] MUST: First Shop after Battle 2 shows 3 neutral modifiers from `Front Recycle`, `Junk Sieve`, `Surge Buffer`, `Queue Brace`, `Muster Pair`, with at least one patch option.
- [ ] MUST: First Shop allows at most one neutral modifier purchase; Rest is separate and does not consume the neutral modifier quota.
- [ ] MUST: Battle 4 gives Reward 2, a free 2-3 option reward using current-axis priority and at least one patch or pivot.
- [ ] MUST: Gold faucet follows `0 / +6 / +6 / +8 / +0 / +0 / +0`, no kill Gold, no failure Gold.
- [ ] MUST: Result pages record the six MVP learning checkpoints and Final Result records main axis, key choices, counters, Deploy Lane influence, Guardian HP pressure, and next-run watch tag.
- [ ] SHOULD: Support quick battle-script tuning through data resources or equivalent editable configuration.
- [ ] SHOULD: Include a dev-only verification scene or command, but keep it out of player-facing flow.
- [ ] SHOULD: Include grayscale / colorblind readability checks for current lane, danger lane, active ball, and counter target.
- [ ] COULD: Add placeholder audio families for deploy, hit, counter warning, forced redirect, and result transitions.

### Out Of Scope

- PVP, online, accounts, backend, matchmaking, Steam integration.
- Second race, Mech, Arcane, Infection Hive baseline.
- Full relic pool, full event pool, complete enemy roster, complete Boss lineup.
- Meta progression, Guardian equipment, Guardian treasure slot, Guardian upgrade tree.
- Free RTS map, complex pathfinding, direct unit control.
- `Overdrive` as a base button.
- Full final art, final sprite sheets, final fonts, final sound mix.
- Any archived implementation structure or validation command as current authority.

### Placeholder OK

- Placeholder OK: Unit, enemy, Guardian, Endpoint sprites can be stable readable silhouettes.
- Placeholder OK: Machine pegs, slots, rails, Pool balls, and Unit slots can be geometric.
- Placeholder OK: Reward / shop card art can be axis icons plus clear text.
- Placeholder OK: Battlefield paths can be simple lightly curved lines.
- Placeholder OK: Wave scripts can be first-pass authored encounters, not procedural encounter pools.
- Placeholder OK: Result pages can be text-heavy if cause tags and learning fields are clear.
- Placeholder OK: Audio can be absent or simple placeholders. Visual readability cannot depend on audio.

### Defer Entirely

- Final playtest balance.
- Final physical parameters for peg layout, active blocks, cannon swing, ball count, inter-board randomness.
- Final sprite sheets, pivot points, collision tuning, animation polish.
- More than 6 battles or alternate run map.
- More than 9 neutral modifier effects.
- Deep save / continue flow.

## 3. Gameplay Requirements

| Player Action | Expected Response | Timing | Feel Target |
|---|---|---|---|
| Start new run | Main Menu enters Guardian Contract. | Immediate or short transition. | The player starts a short run, not a debug sandbox. |
| Select Guardian | `巢脉母` or `酸冠母` card highlights, showing machine lean, tactical defense, risk. | Same frame / next frame. | Contract choice, not hero control. |
| Confirm Guardian | Battle 1 opens with selected Guardian identity and contract markers. | Immediate or short transition. | Run identity is anchored before machine starts. |
| Watch first 30s of Battle 1 | Player sees Forge, Pool, Launcher, Tuning result, Unit progress, Queue, selected lane, lane danger. | Within first 30s. | The basic machine chain is learnable without pausing. |
| Click battlefield lane | Current lane highlight, selected spawn port, queue landing marker, and Bridge line update. | Same frame / next frame. | Direct lane selection. No button-board feeling. |
| Queue entry deploys | Queue head moves / flashes, Bridge points to selected port, spawn port flashes, unit appears there. | 0.3-0.5s confirmation around deploy. | "Machine output landed here." |
| Ball hits `Gate / Prime / Echo / Surge` | Tuning slot bites / lights; Unit progress or logic settlement is visible. | Immediate on landing. | Quality conversion, not random sparkle. |
| Ball hits blocked Unit exposure | Ball visibly bounces from physical blocker. | Immediate collision response. | "Not open yet", not "the ball vanished." |
| Choose Reward 1 | Card shows axis, component, operation, player read. Choice affects later battle feedback. | Selection immediate, battle payoff visible in Battle 2-3. | First real machine commitment. |
| Enter Shop / Rest | Gold, quota, item role, Rest cost, Rest availability, and opportunity cost are visible. | Immediate. | Buying is a machine decision, not shopping by bigger number. |
| See counter warning | Targeted machine component receives warning before effect. Lane danger only rises when battlefield threat exists. | Warning 3-5s before counter. | The enemy attacks a component, not the player secretly. |
| Counter resolves | Pool Junk, Echo downgrade, or Stagger raid shows the attacked component and battlefield consequence. | During active window. | The player can name the attacked weakness. |
| Choose Reward 2 | UI shows current axis and offers deepen plus patch / pivot option. | Immediate. | Current build shape becomes readable. |
| Fight Endpoint | Endpoint Guardian sweep is telegraphed, lane breaks lead to base-circle damage windows. | Sweep warning 1.2s before hit. | Final exam, not HP wall. |
| Finish or fail run | Final Result states main axis, choices, counters, lane impact, Guardian HP pressure, win/loss reason, next watch tag. | At run end. | The run leaves one clear lesson. |

## 4. System Requirements

| System | What It Does | Exists? | Notes |
|---|---|---|---|
| Godot Project | Fresh Godot 4.6 GDScript Compatibility project target. | No active current project | Must not restore archived `mvp/` as current source. |
| Run Flow | Routes pages and 6 battle nodes. | No active current implementation | Must support win/fail ending. |
| Guardian Contract | Selects one fixed Guardian for whole run. | Design locked | Needs UI and data. |
| Machine Simulation | Runs Forge, Pool, Launcher, three-board results, Machine Contract effects, counters. | Design locked, implementation absent | Physical presentation must map to logic. |
| Physical Machine View | Shows three-board ball motion, result slots, forced redirect, blocked bounce, counter disruption. | Implementation absent | Exact physics params are tuning items. |
| Unit Queue | FIFO queue, deploy cadence, queue preview, deploy Bridge. | Design locked | Soul-critical. |
| Battlefield | Three fixed lanes, units, gates, base circles, Guardians, Endpoint behavior. | Design locked | No free RTS pathing. |
| Deploy Lane Input | Direct click on battlefield lanes. | Design locked | No primary side buttons. |
| Enemy Waves | Scripted 6-battle pressure curve. | Design locked, exact scripts TBD | Wave counts and timings are tuning items. |
| Counter System | Pool Polluter, Echo Breaker, Stagger Punisher. | Design locked | Must warn and leave visible traces. |
| Rewards / Shop / Rest | Reward 1, Shop after Battle 2, Rest windows, Reward 2 after Battle 4. | Design locked | Final balance not locked. |
| Result / Telemetry | Records learning checkpoint fields and final cause tags. | Design locked | Player-facing result should not be debug dump. |
| Verification | Defines new current validation command. | Not defined | Must be created during implementation plan, not borrowed from archive. |

## 5. Asset Requirements

| Asset | Real or Placeholder | Spec |
|---|---|---|
| Global base chassis | MUST BE REAL as layout | Race-neutral 2.5D war-table, three-zone Battle Screen. Final art can wait. |
| Machine boards | MUST BE REAL as readable geometry | Three stacked boards labeled `Launch`, `Tuning`, `Unit`; pegs, slots, active ball, result feedback. |
| Active ball | MUST BE REAL | Must support active-ball highlighting and causal chain. |
| Forced redirect guide | MUST BE REAL | Short guide rail / slot guide. Text-only forced result is not acceptable. |
| Blocked bounce | MUST BE REAL | Physical blocker / rebound response for Unit Exposure. |
| Queue Bridge | MUST BE REAL | Bridge points to selected spawn port. This is part of the build soul. |
| Spawn ports / Lane Gates | MUST BE REAL as silhouettes / structures | Separate from Guardian, one per lane. |
| Lane danger markers | MUST BE REAL | Shape + motion + color separation from selected lane. |
| Hive units | Placeholder OK | Stable silhouettes with role readability. |
| Guardians | MUST BE REAL as battlefield entities | Large silhouettes with attached HP / tactical feedback. |
| Endpoint Guardian | MUST BE REAL as battlefield entity | Needs telegraphed sweep feedback. |
| Reward / shop cards | Placeholder OK | Axis, component, operation, player read, price / quota. |
| Audio | Placeholder OK | Visuals must remain sufficient without audio. |

## 6. Battle And Learning Sequence

| Node | Must Teach / Test | Content | Pass Signal |
|---|---|---|---|
| Guardian Contract | Guardian is run contract, not controlled hero. | Choose `巢脉母` or `酸冠母`. | Player can say which machine axis the contract leans toward. |
| Battle 1 | Basic machine chain and Deploy Lane boundary. | 90-110s, single-lane light pressure, no counter. | Player can explain ball -> Tuning -> Unit progress -> Queue -> selected lane. |
| Reward 1 | First axis commitment. | `Pool Pocket` / `Prime Charge` / `Slot Primer`. | Player can name chosen axis and expected battlefield payoff. |
| Battle 2 | Chosen machine direction begins to form. | 100-125s, double-lane pressure, no counter. | Player sees sustained flow / high-value hit / anchor slot payoff begin. |
| Shop / Rest | Gold is opportunity cost. Shop is machine patch / pivot. | 12 Gold if B1+B2 won, one neutral modifier quota, optional Rest. | Player understands why they cannot buy every neutral modifier. |
| Battle 3 | First counter attacks current machine weakness. | 115-140s, one counter family. | Player can identify Pool / Echo-Surge / Queue gap as target. |
| Rest Window | HP pressure can be answered at cost. | Optional Rest if damaged. | Player sees Rest as HP sink, not machine modifier. |
| Battle 4 | Shop choice validates patch or pivot. | 105-130s, no counter, route pressure. | Player can see whether shop choice helped or not. |
| Reward 2 | Current axis deepens or patches exposed weakness. | Free 2-3 options after Battle 4. | Player can distinguish deepen current axis from patch / pivot. |
| Battle 5 | Stronger counter retests build. | 125-150s, one or two counter triggers. | Player can see whether build survived the second pressure peak. |
| Endpoint Prep | Last HP decision before final. | Optional Rest, no new Gold. | Player sees remaining Gold as survival vs opportunity cost history. |
| Endpoint | Final exam. | 165-195s, Endpoint Guardian, telegraphed sweep, one counter family. | Player can explain win/loss by machine axis, counter, lane, or Guardian HP pressure. |
| Final Result | Run-level learning. | Summary page. | Player leaves with one `next_run_watch_tag`. |

## 7. Acceptance Criteria

### Engineering Done

- [ ] New current Godot project exists only after explicit implementation approval.
- [ ] Current validation command is documented and runs without relying on archived scripts.
- [ ] Main Menu can start a new run.
- [ ] Guardian Contract can select either Guardian and enter Battle 1.
- [ ] All six battles can be entered in sequence.
- [ ] Each battle can end in victory and failure.
- [ ] Machine simulation produces queue entries through `Launch / Tuning / Unit`.
- [ ] Queue deploys entries to current `Deploy Lane`.
- [ ] Three-lane battlefield supports units, gates, base circles, Player Guardian, Endpoint Guardian.
- [ ] Reward 1, Shop / Rest, Reward 2, Endpoint Prep, Final Result are reachable.
- [ ] Gold faucet and first shop quota match the formal docs.
- [ ] Counters warn before resolving and target the correct machine component.
- [ ] No player-facing screen exposes dev sliders, telemetry dumps, old debug routes, or implementation-state text.

### Design Done

- [ ] In Battle 1, a tester can explain the basic machine chain in their own words.
- [ ] After clicking a lane, a tester understands it changes future deployment position, not machine output.
- [ ] After Reward 1, a tester can name their chosen axis and expected battlefield payoff.
- [ ] In Battle 3, a tester can identify which machine component the counter attacked.
- [ ] After first shop, a tester can explain why buying one neutral modifier is a choice, not just shopping by price.
- [ ] After Reward 2, a tester can distinguish deepen from patch / pivot.
- [ ] During Endpoint, a tester can see the sweep warning before damage.
- [ ] Final Result can explain the run using machine axis, reward / shop, counter, Deploy Lane, and Guardian HP cause tags.
- [ ] The build preserves the soul: machine cause becomes battlefield result, and Deploy Lane does not replace machine commitment.

### Not Done Until

- [ ] Someone other than the implementer plays from Main Menu to at least Battle 3.
- [ ] Someone other than the implementer plays or watches a simulated full run through Final Result.
- [ ] At least one run is checked for win path and one for fail path.
- [ ] Tester can answer: "What did my first reward change in the machine?"
- [ ] Tester can answer: "Did I lose because of machine weakness, route placement, counter pressure, or Guardian HP?"
- [ ] Screenshots of Battle Screen show no text overlap and no debug UI.

## 8. Known Risks

| Risk | Impact | The Tempting Shortcut | Why It Kills The Experience |
|---|---|---|---|
| Full 6-battle scope becomes too wide | Critical | Build all screens shallowly and leave machine causality vague | A complete run with weak causality tests nothing. |
| Physical machine is fake RNG animation | Critical | Roll result first, animate ball afterward | Breaks the confirmed true-physical MVP v0 assumption. |
| Physics tuning consumes the whole milestone | Critical | Tune pegs until distributions look perfect before run loop exists | The MVP needs session learning first; exact distributions are playtest tuning. |
| Queue Bridge is text-only | Critical | Show `Current lane: Mid` and skip visual bridge | Player misses machine -> battlefield causality. |
| Deploy Lane becomes the main game | Critical | Make danger prompt too strong and reward optimal lane clicking | Player ignores machine, MVP fails. |
| Counters feel random | High | Spawn effects without component warning | Player reads punishment, not machine weakness. |
| Reward / shop cards become generic buffs | High | Show only stat text | Player cannot learn `warehouse -> component -> operation`. |
| Guardian becomes a hero unit | High | Make Guardian controllable or spawn units from it | Breaks Guardian system and battlefield topology. |
| Result page becomes debug telemetry | High | Dump all tracked fields | Player sees data but not cause. |
| Unit slot 3 or 4 dominates early | Medium | Tune for spectacle instead of exposure timing | Unit becomes default best axis. |

Do not take these shortcuts:

1. Do not restore archived `mvp/` as current implementation.
2. Do not use archived verification scripts as current validation.
3. Do not replace true physical ball landing with hidden RNG unless the user changes the design.
4. Do not spawn units from Guardian.
5. Do not add a primary lane button panel.
6. Do not make counters silent or unannounced.
7. Do not use "more units" as the read for all rewards.

## 9. Implementation Milestones

These milestones are execution order, not separate design approvals.

### M0: Fresh Godot Project And Validation Contract

Goal: create the new current Godot project target and current validation command.

MUST:

- Godot 4.6, GDScript, Compatibility / `gl_compatibility`.
- Fresh project directory, not restored from archive.
- New current verification command documented.
- Minimal Main Menu opens.

GodotPrompter skills before implementation:

- `godot-prompter:godot-project-setup`
- `godot-prompter:scene-organization`
- `godot-prompter:godot-testing`

### M1: Machine-To-Queue-To-Lane Core

Goal: Battle Screen proves the soul in one battle.

MUST:

- Three-board machine display.
- Ball result -> Unit progress -> Queue.
- Queue Bridge -> selected spawn port.
- Direct lane clicking.
- Battle 1 win/fail path.

GodotPrompter skills:

- `godot-prompter:physics-system`
- `godot-prompter:resource-pattern`
- `godot-prompter:godot-ui`
- `godot-prompter:input-handling`

### M2: Full Run Flow And Economy Skeleton

Goal: full node sequence exists from Guardian Contract to Final Result.

MUST:

- Guardian Contract.
- Reward 1.
- Battle 2.
- First Shop / Rest.
- Battle 3.
- Rest window.
- Result routing.

GodotPrompter skills:

- `godot-prompter:resource-pattern`
- `godot-prompter:godot-ui`
- `godot-prompter:hud-system`

### M3: Counters, Reward 2, Battle 4-5

Goal: counter learning and patch / deepen loop work.

MUST:

- Pool Polluter, Echo Breaker, Stagger Punisher.
- Battle 4 shop validation.
- Reward 2 current-axis pool.
- Battle 5 stronger pressure.

GodotPrompter skills:

- `godot-prompter:event-bus` or equivalent signal guidance if decoupling is needed.
- `godot-prompter:component-system`
- `godot-prompter:tween-animation`

### M4: Endpoint And Final Result

Goal: full 6-battle MVP can finish or fail.

MUST:

- Endpoint Guardian.
- Telegraphed Sweep.
- Endpoint Prep Rest window.
- Final Result with run-level cause tags and next-run watch tag.

GodotPrompter skills:

- `godot-prompter:animation-system`
- `godot-prompter:particles-vfx` only if VFX polish is needed for readability.
- `godot-prompter:godot-code-review` after implementation.

## 10. Test Hooks

| What To Test | How To Test | Pass Criteria |
|---|---|---|
| Project health | Run the new current verification command. | Passes without archived scripts. |
| Battle 1 learning | Observe first 30s. | Tester explains machine -> Queue -> Deploy Lane. |
| Lane click boundary | Click lanes while Queue has entries. | Tester says future deployments move; current units do not. |
| Reward 1 read | Choose each Reward 1 option in separate runs or scripted states. | Tester names axis and battlefield expectation. |
| First shop economy | Enter first shop with 12 Gold. | Tester understands one neutral modifier quota and Rest separation. |
| Counter warning | Force each counter family. | Tester names attacked component before or during resolution. |
| Battle 4 validation | Compare shop choice to next battle. | Result page can link patch / pivot to observed pressure. |
| Reward 2 read | Enter Reward 2 after different main axes. | UI offers deepen plus patch / pivot and explains why. |
| Endpoint sweep | Force base-circle invasion. | Sweep warning appears before damage and does not cross lanes. |
| Full run | Play or simulate win and fail paths. | Final Result names main axis, key choices, counter pressure, lane impact, Guardian HP pressure, next watch tag. |
| No debug UI | Inspect all player-facing screens. | No debug panels, sliders, telemetry dumps, old route labels. |
| Grayscale readability | Convert Battle Screen screenshots to grayscale. | Current lane, highest danger, active ball, counter target remain distinguishable. |

## 11. Open Items

These are not blockers for writing the implementation plan, but they must remain visible.

- Final physical peg layout, active blocks, cannon swing, ball parameters, inter-board randomness, same-screen ball count.
- `Unit.Slot.Exposure Gate` interpolation between start and full exposure.
- Exact enemy wave counts, spawn timings, and lane assignments for each battle.
- Final balance for neutral modifiers, Hive units, Guardian tactical / strategic skills.
- Final sprite sheets, animation frames, pivot points, collision areas, UI responsive details.
- Final audio families and mix.

## Completion Summary

```text
/implementation-handoff complete

Game: PlanB
Build target: Full MVP v0 6-battle reset handoff
Hypothesis: A 15-20 minute run can teach machine axis commitment, counter pressure, Deploy Lane boundary, and Endpoint payoff.
Soul: physical machine cause -> Queue -> selected spawn port -> battlefield result; rewards / shop / counters remain machine-component readable.
MUST items: 33

Status: DONE_WITH_CONCERNS

Top concern:
  Full 6-battle scope is valid only if implementation milestones keep M1 focused on machine-to-frontline causality. If M0-M1 try to solve all physics, assets, economy, and Endpoint at once, the build will bog down before the core read is testable.

Next Step:
  PRIMARY: Confirm this handoff, then write the implementation plan for M0-M1 only.
  IF physical behavior becomes the active blocker: use GodotPrompter physics-system and scene-organization before writing Godot code.
  IF design scope changes: rerun /implementation-handoff or backtrack to /prototype-slice-plan.
```
