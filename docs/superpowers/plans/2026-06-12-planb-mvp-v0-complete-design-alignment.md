# PlanB MVP v0 Complete Design Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the active `godot/` MVP v0 implementation into full alignment with the confirmed reset handoff M0-M4 and current formal design docs, without inventing M5/M6 scope or replacing confirmed mechanics with narrower verifier-only approximations.

**Architecture:** Rebase completion around explicit contracts: physical ball landing drives machine results, `Unit.Slot.Exposure Gate` is a visible physics gate, Guardian Contract hooks into both machine and battlefield resolution, battle pacing follows documented duration bands, and Final Result records the complete learning-checkpoint schema from actual telemetry. Existing run shell and scene structure stay in place, but verifier coverage expands from structural pass checks to confirmed-design behavior checks.

**Tech Stack:** Godot 4.6, GDScript, Compatibility / `gl_compatibility`, Godot 2D physics, Control UI with embedded Node2D physics layers, headless Godot verifier scripts via `bash tools/verify_godot.sh`.

---

## Authority And Non-Negotiable Scope

Use these current docs as implementation authority:

- `docs/gstack-artifacts/planb-mvp-v0-reset-handoff-20260611.zh.md`
- `docs/mvp-scope.md`
- `docs/machine-warehouses.md`
- `docs/ball-machine-physical.md`
- `docs/battlefield-rules.md`
- `docs/enemy-rules.md`
- `docs/deploy-lane-ui.md`
- `docs/guardian-system.md`
- `docs/mvp-learning-checkpoints.md`
- `docs/mvp-hive-loadout.md`
- `docs/rewards-economy.md`
- `docs/DESIGN.md`
- `AGENTS.md`

This plan must not:

- Create M5/M6 scope.
- Restore archived `mvp/`, archived prototypes, old Web MVP behavior, or old Battle Lab assumptions.
- Treat verifier-only stubs as finished gameplay.
- Replace true physical machine causality with hidden RNG or deterministic result patterns in the player runtime.
- Mark final art, final balance, or playtest-only thresholds as fully proven before playtest evidence exists.

## Confirmed Gap Matrix

| Gap | Current state | Required state | Covered by task |
|---|---|---|---|
| True physical ball machine | `MachineSimulator.advance_step()` uses fixed result patterns; `MachinePhysicsBoardView` is only contract/verifier side path. | Runtime machine result comes from visible 2D physics landing, with deterministic verifier seed only as test mode. | Task 1 |
| Slot Exposure Gate | Slot selection ignores exposure timing and blocked bounce. | Slot 1-4 exposure follows `0/12/36/72` start and `0/24/54/96` full times; blocked areas physically bounce and are recorded. | Task 2 |
| Guardian Contract | Guardian choice is mostly card text. | `巢脉母` and `酸冠母` strategic and tactical rules resolve in machine/battle layers with per-battle resets. | Task 3 |
| Guardian battlefield basics | Player Guardian has HP but no basic attack behavior. | Player Guardian attacks base-zone intruders with documented range/interval/damage and stays weaker than proper lane defense. | Task 3 |
| Unit loadout | Unit stats and special behaviors do not match documented Hive first-pass table. | Short Fang, Shield Shell, Acid Sac, Crush Shell Beast use confirmed hp/damage/range/speed/attack behavior. | Task 4 |
| Battle duration | Battles use compressed verifier pressure windows. | Battle pacing uses documented bands: B1 90-110s, B2 100-125s, B3 115-140s, B4 105-130s, B5 125-150s, Endpoint 165-195s. | Task 4 |
| Reward/shop modifier semantics | Several effects are simplified approximations. | Pool Pocket, Front Recycle, Junk Sieve, Prime Charge, Echo Latch, Surge Buffer, Queue Brace, Muster Pair, Slot Primer match `docs/rewards-economy.md`. | Task 5 |
| Counters | Counter families exist but need exact timing/limits/danger route semantics. | Pool Polluter, Echo Breaker, Stagger Punisher match warning, active window, trigger count, cooldown, and visible effect rules. | Task 6 |
| Final Result fields | Verifier checks only a subset; several required learning fields are missing. | Final Result contains the complete learning-checkpoint schema and uses actual telemetry where runtime can observe it. | Task 7 |
| UI/player-facing polish | Mostly Chinese and layout is structurally correct, but physics/Guardian/Exposure feedback is absent. | Player sees machine physical causality, gate state, Guardian effects, counter target, queue gap, and result tags in Chinese. | Task 8 |
| Design completion proof | Headless verifiers pass, but player understanding is not proven. | Code gates pass and a playtest acceptance protocol records non-implementer comprehension before calling design-complete. | Task 9 |

## File Structure

### Create

- `godot/scripts/model/machine/machine_slot_exposure_state.gd`  
  Computes per-battle Unit slot exposure state, progress gate snapshots, and legal slot checks.

- `godot/scripts/model/guardian/guardian_contract_state.gd`  
  Owns selected Guardian id, per-battle strategic counters, tactical cooldowns, and machine/battle hooks.

- `godot/scripts/model/run/run_learning_record.gd`  
  Builds the complete `docs/mvp-learning-checkpoints.md` result schema from session, machine, battle, reward, shop, rest, and counter telemetry.

- `godot/tools/verify_physics_machine_integration.gd`  
  Fails unless visible physics landings drive queue-producing machine results in the runtime path.

- `godot/tools/verify_exposure_gate.gd`  
  Fails unless slot exposure timings, blocked hit behavior, and `battle1.exposure_gate_snapshot` work.

- `godot/tools/verify_guardian_contract_behaviors.gd`  
  Fails unless both Guardian strategic and tactical effects resolve and reset per battle.

- `godot/tools/verify_hive_unit_and_battle_profile.gd`  
  Fails unless unit stats/behaviors and battle duration bands match confirmed docs.

- `godot/tools/verify_modifier_semantics.gd`  
  Fails unless the 9 reward/shop modifiers match documented semantics and guardrails.

- `godot/tools/verify_complete_learning_record.gd`  
  Fails unless Final Result includes the full learning checkpoint field set with player-visible Chinese labels.

- `docs/playtest/planb-mvp-v0-acceptance-protocol.md`  
  Defines the manual acceptance protocol for the player-understanding claims that cannot be proven by headless tests.

### Modify

- `tools/verify_godot.sh`
- `godot/project.godot`
- `godot/scenes/run/battle_one_vertical.tscn`
- `godot/scripts/model/machine/machine_simulator.gd`
- `godot/scripts/model/machine/machine_physics_result.gd`
- `godot/scripts/ui/machine_physics_board_view.gd`
- `godot/scripts/ui/machine_board_view.gd`
- `godot/scripts/ui/machine_strip_view.gd`
- `godot/scripts/run/battle_one_vertical.gd`
- `godot/scripts/model/battle/battle_entity_state.gd`
- `godot/scripts/model/battle/battlefield_state.gd`
- `godot/scripts/model/battle/battlefield_telemetry.gd`
- `godot/scripts/data/battle_unit_definition.gd`
- `godot/scripts/data/battle_wave_definition.gd`
- `godot/scripts/model/counter/counter_state.gd`
- `godot/scripts/model/run/run_session_model.gd`
- `godot/scripts/run/mvp_run_session.gd`
- `godot/scripts/ui/run/run_hud_view.gd`
- `godot/scripts/ui/run/final_result_view.gd`
- `docs/PROGRESS.md`

## Task 0: Expand Red Verification Gates Before Gameplay Changes

**Files:**
- Create: `godot/tools/verify_physics_machine_integration.gd`
- Create: `godot/tools/verify_exposure_gate.gd`
- Create: `godot/tools/verify_guardian_contract_behaviors.gd`
- Create: `godot/tools/verify_hive_unit_and_battle_profile.gd`
- Create: `godot/tools/verify_modifier_semantics.gd`
- Create: `godot/tools/verify_complete_learning_record.gd`
- Modify: `tools/verify_godot.sh`

- [ ] **Step 0.1: Add failing physics integration verifier**

`verify_physics_machine_integration.gd` must instantiate `res://scenes/run/battle_one_vertical.tscn`, drive the battle runtime, and fail unless the runtime path reports at least one `MachinePhysicsResult` source in a queue-producing chain.

Required checks:

```gdscript
var visual_contract: Dictionary = battle.call("get_machine_visual_contract")
if not bool(visual_contract.get("runtime_physics_drives_results", false)):
	failures.append("Runtime machine results must be driven by visible physics landings.")
if int(visual_contract.get("physics_landing_count", 0)) <= 0:
	failures.append("Battle runtime must observe at least one physics landing.")
if not String(battle.call("get_active_machine_log_text")).contains("物理落点"):
	failures.append("Machine log must expose physical landing causality in Chinese.")
```

Run:

```bash
bash tools/verify_godot.sh
```

Expected before Task 1 implementation: FAIL on `verify_physics_machine_integration.gd`.

- [ ] **Step 0.2: Add failing Exposure Gate verifier**

`verify_exposure_gate.gd` must instantiate `MachineSlotExposureState` and verify:

```gdscript
if not exposure.is_slot_fully_exposed(1, 0.0):
	failures.append("Slot 1 must be fully exposed at battle start.")
if exposure.is_slot_open_for_progress(2, 11.9):
	failures.append("Slot 2 must not accept progress before 12s exposure start.")
if not exposure.is_slot_fully_exposed(2, 24.0):
	failures.append("Slot 2 must be fully exposed by 24s.")
if exposure.is_slot_open_for_progress(4, 71.9):
	failures.append("Slot 4 must not accept progress before 72s exposure start.")
```

It must also drive Battle 1 for 30 simulated seconds and require `battle1.exposure_gate_snapshot`.

Expected before Task 2 implementation: FAIL.

- [ ] **Step 0.3: Add failing Guardian Contract verifier**

`verify_guardian_contract_behaviors.gd` must check both Guardian ids:

```gdscript
run.call("select_guardian", "hive_vein_mother")
run.call("confirm_guardian")
var battle = run.get("active_battle")
if not battle.call("force_guardian_recycle_sequence_for_verifier", 6):
	failures.append("巢脉母 must trigger hidden pity on the 6th legal Recycle.")

run.call("select_guardian", "hive_acid_crown_mother")
run.call("confirm_guardian")
if not battle.call("force_guardian_gate_sequence_for_verifier", 6):
	failures.append("酸冠母 must convert the 6th Gate miss path into Prime.")
```

It must also force an intruder and HP damage event to verify `巢脉牵缚` and `酸冠反喷`.

Expected before Task 3 implementation: FAIL.

- [ ] **Step 0.4: Add failing unit/battle profile verifier**

`verify_hive_unit_and_battle_profile.gd` must assert exact confirmed values:

```gdscript
var catalog: Dictionary = BattleUnitDefinition.catalog()
_expect_unit(catalog["hive_short_fang"], 6, 1, 0.7, 1.5, 10.0)
_expect_unit(catalog["hive_shield_shell"], 18, 2, 1.4, 1.5, 6.0)
_expect_unit(catalog["hive_acid_sac"], 8, 3, 1.8, 7.0, 7.0)
_expect_unit(catalog["hive_crush_shell_beast"], 26, 6, 2.6, 2.0, 5.0)
```

It must assert wave target durations:

```gdscript
_expect_duration(BattleWaveDefinition.make_for_battle(1), 90.0, 110.0)
_expect_duration(BattleWaveDefinition.make_for_battle(5), 125.0, 150.0)
_expect_duration(BattleWaveDefinition.make_for_battle(6), 165.0, 195.0)
```

Expected before Task 4 implementation: FAIL.

- [ ] **Step 0.5: Add failing modifier semantics verifier**

`verify_modifier_semantics.gd` must cover these exact behaviors:

- `Junk Sieve`: head Junk is discarded as Waste at most once per 10s and creates no clean ball.
- `Surge Buffer`: charge is per slot, max 1, consumed only by that slot's next queue entry with 0.25s deploy delay.
- `Queue Brace`: after 3s with no deployed queue entry, lowest-progress exposed legal slot gets +1, with 12s cooldown.
- `Muster Pair`: two same-slot entries generated within 1.2s merge into one `paired_entry` with `count = 2`.
- `Echo Latch`: locks Echo copy to the same slot and shows a ghost hit; it does not create a third Echo copy.

Expected before Task 5 implementation: FAIL on at least `Queue Brace`, `Muster Pair`, and `Echo Latch`.

- [ ] **Step 0.6: Add complete learning-record verifier**

`verify_complete_learning_record.gd` must drive a full run to Final Result and require every field from `docs/mvp-learning-checkpoints.md`:

```gdscript
var required_keys: Array[String] = [
	"guardian.choice_id",
	"guardian.choice_read",
	"guardian.outcome",
	"guardian.hp_pressure_events",
	"battle1.machine_chain_sample",
	"battle1.exposure_gate_snapshot",
	"battle1.deploy_lane_selection",
	"battle1.lane_danger_snapshot",
	"unit.visible_contribution_slots",
	"unit.key_queue_entries_by_slot",
	"unit.dominant_slot_share",
	"reward1.choice_id",
	"reward1.axis",
	"reward1.component_operation",
	"reward1.battlefield_expectation",
	"reward1.battlefield_result",
	"shop1.gold_before",
	"shop1.purchase_id",
	"shop1.purchase_role",
	"shop1.gold_after",
	"rest_windows",
	"rest.total_purchases",
	"rest.total_gold_spent",
	"rest.total_hp_restored",
	"rest.endpoint_relevance",
	"counter1.family",
	"counter1.target_component",
	"counter1.visible_effect",
	"counter1.response_link",
	"second_offer.current_axis",
	"second_offer.candidates",
	"second_offer.choice_id",
	"second_offer.choice_role",
	"endpoint.outcome",
	"endpoint.primary_axis_payoff",
	"endpoint.main_break_reason",
	"endpoint.next_run_watch_tag",
	"endpoint.deploy_lane_impact",
	"endpoint.guardian_hp",
	"session.decision_windows",
	"session.consecutive_no_explained_decision_battles"
]
```

Expected before Task 7 implementation: FAIL.

- [ ] **Step 0.7: Wire new verifiers into `tools/verify_godot.sh`**

Add the new scripts after the existing full handoff checks:

```bash
run_godot_verifier "res://tools/verify_physics_machine_integration.gd"
run_godot_verifier "res://tools/verify_exposure_gate.gd"
run_godot_verifier "res://tools/verify_guardian_contract_behaviors.gd"
run_godot_verifier "res://tools/verify_hive_unit_and_battle_profile.gd"
run_godot_verifier "res://tools/verify_modifier_semantics.gd"
run_godot_verifier "res://tools/verify_complete_learning_record.gd"
```

## Task 1: Make Runtime Machine Results Come From Visible Physics

**Files:**
- Modify: `godot/scripts/ui/machine_physics_board_view.gd`
- Modify: `godot/scripts/ui/machine_board_view.gd`
- Modify: `godot/scripts/ui/machine_strip_view.gd`
- Modify: `godot/scripts/model/machine/machine_physics_result.gd`
- Modify: `godot/scripts/model/machine/machine_simulator.gd`
- Modify: `godot/scripts/run/battle_one_vertical.gd`
- Test: `godot/tools/verify_physics_machine_integration.gd`

- [ ] **Step 1.1: Split machine simulator into supply timing and result application**

`MachineSimulator.advance_step()` must stop resolving `_launch_result_for_step()`, `_tuning_result_for_step()`, and `_slot_for_step()` in runtime. Keep Forge/Launcher timing, Pool, Queue, modifiers, and result application.

New public contract:

```gdscript
func advance_supply(delta: float) -> Array[Dictionary]:
	# Returns ball launch requests when Launcher fires.

func apply_physics_result(result: MachinePhysicsResult) -> Array[Dictionary]:
	# Applies Launch/Tuning/Unit physical landing result and returns produced queue entries.

func get_machine_chain_sample() -> Dictionary:
	# Last physical chain: Pool -> Launch -> Tuning -> Unit -> Queue.
```

The old deterministic pattern functions may remain only behind verifier helper methods with names containing `for_verifier`.

- [ ] **Step 1.2: Rework `MachinePhysicsBoardView` into the runtime driver**

`MachinePhysicsBoardView` must:

- Build visible Launch, Tuning, and Unit physics board regions with `RigidBody2D` balls, `StaticBody2D` pegs/gates, and `Area2D` bins.
- Use primitive collision shapes and direct shape parameters, not node `scale`.
- Emit `landing_resolved(result: MachinePhysicsResult)` from bin `body_entered`.
- Carry `source = "physics"` for real runtime results and `source = "verifier_seed"` only in deterministic test mode.
- Provide:

```gdscript
func launch_ball(ball: Dictionary, battle_elapsed: float) -> void
func set_exposure_state(exposure_state: MachineSlotExposureState) -> void
func get_runtime_contract() -> Dictionary
```

- [ ] **Step 1.3: Embed physics board in the visible machine panel**

`MachineBoardView` must keep the current readable board but include the actual physics driver as a child node whose active ball and landing path are visible in the same machine panel.

`get_visual_contract_summary()` must include:

```gdscript
"runtime_physics_drives_results": true,
"physics_landing_count": physics_landing_count,
"last_physics_result": last_physics_result.to_dictionary(),
"has_visible_rigidbody_ball": true
```

- [ ] **Step 1.4: Route physics results to machine and Queue Bridge**

`BattleOneVertical` must use `_physics_process(delta)` for machine physics and battle stepping. When `MachinePhysicsBoardView` emits `landing_resolved`, call `machine.apply_physics_result(result)`, update the readable log, then let the existing 0.5s FIFO deploy tick deploy produced entries.

Runtime logs must expose a Chinese chain like:

```text
物理落点：Launch -> Tuning
物理落点：Tuning Prime -> S1 +2
Unit：S1 槽满，短牙虫进入 Queue
```

- [ ] **Step 1.5: Preserve deterministic headless verification without changing player runtime**

Verifier mode must call explicit helper APIs:

```gdscript
func emit_seeded_landing_for_verifier(result: MachinePhysicsResult) -> void
func run_seeded_chain_for_verifier(results: Array[MachinePhysicsResult]) -> void
```

These helpers cannot be called by normal `_physics_process()`.

- [ ] **Step 1.6: Run verification**

Run:

```bash
bash tools/verify_godot.sh
```

Expected after Task 1: `verify_physics_machine_integration: PASS`.

Commit:

```bash
git add godot/scripts/model/machine godot/scripts/ui/machine_physics_board_view.gd godot/scripts/ui/machine_board_view.gd godot/scripts/ui/machine_strip_view.gd godot/scripts/run/battle_one_vertical.gd godot/tools/verify_physics_machine_integration.gd tools/verify_godot.sh
git commit -m "feat: drive machine results from visible physics"
```

## Task 2: Implement Unit Slot Exposure Gate As Physics And Rules

**Files:**
- Create: `godot/scripts/model/machine/machine_slot_exposure_state.gd`
- Modify: `godot/scripts/model/machine/machine_simulator.gd`
- Modify: `godot/scripts/ui/machine_physics_board_view.gd`
- Modify: `godot/scripts/ui/machine_board_view.gd`
- Modify: `godot/scripts/model/battle/battlefield_telemetry.gd`
- Test: `godot/tools/verify_exposure_gate.gd`

- [ ] **Step 2.1: Add slot exposure state model**

`MachineSlotExposureState` must define:

```gdscript
const EXPOSURE_START_SECONDS: Dictionary = {1: 0.0, 2: 12.0, 3: 36.0, 4: 72.0}
const EXPOSURE_FULL_SECONDS: Dictionary = {1: 0.0, 2: 24.0, 3: 54.0, 4: 96.0}
const SLOT_REQUIREMENTS: Dictionary = {1: 3, 2: 5, 3: 8, 4: 12}

func get_exposure_ratio(slot_id: int, battle_elapsed: float) -> float
func is_slot_open_for_progress(slot_id: int, battle_elapsed: float) -> bool
func is_slot_fully_exposed(slot_id: int, battle_elapsed: float) -> bool
func snapshot(battle_elapsed: float) -> Dictionary
func lowest_progress_legal_slot(slot_progress: Dictionary, battle_elapsed: float) -> int
```

`is_slot_open_for_progress()` returns true only after exposure start; full ratio controls visible opening size.

- [ ] **Step 2.2: Make Unit physics board bounce blocked areas**

`MachinePhysicsBoardView` Unit board must create per-slot blocker `StaticBody2D` nodes whose collision shapes shrink as exposure ratio increases. If a ball contacts a blocked area, the result is not applied as Unit progress; the ball continues or resolves into another legal area.

The visual board must draw:

- Closed gate plate for unopened slot.
- Partial opening during interpolation.
- Fully open slot when ratio is 1.0.
- A Chinese bounce log when a ball hits a blocked area.

- [ ] **Step 2.3: Enforce exposure in simulator as a second safety layer**

`MachineSimulator.apply_physics_result()` must reject any Unit progress result for a slot that is not open at the current battle time:

```gdscript
if result.component == "Unit" and not exposure_state.is_slot_open_for_progress(result.slot_id, battle_elapsed):
	event_log.append("Unit：S%d 暴露闸门未开启，球被挡开" % result.slot_id)
	return []
```

This is a safety guard; normal runtime should physically bounce before this branch.

- [ ] **Step 2.4: Record Battle 1 exposure learning fields**

`BattlefieldTelemetry` or `RunLearningRecord` must record:

```gdscript
"battle1.exposure_gate_snapshot": {
	"t_0": exposure.snapshot(0.0),
	"t_12": exposure.snapshot(12.0),
	"t_24": exposure.snapshot(24.0),
	"t_30": exposure.snapshot(30.0)
}
```

- [ ] **Step 2.5: Run verification**

Run:

```bash
bash tools/verify_godot.sh
```

Expected after Task 2: `verify_exposure_gate: PASS`.

Commit:

```bash
git add godot/scripts/model/machine/machine_slot_exposure_state.gd godot/scripts/model/machine/machine_simulator.gd godot/scripts/ui/machine_physics_board_view.gd godot/scripts/ui/machine_board_view.gd godot/scripts/model/battle/battlefield_telemetry.gd godot/tools/verify_exposure_gate.gd
git commit -m "feat: implement unit slot exposure gates"
```

## Task 3: Implement Guardian Contract Strategic And Tactical Rules

**Files:**
- Create: `godot/scripts/model/guardian/guardian_contract_state.gd`
- Modify: `godot/scripts/run/mvp_run_session.gd`
- Modify: `godot/scripts/run/battle_one_vertical.gd`
- Modify: `godot/scripts/model/machine/machine_simulator.gd`
- Modify: `godot/scripts/model/battle/battle_entity_state.gd`
- Modify: `godot/scripts/model/battle/battlefield_state.gd`
- Modify: `godot/scripts/model/battle/battlefield_telemetry.gd`
- Modify: `godot/scripts/ui/battlefield_view.gd`
- Test: `godot/tools/verify_guardian_contract_behaviors.gd`

- [ ] **Step 3.1: Add Guardian contract state**

`GuardianContractState` must support:

```gdscript
func configure(guardian_id: String, rng_seed: int = 0) -> void
func reset_for_battle() -> void
func on_launch_recycle(machine: MachineSimulator) -> bool
func on_tuning_result(result_id: String) -> String
func on_player_guardian_damaged(attacker: BattleEntityState, battlefield: BattlefieldState) -> void
func on_base_zone_intruder(intruder: BattleEntityState, battlefield: BattlefieldState) -> void
func telemetry_snapshot() -> Dictionary
```

- [ ] **Step 3.2: Implement `巢脉母` strategic machine rule**

On legal Recycle:

- Roll 15% with seeded `RandomNumberGenerator`.
- If not triggered, increment hidden pity.
- On the 6th legal Recycle, trigger even if the roll failed.
- Trigger adds exactly one clean value-1 ball through normal Pool insertion rules.
- Pool full still rejects the extra ball.
- Reset pity after trigger.
- Reset counters at each battle start.

Required player log:

```text
守护者契约：巢脉回流触发，Recycle 额外返回 1 颗净球
```

- [ ] **Step 3.3: Implement `酸冠母` strategic machine rule**

On `Tuning.Gate`:

- Count only Gate results.
- On the 6th Gate miss, convert that result to `Prime`.
- Reset counter after conversion.
- Do not count Echo, Surge, Launch Split, Recycle, or Waste.
- Do not change Prime width or Prime value bonus.

Required player log:

```text
守护者契约：酸冠入槽，本次 Gate 转为 Prime
```

- [ ] **Step 3.4: Implement Player Guardian basic attack**

`BattlefieldState` must let Player Guardian attack intruders inside player base circle only:

- Damage: 5.
- Interval: 1.5s.
- Target: closest intruder in base circle; if tied, lower HP.
- Does not attack along whole lane.
- Does not attack Endpoint Guardian.
- Does not accept player control.

- [ ] **Step 3.5: Implement `巢脉牵缚` tactical rule**

When an enemy enters the player base circle and cooldown is available:

- Cooldown: 8s.
- Target: closest to Player Guardian; tie by lower HP.
- Damage: 4.
- Stop: 0.5s.
- Slow: 40% for 1.2s.
- Visual/log text must mention `巢脉牵缚`.

Add to `BattleEntityState`:

```gdscript
var root_timer: float = 0.0
var slow_timer: float = 0.0
var slow_multiplier: float = 1.0
```

- [ ] **Step 3.6: Implement `酸冠反喷` tactical rule**

When Player Guardian takes actual HP damage and cooldown is available:

- Cooldown: 6s.
- Trigger once per damage event.
- Cooldown hits are not stored.
- Attacker takes 4 damage.
- Up to 2 nearby intruders in player base circle within radius 3.0 take 1 damage.
- No healing, no resource refund, no max HP increase, no damage prevention.
- Visual/log text must mention `酸冠反喷`.

- [ ] **Step 3.7: Record Guardian learning fields**

Final record must include:

```gdscript
"guardian.choice_read": "Launch 契约：巢脉回流 / 守家牵缚"
```

or:

```gdscript
"guardian.choice_read": "Tuning 契约：Gate 转 Prime / 受击反喷"
```

Also append `guardian.hp_pressure_events` when Guardian attacks, uses tactical skill, takes damage, or buys rest.

- [ ] **Step 3.8: Run verification**

Run:

```bash
bash tools/verify_godot.sh
```

Expected after Task 3: `verify_guardian_contract_behaviors: PASS`.

Commit:

```bash
git add godot/scripts/model/guardian godot/scripts/run/battle_one_vertical.gd godot/scripts/run/mvp_run_session.gd godot/scripts/model/machine/machine_simulator.gd godot/scripts/model/battle godot/scripts/ui/battlefield_view.gd godot/tools/verify_guardian_contract_behaviors.gd
git commit -m "feat: implement guardian contract behavior"
```

## Task 4: Align Hive Units, Battlefield Behaviors, And Battle Duration Profile

**Files:**
- Modify: `godot/scripts/data/battle_unit_definition.gd`
- Modify: `godot/scripts/data/battle_wave_definition.gd`
- Modify: `godot/scripts/model/battle/battle_entity_state.gd`
- Modify: `godot/scripts/model/battle/battlefield_state.gd`
- Modify: `godot/scripts/ui/battlefield_view.gd`
- Test: `godot/tools/verify_hive_unit_and_battle_profile.gd`

- [ ] **Step 4.1: Set exact Hive unit first-pass values**

Update catalog:

```gdscript
"hive_short_fang": hp 6, damage 1, interval 0.7, range 1.5, speed 10.0
"hive_shield_shell": hp 18, damage 2, interval 1.4, range 1.5, speed 6.0
"hive_acid_sac": hp 8, damage 3, interval 1.8, range 7.0, speed 7.0
"hive_crush_shell_beast": hp 26, damage 6, interval 2.6, range 2.0, speed 5.0
```

Keep enemy templates `Enemy Grunt`, `Enemy Raider`, `Enemy Brute`.

- [ ] **Step 4.2: Add unit attack profile fields**

Add to `BattleUnitDefinition`:

```gdscript
var attack_profile: String = "single_melee"
var projectile_speed: float = 0.0
var splash_radius: float = 0.0
var max_splash_targets: int = 0
var sweep_radius: float = 0.0
var max_sweep_targets: int = 0
```

Values:

- `hive_acid_sac`: `attack_profile = "acid_projectile"`, `projectile_speed = 14.0`, `splash_radius = 2.5`, `max_splash_targets = 2`.
- `hive_crush_shell_beast`: `attack_profile = "lane_sweep"`, `sweep_radius = 3.5`, `max_sweep_targets = 3`.

- [ ] **Step 4.3: Implement Acid Sac and Crush Shell behavior**

`BattlefieldState._attack_entity()` must branch:

- `single_melee`: current single-target damage.
- `acid_projectile`: apply main damage to target and 1 splash damage to up to 2 additional same-lane enemies within 2.5 path units of target position.
- `lane_sweep`: apply full damage to up to 3 same-lane enemies within 3.5 path units of the contact point.

No DoT, no acid pool, no cross-lane hit, no knockback.

- [ ] **Step 4.4: Replace compressed duration windows**

`BattleWaveDefinition` must expose:

```gdscript
var target_duration_min_seconds: float
var target_duration_max_seconds: float
var pressure_limit_seconds: float
```

Set:

- Battle 1: 90-110s.
- Battle 2: 100-125s.
- Battle 3: 115-140s.
- Battle 4: 105-130s.
- Battle 5: 125-150s.
- Endpoint: 165-195s.

Use `pressure_limit_seconds = target_duration_min_seconds` for ordinary battle win/loss pressure checks, and Endpoint remains HP-based with the sweep.

- [ ] **Step 4.5: Update wave spawn timing**

Scale wave spawns to those windows:

- Battle 1: single left-lane light pressure, no counter.
- Battle 2: basic two-lane pressure, no counter.
- Battle 3: main pressure plus counter warning starting between 25-40s.
- Battle 4: validates shop/rest patch without new counter.
- Battle 5: main pressure plus secondary pressure, 1-2 counter triggers.
- Endpoint: Endpoint Guardian plus one counter family and sweep.

- [ ] **Step 4.6: Keep headless tests fast by simulated stepping, not compressed rules**

`advance_for_verifier(seconds)` may continue stepping simulated time quickly. It must not alter battle duration constants or player runtime pacing.

- [ ] **Step 4.7: Run verification**

Run:

```bash
bash tools/verify_godot.sh
```

Expected after Task 4: `verify_hive_unit_and_battle_profile: PASS`.

Commit:

```bash
git add godot/scripts/data/battle_unit_definition.gd godot/scripts/data/battle_wave_definition.gd godot/scripts/model/battle godot/scripts/ui/battlefield_view.gd godot/tools/verify_hive_unit_and_battle_profile.gd
git commit -m "feat: align hive battle profile"
```

## Task 5: Correct Reward And Shop Modifier Semantics

**Files:**
- Modify: `godot/scripts/model/machine/machine_simulator.gd`
- Modify: `godot/scripts/model/machine/machine_slot_exposure_state.gd`
- Modify: `godot/scripts/run/battle_one_vertical.gd`
- Modify: `godot/scripts/ui/machine_board_view.gd`
- Modify: `godot/scripts/ui/machine_strip_view.gd`
- Test: `godot/tools/verify_modifier_semantics.gd`

- [ ] **Step 5.1: Implement `Junk Sieve` cooldown and head-only behavior**

When Launcher would fire a Junk at Pool head:

- If `junk_sieve_enabled` and `junk_sieve_cooldown <= 0`, remove that head Junk as Waste.
- Start 10s cooldown.
- Do not generate clean ball.
- Do not clear non-head Junk.
- If cooldown active, Junk fires and produces no Unit hit.

- [ ] **Step 5.2: Implement `Surge Buffer` per-slot charge**

Track:

```gdscript
var surge_buffer_charge_by_slot: Dictionary = {1: false, 2: false, 3: false, 4: false}
```

When Surge hits a slot and does not generate a queue entry, set that slot charge to true. When that slot next generates a queue entry, attach:

```gdscript
entry["deploy_delay"] = 0.25
entry["source_tags"] = ["Surge Buffer"]
```

Then clear that slot charge. Do not affect other slots or all queue entries.

- [ ] **Step 5.3: Implement `Queue Brace` as time-based empty deployment gap**

`BattleOneVertical` must notify machine when a deploy tick finds no queue entry:

```gdscript
machine.record_empty_deploy_gap(DEPLOY_TICK_SECONDS, battle_elapsed, exposure_state)
```

`MachineSimulator` must:

- Track continuous seconds since last deployed queue entry.
- If >= 3s and cooldown <= 0, find lowest-progress exposed legal slot.
- Add +1 progress to that slot.
- Start 12s cooldown.
- Never grant progress to unopened slots.
- Never directly generate a queue entry unless that +1 naturally completes the slot.

- [ ] **Step 5.4: Implement `Muster Pair` merge window**

When a queue entry is generated:

- If previous unpaired entry exists from the same slot within 1.2s, merge into one entry:

```gdscript
entry["count"] = 2
entry["paired_entry"] = true
entry["source_tags"].append("Muster Pair")
```

- Do not merge across slots.
- Do not change unit stats.
- Do not increase count beyond 2 from one merge.

- [ ] **Step 5.5: Correct `Echo Latch`**

Echo baseline already creates one copy hit. With `Echo Latch`:

- Lock the Echo copy to the same slot as the original Echo hit.
- Show a visible ghost hit marker.
- Do not create an additional third copy.
- Do not spawn a new physics ball.
- Do not trigger Echo recursively.

Remove the current extra `EchoLatch +1` progress branch if it creates a third hit beyond original + copy.

- [ ] **Step 5.6: Keep confirmed existing semantics intact**

Verify:

- `Pool Pocket`: capacity 5 -> 6, not 7.
- `Front Recycle`: returns clean ball to Pool front/early position, Pool full still rejects.
- `Prime Charge`: Prime value bonus changes from +1 to +2 only.
- `Slot Primer`: one selected slot has floor 1 across the run; no multi-slot floor; no exposure bypass.

- [ ] **Step 5.7: Run verification**

Run:

```bash
bash tools/verify_godot.sh
```

Expected after Task 5: `verify_modifier_semantics: PASS`.

Commit:

```bash
git add godot/scripts/model/machine godot/scripts/run/battle_one_vertical.gd godot/scripts/ui/machine_board_view.gd godot/scripts/ui/machine_strip_view.gd godot/tools/verify_modifier_semantics.gd
git commit -m "fix: match modifier semantics"
```

## Task 6: Tighten Counter Timing, Limits, And Route Semantics

**Files:**
- Modify: `godot/scripts/model/counter/counter_state.gd`
- Modify: `godot/scripts/run/battle_one_vertical.gd`
- Modify: `godot/scripts/model/battle/battlefield_state.gd`
- Modify: `godot/scripts/ui/battlefield_view.gd`
- Test: `godot/tools/verify_m3_counter_flow.gd`
- Test: `godot/tools/verify_full_handoff_flow.gd`

- [ ] **Step 6.1: Pool Polluter exact behavior**

Implement:

- 4s warning.
- Insert 1 Junk on activation.
- Active 18s.
- Every 6s during active, try one additional Junk.
- At most 2 Pool Polluter Junk in Pool at the same time.
- Do not delete clean balls.
- Do not fill Pool without warning.

- [ ] **Step 6.2: Echo Breaker exact behavior**

Implement:

- 4s warning.
- Active 14s.
- Next Echo copy only is downgraded to ordinary Gate settlement.
- At most 1 swallowed Echo copy per active window.
- If a second same-family trigger happens, enforce at least 25s gap.
- Do not disable all Echo or all Tuning reward slots.

- [ ] **Step 6.3: Stagger Punisher exact behavior**

Implement:

- Monitor 4s continuous time without deployed queue entry.
- Show 3s warning on the most dangerous route.
- Spawn 2 Enemy Raiders on that same route.
- Active 16s.
- At most 2 triggers per active window.
- Do not clear the queue.
- Do not punish every Unit build if it has continuous deployments.

- [ ] **Step 6.4: Battle 5 and Endpoint counter profile**

Battle 5 must use 1-2 stronger counter triggers, prioritizing the same family if the player's build still exposes it. Endpoint must use one counter family plus Endpoint Guardian sweep.

The counter chooser must derive from current main axis:

- `Launch` / Pool-heavy: `pool_polluter`.
- `Tuning` / Echo or Surge value: `echo_breaker`.
- `Unit` / queue-gap exposed: `stagger_punisher`.

- [ ] **Step 6.5: Run verification**

Run:

```bash
bash tools/verify_godot.sh
```

Expected after Task 6: existing M3 and full handoff verifiers remain PASS, with stronger counter checks included.

Commit:

```bash
git add godot/scripts/model/counter/counter_state.gd godot/scripts/run/battle_one_vertical.gd godot/scripts/model/battle/battlefield_state.gd godot/scripts/ui/battlefield_view.gd godot/tools/verify_m3_counter_flow.gd godot/tools/verify_full_handoff_flow.gd
git commit -m "fix: align counter timing and limits"
```

## Task 7: Build Complete Learning Checkpoint Record From Real Telemetry

**Files:**
- Create: `godot/scripts/model/run/run_learning_record.gd`
- Modify: `godot/scripts/model/run/run_session_model.gd`
- Modify: `godot/scripts/run/mvp_run_session.gd`
- Modify: `godot/scripts/model/battle/battlefield_telemetry.gd`
- Modify: `godot/scripts/ui/run/final_result_view.gd`
- Test: `godot/tools/verify_complete_learning_record.gd`
- Test: `godot/tools/verify_endpoint_result_fields.gd`

- [ ] **Step 7.1: Move final record construction into `RunLearningRecord`**

`RunLearningRecord.build(session, machine_records, battle_records, guardian_records)` must return the complete field set listed in Task 0.6.

- [ ] **Step 7.2: Capture missing Battle 1 fields**

Record:

- `battle1.machine_chain_sample`: actual physical chain from Task 1.
- `battle1.exposure_gate_snapshot`: Task 2 snapshots.
- `battle1.deploy_lane_selection`: first 30s selected route sequence.
- `battle1.lane_danger_snapshot`: highest danger 0-3 by lane during first 30s.

`DeployLaneModel.select_lane()` or `BattleOneVertical.select_deploy_lane()` must call telemetry `record_lane_change(lane, elapsed)`.

- [ ] **Step 7.3: Capture Unit contribution fields**

Record:

- `unit.visible_contribution_slots`: slots whose queue entries changed lane state, prevented leak, broke gate, damaged Guardian, or contributed to Endpoint result.
- `unit.key_queue_entries_by_slot`: up to 3 key entries per slot.
- `unit.dominant_slot_share`: `{ "slot_id": int, "share": float }` based on key queue entries, not raw spam count.

- [ ] **Step 7.4: Capture Reward and Shop fields**

Record:

- `reward1.battlefield_expectation`: one of `Launch sustained flow`, `Tuning high-value hit`, `Unit anchor slot`.
- `reward1.battlefield_result`: battle/lane/time where expectation visibly occurred, or `未明显兑现`.
- `shop1.gold_before`.
- `shop1.gold_after`.
- `shop1.purchase_role`: `Patch`, `Pivot`, `Deepen`, `Rest`, or `无`.

- [ ] **Step 7.5: Capture Rest fields**

Record:

- `rest_windows`: each window name, whether it appeared, whether rest was bought, Gold spent, HP restored.
- `rest.total_purchases`.
- `rest.total_gold_spent`.
- `rest.total_hp_restored`.
- `rest.endpoint_relevance`.

When rest is bought, append a Guardian HP pressure event:

```text
休整：花费 3 Gold，恢复 20 HP
```

- [ ] **Step 7.6: Capture session cadence**

Record:

- `session.decision_windows`: Guardian, Reward 1, Shop, Rest windows, Reward 2, Endpoint Prep, key Deploy Lane changes.
- `session.consecutive_no_explained_decision_battles`: count consecutive battles without reward/shop/rest/counter/route impact/result-page payoff.

- [ ] **Step 7.7: Update Final Result UI**

`FinalResultView` must display these labels in Chinese:

- 主要机器轴
- 关键奖励
- 关键商店
- Guardian 选择
- Unit 槽贡献
- 主要反制
- Deploy Lane 影响
- 终点战结论
- 休整与 Gold
- 下一局观察

It must not display implementation terms such as `M4`, `M5`, `M6`, `DEBUG`, `verifier`, or `后续里程碑`.

- [ ] **Step 7.8: Run verification**

Run:

```bash
bash tools/verify_godot.sh
```

Expected after Task 7: `verify_complete_learning_record: PASS`.

Commit:

```bash
git add godot/scripts/model/run/run_learning_record.gd godot/scripts/model/run/run_session_model.gd godot/scripts/run/mvp_run_session.gd godot/scripts/model/battle/battlefield_telemetry.gd godot/scripts/ui/run/final_result_view.gd godot/tools/verify_complete_learning_record.gd godot/tools/verify_endpoint_result_fields.gd
git commit -m "feat: complete learning checkpoint record"
```

## Task 8: Player-Facing UI And Readability Pass

**Files:**
- Modify: `godot/project.godot`
- Modify: `godot/scenes/run/battle_one_vertical.tscn`
- Modify: `godot/scripts/ui/machine_board_view.gd`
- Modify: `godot/scripts/ui/machine_strip_view.gd`
- Modify: `godot/scripts/ui/battlefield_view.gd`
- Modify: `godot/scripts/ui/queue_bridge_view.gd`
- Modify: `godot/scripts/ui/run/run_hud_view.gd`
- Modify: `godot/scripts/ui/run/final_result_view.gd`
- Test: `godot/tools/verify_project.gd`
- Test: `godot/tools/verify_full_handoff_flow.gd`

- [ ] **Step 8.1: Remove player-visible debug wording**

`project.godot` title and all player-facing labels must not contain:

- `DEBUG`
- `M5`
- `M6`
- `verifier`
- `stub`
- `sandbox`
- `后续里程碑`

Formal machine terms may remain English: `Launch`, `Tuning`, `Unit`, `Queue`, `Deploy Lane`, `Gate`, `Prime`, `Echo`, `Surge`, `Pool`, `Forge`, `Launcher`.

- [ ] **Step 8.2: Show physical causality without debug logs**

Machine panel must show:

- Current physical ball.
- Last physical landing.
- Slot gate state.
- Modifier target marker.
- Counter target marker.
- Queue preview.

Do not show raw JSON, internal method names, or generic debug event logs.

- [ ] **Step 8.3: Show Guardian and counter feedback in battlefield**

Battlefield must visibly show:

- Player Guardian HP and basic attack feedback.
- `巢脉牵缚` or `酸冠反喷` when triggered.
- Endpoint Guardian HP.
- Sweep warning before hit.
- Route danger 0-3.
- Stagger warning route and Raider spawn on same route.

- [ ] **Step 8.4: Validate layout**

Battle screen must keep `38 / 14 / 48` stretch ratios and stay readable at the default Godot run size. No nested debug panels, no old button-card battlefield replacing the real battlefield.

- [ ] **Step 8.5: Grayscale/colorblind manual screenshot pass**

Capture screenshots at:

- Battle 1 first 30s.
- Battle 3 counter active.
- Battle 5 stronger counter.
- Endpoint sweep warning.
- Final Result.

Review against `docs/DESIGN.md`:

- Not color-only semantics.
- Distinct shapes for ball, Junk, gate, units, Guardians, danger, sweep warning.
- No overlapping text.

Record findings in `docs/PROGRESS.md`.

- [ ] **Step 8.6: Run verification**

Run:

```bash
bash tools/verify_godot.sh
```

Expected after Task 8: all automated verifiers PASS and no player-facing implementation-state wording remains.

Commit:

```bash
git add godot/project.godot godot/scenes/run/battle_one_vertical.tscn godot/scripts/ui docs/PROGRESS.md
git commit -m "fix: polish player-facing design alignment"
```

## Task 9: Full Verification, Playtest Acceptance Protocol, And Final Gate

**Files:**
- Create: `docs/playtest/planb-mvp-v0-acceptance-protocol.md`
- Modify: `docs/PROGRESS.md`
- Test: `tools/verify_godot.sh`

- [ ] **Step 9.1: Create manual acceptance protocol**

`docs/playtest/planb-mvp-v0-acceptance-protocol.md` must define:

- Tester is not the implementer.
- Run target is one complete short run from Main Menu to Final Result.
- Test at least one win path and one loss path.
- Tester must answer in their own words:
  - Which axis did you mainly build: `Launch`, `Tuning`, or `Unit`?
  - Which machine component did Reward 1 change?
  - Which machine component did Shop change?
  - Which component did the first counter attack?
  - What did `Deploy Lane` change?
  - Why did the Endpoint win/loss happen?
  - Was Guardian HP pressure relevant?
- Observer records whether each answer is clear, confused, or absent.
- Screenshots required: Battle 1, first counter, second reward, Endpoint, Final Result.

- [ ] **Step 9.2: Run full automated gate**

Run:

```bash
bash tools/verify_godot.sh
```

Expected:

```text
verify_project: PASS
verify_m1_machine_to_lane: PASS
verify_m2_run_flow: PASS
verify_m3_counter_flow: PASS
verify_m4_second_reward_flow: PASS
verify_entity_battlefield: PASS
verify_full_handoff_flow: PASS
verify_endpoint_result_fields: PASS
verify_machine_physics_contract: PASS
verify_physics_machine_integration: PASS
verify_exposure_gate: PASS
verify_guardian_contract_behaviors: PASS
verify_hive_unit_and_battle_profile: PASS
verify_modifier_semantics: PASS
verify_complete_learning_record: PASS
verify_godot: PASS
```

- [ ] **Step 9.3: Run one local manual smoke pass**

Open the active Godot project and play at least through:

```text
Main Menu -> Guardian Contract -> Battle 1 -> Reward 1 -> Battle 2 -> Shop / Rest -> Battle 3 -> Rest -> Battle 4 -> Reward 2 -> Battle 5 -> Endpoint Prep -> Endpoint -> Final Result
```

Record in `docs/PROGRESS.md`:

- Date.
- Commit hash.
- Whether physical ball causality was visible.
- Whether slot exposure gates were visible.
- Whether Guardian skill triggered.
- Whether Final Result fields were populated.
- Any unresolved visual/readability issue.

- [ ] **Step 9.4: Final status wording**

Only report “实现已按已确认设计内容补齐” if:

- All automated verifiers pass.
- Local manual smoke pass reaches Final Result without debug UI.
- `docs/PROGRESS.md` records the smoke evidence.
- Any still-unproven player-understanding claims are explicitly labeled as requiring non-implementer playtest evidence.

Commit:

```bash
git add docs/playtest/planb-mvp-v0-acceptance-protocol.md docs/PROGRESS.md
git commit -m "docs: add mvp v0 acceptance protocol"
```

## Completion Definition

This plan is complete only when all of the following are true:

- Runtime machine results are driven by visible 2D physics landings.
- `Unit.Slot.Exposure Gate` timing and blocked-bounce behavior are implemented and visible.
- `巢脉母` and `酸冠母` Guardian strategic/tactical rules resolve in the correct layer.
- Player Guardian basic attack exists and does not replace lane defense.
- Hive unit stats and special behaviors match confirmed first-pass loadout.
- Battle duration bands match confirmed target ranges.
- Reward/shop modifiers match `docs/rewards-economy.md` semantics and guardrails.
- Counter families match `docs/enemy-rules.md` timing, limits, and visible effects.
- Final Result includes the complete learning-checkpoint field set.
- Player-facing text is Chinese except formal machine terms.
- `bash tools/verify_godot.sh` passes the expanded verification chain.
- `docs/PROGRESS.md` records manual smoke evidence and distinguishes automated proof from playtest-only player-understanding proof.
