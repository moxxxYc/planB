extends SceneTree

const PHYSICS_BOARD_PATH: String = "res://scripts/ui/machine_physics_board_view.gd"
const PAYLOAD_HELPER_PATH: String = "res://scripts/model/machine/machine_ball_payload.gd"

var failures: Array[String] = []

func _initialize() -> void:
	_verify_runtime_physics_has_no_preselected_target()
	_verify_weighted_bin_widths()
	_verify_bin_order_contract()
	_verify_fixed_peg_template_contract()
	_verify_moving_mechanism_contract()
	_verify_visible_schematic_widths()
	_verify_swinging_launcher_turret_contract()
	_verify_unit_gate_rebound_contract()
	_verify_stage_backflow_guard_contract()
	_verify_stage_bottom_catcher_contract()
	_verify_forced_redirect_contract()
	_verify_ball_payload_contract()
	_verify_machine_contract_fields()
	_verify_surge_queue_timing()
	_verify_echo_loop_safety()
	_verify_slot_primer_target_selection()
	_finish()

func _verify_runtime_physics_has_no_preselected_target() -> void:
	var board: Node = _new_board()
	if board == null:
		return
	var contract: Dictionary = board.call("get_runtime_contract") as Dictionary
	if bool(contract.get("runtime_uses_preselected_target_labels", true)):
		failures.append("Runtime physics must not preselect target labels; normal bins must determine landings.")
	if not bool(contract.get("verifier_seed_path_available", false)):
		failures.append("Machine physics board must keep an explicit verifier-only seeded path.")
	_dispose_node(board)

func _verify_weighted_bin_widths() -> void:
	var board: Node = _new_board()
	if board == null:
		return
	var contract: Dictionary = board.call("get_runtime_contract") as Dictionary
	var ratios_variant: Variant = contract.get("bin_width_ratios", {})
	if not (ratios_variant is Dictionary):
		failures.append("Machine physics runtime contract must expose bin_width_ratios.")
		_dispose_node(board)
		return
	var ratios: Dictionary = ratios_variant as Dictionary
	var launch_widths: Dictionary = _expect_dictionary(ratios.get("Launch", {}), "Launch bin_width_ratios")
	_expect_ratio(launch_widths, "Tuning", 0.65, 0.05)
	_expect_ratio(launch_widths, "Split", 0.15, 0.04)
	_expect_ratio(launch_widths, "Recycle", 0.15, 0.04)
	_expect_ratio(launch_widths, "Waste", 0.05, 0.03)
	var tuning_widths: Dictionary = _expect_dictionary(ratios.get("Tuning", {}), "Tuning bin_width_ratios")
	_expect_ratio(tuning_widths, "Gate", 0.55, 0.05)
	_expect_ratio(tuning_widths, "Prime", 0.15, 0.04)
	_expect_ratio(tuning_widths, "Echo", 0.15, 0.04)
	_expect_ratio(tuning_widths, "Surge", 0.15, 0.04)
	_dispose_node(board)

func _verify_bin_order_contract() -> void:
	var board: Node = _new_board()
	if board == null:
		return
	var contract: Dictionary = board.call("get_runtime_contract") as Dictionary
	var orders: Dictionary = _expect_dictionary(contract.get("bin_orders", {}), "bin_orders")
	_expect_string_array(orders.get("Launch", []), ["Split", "Tuning", "Recycle", "Waste"], "Launch bin order")
	_expect_string_array(orders.get("Tuning", []), ["Prime", "Gate", "Echo", "Surge"], "Tuning bin order")
	_expect_string_array(orders.get("Unit", []), ["S1", "S2", "S3", "S4"], "Unit bin order")
	_dispose_node(board)

func _verify_fixed_peg_template_contract() -> void:
	var board: Node = _new_board()
	if board == null:
		return
	var contract: Dictionary = board.call("get_runtime_contract") as Dictionary
	var peg_counts: Dictionary = _expect_dictionary(contract.get("peg_counts", {}), "peg_counts")
	var peg_grid: Dictionary = _expect_dictionary(contract.get("peg_grid", {}), "peg_grid")
	var expected_counts: Dictionary = {"Launch": 30, "Tuning": 30, "Unit": 20}
	var expected_rows: Dictionary = {"Launch": 5, "Tuning": 5, "Unit": 4}
	for stage: String in ["Launch", "Tuning", "Unit"]:
		var count: int = int(peg_counts.get(stage, 0))
		var expected_count: int = int(expected_counts.get(stage, 0))
		if count != expected_count:
			failures.append("%s peg layout must use the denser fixed readable template; expected %d pegs, got %d." % [stage, expected_count, count])
		var stage_grid: Dictionary = _expect_dictionary(peg_grid.get(stage, {}), "%s peg_grid" % stage)
		if String(stage_grid.get("layout_type", "")) != "fixed_template":
			failures.append("%s peg layout must be fixed_template, not size-derived rows/columns." % stage)
		if int(stage_grid.get("actual_count", 0)) != int(stage_grid.get("expected_count", -1)):
			failures.append("%s peg layout actual_count must match expected_count." % stage)
		if int(stage_grid.get("row_count", 0)) < int(expected_rows.get(stage, 0)):
			failures.append("%s peg layout must use at least %d staggered rows." % [stage, int(expected_rows.get(stage, 0))])
		if stage == "Unit" and float(stage_grid.get("max_y_ratio", 1.0)) > 0.52:
			failures.append("Unit peg layout must leave the lower slot/gate landing area clear.")
	_dispose_node(board)

func _verify_moving_mechanism_contract() -> void:
	var board: Node = _new_board()
	if board == null:
		return
	var contract: Dictionary = board.call("get_runtime_contract") as Dictionary
	if not bool(contract.get("has_moving_mechanism_nodes", false)):
		failures.append("Machine physics board must include AnimatableBody2D moving mechanisms.")
	var counts: Dictionary = _expect_dictionary(contract.get("moving_mechanism_counts", {}), "moving_mechanism_counts")
	if int(counts.get("Launch", 0)) != 1:
		failures.append("Launch must use exactly one moving peg row.")
	if int(counts.get("Tuning", 0)) != 1:
		failures.append("Tuning must use exactly one moving peg band.")
	if int(counts.get("Unit", 0)) != 0:
		failures.append("Unit must not add moving peg randomizers yet.")
	var mechanisms: Dictionary = _expect_dictionary(contract.get("moving_mechanisms", {}), "moving_mechanisms")
	for retired_name: String in ["LaunchDiverterPaddle", "LaunchReturnFlap", "TuningQualityCam"]:
		if mechanisms.has(retired_name):
			failures.append("%s retired moving plate must not be part of the default ball machine." % retired_name)
	_expect_moving_peg_group(mechanisms, "LaunchMovingPegRow", "Launch", "launch_moving_peg_row", "moving_peg_row", 15, 1)
	_expect_moving_peg_group(mechanisms, "TuningMovingPegBand", "Tuning", "tuning_moving_peg_band", "moving_peg_band", 26, 2)
	var materials: Dictionary = _expect_dictionary(contract.get("physics_materials", {}), "physics_materials")
	_expect_material_bounce(_expect_dictionary(materials.get("moving_mechanism", {}), "moving mechanism material"), "moving_mechanism", 0.6)
	_dispose_node(board)

func _verify_visible_schematic_widths() -> void:
	var board_script: Script = load("res://scripts/ui/machine_board_view.gd") as Script
	if board_script == null:
		failures.append("MachineBoardView script should load for visible slot width verification.")
		return
	var board: Control = board_script.new() as Control
	if board == null:
		failures.append("MachineBoardView should instantiate for visible slot width verification.")
		return
	board.size = Vector2(760.0, 640.0)
	root.add_child(board)
	var contract: Dictionary = board.call("get_visual_contract_summary") as Dictionary
	if bool(contract.get("has_schematic_active_ball_overlay", true)):
		failures.append("MachineBoardView must not draw the legacy schematic active-ball overlay on top of the physics board.")
	if bool(contract.get("has_schematic_peg_overlay", true)):
		failures.append("MachineBoardView must not draw the legacy sparse schematic peg overlay on top of the physics board.")
	_expect_stage_clip_contract(contract, "MachineBoardView")
	_expect_moving_mechanism_overlay_contract(contract, "MachineBoardView")
	var ratios: Dictionary = _expect_dictionary(contract.get("schematic_slot_width_ratios", {}), "schematic_slot_width_ratios")
	var orders: Dictionary = _expect_dictionary(contract.get("schematic_slot_orders", {}), "schematic_slot_orders")
	var subtitles: Dictionary = _expect_dictionary(contract.get("board_subtitles", {}), "board_subtitles")
	_expect_string_array(orders.get("Launch", []), ["Split", "Tuning", "Recycle", "Waste"], "Launch visible slot order")
	_expect_string_array(orders.get("Tuning", []), ["Prime", "Gate", "Echo", "Surge"], "Tuning visible slot order")
	_expect_string_value(subtitles.get("Launch", ""), "Split / Tuning / Recycle / Waste", "Launch board subtitle")
	_expect_string_value(subtitles.get("Tuning", ""), "Prime / Gate / Echo / Surge", "Tuning board subtitle")
	var launch_widths: Dictionary = _expect_dictionary(ratios.get("Launch", {}), "Launch schematic_slot_width_ratios")
	_expect_ratio(launch_widths, "Tuning", 0.65, 0.01)
	_expect_ratio(launch_widths, "Split", 0.15, 0.01)
	_expect_ratio(launch_widths, "Recycle", 0.15, 0.01)
	_expect_ratio(launch_widths, "Waste", 0.05, 0.01)
	var tuning_widths: Dictionary = _expect_dictionary(ratios.get("Tuning", {}), "Tuning schematic_slot_width_ratios")
	_expect_ratio(tuning_widths, "Gate", 0.55, 0.01)
	_expect_ratio(tuning_widths, "Prime", 0.15, 0.01)
	_expect_ratio(tuning_widths, "Echo", 0.15, 0.01)
	_expect_ratio(tuning_widths, "Surge", 0.15, 0.01)
	_dispose_node(board)

func _verify_swinging_launcher_turret_contract() -> void:
	var board: Node = _new_board()
	if board == null:
		return
	board.call("set_battle_elapsed", 0.8)
	var contract_before: Dictionary = board.call("get_runtime_contract") as Dictionary
	var turret_before: Dictionary = _expect_dictionary(contract_before.get("launcher_turret", {}), "launcher_turret")
	_expect_launcher_turret_contract(turret_before, "MachinePhysicsBoardView launcher_turret")
	if String(contract_before.get("active_ball_chain_id", "")) == "preview" and not bool(contract_before.get("active_ball_at_visible_muzzle", false)):
		failures.append("MachinePhysicsBoardView preview ball must sit on the visible launcher muzzle before launch.")
	board.call("launch_ball", {"kind": "clean", "value": 1, "tags": [], "source_pass": "turret_contract"}, 0.8)
	var contract_after: Dictionary = board.call("get_runtime_contract") as Dictionary
	var turret_after: Dictionary = _expect_dictionary(contract_after.get("launcher_turret", {}), "launcher_turret after launch")
	var muzzle_variant: Variant = turret_after.get("muzzle_position", Vector2.INF)
	var visual_muzzle_variant: Variant = turret_after.get("visual_muzzle_position", Vector2.INF)
	var origin_variant: Variant = turret_after.get("last_launch_origin", Vector2.ZERO)
	if not (muzzle_variant is Vector2) or not (visual_muzzle_variant is Vector2) or not (origin_variant is Vector2):
		failures.append("Launcher turret must expose Vector2 muzzle_position, visual_muzzle_position, and last_launch_origin.")
	else:
		var muzzle_position: Vector2 = muzzle_variant as Vector2
		var visual_muzzle_position: Vector2 = visual_muzzle_variant as Vector2
		var launch_origin: Vector2 = origin_variant as Vector2
		if muzzle_position.distance_to(visual_muzzle_position) > 0.5:
			failures.append("Runtime muzzle_position must match the visible Muzzle node.")
		if launch_origin.distance_to(visual_muzzle_position) > 0.5:
			failures.append("Runtime Launch ball must originate from visible launcher muzzle. origin=%s visual=%s distance=%.3f" % [
				str(launch_origin),
				str(visual_muzzle_position),
				launch_origin.distance_to(visual_muzzle_position),
			])
	var velocity_variant: Variant = turret_after.get("last_launch_velocity", Vector2.ZERO)
	var pivot_variant: Variant = turret_after.get("pivot_position", Vector2.ZERO)
	if not (velocity_variant is Vector2) or not (visual_muzzle_variant is Vector2) or not (pivot_variant is Vector2):
		failures.append("Launcher turret must expose Vector2 pivot_position, visual_muzzle_position, and last_launch_velocity.")
	else:
		var launch_velocity: Vector2 = velocity_variant as Vector2
		var visible_direction: Vector2 = ((visual_muzzle_variant as Vector2) - (pivot_variant as Vector2)).normalized()
		if launch_velocity.length() <= 0.0:
			failures.append("Runtime Launch ball must receive muzzle velocity.")
		elif launch_velocity.normalized().dot(visible_direction) < 0.98:
			failures.append("Runtime Launch velocity must follow the visible launcher barrel direction.")
	_dispose_node(board)

	var visual_board_script: Script = load("res://scripts/ui/machine_board_view.gd") as Script
	if visual_board_script == null:
		failures.append("MachineBoardView script should load for launcher turret verification.")
		return
	var visual_board: Control = visual_board_script.new() as Control
	visual_board.size = Vector2(760.0, 640.0)
	root.add_child(visual_board)
	var visual_contract: Dictionary = visual_board.call("get_visual_contract_summary") as Dictionary
	var visual_turret: Dictionary = _expect_dictionary(visual_contract.get("launcher_turret", {}), "MachineBoardView launcher_turret")
	_expect_launcher_turret_contract(visual_turret, "MachineBoardView launcher_turret")
	if String(visual_contract.get("launcher_turret_visual_source", "")) != "MachinePhysicsBoardView":
		failures.append("MachineBoardView must use MachinePhysicsBoardView as the single visible launcher turret source.")
	if int(visual_contract.get("launcher_turret_visual_source_count", 0)) != 1:
		failures.append("MachineBoardView must expose exactly one visible launcher turret source.")
	_dispose_node(visual_board)

func _verify_unit_gate_rebound_contract() -> void:
	var board: Node = _new_board()
	if board == null:
		return
	var contract: Dictionary = board.call("get_runtime_contract") as Dictionary
	var materials: Dictionary = _expect_dictionary(contract.get("physics_materials", {}), "physics_materials")
	_expect_material_bounce(_expect_dictionary(materials.get("ball", {}), "ball physics material"), "ball", 0.5)
	_expect_material_bounce(_expect_dictionary(materials.get("peg", {}), "peg physics material"), "peg", 0.5)
	_expect_material_bounce(_expect_dictionary(materials.get("unit_gate", {}), "unit_gate physics material"), "unit_gate", 0.75)
	if not board.has_method("simulate_unit_gate_contact_rebound_for_verifier"):
		failures.append("MachinePhysicsBoardView must expose verifier-only Unit gate contact rebound simulation.")
		_dispose_node(board)
		return
	var rebound: Dictionary = board.call("simulate_unit_gate_contact_rebound_for_verifier", 2) as Dictionary
	var velocity_variant: Variant = rebound.get("linear_velocity", Vector2.ZERO)
	if not (velocity_variant is Vector2):
		failures.append("Unit gate rebound simulation must return linear_velocity.")
	else:
		var velocity: Vector2 = velocity_variant as Vector2
		if velocity.length() < 180.0:
			failures.append("Unit gate contact must rebound with visible speed, got %.2f." % velocity.length())
		if velocity.y >= -20.0:
			failures.append("Unit gate contact must kick the ball upward instead of letting it settle.")
	if int(rebound.get("rebound_count", 0)) <= 0:
		failures.append("Unit gate contact rebound simulation must increment rebound_count.")
	_dispose_node(board)

func _verify_stage_backflow_guard_contract() -> void:
	var board: Node = _new_board()
	if board == null:
		return
	var contract: Dictionary = board.call("get_runtime_contract") as Dictionary
	var guards: Dictionary = _expect_dictionary(contract.get("stage_top_guards", {}), "stage_top_guards")
	for stage: String in ["Tuning", "Unit"]:
		var guard: Dictionary = _expect_dictionary(guards.get(stage, {}), "%s stage_top_guard" % stage)
		if not bool(guard.get("has_guard", false)):
			failures.append("%s must have a physical top guard; lower warehouse balls must not bounce into the upper warehouse." % stage)
		if String(guard.get("physics_role", "")) != "stage_top_backflow_guard":
			failures.append("%s top guard must be a stage_top_backflow_guard, not a decorative line." % stage)
		if not bool(guard.get("prevents_upward_stage_escape", false)):
			failures.append("%s top guard must explicitly prevent upward stage escape." % stage)
		if not bool(guard.get("full_width", false)):
			failures.append("%s top guard must span the full physical warehouse width." % stage)
	if not board.has_method("simulate_stage_backflow_guard_for_verifier"):
		failures.append("MachinePhysicsBoardView must expose verifier coverage for stage backflow guards.")
		_dispose_node(board)
		return
	for stage: String in ["Tuning", "Unit"]:
		var simulation: Dictionary = board.call("simulate_stage_backflow_guard_for_verifier", stage) as Dictionary
		if not bool(simulation.get("has_guard", false)):
			failures.append("%s backflow guard simulation must include the guard body." % stage)
		if not bool(simulation.get("would_cross_stage_top_without_guard", false)):
			failures.append("%s backflow guard simulation must cover the upward-crossing failure case." % stage)
		if not bool(simulation.get("starts_below_guard", false)):
			failures.append("%s backflow guard simulation must start below the guard, matching normal stage entry." % stage)
		var contact_limit_y: float = float(simulation.get("ball_contact_limit_y", -INF))
		var stage_top_y: float = float(simulation.get("stage_top_y", INF))
		if contact_limit_y <= stage_top_y:
			failures.append("%s backflow guard contact limit must stay below the previous warehouse boundary. contact=%.2f top=%.2f" % [
				stage,
				contact_limit_y,
				stage_top_y,
			])
		if not bool(simulation.get("guardrail_corrected", false)):
			failures.append("%s backflow guard simulation must correct an escaped ball back into its own warehouse." % stage)
	_dispose_node(board)

func _verify_stage_bottom_catcher_contract() -> void:
	var board: Node = _new_board()
	if board == null:
		return
	var contract: Dictionary = board.call("get_runtime_contract") as Dictionary
	var catchers: Dictionary = _expect_dictionary(contract.get("stage_bottom_catchers", {}), "stage_bottom_catchers")
	var stage_rects: Dictionary = _expect_dictionary(contract.get("stage_rects", {}), "stage_rects")
	for stage: String in ["Launch", "Tuning", "Unit"]:
		var catcher: Dictionary = _expect_dictionary(catchers.get(stage, {}), "%s stage_bottom_catcher" % stage)
		var stage_rect: Rect2 = _stage_info_to_rect(stage_rects.get(stage, {}), "%s stage_rect" % stage)
		if not bool(catcher.get("has_catcher", false)):
			failures.append("%s must have a full-width physical landing catcher; balls must not fall through slot gaps without resolving." % stage)
		if String(catcher.get("visual_role", "")) != "stage_bottom_catch_all":
			failures.append("%s bottom catcher must be an invisible stage_bottom_catch_all landing contract." % stage)
		if not bool(catcher.get("stage_catch_all", false)):
			failures.append("%s bottom catcher must mark stage_catch_all=true." % stage)
		if not bool(catcher.get("full_width", false)):
			failures.append("%s bottom catcher must span the full warehouse width." % stage)
		_expect_bottom_catcher_lower_band(catcher, stage_rect, stage)
	_dispose_node(board)

func _expect_bottom_catcher_lower_band(catcher: Dictionary, stage_rect: Rect2, stage: String) -> void:
	if stage_rect.size.y <= 0.0:
		return
	var top_y: float = float(catcher.get("top_y", INF))
	var height: float = float(catcher.get("height", 0.0))
	var top_ratio: float = (top_y - stage_rect.position.y) / stage_rect.size.y
	var height_ratio: float = height / stage_rect.size.y
	if top_ratio < 0.62:
		failures.append("%s bottom catcher must start in the lower warehouse band, not around the middle. top_ratio=%.2f" % [stage, top_ratio])
	if height_ratio > 0.38:
		failures.append("%s bottom catcher must not cover nearly half the warehouse. height_ratio=%.2f" % [stage, height_ratio])

func _verify_forced_redirect_contract() -> void:
	var machine := MachineSimulator.new()
	var guardian := GuardianContractState.new()
	guardian.configure("hive_acid_crown_mother", 17)
	machine.set_guardian_contract(guardian)
	if not machine.has_method("redirect_tuning_result_if_needed"):
		failures.append("MachineSimulator must expose redirect_tuning_result_if_needed() before final Tuning apply.")
		return
	var redirect: Dictionary = {}
	for _index: int in range(6):
		redirect = machine.call("redirect_tuning_result_if_needed", "Gate") as Dictionary
	if String(redirect.get("final_result_id", "")) != "Prime":
		failures.append("Sixth Acid Crown Gate redirect must finalize as Prime.")
	if String(redirect.get("forced_by", "")).strip_edges().is_empty():
		failures.append("Forced redirect must record a non-empty forced_by source.")
	if String(redirect.get("feedback_state", "")) != "Forced Redirect":
		failures.append("Forced redirect must expose feedback_state=Forced Redirect.")

	var result := MachinePhysicsResult.make("Tuning", "Prime", 0, 1, "clean", "physics", "redirect_contract")
	result.natural_result_id = "Gate"
	result.forced_by = String(redirect.get("forced_by", ""))
	result.feedback_state = String(redirect.get("feedback_state", ""))
	var result_dict: Dictionary = result.to_dictionary()
	for key: String in ["natural_result_id", "forced_by", "feedback_state"]:
		if String(result_dict.get(key, "")).strip_edges().is_empty():
			failures.append("MachinePhysicsResult redirect metadata missing %s." % key)

func _verify_ball_payload_contract() -> void:
	if not ResourceLoader.exists(PAYLOAD_HELPER_PATH):
		failures.append("Missing MachineBallPayload helper at %s." % PAYLOAD_HELPER_PATH)
		return
	var payload_script: Script = load(PAYLOAD_HELPER_PATH) as Script
	if payload_script == null:
		failures.append("MachineBallPayload script failed to load.")
		return
	var clean_payload: Dictionary = payload_script.call("clean", "payload_contract", 0) as Dictionary
	_expect_payload_keys(clean_payload, "MachineBallPayload.clean")
	var junk_payload: Dictionary = payload_script.call("junk", "payload_contract", "Pool Polluter") as Dictionary
	_expect_payload_keys(junk_payload, "MachineBallPayload.junk")
	if not (junk_payload.get("tags", []) is Array) or not (junk_payload.get("tags", []) as Array).has("junk"):
		failures.append("MachineBallPayload.junk must include tags=[junk].")

	var machine := MachineSimulator.new()
	machine.add_guardian_clean_pool_ball()
	if machine.pool.is_empty():
		failures.append("MachineSimulator add_guardian_clean_pool_ball should add a canonical pool payload.")
	else:
		_expect_payload_keys(machine.pool[0], "MachineSimulator clean pool payload")
	machine.apply_pool_polluter_junk()
	for ball: Dictionary in machine.pool:
		_expect_payload_keys(ball, "MachineSimulator pool payload")

func _verify_machine_contract_fields() -> void:
	var run := MvpRunSession.new()
	root.add_child(run)
	run.call("_ensure_catalogs")
	for catalog_name: String in ["reward_defs", "shop_defs", "second_reward_defs"]:
		var catalog: Dictionary = run.get(catalog_name) as Dictionary
		for modifier_id: String in catalog.keys():
			var definition: Resource = catalog[modifier_id] as Resource
			if definition != null:
				_expect_modifier_contract(definition, "%s.%s" % [catalog_name, modifier_id])
	_dispose_node(run)

	var guardian := GuardianContractState.new()
	guardian.configure("hive_acid_crown_mother", 23)
	guardian.on_tuning_result("Gate")
	var snapshot: Dictionary = guardian.telemetry_snapshot()
	_expect_contract_fields(snapshot.get("last_gate_record", {}), "Guardian Acid Crown gate contract")

	var counter_def := CounterDefinition.new()
	counter_def.id = "pool_polluter"
	counter_def.display_name = "Pool 污染者"
	counter_def.target_component = "Pool"
	counter_def.visible_effect = "Junk 插入 Pool"
	counter_def.warning_seconds = 4.0
	counter_def.active_seconds = 18.0
	_set_if_property(counter_def, "source", "Enemy.Counter")
	_set_if_property(counter_def, "warehouse", "Launch")
	_set_if_property(counter_def, "operation", "insert Junk")
	_set_if_property(counter_def, "scope", "单场反制窗口")
	_set_if_property(counter_def, "player_read", "预警后 Junk 插入 Pool")
	_set_if_property(counter_def, "failure_risk", "无预警塞满 Pool 会读成沉默删除构筑")
	_set_if_property(counter_def, "guardrail", "同一时间 Pool 内最多 2 个来自本反制的 Junk Ball")
	var counter := CounterState.new()
	counter.configure(counter_def, "废球筛")
	_expect_contract_fields(counter.to_record(), "CounterState record")

func _verify_surge_queue_timing() -> void:
	var machine := MachineSimulator.new()
	machine.apply_physics_result(MachinePhysicsResult.make("Tuning", "Surge", 0, 3, "clean", "physics", "surge_contract", 30.0))
	machine.apply_physics_result(MachinePhysicsResult.make("Unit", "UnitHit", 1, 0, "clean", "physics", "surge_contract", 30.0))
	if machine.queue.is_empty():
		failures.append("Base Surge staged chain must be able to create a queue entry for timing verification.")
		return
	var entry: Dictionary = machine.queue[0]
	if absf(float(entry.get("deploy_delay", 0.0)) - 0.25) > 0.01:
		failures.append("Base Surge queue entry must use deploy_delay=0.25.")
	if absf(float(entry.get("generated_elapsed", 0.0)) - 30.0) > 0.01:
		failures.append("Queue entry must record generated_elapsed.")
	if absf(float(entry.get("ready_elapsed", 0.0)) - 30.25) > 0.01:
		failures.append("Surge queue entry must be ready at generated_elapsed + 0.25.")
	if not machine.has_method("queue_head_ready"):
		failures.append("MachineSimulator must expose queue_head_ready(battle_elapsed).")
		return
	if bool(machine.call("queue_head_ready", 30.1)):
		failures.append("Surge queue head must not deploy before ready_elapsed.")
	if not bool(machine.call("queue_head_ready", 30.25)):
		failures.append("Surge queue head must deploy once ready_elapsed is reached.")

func _verify_echo_loop_safety() -> void:
	var direct_machine := MachineSimulator.new()
	direct_machine.slot_progress[1] = 2
	var direct_entries: Array[Dictionary] = direct_machine.apply_physics_result(
		MachinePhysicsResult.make("Tuning", "Echo", 1, 3, "clean", "verifier", "echo_loop_direct", 12.0)
	)
	if direct_entries.size() != 1 or direct_machine.queue.size() != 1:
		failures.append("Echo direct settlement must produce at most one Queue entry per physical ball.")
	if int(direct_machine.slot_progress.get(1, 0)) >= 3:
		failures.append("Echo loop safety must cap same-ball overflow below the next Queue threshold.")

	var staged_machine := MachineSimulator.new()
	staged_machine.slot_progress[1] = 2
	staged_machine.apply_physics_result(MachinePhysicsResult.make("Tuning", "Echo", 0, 3, "clean", "physics", "echo_loop_staged", 20.0))
	var staged_entries: Array[Dictionary] = staged_machine.apply_physics_result(
		MachinePhysicsResult.make("Unit", "UnitHit", 1, 0, "clean", "physics", "echo_loop_staged", 20.0)
	)
	if staged_entries.size() != 1 or staged_machine.queue.size() != 1:
		failures.append("Echo staged physics chain must produce at most one Queue entry per physical ball.")
	if int(staged_machine.slot_progress.get(1, 0)) >= 3:
		failures.append("Echo staged loop safety must leave overflow waiting for a later physical hit.")

func _verify_slot_primer_target_selection() -> void:
	var session := RunSessionModel.new()
	session.current_node_id = RunSessionModel.NODE_REWARD_1
	if not session.has_method("choose_reward_one_with_payload"):
		failures.append("RunSessionModel must expose choose_reward_one_with_payload().")
		return
	session.call("choose_reward_one_with_payload", "slot_primer", {"slot_id": 3})
	if int(session.get("reward_one_payload").get("slot_id", 0)) != 3:
		failures.append("RunSessionModel must persist Slot Primer selected slot_id.")

	var run := MvpRunSession.new()
	root.add_child(run)
	run.call("_ensure_catalogs")
	run.set("session", session)
	var payload: Dictionary = run.call("_battle_modifier_payload") as Dictionary
	var slot_primer_payload: Dictionary = _expect_dictionary(payload.get("slot_primer", {}), "battle slot_primer payload")
	if int(slot_primer_payload.get("slot_id", 0)) != 3:
		failures.append("Slot Primer must preserve selected slot_id instead of forcing S1.")
	_dispose_node(run)

	var record: Dictionary = session.build_final_result_record()
	if not (record.get("reward1.payload", {}) is Dictionary):
		failures.append("Final result record must include reward1.payload.")
	if int(record.get("slot_primer.selected_slot", 0)) != 3:
		failures.append("Final result record must include slot_primer.selected_slot.")

func _new_board() -> Node:
	var board_script: Script = load(PHYSICS_BOARD_PATH) as Script
	if board_script == null:
		failures.append("MachinePhysicsBoardView script should load.")
		return null
	var board: Node = board_script.new() as Node
	if board == null:
		failures.append("MachinePhysicsBoardView should instantiate.")
		return null
	root.add_child(board)
	return board

func _expect_ratio(ratios: Dictionary, label: String, expected: float, tolerance: float) -> void:
	if not ratios.has(label):
		failures.append("Missing physical bin width ratio for %s." % label)
		return
	var actual: float = float(ratios.get(label, -1.0))
	if absf(actual - expected) > tolerance:
		failures.append("%s width ratio expected %.2f ± %.2f, got %.3f." % [label, expected, tolerance, actual])

func _expect_material_bounce(material: Dictionary, label: String, minimum_bounce: float) -> void:
	if not bool(material.get("has_material", false)):
		failures.append("%s must have a PhysicsMaterial." % label)
	if float(material.get("bounce", 0.0)) < minimum_bounce:
		failures.append("%s PhysicsMaterial bounce must be >= %.2f, got %.2f." % [
			label,
			minimum_bounce,
			float(material.get("bounce", 0.0)),
		])
	if float(material.get("friction", 1.0)) > 0.12:
		failures.append("%s PhysicsMaterial friction must stay low enough for rolling/bouncing." % label)

func _expect_string_array(value: Variant, expected: Array[String], label: String) -> void:
	if not (value is Array):
		failures.append("%s must be an Array, got %s." % [label, type_string(typeof(value))])
		return
	var actual: Array = value as Array
	if actual.size() != expected.size():
		failures.append("%s expected %s, got %s." % [label, str(expected), str(actual)])
		return
	for index: int in range(expected.size()):
		if String(actual[index]) != expected[index]:
			failures.append("%s expected %s, got %s." % [label, str(expected), str(actual)])
			return

func _expect_string_value(value: Variant, expected: String, label: String) -> void:
	var actual := String(value)
	if actual != expected:
		failures.append("%s expected '%s', got '%s'." % [label, expected, actual])

func _expect_stage_clip_contract(contract: Dictionary, label: String) -> void:
	if not bool(contract.get("clips_physics_children", false)):
		failures.append("%s must clip physics children inside the machine stage area." % label)
	_expect_layout_rect_alignment_contract(contract, label)
	if int(contract.get("physics_clip_children_mode", -1)) != CanvasItem.CLIP_CHILDREN_AND_DRAW:
		failures.append("%s PhysicsStageClip must use clip_children=Clip + Draw so Node2D physics visuals are clipped." % label)
	if not bool(contract.get("physics_board_uses_stage_clip", false)):
		failures.append("%s physics board must be parented under PhysicsStageClip, not the whole board." % label)
	if not bool(contract.get("physics_clip_excludes_supply_strip", false)):
		failures.append("%s PhysicsStageClip must exclude the supply strip so mechanisms cannot render over Forge/Pool." % label)
	var clip_rect_variant: Variant = contract.get("physics_clip_rect", Rect2())
	if not (clip_rect_variant is Rect2):
		failures.append("%s must expose physics_clip_rect as Rect2." % label)
		return
	var clip_rect: Rect2 = clip_rect_variant as Rect2
	var supply_height: float = float(contract.get("supply_strip_height", 0.0))
	if clip_rect.position.y < supply_height:
		failures.append("%s PhysicsStageClip starts above supply strip. y=%.1f supply=%.1f" % [label, clip_rect.position.y, supply_height])
	var board_origin_variant: Variant = contract.get("physics_board_canvas_origin", Vector2.INF)
	if not (board_origin_variant is Vector2) or (board_origin_variant as Vector2).distance_to(Vector2.ZERO) > 0.5:
		failures.append("%s physics board offset must cancel clip position and preserve canvas coordinates." % label)
	var board_position_variant: Variant = contract.get("physics_board_position", Vector2.INF)
	if not (board_position_variant is Vector2) or ((board_position_variant as Vector2) + clip_rect.position).distance_to(Vector2.ZERO) > 0.5:
		failures.append("%s physics board local position must be the negative PhysicsStageClip position." % label)

func _expect_layout_rect_alignment_contract(contract: Dictionary, label: String) -> void:
	if String(contract.get("layout_metrics_source", "")) != "MachineBoardLayoutMetrics":
		failures.append("%s must use MachineBoardLayoutMetrics as layout source." % label)
	var visible_rects: Dictionary = _expect_dictionary(contract.get("visible_stage_rects", {}), "%s visible_stage_rects" % label)
	var physics_rects: Dictionary = _expect_dictionary(contract.get("stage_rects", {}), "%s stage_rects" % label)
	var merged := Rect2()
	var has_merged := false
	for stage: String in ["Launch", "Tuning", "Unit"]:
		var visible_rect: Rect2 = _stage_info_to_rect(visible_rects.get(stage, {}), "%s visible %s" % [label, stage])
		var physics_rect: Rect2 = _stage_info_to_rect(physics_rects.get(stage, {}), "%s physics %s" % [label, stage])
		if not _rects_close(visible_rect, physics_rect):
			failures.append("%s %s visible rect must match physics rect." % [label, stage])
		merged = visible_rect if not has_merged else merged.merge(visible_rect)
		has_merged = true
	var clip_variant: Variant = contract.get("physics_clip_rect", Rect2())
	if clip_variant is Rect2 and not _rects_close(clip_variant as Rect2, merged):
		failures.append("%s physics clip must match merged visible stage rects." % label)

func _stage_info_to_rect(value: Variant, label: String) -> Rect2:
	if value is Rect2:
		return value as Rect2
	if not (value is Dictionary):
		failures.append("%s must be a Dictionary or Rect2." % label)
		return Rect2()
	var info: Dictionary = value as Dictionary
	var position_variant: Variant = info.get("position", Vector2.INF)
	var size_variant: Variant = info.get("size", Vector2.ZERO)
	if not (position_variant is Vector2) or not (size_variant is Vector2):
		failures.append("%s must expose Vector2 position and size." % label)
		return Rect2()
	return Rect2(position_variant as Vector2, size_variant as Vector2)

func _rects_close(a: Rect2, b: Rect2) -> bool:
	return a.position.distance_to(b.position) <= 0.5 and a.size.distance_to(b.size) <= 0.5

func _expect_moving_mechanism_overlay_contract(contract: Dictionary, label: String) -> void:
	if not bool(contract.get("draws_moving_mechanism_overlay", false)):
		failures.append("%s must draw a top-level moving mechanism overlay." % label)
	var overlay: Dictionary = _expect_dictionary(contract.get("moving_mechanism_overlay", {}), "%s moving_mechanism_overlay" % label)
	if String(overlay.get("source", "")) != "MachineBoardView":
		failures.append("%s moving mechanism overlay must come from MachineBoardView." % label)
	if int(overlay.get("drawable_count", 0)) != 2 or not bool(overlay.get("all_required_drawable", false)):
		failures.append("%s moving mechanism overlay must draw LaunchMovingPegRow and TuningMovingPegBand." % label)

func _expect_moving_peg_group(
	mechanisms: Dictionary,
	mechanism_name: String,
	stage: String,
	motion_role: String,
	motion_kind: String,
	minimum_peg_count: int,
	expected_row_count: int
) -> void:
	var mechanism: Dictionary = _expect_dictionary(mechanisms.get(mechanism_name, {}), mechanism_name)
	if String(mechanism.get("node_type", "")) != "MovingPegGroup":
		failures.append("%s must expose node_type=MovingPegGroup." % mechanism_name)
	if String(mechanism.get("stage", "")) != stage:
		failures.append("%s must belong to %s." % [mechanism_name, stage])
	if String(mechanism.get("physics_role", "")) != "moving_landing_mechanism":
		failures.append("%s must expose physics_role=moving_landing_mechanism." % mechanism_name)
	if String(mechanism.get("motion_role", "")) != motion_role:
		failures.append("%s must expose motion_role=%s." % [mechanism_name, motion_role])
	if String(mechanism.get("motion_kind", "")) != motion_kind:
		failures.append("%s must expose motion_kind=%s." % [mechanism_name, motion_kind])
	if not bool(mechanism.get("uses_physics_time", false)):
		failures.append("%s must be driven by physics time." % mechanism_name)
	if not bool(mechanism.get("changes_landing_locally", false)):
		failures.append("%s must affect local landing variation." % mechanism_name)
	if not bool(mechanism.get("does_not_replace_bin_widths", false)):
		failures.append("%s must not replace the slot-width primary distribution." % mechanism_name)
	if float(mechanism.get("cycle_seconds", 0.0)) <= 0.0:
		failures.append("%s must expose a positive cycle_seconds." % mechanism_name)
	if float(mechanism.get("motion_range", 0.0)) <= 0.0:
		failures.append("%s must expose a positive motion_range." % mechanism_name)
	if String(mechanism.get("motion_profile", "")) != "ping_pong_uniform":
		failures.append("%s must use a uniform ping-pong motion profile." % mechanism_name)
	if float(mechanism.get("horizontal_sweep_coverage_ratio", 0.0)) < 0.98:
		failures.append("%s moving pegs must sweep across the full warehouse width." % mechanism_name)
	if float(mechanism.get("horizontal_visible_coverage_ratio", 0.0)) < 0.90:
		failures.append("%s moving pegs must be visibly distributed across the warehouse width." % mechanism_name)
	if not bool(mechanism.get("visible", false)):
		failures.append("%s must be visible in the physical stage." % mechanism_name)
	if bool(mechanism.get("has_large_plate", true)):
		failures.append("%s must not be implemented as a large moving plate." % mechanism_name)
	if not bool(mechanism.get("peg_visuals_visible", false)):
		failures.append("%s must expose visible moving peg visuals." % mechanism_name)
	if not bool(mechanism.get("has_physical_peg_bodies", false)):
		failures.append("%s must expose physical moving peg bodies." % mechanism_name)
	if not bool(mechanism.get("stage_rect_contains_center", false)):
		failures.append("%s center must stay inside its %s warehouse." % [mechanism_name, stage])
	if not bool(mechanism.get("stage_rect_intersects_bounds", false)):
		failures.append("%s visual bounds must intersect its %s warehouse." % [mechanism_name, stage])
	if not bool(mechanism.get("all_pegs_inside_stage", false)):
		failures.append("%s moving pegs must stay inside their %s warehouse." % [mechanism_name, stage])
	if int(mechanism.get("peg_count", 0)) < minimum_peg_count:
		failures.append("%s must expose at least %d moving pegs." % [mechanism_name, minimum_peg_count])
	if int(mechanism.get("row_count", 0)) != expected_row_count:
		failures.append("%s must expose row_count=%d." % [mechanism_name, expected_row_count])
	if int(mechanism.get("physical_body_count", 0)) != int(mechanism.get("peg_count", -1)):
		failures.append("%s physical_body_count must match peg_count." % mechanism_name)
	var peg_positions_variant: Variant = mechanism.get("peg_positions", [])
	if not (peg_positions_variant is Array) or (peg_positions_variant as Array).size() < minimum_peg_count:
		failures.append("%s must expose current peg_positions." % mechanism_name)
	var max_body_size_variant: Variant = mechanism.get("max_body_size", Vector2.ZERO)
	if not (max_body_size_variant is Vector2):
		failures.append("%s must expose max_body_size as Vector2." % mechanism_name)
	else:
		var max_body_size: Vector2 = max_body_size_variant as Vector2
		if max_body_size.x > 28.0 or max_body_size.y > 28.0:
			failures.append("%s moving peg bodies must stay small, got %s." % [mechanism_name, str(max_body_size)])
	var bounds_variant: Variant = mechanism.get("bounds", Rect2())
	if not (bounds_variant is Rect2):
		failures.append("%s must expose rendered bounds as Rect2." % mechanism_name)
	else:
		var bounds: Rect2 = bounds_variant as Rect2
		if bounds.size.x <= 1.0 or bounds.size.y <= 1.0:
			failures.append("%s rendered bounds must have visible area." % mechanism_name)

func _expect_payload_keys(payload: Variant, label: String) -> void:
	if not (payload is Dictionary):
		failures.append("%s must be a Dictionary payload." % label)
		return
	var dictionary: Dictionary = payload as Dictionary
	for key: String in ["kind", "value", "tags", "tuning_mark", "source_pass", "chain_id", "source"]:
		if not dictionary.has(key):
			failures.append("%s missing payload key %s." % [label, key])
	if not (dictionary.get("tags", []) is Array):
		failures.append("%s tags must be an Array." % label)

func _expect_modifier_contract(definition: Resource, label: String) -> void:
	for property_name: String in ["source", "warehouse", "target_component", "operation", "scope", "player_read", "failure_risk", "guardrail"]:
		if not _has_property(definition, property_name):
			failures.append("%s missing Machine Contract property %s." % [label, property_name])
			continue
		if String(definition.get(property_name)).strip_edges().is_empty():
			failures.append("%s Machine Contract field %s must be non-empty." % [label, property_name])

func _expect_contract_fields(record_variant: Variant, label: String) -> void:
	if not (record_variant is Dictionary):
		failures.append("%s must be a Dictionary." % label)
		return
	var record: Dictionary = record_variant as Dictionary
	for key: String in ["source", "warehouse", "target_component", "operation", "scope", "player_read", "failure_risk", "guardrail"]:
		if String(record.get(key, "")).strip_edges().is_empty():
			failures.append("%s missing Machine Contract field %s." % [label, key])

func _expect_dictionary(value: Variant, label: String) -> Dictionary:
	if not (value is Dictionary):
		failures.append("%s must be a Dictionary, got %s." % [label, type_string(typeof(value))])
		return {}
	return value as Dictionary

func _expect_launcher_turret_contract(contract: Dictionary, label: String) -> void:
	if not bool(contract.get("visible", false)):
		failures.append("%s must be visible." % label)
	if String(contract.get("stage", "")) != "Launch":
		failures.append("%s must belong to Launch stage." % label)
	if String(contract.get("visual_role", "")) != "automatic_swinging_launcher_turret":
		failures.append("%s must expose automatic_swinging_launcher_turret visual_role." % label)
	if not bool(contract.get("automatic", false)):
		failures.append("%s must be automatic." % label)
	if bool(contract.get("player_controlled", true)):
		failures.append("%s must not be player controlled." % label)
	if not bool(contract.get("swinging", false)):
		failures.append("%s must be swinging." % label)
	if float(contract.get("barrel_length", 0.0)) <= 0.0:
		failures.append("%s must expose a positive barrel_length." % label)
	if float(contract.get("swing_angle_min", 0.0)) >= 0.0 or float(contract.get("swing_angle_max", 0.0)) <= 0.0:
		failures.append("%s must expose a bidirectional swing angle range." % label)
	if absf(float(contract.get("swing_angle_min", 0.0)) + PI * 0.5) > 0.001:
		failures.append("%s swing_angle_min must be -90 degrees." % label)
	if absf(float(contract.get("swing_angle_max", 0.0)) - PI * 0.5) > 0.001:
		failures.append("%s swing_angle_max must be 90 degrees." % label)
	if not bool(contract.get("muzzle_matches_visual", false)):
		failures.append("%s muzzle_position must match the visible Muzzle node." % label)

func _has_property(object: Object, property_name: String) -> bool:
	for property_info: Dictionary in object.get_property_list():
		if String(property_info.get("name", "")) == property_name:
			return true
	return false

func _set_if_property(object: Object, property_name: String, value: Variant) -> void:
	if _has_property(object, property_name):
		object.set(property_name, value)

func _dispose_node(node: Node) -> void:
	if node == null:
		return
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	node.free()

func _finish() -> void:
	if failures.is_empty():
		print("verify_ball_machine_design_alignment: PASS")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
