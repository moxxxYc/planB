extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_verify_physics_board_contract()
	_verify_machine_visual_shape_contract()
	_verify_machine_accepts_physics_result()
	_finish()

func _verify_physics_board_contract() -> void:
	var board_script: Script = load("res://scripts/ui/machine_physics_board_view.gd") as Script
	if board_script == null:
		failures.append("MachinePhysicsBoardView script should load.")
		return
	var board: Node = board_script.new() as Node
	root.add_child(board)
	if not board.has_method("has_physics_contract_nodes") or not bool(board.call("has_physics_contract_nodes")):
		failures.append("MachinePhysicsBoardView should expose RigidBody2D ball, StaticBody2D peg, and Area2D bin.")
	var contract: Dictionary = board.call("get_runtime_contract") as Dictionary
	if bool(contract.get("runtime_uses_preselected_target_labels", true)):
		failures.append("Machine physics contract cannot pass while runtime uses preselected target labels.")
	if not (contract.get("bin_width_ratios", {}) is Dictionary):
		failures.append("Machine physics contract must expose physical bin width ratios.")
	_verify_bin_order_contract(contract)
	_verify_peg_grid_contract(contract)
	_verify_moving_mechanism_contract(contract)
	_verify_stage_backflow_guard_contract(board, contract)
	_verify_stage_bottom_catcher_contract(contract)
	_expect_launcher_turret_contract(_expect_dictionary(contract.get("launcher_turret", {}), "launcher_turret"), "MachinePhysicsBoardView launcher_turret")
	var materials: Dictionary = _expect_dictionary(contract.get("physics_materials", {}), "physics_materials")
	_expect_material_bounce(_expect_dictionary(materials.get("ball", {}), "ball physics material"), "ball", 0.5)
	_expect_material_bounce(_expect_dictionary(materials.get("unit_gate", {}), "unit_gate physics material"), "unit_gate", 0.75)
	_expect_material_bounce(_expect_dictionary(materials.get("moving_mechanism", {}), "moving mechanism material"), "moving_mechanism", 0.6)
	if String(contract.get("active_ball_chain_id", "")) == "preview" and not bool(contract.get("active_ball_at_visible_muzzle", false)):
		failures.append("MachinePhysicsBoardView preview ball must sit on the visible launcher muzzle before launch.")
	if board.has_method("simulate_unit_gate_contact_rebound_for_verifier"):
		var rebound: Dictionary = board.call("simulate_unit_gate_contact_rebound_for_verifier", 2) as Dictionary
		var rebound_velocity_variant: Variant = rebound.get("linear_velocity", Vector2.ZERO)
		if rebound_velocity_variant is Vector2:
			var rebound_velocity: Vector2 = rebound_velocity_variant as Vector2
			if rebound_velocity.length() < 180.0 or rebound_velocity.y >= -20.0:
				failures.append("Unit gate contact should visibly rebound instead of settling.")
		else:
			failures.append("Unit gate contact rebound simulation must return a Vector2 linear_velocity.")
	else:
		failures.append("MachinePhysicsBoardView must expose Unit gate contact rebound simulation.")
	board.call("launch_ball", {"kind": "clean", "value": 1, "tags": [], "source_pass": "physics_contract"}, 0.8)
	var launched_contract: Dictionary = board.call("get_runtime_contract") as Dictionary
	var launched_turret: Dictionary = _expect_dictionary(launched_contract.get("launcher_turret", {}), "launcher_turret after launch")
	if launched_turret.get("last_launch_origin", Vector2.ZERO) is Vector2 and launched_turret.get("visual_muzzle_position", Vector2.INF) is Vector2:
		var launch_origin: Vector2 = launched_turret.get("last_launch_origin", Vector2.ZERO) as Vector2
		var visual_muzzle_position: Vector2 = launched_turret.get("visual_muzzle_position", Vector2.INF) as Vector2
		if launch_origin.distance_to(visual_muzzle_position) > 0.5:
			failures.append("MachinePhysicsBoardView Launch ball should originate from visible launcher muzzle.")
	else:
		failures.append("MachinePhysicsBoardView launcher_turret should expose launch origin and visible muzzle position.")
	var result: MachinePhysicsResult = board.call("emit_deterministic_landing") as MachinePhysicsResult
	if result == null or result.component.is_empty() or result.result_id.is_empty():
		failures.append("MachinePhysicsBoardView deterministic landing should emit a typed physics result.")
	root.remove_child(board)
	board.free()

func _verify_machine_visual_shape_contract() -> void:
	var board_script: Script = load("res://scripts/ui/machine_board_view.gd") as Script
	if board_script == null:
		failures.append("MachineBoardView script should load.")
		return
	var board: Control = board_script.new() as Control
	if board == null:
		failures.append("MachineBoardView should instantiate.")
		return
	board.size = Vector2(420.0, 640.0)
	root.add_child(board)
	var contract: Dictionary = board.call("get_visual_contract_summary") as Dictionary
	_expect_stage_clip_contract(contract, "MachineBoardView")
	if not bool(contract.get("tuning_slots_distinguished_by_shape", false)):
		failures.append("MachineBoardView must distinguish Gate/Prime/Echo/Surge by shape, not just text/color.")
	var shape_tokens_variant: Variant = contract.get("tuning_slot_shape_tokens", {})
	if not (shape_tokens_variant is Dictionary):
		failures.append("MachineBoardView must expose tuning_slot_shape_tokens.")
	else:
		var shape_tokens: Dictionary = shape_tokens_variant as Dictionary
		var seen_tokens: Dictionary = {}
		for label: String in ["Gate", "Prime", "Echo", "Surge"]:
			var token: String = String(shape_tokens.get(label, ""))
			if token.strip_edges().is_empty():
				failures.append("Missing shape token for Tuning.%s." % label)
			if seen_tokens.has(token):
				failures.append("Tuning.%s shape token must be unique." % label)
			seen_tokens[token] = true
	var schematic_ratios: Dictionary = _expect_dictionary(contract.get("schematic_slot_width_ratios", {}), "schematic_slot_width_ratios")
	var schematic_orders: Dictionary = _expect_dictionary(contract.get("schematic_slot_orders", {}), "schematic_slot_orders")
	var board_subtitles: Dictionary = _expect_dictionary(contract.get("board_subtitles", {}), "board_subtitles")
	_expect_string_array(schematic_orders.get("Launch", []), ["Split", "Tuning", "Recycle", "Waste"], "Launch visible slot order")
	_expect_string_array(schematic_orders.get("Tuning", []), ["Prime", "Gate", "Echo", "Surge"], "Tuning visible slot order")
	_expect_string_value(board_subtitles.get("Launch", ""), "Split / Tuning / Recycle / Waste", "Launch board subtitle")
	_expect_string_value(board_subtitles.get("Tuning", ""), "Prime / Gate / Echo / Surge", "Tuning board subtitle")
	var launch_ratios: Dictionary = _expect_dictionary(schematic_ratios.get("Launch", {}), "Launch schematic_slot_width_ratios")
	_expect_visual_ratio(launch_ratios, "Tuning", 0.65, 0.01)
	_expect_visual_ratio(launch_ratios, "Split", 0.15, 0.01)
	_expect_visual_ratio(launch_ratios, "Recycle", 0.15, 0.01)
	_expect_visual_ratio(launch_ratios, "Waste", 0.05, 0.01)
	var tuning_ratios: Dictionary = _expect_dictionary(schematic_ratios.get("Tuning", {}), "Tuning schematic_slot_width_ratios")
	_expect_visual_ratio(tuning_ratios, "Gate", 0.55, 0.01)
	_expect_visual_ratio(tuning_ratios, "Prime", 0.15, 0.01)
	_expect_visual_ratio(tuning_ratios, "Echo", 0.15, 0.01)
	_expect_visual_ratio(tuning_ratios, "Surge", 0.15, 0.01)
	_expect_launcher_turret_contract(
		_expect_dictionary(contract.get("launcher_turret", {}), "MachineBoardView launcher_turret"),
		"MachineBoardView launcher_turret"
	)
	if String(contract.get("launcher_turret_visual_source", "")) != "MachinePhysicsBoardView":
		failures.append("MachineBoardView must use MachinePhysicsBoardView as the single visible launcher turret source.")
	if int(contract.get("launcher_turret_visual_source_count", 0)) != 1:
		failures.append("MachineBoardView must expose exactly one visible launcher turret source.")
	root.remove_child(board)
	board.free()

func _verify_machine_accepts_physics_result() -> void:
	var machine := MachineSimulator.new()
	if not machine.has_method("apply_physics_result"):
		failures.append("MachineSimulator missing apply_physics_result().")
		return
	machine.apply_physics_result(MachinePhysicsResult.make("Unit", "QueueEntry", 1, 3, "clean", "physics"))
	if not machine.has_queue_entry():
		failures.append("Machine physics Unit result should produce a queue entry.")
	var log_text := "\n".join(machine.event_log)
	if not log_text.contains("Unit:QueueEntry"):
		failures.append("Machine physics result should preserve Unit:QueueEntry causality log.")

func _verify_bin_order_contract(contract: Dictionary) -> void:
	var orders: Dictionary = _expect_dictionary(contract.get("bin_orders", {}), "bin_orders")
	_expect_string_array(orders.get("Launch", []), ["Split", "Tuning", "Recycle", "Waste"], "Launch bin order")
	_expect_string_array(orders.get("Tuning", []), ["Prime", "Gate", "Echo", "Surge"], "Tuning bin order")
	_expect_string_array(orders.get("Unit", []), ["S1", "S2", "S3", "S4"], "Unit bin order")

func _verify_peg_grid_contract(contract: Dictionary) -> void:
	var peg_counts: Dictionary = _expect_dictionary(contract.get("peg_counts", {}), "peg_counts")
	var peg_grid: Dictionary = _expect_dictionary(contract.get("peg_grid", {}), "peg_grid")
	var expected_counts: Dictionary = {"Launch": 16, "Tuning": 14, "Unit": 12}
	for stage: String in ["Launch", "Tuning", "Unit"]:
		var count: int = int(peg_counts.get(stage, 0))
		var expected_count: int = int(expected_counts.get(stage, 0))
		if count != expected_count:
			failures.append("%s peg layout must use the fixed readable template; expected %d pegs, got %d." % [stage, expected_count, count])
		var stage_grid: Dictionary = _expect_dictionary(peg_grid.get(stage, {}), "%s peg_grid" % stage)
		if String(stage_grid.get("layout_type", "")) != "fixed_template":
			failures.append("%s peg layout must be fixed_template, not size-derived rows/columns." % stage)
		if int(stage_grid.get("actual_count", 0)) != int(stage_grid.get("expected_count", -1)):
			failures.append("%s peg layout actual_count must match expected_count." % stage)
		if stage == "Unit" and float(stage_grid.get("max_y_ratio", 1.0)) > 0.52:
			failures.append("Unit peg layout must leave the lower slot/gate landing area clear.")

func _verify_moving_mechanism_contract(contract: Dictionary) -> void:
	if not bool(contract.get("has_moving_mechanism_nodes", false)):
		failures.append("Machine physics board must include AnimatableBody2D moving mechanisms.")
	var counts: Dictionary = _expect_dictionary(contract.get("moving_mechanism_counts", {}), "moving_mechanism_counts")
	if int(counts.get("Launch", 0)) < 2:
		failures.append("Launch must include a diverter and return-side moving mechanism.")
	if int(counts.get("Tuning", 0)) < 1:
		failures.append("Tuning must include a quality-conversion moving mechanism.")
	if int(counts.get("Unit", 0)) != 0:
		failures.append("Unit should use Exposure Gate as its moving structure, not extra randomizers.")
	var mechanisms: Dictionary = _expect_dictionary(contract.get("moving_mechanisms", {}), "moving_mechanisms")
	_expect_mechanism(mechanisms, "LaunchDiverterPaddle", "Launch", "launch_diverter")
	_expect_mechanism(mechanisms, "LaunchReturnFlap", "Launch", "launch_return_flap")
	_expect_mechanism(mechanisms, "TuningQualityCam", "Tuning", "tuning_quality_cam")

func _verify_stage_backflow_guard_contract(board: Node, contract: Dictionary) -> void:
	var guards: Dictionary = _expect_dictionary(contract.get("stage_top_guards", {}), "stage_top_guards")
	for stage: String in ["Tuning", "Unit"]:
		var guard: Dictionary = _expect_dictionary(guards.get(stage, {}), "%s stage_top_guard" % stage)
		if not bool(guard.get("has_guard", false)):
			failures.append("%s stage must have a physical top guard so lower balls cannot bounce into the previous warehouse." % stage)
		if String(guard.get("physics_role", "")) != "stage_top_backflow_guard":
			failures.append("%s top guard must expose physics_role=stage_top_backflow_guard." % stage)
		if not bool(guard.get("prevents_upward_stage_escape", false)):
			failures.append("%s top guard must prevent upward stage escape." % stage)
		if not bool(guard.get("full_width", false)):
			failures.append("%s top guard must span the full stage width." % stage)
		if float(guard.get("ball_contact_limit_y", -INF)) <= float(guard.get("stage_top_y", INF)):
			failures.append("%s top guard must keep the ball contact limit below the previous stage boundary." % stage)
	if not board.has_method("simulate_stage_backflow_guard_for_verifier"):
		failures.append("MachinePhysicsBoardView must expose stage backflow guard verifier simulation.")
		return
	for stage: String in ["Tuning", "Unit"]:
		var simulation: Dictionary = board.call("simulate_stage_backflow_guard_for_verifier", stage) as Dictionary
		if not bool(simulation.get("has_guard", false)):
			failures.append("%s backflow simulation must include a top guard." % stage)
		if not bool(simulation.get("would_cross_stage_top_without_guard", false)):
			failures.append("%s backflow simulation must cover an upward crossing case." % stage)
		if not bool(simulation.get("guard_is_full_width", false)):
			failures.append("%s backflow simulation must use a full-width guard." % stage)
		if not bool(simulation.get("guardrail_corrected", false)):
			failures.append("%s backflow simulation must correct an escaped ball back into its own stage." % stage)

func _verify_stage_bottom_catcher_contract(contract: Dictionary) -> void:
	var catchers: Dictionary = _expect_dictionary(contract.get("stage_bottom_catchers", {}), "stage_bottom_catchers")
	for stage: String in ["Launch", "Tuning", "Unit"]:
		var catcher: Dictionary = _expect_dictionary(catchers.get(stage, {}), "%s stage_bottom_catcher" % stage)
		if not bool(catcher.get("has_catcher", false)):
			failures.append("%s stage must have a bottom catch-all Area2D so balls cannot miss every physical bin." % stage)
		if String(catcher.get("visual_role", "")) != "stage_bottom_catch_all":
			failures.append("%s bottom catcher must expose visual_role=stage_bottom_catch_all." % stage)
		if not bool(catcher.get("stage_catch_all", false)):
			failures.append("%s bottom catcher must mark stage_catch_all=true." % stage)
		if not bool(catcher.get("full_width", false)):
			failures.append("%s bottom catcher must span the full stage width." % stage)

func _expect_dictionary(value: Variant, label: String) -> Dictionary:
	if not (value is Dictionary):
		failures.append("%s must be a Dictionary, got %s." % [label, type_string(typeof(value))])
		return {}
	return value as Dictionary

func _expect_visual_ratio(ratios: Dictionary, label: String, expected: float, tolerance: float) -> void:
	if not ratios.has(label):
		failures.append("Missing visible schematic slot width ratio for %s." % label)
		return
	var actual: float = float(ratios.get(label, -1.0))
	if absf(actual - expected) > tolerance:
		failures.append("%s visible schematic width expected %.2f ± %.2f, got %.3f." % [label, expected, tolerance, actual])

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
	if int(contract.get("physics_clip_children_mode", -1)) != CanvasItem.CLIP_CHILDREN_AND_DRAW:
		failures.append("%s PhysicsStageClip must use clip_children=Clip + Draw so Node2D physics visuals are clipped." % label)
	if not bool(contract.get("physics_board_uses_stage_clip", false)):
		failures.append("%s physics board must be parented under PhysicsStageClip." % label)
	if not bool(contract.get("physics_clip_excludes_supply_strip", false)):
		failures.append("%s PhysicsStageClip must exclude the supply strip." % label)
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

func _expect_mechanism(mechanisms: Dictionary, mechanism_name: String, stage: String, motion_role: String) -> void:
	var mechanism: Dictionary = _expect_dictionary(mechanisms.get(mechanism_name, {}), mechanism_name)
	if String(mechanism.get("node_type", "")) != "AnimatableBody2D":
		failures.append("%s must be an AnimatableBody2D physical mechanism." % mechanism_name)
	if String(mechanism.get("stage", "")) != stage:
		failures.append("%s must belong to %s." % [mechanism_name, stage])
	if String(mechanism.get("physics_role", "")) != "moving_landing_mechanism":
		failures.append("%s must expose physics_role=moving_landing_mechanism." % mechanism_name)
	if String(mechanism.get("motion_role", "")) != motion_role:
		failures.append("%s must expose motion_role=%s." % [mechanism_name, motion_role])
	if not bool(mechanism.get("uses_physics_time", false)):
		failures.append("%s must be driven by physics time." % mechanism_name)
	if not bool(mechanism.get("changes_landing_locally", false)):
		failures.append("%s must affect local landing variation." % mechanism_name)
	if not bool(mechanism.get("does_not_replace_bin_widths", false)):
		failures.append("%s must not replace the slot-width primary distribution." % mechanism_name)
	if float(mechanism.get("cycle_seconds", 0.0)) <= 0.0:
		failures.append("%s must expose a positive cycle_seconds." % mechanism_name)
	if not bool(mechanism.get("visible", false)):
		failures.append("%s must be visible in the physical stage." % mechanism_name)
	if not bool(mechanism.get("plate_visible", false)):
		failures.append("%s must expose a visible MechanismPlate." % mechanism_name)
	if not bool(mechanism.get("highlight_visible", false)):
		failures.append("%s must expose a visible highlight so the moving plate is readable." % mechanism_name)
	if not bool(mechanism.get("stage_rect_contains_center", false)):
		failures.append("%s center must stay inside its %s warehouse." % [mechanism_name, stage])
	if not bool(mechanism.get("stage_rect_intersects_bounds", false)):
		failures.append("%s visual bounds must intersect its %s warehouse." % [mechanism_name, stage])
	var body_size_variant: Variant = mechanism.get("body_size", Vector2.ZERO)
	if not (body_size_variant is Vector2):
		failures.append("%s must expose body_size as Vector2." % mechanism_name)
	else:
		var body_size: Vector2 = body_size_variant as Vector2
		if minf(body_size.x, body_size.y) < 10.0:
			failures.append("%s moving plate thickness must be readable, got %.1f." % [mechanism_name, minf(body_size.x, body_size.y)])
	var bounds_variant: Variant = mechanism.get("bounds", Rect2())
	if not (bounds_variant is Rect2):
		failures.append("%s must expose rendered bounds as Rect2." % mechanism_name)
	else:
		var bounds: Rect2 = bounds_variant as Rect2
		if bounds.size.x <= 1.0 or bounds.size.y <= 1.0:
			failures.append("%s rendered bounds must have visible area." % mechanism_name)

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

func _finish() -> void:
	if failures.is_empty():
		print("verify_machine_physics_contract: PASS")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
