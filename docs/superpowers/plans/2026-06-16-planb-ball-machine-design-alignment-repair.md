# PlanB Ball Machine Design Alignment Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Repair every known mismatch between the active `godot/` ball machine implementation and the current machine / physical-ball design docs, without expanding beyond confirmed MVP v0 M0-M4 scope.

**Architecture:** Keep the current `godot/` run shell, three-panel machine UI, and verifier entry, but make the runtime contract stricter: real visible 2D physics must determine normal landings, forced redirects must be represented as visible guide-rail events, every ball must carry the documented payload fields, every machine-changing rule must expose Machine Contract fields, and Queue timing must respect normal `0.5s` deployment delay plus `Surge` `0.25s` delay. Deterministic patterns remain only under explicit verifier APIs.

**Tech Stack:** Godot 4.6, GDScript, Compatibility / `gl_compatibility`, Godot 2D physics (`RigidBody2D`, `StaticBody2D`, `Area2D`), headless Godot verifiers via `bash tools/verify_godot.sh`.

---

## Authority And Scope

Use these current sources:

- `AGENTS.md`
- `docs/gdd.md`
- `docs/machine-warehouses.md`
- `docs/ball-machine-physical.md`
- `docs/DESIGN.md`
- `docs/rewards-economy.md`
- `docs/mvp-hive-loadout.md`
- `docs/enemy-rules.md`
- `docs/deploy-lane-ui.md`
- `docs/mvp-learning-checkpoints.md`

This plan must not:

- Touch `docs/archive/` implementation or prototype files.
- Restore old `mvp/` runtime assumptions.
- Add M5/M6 scope.
- Lock final physics parameters, final peg layout, final art, or final balance beyond MVP v0 implementation assumptions.
- Treat verifier seed paths as player runtime behavior.

Implementation requires explicit user confirmation after this plan.

## Gap Matrix

| Gap | Required repair | Task |
|---|---|---|
| Runtime physics currently pre-targets bins by deterministic pattern. | Runtime launch / transfer must not preselect result labels; `Area2D` bin contact determines result. | Task 1 |
| Route and Tuning slots are equal width. | Launch bins use `65/15/15/5` physical width ratios; Tuning uses `55/15/15/15`; Gate is visibly wider. | Task 1 |
| Forced redirects are logic-only conversions. | `Gate -> Prime` override and future single-ball redirects emit visible guide-rail feedback with natural and final result recorded. | Task 2 |
| Ball Payload lacks `tags`, `tuning_mark`, `source_pass`. | All pool/runtime balls use canonical payload dictionaries with documented fields and loop-safety defaults. | Task 3 |
| Machine Contract records are incomplete. | Modifiers, Guardian strategic skills, and counters expose `source`, `warehouse`, `target_component`, `operation`, `scope`, `player_read`, `failure_risk`, `guardrail`. | Task 3 |
| Base `Surge` does not actually deploy at `0.25s`. | Queue entries carry `generated_elapsed`, `deploy_delay`, `ready_elapsed`; base delay is `0.5s`, Surge delay is `0.25s`; max one deployment per ready event. | Task 4 |
| `Slot Primer` is fixed to S1. | Reward flow lets the player choose one legal Unit slot and persists that slot in battle payload / result records. | Task 5 |
| Existing verifiers prove structure more than design alignment. | Add red gates for natural physics, weighted bins, forced redirect, payload fields, contract fields, Surge timing, and Slot Primer selection. | Task 0 and Task 6 |

## File Map

### Create

- `godot/scripts/model/machine/machine_ball_payload.gd`  
  Canonical payload helper for `kind`, `value`, `tags`, `tuning_mark`, `source_pass`, `chain_id`, and source metadata.

- `godot/scripts/data/machine_contract_entry.gd`  
  Typed data record for Machine Contract fields used by modifiers, Guardian strategic effects, and counters.

- `godot/tools/verify_ball_machine_design_alignment.gd`  
  New focused verifier for the exact mismatches repaired by this plan.

### Modify

- `tools/verify_godot.sh`
- `godot/scripts/model/machine/machine_simulator.gd`
- `godot/scripts/model/machine/machine_physics_result.gd`
- `godot/scripts/model/machine/machine_slot_exposure_state.gd`
- `godot/scripts/ui/machine_physics_board_view.gd`
- `godot/scripts/ui/machine_board_view.gd`
- `godot/scripts/ui/machine_strip_view.gd`
- `godot/scripts/data/modifier_definition.gd`
- `godot/scripts/model/guardian/guardian_contract_state.gd`
- `godot/scripts/model/counter/counter_state.gd`
- `godot/scripts/model/run/run_session_model.gd`
- `godot/scripts/run/mvp_run_session.gd`
- `godot/scripts/run/battle_one_vertical.gd`
- `godot/scripts/ui/run/reward_choice_view.gd`
- `godot/scripts/ui/run/final_result_view.gd`
- `godot/tools/verify_machine_physics_contract.gd`
- `godot/tools/verify_physics_machine_integration.gd`
- `godot/tools/verify_modifier_semantics.gd`
- `docs/PROGRESS.md`

## Task 0: Add Red Design-Alignment Gates

**Files:**
- Create: `godot/tools/verify_ball_machine_design_alignment.gd`
- Modify: `tools/verify_godot.sh`

- [ ] **Step 0.1: Add verifier shell**

Create `godot/tools/verify_ball_machine_design_alignment.gd` with these top-level checks:

```gdscript
extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_verify_runtime_physics_has_no_preselected_target()
	_verify_weighted_bin_widths()
	_verify_forced_redirect_contract()
	_verify_ball_payload_contract()
	_verify_machine_contract_fields()
	_verify_surge_queue_timing()
	_verify_slot_primer_target_selection()
	_finish()
```

Run:

```bash
GODOT_BIN="${GODOT_BIN:-godot}" "$GODOT_BIN" --headless --path godot --script res://tools/verify_ball_machine_design_alignment.gd
```

Expected now: FAIL on missing verifier helpers or unmet contracts.

- [ ] **Step 0.2: Gate against runtime pre-targeting**

Inside the verifier, instantiate `MachinePhysicsBoardView` and require a runtime contract field that proves normal runtime mode has no target pattern:

```gdscript
var board = load("res://scripts/ui/machine_physics_board_view.gd").new()
root.add_child(board)
var contract: Dictionary = board.call("get_runtime_contract")
if bool(contract.get("runtime_uses_preselected_target_labels", true)):
	failures.append("Runtime physics must not preselect target labels; normal bins must determine landings.")
root.remove_child(board)
board.free()
```

Expected now: FAIL until Task 1 exposes and satisfies the contract.

- [ ] **Step 0.3: Gate weighted bin widths**

Require Launch and Tuning bin width ratios in runtime contract:

```gdscript
var launch_widths: Dictionary = contract.get("bin_width_ratios", {}).get("Launch", {})
_expect_ratio(launch_widths, "Tuning", 0.65, 0.05)
_expect_ratio(launch_widths, "Split", 0.15, 0.04)
_expect_ratio(launch_widths, "Recycle", 0.15, 0.04)
_expect_ratio(launch_widths, "Waste", 0.05, 0.03)
var tuning_widths: Dictionary = contract.get("bin_width_ratios", {}).get("Tuning", {})
_expect_ratio(tuning_widths, "Gate", 0.55, 0.05)
```

Expected now: FAIL because current bins are equal-width.

- [ ] **Step 0.4: Wire verifier into root command**

Add after `verify_machine_physics_contract.gd` and before red gates in `tools/verify_godot.sh`:

```bash
if [[ ! -f "$PROJECT_DIR/tools/verify_ball_machine_design_alignment.gd" ]]; then
  echo "Missing required ball machine design alignment verifier at $PROJECT_DIR/tools/verify_ball_machine_design_alignment.gd" >&2
  exit 1
fi

run_godot_verifier "res://tools/verify_ball_machine_design_alignment.gd"
```

Run:

```bash
bash tools/verify_godot.sh
```

Expected now: FAIL at the new verifier. Do not proceed to green implementation until the failure messages identify all seven gaps in the matrix.

## Task 1: Make Normal Runtime Landings Truly Physics-Determined

**Files:**
- Modify: `godot/scripts/ui/machine_physics_board_view.gd`
- Modify: `godot/scripts/model/machine/machine_physics_result.gd`
- Test: `godot/tools/verify_ball_machine_design_alignment.gd`
- Test: `godot/tools/verify_physics_machine_integration.gd`

- [ ] **Step 1.1: Split runtime launch from verifier seeded launch**

Replace runtime use of `_target_label_for_body()` in `launch_ball()` and `_place_body_for_stage()` with physics-only spawn logic. Keep deterministic landing only through `emit_seeded_landing_for_verifier()` and `run_seeded_chain_for_verifier()`.

Required runtime behavior:

```gdscript
func launch_ball(ball: Dictionary, battle_elapsed: float) -> void:
	_launch_index += 1
	var body: RigidBody2D = _make_ball(ball)
	add_child(body)
	_place_body_for_stage_runtime(body, "Launch", battle_elapsed)

func _place_body_for_stage_runtime(body: RigidBody2D, stage: String, battle_elapsed: float) -> void:
	var rect: Rect2 = _stage_rect(stage)
	var phase: float = float(_launch_index % 17) / 17.0 * TAU
	var swing_x: float = sin(phase) * rect.size.x * 0.28
	body.set_meta("stage", stage)
	body.set_meta("resolving_stage", false)
	body.set_meta("battle_elapsed", battle_elapsed)
	body.freeze = false
	body.sleeping = false
	body.position = Vector2(rect.get_center().x + swing_x, rect.position.y + 16.0)
	body.linear_velocity = Vector2(sin(phase) * 115.0, 165.0)
	body.angular_velocity = sin(phase) * 1.2
	body.reset_physics_interpolation()
```

Do not call `_target_label_for_body()` from normal runtime launch or stage transfer.

- [ ] **Step 1.2: Add runtime contract fields**

Add to `get_runtime_contract()`:

```gdscript
"runtime_uses_preselected_target_labels": false,
"verifier_seed_path_available": has_method("run_seeded_chain_for_verifier"),
"bin_width_ratios": _bin_width_ratio_snapshot(),
```

Add `_bin_width_ratio_snapshot()` by reading actual bin sizes, not hardcoded strings:

```gdscript
func _bin_width_ratio_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for stage: String in ["Launch", "Tuning", "Unit"]:
		var total_width: float = 0.0
		var stage_bins: Dictionary = {}
		for key_variant: Variant in _stage_bins.keys():
			var key: String = String(key_variant)
			if not key.begins_with(stage + ":"):
				continue
			var bin: Area2D = _stage_bins[key_variant] as Area2D
			var width: float = _bin_size(bin).x
			total_width += width
			stage_bins[String(bin.get_meta("label", ""))] = width
		var ratios: Dictionary = {}
		for label: String in stage_bins.keys():
			ratios[label] = float(stage_bins[label]) / maxf(total_width, 1.0)
		snapshot[stage] = ratios
	return snapshot
```

- [ ] **Step 1.3: Implement weighted physical bins**

Change `_build_stage_geometry()` so Launch and Tuning bin widths use explicit physical ratios:

```gdscript
func _bin_weight_for_label(stage: String, label: String) -> float:
	if stage == "Launch":
		match label:
			"Tuning": return 0.65
			"Split": return 0.15
			"Recycle": return 0.15
			"Waste": return 0.05
	if stage == "Tuning":
		match label:
			"Gate": return 0.55
			"Prime", "Echo", "Surge": return 0.15
	return 1.0
```

Use those weights to compute each `Area2D` bin's width and center. Unit slots remain equal width because the current formal rule allows equal physical width plus Exposure Gate gating.

- [ ] **Step 1.4: Preserve explicit verifier determinism**

Keep `_target_label_for_body()` only for a verifier-specific helper:

```gdscript
func _target_label_for_verifier_step(stage: String, step: int) -> String:
	match stage:
		"Launch":
			return ["Tuning", "Tuning", "Split", "Tuning", "Recycle", "Tuning", "Waste", "Tuning"][(step - 1) % 8]
		"Tuning":
			return ["Gate", "Prime", "Gate", "Echo", "Gate", "Surge"][(step - 1) % 6]
		"Unit":
			return ["S1", "S1", "S2", "S1", "S2", "S3", "S1", "S4"][(step - 1) % 8]
	return ""
```

The player runtime must not call this method.

- [ ] **Step 1.5: Verify**

Run:

```bash
GODOT_BIN="${GODOT_BIN:-godot}" "$GODOT_BIN" --headless --path godot --script res://tools/verify_ball_machine_design_alignment.gd
GODOT_BIN="${GODOT_BIN:-godot}" "$GODOT_BIN" --headless --path godot --script res://tools/verify_physics_machine_integration.gd
```

Expected: both PASS for runtime physics and weighted-bin checks.

## Task 2: Physicalize Forced Redirects

**Files:**
- Modify: `godot/scripts/model/machine/machine_physics_result.gd`
- Modify: `godot/scripts/ui/machine_physics_board_view.gd`
- Modify: `godot/scripts/model/machine/machine_simulator.gd`
- Modify: `godot/scripts/model/guardian/guardian_contract_state.gd`
- Modify: `godot/scripts/ui/machine_board_view.gd`
- Modify: `godot/scripts/ui/machine_strip_view.gd`
- Test: `godot/tools/verify_ball_machine_design_alignment.gd`
- Test: `godot/tools/verify_guardian_contract_behaviors.gd`

- [ ] **Step 2.1: Extend physics result with redirect metadata**

Add fields to `MachinePhysicsResult`:

```gdscript
var natural_result_id: String = ""
var forced_by: String = ""
var feedback_state: String = ""
```

Update `make()`, `to_dictionary()`, and `duplicate_result()` so these fields survive verifier and runtime paths.

- [ ] **Step 2.2: Add pre-landing redirect query to machine simulator**

Add method:

```gdscript
func redirect_tuning_result_if_needed(natural_result_id: String) -> Dictionary:
	if guardian_contract == null:
		return {
			"final_result_id": natural_result_id,
			"forced_by": "",
			"feedback_state": "Natural Hit",
		}
	var final_result_id: String = String(guardian_contract.call("on_tuning_result", natural_result_id))
	_drain_guardian_machine_logs()
	return {
		"final_result_id": final_result_id,
		"forced_by": "Guardian.StrategicSkill:hive_acid_crown_mother" if final_result_id != natural_result_id else "",
		"feedback_state": "Forced Redirect" if final_result_id != natural_result_id else "Natural Hit",
	}
```

Then change `apply_physics_result()` so it no longer calls `guardian_contract.on_tuning_result()` a second time for already-final redirected results.

- [ ] **Step 2.3: Route Tuning Gate override through visible guide rail**

In `MachinePhysicsBoardView._on_bin_body_entered()`, when `stage == "Tuning"` and natural label is `Gate`, ask the owning battle/machine path for redirect before emitting final result. Use a signal or injected callable; do not make the board reach up the tree.

Required board API:

```gdscript
signal redirect_requested(natural_result_id: String, body: RigidBody2D)

func resolve_redirect_for_verifier(natural_result_id: String) -> Dictionary:
	return {
		"final_result_id": natural_result_id,
		"forced_by": "",
		"feedback_state": "Natural Hit",
	}
```

If redirected to `Prime`, animate a short guide path before emitting:

```gdscript
func _emit_forced_redirect(body: RigidBody2D, bin: Area2D, redirect: Dictionary) -> void:
	var final_label: String = String(redirect.get("final_result_id", "Gate"))
	var prime_center: Vector2 = _bin_center("Tuning", final_label)
	_show_redirect_guide(bin.global_position, prime_center, String(redirect.get("forced_by", "")))
	body.global_position = prime_center + Vector2(0.0, -10.0)
	body.reset_physics_interpolation()
	var result: MachinePhysicsResult = _result_from_bin(body, _stage_bins["Tuning:%s" % final_label])
	result.natural_result_id = String(bin.get_meta("label", ""))
	result.forced_by = String(redirect.get("forced_by", ""))
	result.feedback_state = "Forced Redirect"
	_record_landing(result)
	landing_resolved.emit(result)
	call_deferred("_advance_body_after_landing", body, result)
```

- [ ] **Step 2.4: Show redirect as player-readable machine log and board feedback**

Add visible strings:

```gdscript
if result.feedback_state == "Forced Redirect":
	event_log.append("物理改道：%s 将 %s 导入 %s" % [
		result.forced_by,
		result.natural_result_id,
		result.result_id,
	])
```

In `MachineBoardView`, draw a short line / rail marker when `last_physics_result.feedback_state == "Forced Redirect"` and include source marker text no longer than `"强制导轨"` in the Tuning panel.

- [ ] **Step 2.5: Verify**

Run:

```bash
GODOT_BIN="${GODOT_BIN:-godot}" "$GODOT_BIN" --headless --path godot --script res://tools/verify_guardian_contract_behaviors.gd
GODOT_BIN="${GODOT_BIN:-godot}" "$GODOT_BIN" --headless --path godot --script res://tools/verify_ball_machine_design_alignment.gd
```

Expected: PASS with result dictionaries containing `natural_result_id = "Gate"`, `result_id = "Prime"`, `feedback_state = "Forced Redirect"`, and non-empty `forced_by`.

## Task 3: Canonical Ball Payload And Machine Contract Fields

**Files:**
- Create: `godot/scripts/model/machine/machine_ball_payload.gd`
- Create: `godot/scripts/data/machine_contract_entry.gd`
- Modify: `godot/scripts/model/machine/machine_simulator.gd`
- Modify: `godot/scripts/ui/machine_physics_board_view.gd`
- Modify: `godot/scripts/data/modifier_definition.gd`
- Modify: `godot/scripts/model/guardian/guardian_contract_state.gd`
- Modify: `godot/scripts/model/counter/counter_state.gd`
- Modify: `godot/scripts/run/mvp_run_session.gd`
- Test: `godot/tools/verify_ball_machine_design_alignment.gd`
- Test: `godot/tools/verify_modifier_semantics.gd`

- [ ] **Step 3.1: Add payload helper**

Create `MachineBallPayload`:

```gdscript
class_name MachineBallPayload
extends RefCounted

static func clean(chain_id: String = "", source_pass: int = 0) -> Dictionary:
	return {
		"kind": "clean",
		"value": 1,
		"tags": [],
		"tuning_mark": "",
		"source_pass": source_pass,
		"chain_id": chain_id,
		"source": "machine",
	}

static func junk(chain_id: String = "", source: String = "Pool Polluter") -> Dictionary:
	var payload: Dictionary = clean(chain_id)
	payload["kind"] = "junk"
	payload["value"] = 0
	payload["tags"] = ["junk"]
	payload["source"] = source
	return payload

static func normalize(payload: Dictionary) -> Dictionary:
	var normalized: Dictionary = clean(String(payload.get("chain_id", "")), int(payload.get("source_pass", 0)))
	normalized["kind"] = String(payload.get("kind", normalized["kind"]))
	normalized["value"] = int(payload.get("value", normalized["value"]))
	normalized["tags"] = (payload.get("tags", []) as Array).duplicate() if payload.get("tags", []) is Array else []
	normalized["tuning_mark"] = String(payload.get("tuning_mark", ""))
	normalized["source"] = String(payload.get("source", normalized["source"]))
	return normalized
```

- [ ] **Step 3.2: Use payload helper for all Pool balls**

In `MachineSimulator`, preload the helper and replace raw `{"kind": kind, "value": 1}` construction:

```gdscript
const MachineBallPayloadScript := preload("res://scripts/model/machine/machine_ball_payload.gd")

func _add_pool_ball(kind: String) -> bool:
	if pool.size() >= pool_capacity:
		event_log.append("Launch.Pool full rejected %s" % kind)
		return false
	var payload: Dictionary = MachineBallPayloadScript.junk() if kind == "junk" else MachineBallPayloadScript.clean()
	pool.append(payload)
	event_log.append("Launch.Forge added %s ball" % kind)
	return true
```

Split and Recycle must call `MachineBallPayload.clean()` so child balls do not inherit parent tags or tuning mark.

- [ ] **Step 3.3: Write tuning mark once, and only once**

When Tuning resolves:

```gdscript
var chain: Dictionary = _chain_for_result(result)
var payload: Dictionary = MachineBallPayloadScript.normalize(chain.get("pool", {}))
payload["tuning_mark"] = result.result_id
payload["source_pass"] = int(payload.get("source_pass", 0)) + 1
chain["pool"] = payload
```

Reject secondary tuning marks if `source_pass > 1` and log:

```gdscript
event_log.append("LoopSafety: ignored secondary tuning mark for %s" % result.chain_id)
```

- [ ] **Step 3.4: Add Machine Contract typed record**

Create `MachineContractEntry`:

```gdscript
class_name MachineContractEntry
extends Resource

@export var source: String = ""
@export var warehouse: String = ""
@export var target_component: String = ""
@export var operation: String = ""
@export var scope: String = ""
@export_multiline var player_read: String = ""
@export_multiline var failure_risk: String = ""
@export_multiline var guardrail: String = ""

func is_complete() -> bool:
	return not source.is_empty() and not warehouse.is_empty() and not target_component.is_empty() and not operation.is_empty() and not scope.is_empty() and not player_read.is_empty() and not failure_risk.is_empty()
```

- [ ] **Step 3.5: Extend modifier and Guardian/counter records**

Add fields to `ModifierDefinition`:

```gdscript
@export var scope: String = "整局"
@export_multiline var failure_risk: String = ""
@export_multiline var guardrail: String = ""
```

Populate all nine modifier definitions in `mvp_run_session.gd` with text already present in `docs/rewards-economy.md`.

Add Guardian strategic contract snapshots using documented values:

```gdscript
"source": "Guardian.StrategicSkill",
"warehouse": "Launch",
"target_component": "Launch.Recycle.return_count / Launch.Pool",
"operation": "trigger",
"scope": "每场战斗重置，整局固定",
"player_read": "Route Board / Recycle path 表现为巢脉回流",
"failure_risk": "战略技能过强会替代第一次奖励和商店",
```

Counter records must include `scope` and `failure_risk`, e.g. Pool Polluter:

```gdscript
"scope": "单场反制窗口",
"failure_risk": "无预警塞满 Pool 会读成沉默删除构筑",
"guardrail": "同一时间 Pool 内最多 2 个来自本反制的 Junk Ball",
```

- [ ] **Step 3.6: Verify**

Run:

```bash
GODOT_BIN="${GODOT_BIN:-godot}" "$GODOT_BIN" --headless --path godot --script res://tools/verify_ball_machine_design_alignment.gd
GODOT_BIN="${GODOT_BIN:-godot}" "$GODOT_BIN" --headless --path godot --script res://tools/verify_modifier_semantics.gd
```

Expected: PASS for payload keys and contract completeness.

## Task 4: Implement Base Surge Queue Timing

**Files:**
- Modify: `godot/scripts/model/machine/machine_simulator.gd`
- Modify: `godot/scripts/run/battle_one_vertical.gd`
- Modify: `godot/scripts/ui/queue_bridge_view.gd`
- Modify: `godot/scripts/ui/machine_strip_view.gd`
- Test: `godot/tools/verify_ball_machine_design_alignment.gd`
- Test: `godot/tools/verify_modifier_semantics.gd`

- [ ] **Step 4.1: Add queue scheduling fields**

When finalizing queue entries, set:

```gdscript
var deploy_delay: float = 0.25 if source_tags.has("Surge") else 0.5
entry["generated_elapsed"] = generated_time
entry["deploy_delay"] = deploy_delay
entry["ready_elapsed"] = generated_time + deploy_delay
```

`Surge Buffer` may still attach `deploy_delay = 0.25` to the next same-slot entry, but base `Surge` must already do this when it directly creates a queue entry.

- [ ] **Step 4.2: Replace fixed deploy timer pop with readiness check**

Add to `MachineSimulator`:

```gdscript
func queue_head_ready(battle_elapsed: float) -> bool:
	if queue.is_empty():
		return false
	return battle_elapsed >= float(queue[0].get("ready_elapsed", battle_elapsed))
```

In `BattleOneVertical._deploy_queue_head()`:

```gdscript
if not machine.has_queue_entry() or not machine.queue_head_ready(elapsed):
	machine.record_empty_deploy_gap(DEPLOY_TICK_SECONDS, elapsed, exposure_state)
	return
```

Keep `DEPLOY_TICK_SECONDS = 0.5` as the polling/cap interval, but Queue head readiness must come from entry delay.

- [ ] **Step 4.3: Make bridge preview show delay**

In `QueueBridgeView._queue_preview_text()`, include readiness:

```gdscript
var delay: float = float(entry.get("deploy_delay", 0.5))
parts.append("%s x%d / %.2fs" % [_unit_name(String(entry.get("unit_id", ""))), int(entry.get("count", 1)), delay])
```

- [ ] **Step 4.4: Verify**

Add verifier case:

```gdscript
var machine := MachineSimulator.new()
machine.apply_physics_result(MachinePhysicsResult.make("Tuning", "Surge", 0, 1, "clean", "physics", "surge_chain", 30.0))
machine.apply_physics_result(MachinePhysicsResult.make("Unit", "UnitHit", 1, 0, "clean", "physics", "surge_chain", 30.0))
var entry: Dictionary = machine.queue[0]
if absf(float(entry.get("deploy_delay", 0.0)) - 0.25) > 0.01:
	failures.append("Base Surge queue entry must use deploy_delay=0.25.")
```

Run:

```bash
GODOT_BIN="${GODOT_BIN:-godot}" "$GODOT_BIN" --headless --path godot --script res://tools/verify_ball_machine_design_alignment.gd
```

Expected: PASS for base Surge timing and existing Surge Buffer semantics.

## Task 5: Make Slot Primer Choose A Unit Slot

**Files:**
- Modify: `godot/scripts/ui/run/reward_choice_view.gd`
- Modify: `godot/scripts/model/run/run_session_model.gd`
- Modify: `godot/scripts/run/mvp_run_session.gd`
- Modify: `godot/scripts/run/battle_one_vertical.gd`
- Modify: `godot/scripts/ui/run/final_result_view.gd`
- Test: `godot/tools/verify_ball_machine_design_alignment.gd`
- Test: `godot/tools/verify_m2_run_flow.gd`
- Test: `godot/tools/verify_endpoint_result_fields.gd`

- [ ] **Step 5.1: Store reward payload in run session**

Add:

```gdscript
var reward_one_payload: Dictionary = {}

func choose_reward_one_with_payload(reward_id: String, payload: Dictionary) -> void:
	if current_node_id != NODE_REWARD_1:
		push_error("Reward 1 can only be chosen at Reward 1.")
		return
	reward_one_id = reward_id
	reward_one_payload = payload.duplicate(true)
	current_node_id = NODE_BATTLE_2
```

Keep `choose_reward_one(reward_id)` as compatibility wrapper:

```gdscript
func choose_reward_one(reward_id: String) -> void:
	var payload: Dictionary = {"slot_id": 1} if reward_id == "slot_primer" else {}
	choose_reward_one_with_payload(reward_id, payload)
```

- [ ] **Step 5.2: Add Slot Primer target selection UI**

In `RewardChoiceView`, when rendering `slot_primer`, show four compact buttons:

```gdscript
for slot_id: int in range(1, 5):
	var slot_button := Button.new()
	slot_button.text = "S%d" % slot_id
	slot_button.pressed.connect(func() -> void:
		reward_selected_with_payload.emit("slot_primer", {"slot_id": slot_id})
	)
```

Use labels `S1 / S2 / S3 / S4` because these are formal Unit slot labels; explanatory UI around them stays Chinese.

- [ ] **Step 5.3: Pass payload into battles**

In `_battle_modifier_payload()`:

```gdscript
var payload: Dictionary = {}
if session.reward_one_id == "slot_primer":
	payload["slot_primer"] = {
		"slot_id": clampi(int(session.reward_one_payload.get("slot_id", 1)), 1, 4),
	}
```

Remove the unconditional `slot_id = 1` default except in compatibility wrapper/verifier path.

- [ ] **Step 5.4: Record chosen slot in results**

Final result record must include:

```gdscript
result_record["reward1.payload"] = reward_one_payload.duplicate(true)
result_record["slot_primer.selected_slot"] = int(reward_one_payload.get("slot_id", 0))
```

`FinalResultView` should render: `"Slot Primer：S%d 作为 Unit 锚点槽"` when selected.

- [ ] **Step 5.5: Verify**

Verifier case:

```gdscript
run.call("choose_reward_one_with_payload", "slot_primer", {"slot_id": 3})
var payload: Dictionary = run.call("_battle_modifier_payload")
if int((payload.get("slot_primer", {}) as Dictionary).get("slot_id", 0)) != 3:
	failures.append("Slot Primer must preserve selected slot_id instead of forcing S1.")
```

Run:

```bash
GODOT_BIN="${GODOT_BIN:-godot}" "$GODOT_BIN" --headless --path godot --script res://tools/verify_ball_machine_design_alignment.gd
GODOT_BIN="${GODOT_BIN:-godot}" "$GODOT_BIN" --headless --path godot --script res://tools/verify_m2_run_flow.gd
```

Expected: PASS, with old verifier wrapper still choosing S1 only when no explicit slot is supplied.

## Task 6: Full Verification, Docs Progress, And Regression Sweep

**Files:**
- Modify: `godot/tools/verify_machine_physics_contract.gd`
- Modify: `godot/tools/verify_physics_machine_integration.gd`
- Modify: `godot/tools/verify_modifier_semantics.gd`
- Modify: `docs/PROGRESS.md`

- [ ] **Step 6.1: Strengthen existing machine verifiers**

Update `verify_machine_physics_contract.gd` to reject structural-only proof:

```gdscript
var contract: Dictionary = board.call("get_runtime_contract")
if bool(contract.get("runtime_uses_preselected_target_labels", true)):
	failures.append("Machine physics contract cannot pass while runtime uses preselected target labels.")
if not (contract.get("bin_width_ratios", {}) is Dictionary):
	failures.append("Machine physics contract must expose physical bin width ratios.")
```

- [ ] **Step 6.2: Strengthen integration verifier**

Update `verify_physics_machine_integration.gd` so a queue-producing chain must include:

```gdscript
_chain_has_result(chain, "Launch")
_chain_has_result(chain, "Tuning")
_chain_has_result(chain, "Unit")
_chain_has_payload_keys(chain, ["kind", "value", "tags", "tuning_mark", "source_pass"])
```

If a chain is forced, require `feedback_state == "Forced Redirect"` and non-empty `forced_by`.

- [ ] **Step 6.3: Update progress log**

Append to `docs/PROGRESS.md`:

```markdown
## 2026-06-16 - Ball Machine Design Alignment Repair

- Repaired active `godot/` ball machine mismatches against `docs/machine-warehouses.md`, `docs/ball-machine-physical.md`, `docs/DESIGN.md`, and `docs/rewards-economy.md`.
- Runtime normal landings now come from visible physics bin contact; deterministic result patterns remain verifier-only.
- Launch / Tuning physical bin widths now express first-pass distribution targets; exact peg / activity-block tuning remains an open playtest parameter.
- Forced single-ball redirects now carry visible guide-rail feedback and result metadata.
- Ball Payload and Machine Contract records now include the documented MVP v0 fields.
- Base Surge queue entries now use `0.25s` deploy delay; normal entries use `0.5s`.
- Slot Primer now records the selected Unit slot instead of silently forcing S1.
- Verification: `bash tools/verify_godot.sh`.
```

- [ ] **Step 6.4: Run full verification**

Run:

```bash
bash tools/verify_godot.sh
```

Expected:

```text
verify_ball_machine_design_alignment: PASS
verify_godot: PASS
```

- [ ] **Step 6.5: Review current worktree before final report**

Run:

```bash
git status --short
git diff --stat
```

Expected: only planned files changed, plus any pre-existing user changes preserved. Do not revert unrelated user edits.

## Execution Notes

- Use `godot-prompter:physics-system` during Task 1 and Task 2 implementation.
- Use `godot-prompter:gdscript-patterns` before adding new GDScript helper classes.
- Use `superpowers:executing-plans` or `superpowers:subagent-driven-development` only after the user explicitly confirms execution.
- Before claiming completion, run `bash tools/verify_godot.sh` and report any residual design gaps separately from test status.

## Self-Review

- Spec coverage: all seven mismatches from the 2026-06-16 audit are covered by Tasks 1-5, with verifier hardening in Tasks 0 and 6.
- Placeholder scan: no task uses TBD / later / vague "add tests" language; each task names files, behavior, and verification commands.
- Type consistency: new payload and contract helpers are referenced by exact class names; `deploy_delay`, `ready_elapsed`, `natural_result_id`, `forced_by`, and `feedback_state` are introduced before verifier assertions use them.
