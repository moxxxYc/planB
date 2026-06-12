# PlanB MVP v0 Full Gap Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Bring the active Godot MVP v0 implementation back into alignment with the original reset handoff M0-M4 and the current formal design docs, without inventing M5/M6 scope.

**Architecture:** Keep the active `godot/` project and current run shell, but rebaseline the milestone meaning: the current narrow M4 becomes an intermediate implementation slice, and the completed target is the original handoff through `Battle 5 -> Endpoint Prep -> Endpoint -> Final Result`. Replace the current button/count battlefield with a deterministic, data-driven three-lane entity battlefield that can be verified headlessly and rendered as a real battlefield view. Add a minimal real Godot 2D physics ball driver for machine landing events while preserving a deterministic verifier mode for repeatable tests.

**Tech Stack:** Godot 4.6, GDScript, Compatibility / `gl_compatibility`, Control UI plus embedded Node2D physics board, headless Godot verifiers via `bash tools/verify_godot.sh`.

---

## Authority And Scope

This plan implements the original handoff:

`Main Menu -> Guardian Contract -> Battle 1 -> Reward 1 -> Battle 2 -> Shop / Rest -> Battle 3 -> Rest -> Battle 4 -> Reward 2 -> Battle 5 -> Endpoint Prep -> Endpoint -> Final Result`

No M5/M6 is created. If a file currently says Battle 5 / Endpoint are future M5 scope, that file must be corrected.

The implementation must satisfy these design requirements:

- `docs/gstack-artifacts/planb-mvp-v0-reset-handoff-20260611.zh.md`: M0-M4 full target.
- `docs/mvp-scope.md`: full single-run loop, three-lane auto battle, endpoint validation, final explanation cannot be faked.
- `docs/battlefield-rules.md`: lane gates, base circles, units moving/fighting, Player Guardian and Endpoint Guardian HP win/loss.
- `docs/enemy-rules.md`: Battle 5 stronger pressure and Endpoint pressure profile.
- `docs/deploy-lane-ui.md`: direct battlefield lane click, selected lane highlight, no primary three-button panel.
- `docs/mvp-learning-checkpoints.md`: result fields through endpoint and next-run watch tag.
- `docs/rewards-economy.md`: Gold faucet, Reward 2, Endpoint Prep rest window, no second shop.
- `docs/DESIGN.md`: 38 / 14 / 48 battle layout, no debug or implementation-state text in player-facing screens.
- `AGENTS.md`: player-facing in-game text is Chinese unless user explicitly asks otherwise.

## Current Gap Baseline

Current implementation has:

- Active Godot project and verifier entry.
- Main Menu, Guardian Contract, Battle 1-4 route, Reward 1, First Shop / Rest, Battle 3 counter families, Reward 2 candidate choice.
- Current verifier scripts for M0-M4 narrow slices.

Current implementation does not yet have:

- `Battle 5`.
- `Endpoint Prep`.
- `Endpoint`.
- `Final Result`.
- Entity lane combat with unit HP, movement, attack, gates, base circles, Guardian HP, and endpoint win/loss.
- Reward 2 applied to later battles.
- Endpoint result fields and next-run watch tag.
- Minimal real Godot 2D physics landing driver for machine balls.
- Verifier coverage for the full handoff target.
- Clean docs wording that says M0-M4 full handoff is the target and Battle 5 / Endpoint are not M5/M6.

## File Structure

### Create

- `godot/scripts/data/battle_unit_definition.gd`  
  Typed Resource for Hive units and enemy templates: id, display name, side, hp, damage, interval, range, speed, lane role, result tag.

- `godot/scripts/data/battle_wave_definition.gd`  
  Typed Resource-like class for battle wave scripts: battle number, endpoint flag, enemy spawns, counter intensity, sweep enabled.

- `godot/scripts/model/battle/battle_entity_state.gd`  
  Mutable per-entity state: id, unit definition, lane, side, hp, position, attack cooldown, alive flag, entered_from.

- `godot/scripts/model/battle/battlefield_state.gd`  
  Deterministic battle simulation: three lanes, gates, base circles, player guardian HP, endpoint guardian HP, units, enemies, endpoint sweep warning/damage, result telemetry.

- `godot/scripts/model/battle/battlefield_telemetry.gd`  
  Collects deploy-lane impact, key queue entries by slot, visible contribution slots, guardian HP pressure, endpoint cause tags.

- `godot/scripts/model/machine/machine_physics_result.gd`  
  Small typed result object emitted by the physics board into `MachineSimulator`.

- `godot/scripts/ui/machine_physics_board_view.gd`  
  Minimal embedded 2D physics board: balls, pegs, bins, active landing event visualization. Verifier can run in deterministic landing mode.

- `godot/scripts/ui/run/endpoint_prep_view.gd`  
  Endpoint prep rest-only screen: no shop, up to 2 rests, enter Endpoint.

- `godot/scripts/ui/run/final_result_view.gd`  
  Run-level result page using machine axis, rewards/shop/rest, counters, deploy lane impact, Guardian HP pressure, endpoint outcome and next-run watch tag.

- `godot/tools/verify_full_handoff_flow.gd`  
  Headless full run verification: reaches Battle 5, Endpoint Prep, Endpoint, Final Result.

- `godot/tools/verify_entity_battlefield.gd`  
  Headless entity battlefield verification: units spawn from selected lane, move, fight, break gate, damage Guardian, win/loss by Guardian HP.

- `godot/tools/verify_endpoint_result_fields.gd`  
  Headless final result verification: required endpoint and learning checkpoint fields exist and are player-visible in Chinese.

- `godot/tools/verify_machine_physics_contract.gd`  
  Headless machine contract verification: physics result path exists, deterministic verifier mode produces ball landing events through Launch / Tuning / Unit.

### Modify

- `README.md`  
  Correct project state: active target is original handoff M0-M4 full MVP, not narrow M4 plus future M5.

- `AGENTS.md`  
  Correct implementation boundary: current active scope is full confirmed handoff M0-M4 gap repair after user confirmation.

- `docs/PROGRESS.md`  
  Record the gap rebaseline and remove “next M5” wording for Battle 5 / Endpoint.

- `tools/verify_godot.sh`  
  Add all new verifiers to the required validation chain.

- `godot/project.godot`  
  Remove player-facing `DEBUG` window title if present. Keep MCP runtime port config unchanged unless a verifier finds a conflict.

- `godot/scenes/run/battle_one_vertical.tscn`  
  Replace button-card battlefield slot with real battlefield view while keeping 38 / 14 / 48 layout.

- `godot/scripts/model/run/run_session_model.gd`  
  Add nodes and routing for Battle 5, Endpoint Prep, Endpoint, Final Result, endpoint rest accounting, and final result fields.

- `godot/scripts/run/mvp_run_session.gd`  
  Render new nodes, apply Reward 2 to Battle 5 / Endpoint, generate final result record, remove implementation-state result text.

- `godot/scripts/run/battle_one_vertical.gd`  
  Use `BattlefieldState`, battle wave config, entity telemetry, endpoint sweep, stronger Battle 5 counters, and final endpoint outcome.

- `godot/scripts/model/machine/machine_simulator.gd`  
  Accept `MachinePhysicsResult` events, apply Reward 2 modifiers, preserve deterministic verifier stepping.

- `godot/scripts/ui/battlefield_view.gd`  
  Convert from three button cards into direct-click battlefield renderer: three curved lanes, spawn ports, gates, base circles, Guardians, units, danger, selected lane.

- `godot/scripts/ui/machine_strip_view.gd` and `godot/scripts/ui/machine_board_view.gd`  
  Show active physics ball / landing feedback without replacing machine causality text.

- `godot/scripts/ui/run/run_hud_view.gd`  
  Show Player Guardian HP, Endpoint Guardian HP during battle, highest danger lane, current Deploy Lane, next Queue entry.

- `godot/scripts/ui/run/run_result_view.gd`  
  Either remove or narrow to per-loss route; full completed run must use `FinalResultView`.

## Task 0: Baseline Hygiene And Red Tests

**Files:**
- Modify: `tools/verify_godot.sh`
- Create: `godot/tools/verify_full_handoff_flow.gd`
- Create: `godot/tools/verify_entity_battlefield.gd`
- Create: `godot/tools/verify_endpoint_result_fields.gd`
- Create: `godot/tools/verify_machine_physics_contract.gd`

- [x] **Step 0.1: Add full-target verifier stubs that fail for real missing behavior**

Create each verifier with explicit checks against the missing APIs:

```gdscript
extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	var script: Script = load("res://scripts/model/run/run_session_model.gd") as Script
	if script == null:
		failures.append("RunSessionModel script missing.")
	else:
		var session = script.new()
		for node_id: String in ["battle_5", "endpoint_prep", "endpoint", "final_result"]:
			if not _session_has_node(session, node_id):
				failures.append("Missing run node: %s" % node_id)
	_finish()

func _session_has_node(session, node_id: String) -> bool:
	return session.has_method("has_run_node") and bool(session.call("has_run_node", node_id))

func _finish() -> void:
	if failures.is_empty():
		print("verify_full_handoff_flow: PASS")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)
```

Expected before implementation: FAIL because `has_run_node()` and full nodes do not exist.

- [x] **Step 0.2: Wire new verifiers into `tools/verify_godot.sh`**

Add required runs after current M4 verifier:

```bash
run_godot_script "$PROJECT_DIR/tools/verify_entity_battlefield.gd"
run_godot_script "$PROJECT_DIR/tools/verify_full_handoff_flow.gd"
run_godot_script "$PROJECT_DIR/tools/verify_endpoint_result_fields.gd"
run_godot_script "$PROJECT_DIR/tools/verify_machine_physics_contract.gd"
```

Expected before implementation: `bash tools/verify_godot.sh` FAILS on the new red tests.

## Task 1: Rebaseline Run Flow To Original Handoff M0-M4

**Files:**
- Modify: `godot/scripts/model/run/run_session_model.gd`
- Modify: `godot/scripts/run/mvp_run_session.gd`
- Modify: `godot/scripts/ui/run/run_hud_view.gd`
- Test: `godot/tools/verify_full_handoff_flow.gd`

- [x] **Step 1.1: Add run node constants and public node query**

Add:

```gdscript
const NODE_BATTLE_5: String = "battle_5"
const NODE_ENDPOINT_PREP: String = "endpoint_prep"
const NODE_ENDPOINT: String = "endpoint"
const NODE_FINAL_RESULT: String = "final_result"

func has_run_node(node_id: String) -> bool:
	return [
		NODE_GUARDIAN_CONTRACT,
		NODE_BATTLE_1,
		NODE_REWARD_1,
		NODE_BATTLE_2,
		NODE_SHOP_1,
		NODE_BATTLE_3,
		NODE_REST_AFTER_BATTLE_3,
		NODE_BATTLE_4,
		NODE_REWARD_2,
		NODE_BATTLE_5,
		NODE_ENDPOINT_PREP,
		NODE_ENDPOINT,
		NODE_FINAL_RESULT,
	].has(node_id)
```

- [x] **Step 1.2: Route battle wins and losses**

Required routing:

```text
battle_1 Win -> reward_1, Loss -> final_result
battle_2 Win -> shop_1, Loss -> final_result
battle_3 Win -> rest_after_battle_3, Loss -> final_result
battle_4 Win -> reward_2, Loss -> final_result
reward_2 choice -> battle_5
battle_5 Win -> endpoint_prep, Loss -> final_result
endpoint_prep confirm -> endpoint
endpoint Win/Loss -> final_result
```

Gold faucet:

```text
battle_1 +6
battle_2 +6
battle_3 +8
battle_4 +0
battle_5 +0
endpoint +0
```

- [x] **Step 1.3: Add Endpoint Prep rest accounting**

Add:

```gdscript
var endpoint_prep_rest_count: int = 0

func get_endpoint_prep_rest_limit_remaining() -> int:
	if current_node_id != NODE_ENDPOINT_PREP:
		return 0
	return maxi(0, 2 - endpoint_prep_rest_count)
```

Endpoint Prep can buy rest only when player Guardian HP is damaged, Gold is at least 3, and rest count is below 2.

- [x] **Step 1.4: Update `MvpRunSession` node rendering**

Add rendering cases:

```gdscript
RunSessionModel.NODE_BATTLE_5:
	_show_battle(5)
RunSessionModel.NODE_ENDPOINT_PREP:
	_show_endpoint_prep()
RunSessionModel.NODE_ENDPOINT:
	_show_battle(6)
RunSessionModel.NODE_FINAL_RESULT:
	_show_final_result()
```

Battle number `6` is display-only and must render as `终点战`.

- [x] **Step 1.5: Run red-to-green verifier**

Run:

```bash
bash tools/verify_godot.sh
```

Expected after this task: `verify_full_handoff_flow.gd` reaches all nodes by verifier-forced wins; later entity battle and endpoint field verifiers may still fail.

## Task 2: Entity Battlefield Model

**Files:**
- Create: `godot/scripts/data/battle_unit_definition.gd`
- Create: `godot/scripts/data/battle_wave_definition.gd`
- Create: `godot/scripts/model/battle/battle_entity_state.gd`
- Create: `godot/scripts/model/battle/battlefield_telemetry.gd`
- Create: `godot/scripts/model/battle/battlefield_state.gd`
- Modify: `godot/scripts/model/battle/battle_lane_state.gd`
- Test: `godot/tools/verify_entity_battlefield.gd`

- [x] **Step 2.1: Add battle unit definitions**

Required templates:

```text
hive_short_fang: HP 10, damage 2, interval 1.0, range 3, speed 10
hive_shield_shell: HP 18, damage 1, interval 1.2, range 2.5, speed 7
hive_acid_sac: HP 8, damage 3, interval 1.4, range 4, speed 8
hive_crush_shell_beast: HP 28, damage 5, interval 1.6, range 3.5, speed 5
enemy_grunt: HP 10, damage 2, interval 1.0, range 3, speed 8
enemy_raider: HP 7, damage 2, interval 0.8, range 2.5, speed 13
enemy_brute: HP 24, damage 4, interval 1.5, range 3, speed 5
```

Use Chinese display names for player-facing text:

```text
短牙虫 / 盾壳虫 / 酸囊虫 / 碾壳兽 / 敌方步虫 / 敌方突袭虫 / 敌方重壳虫
```

- [x] **Step 2.2: Implement lane combat state**

`BattlefieldState` must expose:

```gdscript
func configure(battle_number: int, endpoint: bool, player_guardian_hp: int, endpoint_guardian_hp: int) -> void
func deploy_player_queue_entry(lane: String, queue_entry: Dictionary) -> void
func advance(delta: float) -> void
func get_battle_result() -> String
func get_player_guardian_hp() -> int
func get_endpoint_guardian_hp() -> int
func get_lane_snapshot(lane: String) -> Dictionary
func get_telemetry_record() -> Dictionary
```

Simulation rules:

- Player units spawn at selected lane spawn port, not Guardian.
- Enemy units spawn from enemy side.
- Same-lane opposing units attack nearest unit in range.
- Units without opposing units attack lane gate until it breaks.
- Units past a broken gate attack Guardian.
- Win when Endpoint Guardian HP reaches 0.
- Loss when Player Guardian HP reaches 0.

- [x] **Step 2.3: Keep `BattleLaneState` only as compatibility wrapper**

Existing tests that call `get_player_units()` can continue to work, but all new battle logic uses `BattlefieldState`.

- [x] **Step 2.4: Run entity verifier**

Run:

```bash
cd godot && godot --headless --path . -s tools/verify_entity_battlefield.gd
```

Expected: PASS for selected-lane spawn, movement, gate damage, Guardian damage, win and loss.

## Task 3: Real Battlefield View And Deploy Lane Interaction

**Files:**
- Modify: `godot/scripts/ui/battlefield_view.gd`
- Modify: `godot/scenes/run/battle_one_vertical.tscn`
- Modify: `godot/scripts/run/battle_one_vertical.gd`
- Test: `godot/tools/verify_entity_battlefield.gd`

- [x] **Step 3.1: Replace three button cards with direct-click battlefield renderer**

`BattlefieldView` must extend `Control`, accept `BattlefieldState`, and render:

- Three curved or straight lane paths.
- Player-side spawn ports.
- Player lane gates.
- Enemy lane gates.
- Player Guardian / Endpoint Guardian silhouettes.
- Player and enemy unit markers on lanes.
- Selected lane highlight.
- Danger 0-3 shape/motion distinction.
- Endpoint sweep warning before damage.

- [x] **Step 3.2: Implement click-to-lane hit testing**

Click regions:

```text
Top third -> Left
Middle third -> Mid
Bottom third -> Right
```

The emitted signal remains:

```gdscript
signal lane_clicked(lane: String)
```

No visible primary three-button route panel is allowed.

- [x] **Step 3.3: Preserve bridge-to-spawn-port causality**

`QueueBridgeView` text and `BattlefieldView` visuals must agree:

```text
Queue 队首 ===> 中路玩家侧出兵口
```

The selected spawn port flashes briefly when a queue entry deploys.

- [x] **Step 3.4: Verify no implementation-state text on battle screen**

Search command:

```bash
rg -n "M4 到此结束|M5|M6|DEBUG|结果路由|留给后续里程碑" godot/scripts godot/scenes
```

Expected: no player-facing occurrences.

## Task 4: Machine Physics Landing Contract

**Files:**
- Create: `godot/scripts/model/machine/machine_physics_result.gd`
- Create: `godot/scripts/ui/machine_physics_board_view.gd`
- Modify: `godot/scripts/model/machine/machine_simulator.gd`
- Modify: `godot/scripts/ui/machine_board_view.gd`
- Modify: `godot/scripts/ui/machine_strip_view.gd`
- Test: `godot/tools/verify_machine_physics_contract.gd`

- [x] **Step 4.1: Add physics result object**

Required fields:

```gdscript
class_name MachinePhysicsResult
extends RefCounted

var component: String = ""
var result_id: String = ""
var slot_id: int = 0
var value: int = 0
var ball_kind: String = "clean"
var source: String = "physics"
```

- [x] **Step 4.2: Add `MachineSimulator.apply_physics_result()`**

The method routes real landing events:

```gdscript
func apply_physics_result(result: MachinePhysicsResult) -> void:
	match result.component:
		"Launch":
			_apply_launch_result(result.result_id, result.ball_kind)
		"Tuning":
			_apply_tuning_result(result.result_id, result.slot_id, result.value)
		"Unit":
			_apply_unit_hit(result.slot_id, result.value, result.source)
```

The existing deterministic `_step_index` path remains available for headless verifier mode.

- [x] **Step 4.3: Add minimal real Godot physics board**

`MachinePhysicsBoardView` uses:

- `RigidBody2D` for active ball.
- `StaticBody2D` pegs.
- `Area2D` bins.
- `CollisionShape2D` with unscaled primitive shapes.
- Seeded launch impulse for repeatability.

Verifier mode can call a direct deterministic landing sequence, but runtime view must expose real physics bodies and landing signals.

- [x] **Step 4.4: Verify physics contract**

Run:

```bash
cd godot && godot --headless --path . -s tools/verify_machine_physics_contract.gd
```

Expected: PASS when the script can instantiate the physics board, see physics child nodes, and route a landing result into Unit queue output.

## Task 5: Battle 5 Stronger Pressure And Reward 2 Payoff

**Files:**
- Modify: `godot/scripts/run/battle_one_vertical.gd`
- Modify: `godot/scripts/run/mvp_run_session.gd`
- Modify: `godot/scripts/model/machine/machine_simulator.gd`
- Modify: `godot/scripts/model/counter/counter_state.gd`
- Test: `godot/tools/verify_full_handoff_flow.gd`

- [x] **Step 5.1: Apply second reward in later battles**

In `_apply_run_modifiers()`:

```gdscript
if battle_number >= 5 and not run_session.second_reward_id.is_empty():
	machine.apply_modifier(run_session.second_reward_id, _modifier_payload(run_session.second_reward_id))
```

`echo_latch` must be implemented as second-reward-only:

```text
Echo Latch: next Echo copy on same slot adds one extra stored copy marker and records `Tuning repeated hit`.
```

- [x] **Step 5.2: Configure Battle 5 stronger pressure**

Battle 5 must:

- Prefer the same family as Battle 3.
- Trigger 1-2 stronger counter events.
- Add a secondary lane pressure if the first counter family is not lane-based.
- Record `counter2.family`, `counter2.target_component`, `counter2.visible_effect`, `counter2.response_link`.

- [x] **Step 5.3: Verify Reward 2 payoff**

Add assertions to `verify_full_handoff_flow.gd`:

```text
second_offer.choice_id is applied to Battle 5 machine markers
Battle 5 can route to Endpoint Prep
Battle 5 gives 0 Gold
```

## Task 6: Endpoint Prep

**Files:**
- Create: `godot/scripts/ui/run/endpoint_prep_view.gd`
- Modify: `godot/scripts/model/run/run_session_model.gd`
- Modify: `godot/scripts/run/mvp_run_session.gd`
- Test: `godot/tools/verify_full_handoff_flow.gd`

- [x] **Step 6.1: Implement rest-only Endpoint Prep view**

Player-facing text must be Chinese:

```text
终点前整备
当前 Gold：%d
守护者 HP：%d / %d
休整：3 Gold，恢复 20 HP
进入终点战
```

Rules:

- No shop items.
- No new Gold.
- Max 2 rests.
- Rest only if Guardian HP is damaged.

- [x] **Step 6.2: Record rest telemetry**

Add fields:

```text
rest.windows_used
rest.total_purchases
rest.gold_spent
rest.hp_restored
rest.endpoint_relevance
```

## Task 7: Endpoint Battle

**Files:**
- Modify: `godot/scripts/model/battle/battlefield_state.gd`
- Modify: `godot/scripts/ui/battlefield_view.gd`
- Modify: `godot/scripts/run/battle_one_vertical.gd`
- Test: `godot/tools/verify_entity_battlefield.gd`
- Test: `godot/tools/verify_endpoint_result_fields.gd`

- [x] **Step 7.1: Configure endpoint battle**

Endpoint uses:

```text
Endpoint Guardian HP: 180
Player Guardian HP: carried from run session
One counter family
Telegraphed Sweep enabled
No Gold reward
```

- [x] **Step 7.2: Implement Telegraphed Sweep**

Rules:

- Warning appears before damage.
- Warning is lane-local.
- Damage is 8.
- Knockback is lane-local and does not switch lanes.
- Sweep cannot fire without a visible warning.

- [x] **Step 7.3: Carry Guardian HP back to session**

After endpoint:

```gdscript
run_session.guardian_hp = battlefield.get_player_guardian_hp()
run_session.endpoint_guardian_hp = battlefield.get_endpoint_guardian_hp()
```

Endpoint Win / Loss routes to Final Result.

## Task 8: Final Result And Learning Checkpoint Fields

**Files:**
- Create: `godot/scripts/ui/run/final_result_view.gd`
- Modify: `godot/scripts/model/run/run_session_model.gd`
- Modify: `godot/scripts/run/mvp_run_session.gd`
- Modify: `godot/scripts/ui/run/run_result_view.gd`
- Test: `godot/tools/verify_endpoint_result_fields.gd`

- [x] **Step 8.1: Build final result record**

Required fields:

```text
guardian.choice_id
guardian.outcome
guardian.hp_pressure_events
battle1.machine_chain_sample
battle1.deploy_lane_selection
unit.visible_contribution_slots
unit.key_queue_entries_by_slot
reward1.choice_id
reward1.axis
reward1.component_operation
reward1.battlefield_result
shop1.purchase_id
shop1.purchase_role
counter1.family
counter1.target_component
counter1.visible_effect
counter1.response_link
second_offer.current_axis
second_offer.candidates
second_offer.choice_id
second_offer.choice_role
counter2.family
endpoint.outcome
endpoint.primary_axis_payoff
endpoint.main_break_reason
endpoint.next_run_watch_tag
endpoint.deploy_lane_impact
endpoint.guardian_hp
session.decision_windows
```

- [x] **Step 8.2: Render Chinese final result page**

Required headings:

```text
最终结果
主要机器轴
关键选择
敌方反制
部署路线影响
守护者压力
终点战结论
下一局观察
```

Do not display implementation-state words:

```text
M4
M5
M6
DEBUG
后续里程碑
```

- [x] **Step 8.3: Verify endpoint fields**

Run:

```bash
cd godot && godot --headless --path . -s tools/verify_endpoint_result_fields.gd
```

Expected: PASS with all required fields and Chinese visible labels.

## Task 9: Documentation Rebaseline

**Files:**
- Modify: `README.md`
- Modify: `AGENTS.md`
- Modify: `docs/PROGRESS.md`

- [x] **Step 9.1: Correct milestone wording**

Required wording:

```text
当前活动目标是完成原 reset handoff 的 M0-M4 全范围。此前 Battle 4 / Reward 2 的窄版 M4 只是中间切片；Battle 5、Endpoint Prep、Endpoint 和 Final Result 属于原 handoff M3/M4 未完成部分，不另起 M5/M6。
```

- [x] **Step 9.2: Update validation command docs**

Required wording:

```text
当前验证入口：bash tools/verify_godot.sh
该验证链必须覆盖 project parse、M1 machine-to-lane、M2 run flow、M3 counters、Battle 4 / Reward 2、entity battlefield、full handoff flow、Endpoint result fields、machine physics contract。
```

- [x] **Step 9.3: Remove misleading future-scope wording**

Search:

```bash
rg -n "M5|M6|后续里程碑|Battle 5 / Endpoint 留给|M4 之外" README.md AGENTS.md docs/PROGRESS.md
```

Expected: no misleading current-state wording remains in current project docs. Historical plan files may retain old text only if clearly superseded by this plan.

## Task 10: Full Verification, Visual Review, And Commit

**Files:**
- All modified files.

- [x] **Step 10.1: Run full verifier**

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
verify_godot: PASS
```

- [x] **Step 10.2: Launch Godot runtime and inspect with MCP / computer-use when available**

Open active project:

```bash
godot --path godot
```

Runtime checks:

- Main Menu is not a debug page.
- Battle Screen uses 38 / 14 / 48 layout.
- Battlefield shows actual lanes, gates, base circles, Guardians and unit markers.
- Clicking the battlefield lane changes only future deploy lane.
- Queue deploys from selected spawn port.
- Battle 5 exists.
- Endpoint Prep exists.
- Endpoint sweep warning appears before damage.
- Final Result is reachable and player-facing text is Chinese.

- [x] **Step 10.3: Search for player-facing English/debug leftovers**

Run:

```bash
rg -n "M4 到此结束|M5|M6|DEBUG|后续里程碑|Result Routing|Endpoint Prep|Final Result" godot/scripts godot/scenes README.md AGENTS.md docs/PROGRESS.md
```

Expected:

- No player-facing implementation-state leftovers.
- English identifiers may remain in code constants and internal resource ids.
- Player-facing Endpoint Prep / Final Result labels must be Chinese.

- [x] **Step 10.4: Commit**

Run:

```bash
git status --short
git add README.md AGENTS.md docs/PROGRESS.md docs/superpowers/plans/2026-06-12-planb-mvp-v0-full-gap-repair.md tools/verify_godot.sh godot
git commit -m "feat: complete mvp v0 handoff gap repair"
```

Expected: clean commit containing implementation, verifier, and documentation rebaseline.

## Completion Gate

The work is complete only when all are true:

- `bash tools/verify_godot.sh` passes.
- A full run can reach `Final Result`.
- `Battle 5`, `Endpoint Prep`, `Endpoint`, and `Final Result` are implemented under the original handoff M0-M4 target.
- The battlefield has units, gates, base circles, Player Guardian, Endpoint Guardian, movement/combat, and HP-based win/loss.
- Reward 2 affects Battle 5 / Endpoint.
- Endpoint has visible sweep warning before damage.
- Final Result includes endpoint cause tags and next-run watch tag.
- Player-facing text is Chinese.
- No current docs claim Battle 5 / Endpoint are M5/M6.
- Worktree is clean after commit except user-owned unrelated files.

## Self-Review

- Spec coverage: every handoff MUST item that was previously missing maps to Tasks 1-9.
- Placeholder scan: no placeholder markers or deferred implementation wording.
- Type consistency: new APIs are named consistently: `BattlefieldState`, `BattleEntityState`, `BattlefieldTelemetry`, `EndpointPrepView`, `FinalResultView`, `MachinePhysicsResult`.
