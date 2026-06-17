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
	_verify_fixed_peg_rebound_contract(board)
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

func _verify_fixed_peg_rebound_contract(board: Node) -> void:
	if not board.has_method("simulate_fixed_peg_rebound_for_verifier"):
		failures.append("MachinePhysicsBoardView must expose fixed peg rebound simulation.")
		return
	var rebound: Dictionary = board.call("simulate_fixed_peg_rebound_for_verifier", "Launch") as Dictionary
	if String(rebound.get("source", "")) != "fixed_peg_rebound":
		failures.append("Fixed peg rebound simulation must report source=fixed_peg_rebound.")
	var before_velocity_variant: Variant = rebound.get("before_velocity", Vector2.ZERO)
	var after_velocity_variant: Variant = rebound.get("after_velocity", Vector2.ZERO)
	if not (before_velocity_variant is Vector2) or not (after_velocity_variant is Vector2):
		failures.append("Fixed peg rebound simulation must expose before_velocity and after_velocity as Vector2.")
		return
	var before_velocity: Vector2 = before_velocity_variant as Vector2
	var after_velocity: Vector2 = after_velocity_variant as Vector2
	if before_velocity.y <= 0.0:
		failures.append("Fixed peg rebound simulation must start from a downward impact.")
	if after_velocity.y > -135.0:
		failures.append("Fixed peg contact must visibly rebound upward; got after_velocity.y=%.1f." % after_velocity.y)
	if after_velocity.length() < 220.0:
		failures.append("Fixed peg contact must preserve enough speed to read as elastic; got speed=%.1f." % after_velocity.length())

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
	_expect_moving_mechanism_overlay_contract(contract, "MachineBoardView")
	_expect_physics_scale_contract(contract, "MachineBoardView")
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

func _verify_moving_mechanism_contract(contract: Dictionary) -> void:
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
	var stage_rects: Dictionary = _expect_dictionary(contract.get("stage_rects", {}), "stage_rects")
	for stage: String in ["Launch", "Tuning", "Unit"]:
		var catcher: Dictionary = _expect_dictionary(catchers.get(stage, {}), "%s stage_bottom_catcher" % stage)
		var stage_rect: Rect2 = _stage_info_to_rect(stage_rects.get(stage, {}), "%s stage_rect" % stage)
		if not bool(catcher.get("has_catcher", false)):
			failures.append("%s stage must have a bottom catch-all Area2D so balls cannot miss every physical bin." % stage)
		if String(catcher.get("visual_role", "")) != "stage_bottom_catch_all":
			failures.append("%s bottom catcher must expose visual_role=stage_bottom_catch_all." % stage)
		if not bool(catcher.get("stage_catch_all", false)):
			failures.append("%s bottom catcher must mark stage_catch_all=true." % stage)
		if not bool(catcher.get("full_width", false)):
			failures.append("%s bottom catcher must span the full stage width." % stage)
		_expect_bottom_catcher_lower_band(catcher, stage_rect, stage)

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
	_expect_layout_rect_alignment_contract(contract, label)
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

func _expect_physics_scale_contract(contract: Dictionary, label: String) -> void:
	var runtime: Dictionary = _expect_dictionary(contract.get("runtime_contract", {}), "%s runtime_contract" % label) if contract.has("runtime_contract") else {}
	var scale: float = float(contract.get("layout_physics_scale", runtime.get("layout_physics_scale", 0.0)))
	var ball_radius: float = float(contract.get("scaled_ball_radius", runtime.get("scaled_ball_radius", 0.0)))
	var peg_radius: float = float(contract.get("scaled_peg_radius", runtime.get("scaled_peg_radius", 0.0)))
	var mechanism_thickness: float = float(contract.get("scaled_mechanism_thickness", runtime.get("scaled_mechanism_thickness", 0.0)))
	if scale <= 0.0:
		failures.append("%s must expose a positive layout_physics_scale." % label)
	if ball_radius <= 0.0:
		failures.append("%s must expose a positive scaled_ball_radius." % label)
	if peg_radius <= 0.0:
		failures.append("%s must expose a positive scaled_peg_radius." % label)
	if mechanism_thickness < 10.0:
		failures.append("%s scaled mechanism thickness must remain readable." % label)

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
