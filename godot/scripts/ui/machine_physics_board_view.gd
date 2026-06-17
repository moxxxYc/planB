class_name MachinePhysicsBoardView
extends Node2D

signal landing_resolved(result: MachinePhysicsResult)
signal redirect_requested(natural_result_id: String, body: RigidBody2D)

const MachineSlotExposureStateScript := preload("res://scripts/model/machine/machine_slot_exposure_state.gd")
const MachineBallPayloadScript := preload("res://scripts/model/machine/machine_ball_payload.gd")
const MachinePhysicsBallBodyScript := preload("res://scripts/ui/machine_physics_ball_body.gd")

const BALL_LAYER: int = 1
const PEG_LAYER: int = 2
const BIN_LAYER: int = 3
const BALL_RADIUS: float = 7.5
const PEG_RADIUS: float = 4.0
const PEG_LAYOUTS: Dictionary = {
	"Launch": [
		Vector2(0.10, 0.22), Vector2(0.25, 0.22), Vector2(0.40, 0.22), Vector2(0.55, 0.22), Vector2(0.70, 0.22), Vector2(0.85, 0.22),
		Vector2(0.17, 0.32), Vector2(0.32, 0.32), Vector2(0.47, 0.32), Vector2(0.62, 0.32), Vector2(0.77, 0.32), Vector2(0.92, 0.32),
		Vector2(0.10, 0.42), Vector2(0.25, 0.42), Vector2(0.40, 0.42), Vector2(0.55, 0.42), Vector2(0.70, 0.42), Vector2(0.85, 0.42),
		Vector2(0.17, 0.52), Vector2(0.32, 0.52), Vector2(0.47, 0.52), Vector2(0.62, 0.52), Vector2(0.77, 0.52), Vector2(0.92, 0.52),
		Vector2(0.10, 0.62), Vector2(0.25, 0.62), Vector2(0.40, 0.62), Vector2(0.55, 0.62), Vector2(0.70, 0.62), Vector2(0.85, 0.62),
	],
	"Tuning": [
		Vector2(0.10, 0.22), Vector2(0.25, 0.22), Vector2(0.40, 0.22), Vector2(0.55, 0.22), Vector2(0.70, 0.22), Vector2(0.85, 0.22),
		Vector2(0.17, 0.32), Vector2(0.32, 0.32), Vector2(0.47, 0.32), Vector2(0.62, 0.32), Vector2(0.77, 0.32), Vector2(0.92, 0.32),
		Vector2(0.10, 0.42), Vector2(0.25, 0.42), Vector2(0.40, 0.42), Vector2(0.55, 0.42), Vector2(0.70, 0.42), Vector2(0.85, 0.42),
		Vector2(0.17, 0.52), Vector2(0.32, 0.52), Vector2(0.47, 0.52), Vector2(0.62, 0.52), Vector2(0.77, 0.52), Vector2(0.92, 0.52),
		Vector2(0.10, 0.62), Vector2(0.25, 0.62), Vector2(0.40, 0.62), Vector2(0.55, 0.62), Vector2(0.70, 0.62), Vector2(0.85, 0.62),
	],
	"Unit": [
		Vector2(0.12, 0.20), Vector2(0.30, 0.20), Vector2(0.48, 0.20), Vector2(0.66, 0.20), Vector2(0.84, 0.20),
		Vector2(0.21, 0.30), Vector2(0.39, 0.30), Vector2(0.57, 0.30), Vector2(0.75, 0.30), Vector2(0.93, 0.30),
		Vector2(0.12, 0.40), Vector2(0.30, 0.40), Vector2(0.48, 0.40), Vector2(0.66, 0.40), Vector2(0.84, 0.40),
		Vector2(0.21, 0.50), Vector2(0.39, 0.50), Vector2(0.57, 0.50), Vector2(0.75, 0.50), Vector2(0.93, 0.50),
	],
}
const STAGE_BIN_LABELS: Dictionary = {
	"Launch": ["Split", "Tuning", "Recycle", "Waste"],
	"Tuning": ["Prime", "Gate", "Echo", "Surge"],
	"Unit": ["S1", "S2", "S3", "S4"],
}
const WALL_THICKNESS: float = 6.0
const STAGE_TOP_GUARD_THICKNESS: float = 18.0
const STAGE_TOP_GUARD_CLEARANCE: float = 8.0
const STAGE_BOTTOM_CATCHER_HEIGHT: float = 34.0
const MECHANISM_THICKNESS: float = 12.0
const MOVING_PEG_RADIUS: float = 5.5
const MECHANISM_BOUNCE: float = 0.86
const MECHANISM_FRICTION: float = 0.015
const LAUNCH_MOVING_PEG_ROW_CYCLE_SECONDS: float = 3.0
const TUNING_MOVING_PEG_BAND_CYCLE_SECONDS: float = 3.6
const DEFAULT_STAGE_WIDTH: float = 340.0
const DEFAULT_STAGE_HEIGHT: float = 112.0
const VERIFIER_SOURCE: String = "verifier_seed"
const RETIRED_BALL_DWELL_SECONDS: float = 0.5
const MAX_RETIRED_BALLS: int = 4
const UNIT_GATE_PLATE_EXTRA_HEIGHT: float = 18.0
const UNIT_GATE_MIN_COLLISION_WIDTH: float = 1.0
const UNIT_GATE_BOUNCE_MARGIN: float = 4.0
const MACHINE_BIN_RAIL_HEIGHT: float = 7.0
const MAX_BLOCKED_BOUNCES_PER_BALL: int = 3
const LAUNCHER_SWING_CYCLE_SECONDS: float = 2.7
const LAUNCHER_SWING_MAX_ANGLE: float = PI * 0.5
const LAUNCHER_BARREL_LENGTH: float = 34.0
const LAUNCHER_MUZZLE_SPEED: float = 205.0
const BALL_GRAVITY_SCALE: float = 1.65
const STAGE_ENTRY_DOWN_SPEED: float = 285.0
const STAGE_ENTRY_SIDE_SPEED: float = 120.0
const STAGE_FLOW_DOWN_FORCE: float = 760.0
const STAGE_FLOW_SIDE_FORCE: float = 95.0
const STAGE_STALL_SPEED: float = 70.0
const STAGE_STALL_DOWN_IMPULSE: float = 54.0
const STAGE_STALL_SIDE_IMPULSE: float = 22.0
const STAGE_STALL_IMPULSE_INTERVAL_SECONDS: float = 0.18
const STAGE_BACKFLOW_REBOUND_SPEED: float = 240.0
const BALL_FRICTION: float = 0.03
const BALL_BOUNCE: float = 0.68
const PEG_FRICTION: float = 0.02
const PEG_BOUNCE: float = 0.92
const FIXED_PEG_REBOUND_MIN_SPEED: float = 235.0
const FIXED_PEG_REBOUND_MIN_UP_SPEED: float = 145.0
const FIXED_PEG_REBOUND_SPEED_MULTIPLIER: float = 0.96
const FIXED_PEG_REBOUND_INTERVAL_SECONDS: float = 0.045
const WALL_FRICTION: float = 0.05
const WALL_BOUNCE: float = 0.55
const UNIT_GATE_FRICTION: float = 0.0
const UNIT_GATE_BOUNCE: float = 0.92
const UNIT_GATE_CONTACT_REBOUND_SPEED: float = 230.0
const UNIT_GATE_CONTACT_REBOUND_UP_SPEED: float = 125.0
const UNIT_GATE_CONTACT_REBOUND_NUDGE: float = 4.0
const UNIT_GATE_CONTACT_REBOUND_INTERVAL_SECONDS: float = 0.08

var active_ball: RigidBody2D = null
var physics_landing_count: int = 0
var last_physics_result: Dictionary = {}
var exposure_gate_snapshot: Dictionary = {}
var blocked_bounce_count: int = 0
var last_blocked_bounce: Dictionary = {}
var unit_gate_contact_rebound_count: int = 0
var last_unit_gate_contact_rebound: Dictionary = {}
var fixed_peg_rebound_count: int = 0
var last_fixed_peg_rebound: Dictionary = {}
var stage_backflow_guard_count: int = 0
var last_stage_backflow_guard: Dictionary = {}
var _stage_rects: Dictionary = {}
var _stage_bins: Dictionary = {}
var _launch_index: int = 0
var _created_ball_count: int = 0
var _battle_elapsed: float = 0.0
var _exposure_state: RefCounted = MachineSlotExposureStateScript.new()
var _unit_gate_blockers: Dictionary = {}
var _retired_balls: Array[RigidBody2D] = []
var _redirect_resolver: Callable = Callable()
var _last_launch_origin: Vector2 = Vector2.ZERO
var _last_launch_velocity: Vector2 = Vector2.ZERO
var _last_launch_angle: float = 0.0
var _physics_tick_count: int = 0
var _layout_physics_scale: float = 1.0

func _ready() -> void:
	_ensure_default_stage_rects()
	_rebuild_board()
	set_physics_process(true)

func _physics_process(_delta: float) -> void:
	_physics_tick_count += 1
	_update_moving_mechanisms()
	_apply_stage_flow_forces()

func launch_ball(ball: Dictionary, battle_elapsed: float) -> void:
	_ensure_default_stage_rects()
	_rebuild_board()
	_launch_index += 1
	_created_ball_count += 1
	_remove_preview_ball()

	var body: RigidBody2D = _make_ball(ball)
	body.name = "ActiveBall" if active_ball == null or not is_instance_valid(active_ball) else "ActiveBall%d" % _created_ball_count
	active_ball = body
	add_child(body)
	_place_body_for_stage_runtime(body, "Launch", battle_elapsed)

func set_exposure_state(exposure_state: RefCounted) -> void:
	if not _has_exposure_state_contract(exposure_state):
		return
	_exposure_state = exposure_state
	_update_unit_gate_blockers()

func set_battle_elapsed(seconds: float) -> void:
	_battle_elapsed = maxf(0.0, seconds)
	_update_launcher_turret()
	_position_preview_ball_at_launcher_muzzle()
	_update_unit_gate_blockers()

func set_redirect_resolver(resolver: Callable) -> void:
	_redirect_resolver = resolver

func set_layout_physics_scale(value: float) -> void:
	var next_scale: float = clampf(value, 0.5, 2.0)
	if is_equal_approx(_layout_physics_scale, next_scale):
		return
	_layout_physics_scale = next_scale
	_clear_board_geometry()
	_rebuild_board()

func get_runtime_contract() -> Dictionary:
	_rebuild_board()
	_update_moving_mechanisms()
	_ensure_preview_ball()
	return {
		"runtime_uses_preselected_target_labels": false,
		"verifier_seed_path_available": has_method("run_seeded_chain_for_verifier"),
		"bin_width_ratios": _bin_width_ratio_snapshot(),
		"bin_orders": _bin_order_snapshot(),
		"has_visible_rigidbody_ball": _has_visible_rigidbody_ball(),
		"has_physics_contract_nodes": has_physics_contract_nodes(),
		"layout_physics_scale": _layout_physics_scale,
		"scaled_ball_radius": _scaled(BALL_RADIUS),
		"scaled_peg_radius": _scaled(PEG_RADIUS),
		"scaled_mechanism_thickness": _scaled(MECHANISM_THICKNESS, 10.0),
		"has_moving_mechanism_nodes": has_moving_mechanism_nodes(),
		"physics_landing_count": physics_landing_count,
		"last_physics_result": last_physics_result.duplicate(true),
		"created_ball_count": _created_ball_count,
		"stage_count": _stage_rects.size(),
		"stage_rects": _stage_rect_snapshot(),
		"exposure_gate_snapshot": exposure_gate_snapshot.duplicate(true),
		"blocked_bounce_count": blocked_bounce_count,
		"last_blocked_bounce": last_blocked_bounce.duplicate(true),
		"unit_gate_contact_rebound_count": unit_gate_contact_rebound_count,
		"last_unit_gate_contact_rebound": last_unit_gate_contact_rebound.duplicate(true),
		"fixed_peg_rebound_count": fixed_peg_rebound_count,
		"last_fixed_peg_rebound": last_fixed_peg_rebound.duplicate(true),
		"stage_backflow_guard_count": stage_backflow_guard_count,
		"last_stage_backflow_guard": last_stage_backflow_guard.duplicate(true),
		"has_unit_gate_blockers": _has_unit_gate_blockers(),
		"unit_gate_blocker_count": _unit_gate_blockers.size(),
		"peg_counts": _peg_count_snapshot(),
		"peg_grid": _peg_grid_snapshot(),
		"moving_mechanism_counts": _moving_mechanism_count_snapshot(),
		"moving_mechanisms": _moving_mechanism_snapshot(),
		"stage_top_guards": _stage_top_guard_snapshot(),
		"stage_bottom_catchers": _stage_bottom_catcher_snapshot(),
		"bin_visuals": _bin_visual_snapshot(),
		"unit_gate_visuals": _unit_gate_visual_snapshot(),
		"physics_materials": _physics_material_snapshot(),
		"launcher_turret": _launcher_turret_snapshot(),
		"active_ball_position": _active_ball_position(),
		"active_ball_chain_id": _active_ball_chain_id(),
		"active_ball_at_visible_muzzle": _active_ball_at_visible_muzzle(),
		"ball_stage_snapshot": _ball_stage_snapshot(),
		"physics_tick_count": _physics_tick_count,
		"battle_elapsed": _battle_elapsed,
	}

func emit_seeded_landing_for_verifier(result: MachinePhysicsResult) -> MachinePhysicsResult:
	var seeded_result: MachinePhysicsResult = _copy_for_verifier(result)
	_record_landing(seeded_result)
	landing_resolved.emit(seeded_result)
	return seeded_result

func run_seeded_chain_for_verifier(results: Array[MachinePhysicsResult]) -> void:
	for result: MachinePhysicsResult in results:
		emit_seeded_landing_for_verifier(result)

func resolve_redirect_for_verifier(natural_result_id: String) -> Dictionary:
	return {
		"final_result_id": natural_result_id,
		"forced_by": "",
		"feedback_state": "Natural Hit",
	}

func simulate_unit_gate_contact_rebound_for_verifier(slot_id: int = 2) -> Dictionary:
	_ensure_default_stage_rects()
	_rebuild_board()
	set_battle_elapsed(0.0)
	slot_id = clampi(slot_id, 2, 4)
	var blocker: StaticBody2D = _unit_gate_blockers.get(slot_id, null) as StaticBody2D
	if blocker == null:
		return {}
	_remove_preview_ball()
	var body := _make_ball(MachineBallPayloadScript.clean("gate_contact_rebound_verifier"))
	body.name = "GateContactReboundVerifierBall"
	body.set_meta("stage", "Unit")
	body.set_meta("battle_elapsed", _battle_elapsed)
	body.set_meta("last_unit_gate_contact_rebound_seconds", -999.0)
	body.position = blocker.position + Vector2(0.0, -_ball_radius() - 2.0)
	body.linear_velocity = Vector2.ZERO
	active_ball = body
	add_child(body)
	_bounce_body_from_unit_gate_blocker_contact(body, blocker)
	return {
		"slot_id": slot_id,
		"ball_position": body.position,
		"linear_velocity": body.linear_velocity,
		"speed": body.linear_velocity.length(),
		"rebound_count": unit_gate_contact_rebound_count,
		"last_rebound": last_unit_gate_contact_rebound.duplicate(true),
	}

func simulate_fixed_peg_rebound_for_verifier(stage: String = "Launch") -> Dictionary:
	_ensure_default_stage_rects()
	_rebuild_board()
	set_battle_elapsed(0.0)
	var peg: StaticBody2D = _first_peg_body_for_stage(stage)
	if peg == null:
		return {}
	_remove_preview_ball()
	var body := _make_ball(MachineBallPayloadScript.clean("fixed_peg_rebound_verifier"))
	body.name = "FixedPegReboundVerifierBall"
	body.set_meta("stage", stage)
	body.set_meta("last_fixed_peg_rebound_seconds", -999.0)
	body.position = peg.position + Vector2(0.0, -_ball_radius() - _peg_radius() + 1.0)
	body.linear_velocity = Vector2(42.0, 230.0)
	add_child(body)
	_bounce_body_from_fixed_peg_contact(body, peg)
	var record: Dictionary = last_fixed_peg_rebound.duplicate(true)
	remove_child(body)
	body.free()
	return record

func simulate_stage_backflow_guard_for_verifier(stage: String = "Unit") -> Dictionary:
	_ensure_default_stage_rects()
	_rebuild_board()
	if stage != "Tuning" and stage != "Unit":
		stage = "Unit"
	var rect: Rect2 = _stage_rect(stage)
	var guard: StaticBody2D = _stage_top_guard(stage)
	var guard_size: Vector2 = _static_rectangle_size(guard)
	var guard_bottom_y: float = guard.position.y + guard_size.y * 0.5 if guard != null else -INF
	var contact_limit_y: float = guard_bottom_y + _ball_radius()
	var start_position := Vector2(rect.get_center().x, rect.position.y - _ball_radius())
	var upward_velocity := Vector2(0.0, -260.0)
	_remove_preview_ball()
	var body := _make_ball(MachineBallPayloadScript.clean("stage_backflow_guard_verifier"))
	body.name = "StageBackflowGuardVerifierBall"
	body.set_meta("stage", stage)
	_configure_body_stage_top_guard(body, stage)
	body.position = start_position
	body.linear_velocity = upward_velocity
	active_ball = body
	add_child(body)
	_enforce_stage_top_bound(body, stage)
	return {
		"stage": stage,
		"has_guard": guard != null,
		"stage_top_y": rect.position.y,
		"guard_bottom_y": guard_bottom_y,
		"ball_contact_limit_y": contact_limit_y,
		"start_position": start_position,
		"upward_velocity": upward_velocity,
		"would_cross_stage_top_without_guard": start_position.y + upward_velocity.y * 0.12 < rect.position.y,
		"starts_below_guard": _stage_entry_y(stage) > contact_limit_y,
		"guard_is_full_width": guard_size.x >= rect.size.x - 0.5,
		"corrected_position": body.position,
		"corrected_velocity": body.linear_velocity,
		"guardrail_corrected": body.position.y >= _stage_entry_y(stage) and body.linear_velocity.y > 0.0,
		"backflow_guard_count": stage_backflow_guard_count,
	}

# Backward-compatible alias for old gates. New code should call
# emit_seeded_landing_for_verifier() so deterministic source is explicit.
func emit_deterministic_landing() -> MachinePhysicsResult:
	return emit_seeded_landing_for_verifier(
		MachinePhysicsResult.make("Tuning", "Gate", 1, 1, "clean", VERIFIER_SOURCE)
	)

func has_physics_contract_nodes() -> bool:
	_rebuild_board()
	return (
		_find_first_child_of_type(self, "RigidBody2D") != null
		and _find_first_child_of_type(self, "StaticBody2D") != null
		and _find_first_child_of_type(self, "Area2D") != null
	)

func has_moving_mechanism_nodes() -> bool:
	_rebuild_board()
	var mechanisms: Node = get_node_or_null("Mechanisms")
	return mechanisms != null and _find_first_child_of_type(mechanisms, "AnimatableBody2D") != null

func set_stage_rects(stage_rects: Dictionary) -> void:
	var next_rects: Dictionary = {}
	for key_variant: Variant in stage_rects.keys():
		var key: String = String(key_variant)
		var rect_variant: Variant = stage_rects[key_variant]
		if rect_variant is Rect2:
			next_rects[key] = rect_variant
	if next_rects.is_empty():
		return
	var next_key: String = _layout_key(next_rects)
	if next_key == _layout_key(_stage_rects):
		return
	var previous_rects: Dictionary = _stage_rects.duplicate(true)
	_stage_rects = next_rects
	_remap_active_balls_for_stage_rect_change(previous_rects, next_rects)
	_clear_board_geometry()
	_rebuild_board()

func _ensure_default_stage_rects() -> void:
	if not _stage_rects.is_empty():
		return
	_stage_rects = {
		"Launch": Rect2(Vector2(14.0, 196.0), Vector2(DEFAULT_STAGE_WIDTH, DEFAULT_STAGE_HEIGHT)),
		"Tuning": Rect2(Vector2(14.0, 320.0), Vector2(DEFAULT_STAGE_WIDTH, DEFAULT_STAGE_HEIGHT)),
		"Unit": Rect2(Vector2(14.0, 444.0), Vector2(DEFAULT_STAGE_WIDTH, DEFAULT_STAGE_HEIGHT)),
	}

func _remap_active_balls_for_stage_rect_change(previous_rects: Dictionary, next_rects: Dictionary) -> void:
	if previous_rects.is_empty():
		return
	for child: Node in get_children():
		if not (child is RigidBody2D):
			continue
		var body: RigidBody2D = child as RigidBody2D
		if String(body.get_meta("chain_id", "")) == "preview":
			continue
		var stage: String = String(body.get_meta("stage", ""))
		if not previous_rects.has(stage) or not next_rects.has(stage):
			continue
		var previous_rect: Rect2 = previous_rects[stage] as Rect2
		var next_rect: Rect2 = next_rects[stage] as Rect2
		if previous_rect.size.x <= 0.0 or previous_rect.size.y <= 0.0:
			continue
		var relative := Vector2(
			(body.position.x - previous_rect.position.x) / previous_rect.size.x,
			(body.position.y - previous_rect.position.y) / previous_rect.size.y
		)
		body.position = next_rect.position + Vector2(relative.x * next_rect.size.x, relative.y * next_rect.size.y)
		if stage == "Tuning" or stage == "Unit":
			_enforce_stage_top_bound(body, stage)
		body.reset_physics_interpolation()

func _rebuild_board() -> void:
	_ensure_default_stage_rects()
	if get_node_or_null("StaticGeometry") != null:
		_update_launcher_turret()
		_update_moving_mechanisms()
		_update_unit_gate_blockers()
		return

	var static_geometry := Node2D.new()
	static_geometry.name = "StaticGeometry"
	add_child(static_geometry)
	var bins := Node2D.new()
	bins.name = "Bins"
	add_child(bins)
	var mechanisms := Node2D.new()
	mechanisms.name = "Mechanisms"
	mechanisms.z_index = 18
	mechanisms.z_as_relative = true
	add_child(mechanisms)

	_build_stage_geometry("Launch", _stage_labels("Launch"), Color("#7bcb6b"))
	_build_stage_geometry("Tuning", _stage_labels("Tuning"), Color("#e6b450"))
	_build_stage_geometry("Unit", _stage_labels("Unit"), Color("#c58be8"))
	_build_launcher_turret(Color("#7bcb6b"))
	_update_launcher_turret()
	_update_moving_mechanisms()
	_update_unit_gate_blockers()
	_ensure_preview_ball()

func _clear_board_geometry() -> void:
	for node_name: String in ["StaticGeometry", "Bins", "Mechanisms"]:
		var existing: Node = get_node_or_null(node_name)
		if existing != null:
			remove_child(existing)
			existing.queue_free()
	_stage_bins.clear()
	_unit_gate_blockers.clear()
	if active_ball != null and is_instance_valid(active_ball) and String(active_ball.get_meta("chain_id", "")) == "preview":
		_position_preview_ball_at_launcher_muzzle()

func _build_stage_geometry(stage: String, labels: Array[String], color: Color) -> void:
	var rect: Rect2 = _stage_rect(stage)
	var wall_thickness: float = _wall_thickness()
	_add_wall(stage + "LeftWall", rect.position + Vector2(wall_thickness * 0.5, rect.size.y * 0.5), Vector2(wall_thickness, rect.size.y), color.darkened(0.35))
	_add_wall(stage + "RightWall", rect.position + Vector2(rect.size.x - wall_thickness * 0.5, rect.size.y * 0.5), Vector2(wall_thickness, rect.size.y), color.darkened(0.35))
	_add_stage_top_guard(stage, rect, color)
	_build_stage_pegs(stage, rect, color)
	_build_stage_mechanisms(stage, rect, color)

	var total_weight: float = 0.0
	for label: String in labels:
		total_weight += _bin_weight_for_label(stage, label)
	var gap: float = 8.0
	var usable_width: float = maxf(32.0, rect.size.x - gap * float(labels.size() + 1))
	var cursor_x: float = rect.position.x + gap
	for index: int in range(labels.size()):
		var label: String = labels[index]
		var bin_width: float = usable_width * (_bin_weight_for_label(stage, label) / maxf(total_weight, 0.001))
		var center := Vector2(cursor_x + bin_width * 0.5, rect.position.y + rect.size.y - 14.0)
		_add_bin(stage, label, center, Vector2(bin_width, 24.0), index, color)
		cursor_x += bin_width + gap
	_add_stage_bottom_catcher(stage, labels, rect)
	if stage == "Unit":
		_build_unit_gate_blockers(labels, color)

func _build_stage_pegs(stage: String, rect: Rect2, color: Color) -> void:
	var layout: Array[Vector2] = _peg_layout_for_stage(stage)
	for index: int in range(layout.size()):
		var normalized_position: Vector2 = layout[index]
		var peg_position := rect.position + Vector2(rect.size.x * normalized_position.x, rect.size.y * normalized_position.y)
		_add_peg(stage, "%sPeg%02d" % [stage, index + 1], peg_position, color)

func _build_stage_mechanisms(stage: String, rect: Rect2, color: Color) -> void:
	match stage:
		"Launch":
			var launch_motion_range: float = _moving_peg_motion_range(rect, 0.02)
			var launch_edge_x: float = _moving_peg_edge_margin_ratio(rect, launch_motion_range)
			var launch_right_edge_x: float = 1.0 - launch_edge_x
			_add_moving_peg_group(
				stage,
				"LaunchMovingPegRow",
				"launch_moving_peg_row",
				"moving_peg_row",
				[
					{
						"phase_offset": 0.0,
						"points": _moving_peg_full_width_points(launch_edge_x, launch_right_edge_x, 0.36, 15, 0.0),
					},
				],
				rect,
				Vector2.RIGHT,
				launch_motion_range,
				LAUNCH_MOVING_PEG_ROW_CYCLE_SECONDS,
				color
			)
		"Tuning":
			var tuning_motion_range: float = _moving_peg_motion_range(rect, 0.02)
			var tuning_edge_x: float = _moving_peg_edge_margin_ratio(rect, tuning_motion_range)
			var tuning_right_edge_x: float = 1.0 - tuning_edge_x
			_add_moving_peg_group(
				stage,
				"TuningMovingPegBand",
				"tuning_moving_peg_band",
				"moving_peg_band",
				[
					{
						"phase_offset": 0.0,
						"points": _moving_peg_full_width_points(tuning_edge_x, tuning_right_edge_x, 0.35, 13, 0.0),
					},
					{
						"phase_offset": 0.0,
						"points": _moving_peg_full_width_points(tuning_edge_x, tuning_right_edge_x, 0.52, 13, 0.5),
					},
				],
				rect,
				Vector2.RIGHT,
				tuning_motion_range,
				TUNING_MOVING_PEG_BAND_CYCLE_SECONDS,
				color
			)

func _moving_peg_motion_range(rect: Rect2, ratio: float) -> float:
	return clampf(rect.size.x * ratio, _scaled(6.0, 4.0), _scaled(24.0, 12.0))

func _moving_peg_edge_margin_ratio(rect: Rect2, motion_range: float) -> float:
	if rect.size.x <= 0.0:
		return 0.05
	var margin: float = motion_range + _moving_peg_radius() + 1.0
	return clampf(margin / rect.size.x, 0.02, 0.20)

func _moving_peg_full_width_points(left_x: float, right_x: float, y_ratio: float, count: int, phase_bias: float) -> Array:
	var points: Array = []
	var safe_count: int = maxi(count, 2)
	for index: int in range(safe_count):
		var t: float = float(index) / float(safe_count - 1)
		var phase: float = fposmod(phase_bias + t * 0.84, 1.0)
		if index == 0:
			phase = phase_bias
		elif index == safe_count - 1:
			phase = fposmod(phase_bias + 0.5, 1.0)
		points.append({
			"position": Vector2(lerpf(left_x, right_x, t), y_ratio),
			"phase_offset": phase,
		})
	return points

func _add_moving_peg_group(
	stage: String,
	group_name: String,
	motion_role: String,
	motion_kind: String,
	row_layouts: Array,
	rect: Rect2,
	motion_axis: Vector2,
	motion_range: float,
	cycle_seconds: float,
	color: Color
) -> void:
	var mechanisms: Node = get_node_or_null("Mechanisms")
	if mechanisms == null:
		return
	var axis: Vector2 = motion_axis.normalized() if motion_axis.length() > 0.001 else Vector2.RIGHT
	var peg_index: int = 0
	for row_index: int in range(row_layouts.size()):
		var row_variant: Variant = row_layouts[row_index]
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant as Dictionary
		var points_variant: Variant = row.get("points", [])
		if not (points_variant is Array):
			continue
		var phase_offset: float = float(row.get("phase_offset", 0.0))
		var points: Array = points_variant as Array
		for point_variant: Variant in points:
			var normalized_position := Vector2.INF
			var point_phase_offset: float = phase_offset
			if point_variant is Dictionary:
				var point_info: Dictionary = point_variant as Dictionary
				var position_variant: Variant = point_info.get("position", Vector2.INF)
				if position_variant is Vector2:
					normalized_position = position_variant as Vector2
				point_phase_offset += float(point_info.get("phase_offset", 0.0))
			elif point_variant is Vector2:
				normalized_position = point_variant as Vector2
			if not _is_finite_vector2(normalized_position):
				continue
			peg_index += 1
			var home_position := rect.position + Vector2(rect.size.x * normalized_position.x, rect.size.y * normalized_position.y)
			_add_moving_peg_body(
				stage,
				group_name,
				"%s_R%dP%02d" % [group_name, row_index + 1, peg_index],
				motion_role,
				motion_kind,
				home_position,
				axis,
				motion_range,
				cycle_seconds,
				point_phase_offset,
				row_index,
				row_layouts.size(),
				color
			)

func _add_moving_peg_body(
	stage: String,
	group_name: String,
	body_name: String,
	motion_role: String,
	motion_kind: String,
	home_position: Vector2,
	motion_axis: Vector2,
	motion_range: float,
	cycle_seconds: float,
	phase_offset: float,
	row_index: int,
	row_count: int,
	color: Color
) -> void:
	var mechanisms: Node = get_node_or_null("Mechanisms")
	if mechanisms == null:
		return
	if mechanisms.get_node_or_null(body_name) != null:
		return
	var radius: float = _moving_peg_radius()
	var body := AnimatableBody2D.new()
	body.name = body_name
	body.z_index = 0
	body.z_as_relative = true
	body.visible = true
	body.collision_layer = 0
	body.collision_mask = 0
	body.set_collision_layer_value(PEG_LAYER, true)
	body.set_collision_mask_value(BALL_LAYER, true)
	body.physics_material_override = _make_physics_material(MECHANISM_BOUNCE, MECHANISM_FRICTION)
	body.set_meta("stage", stage)
	body.set_meta("physics_role", "moving_landing_mechanism")
	body.set_meta("motion_role", motion_role)
	body.set_meta("moving_mechanism", true)
	body.set_meta("moving_peg", true)
	body.set_meta("mechanism_group", group_name)
	body.set_meta("uses_physics_time", true)
	body.set_meta("motion_kind", motion_kind)
	body.set_meta("motion_profile", "ping_pong_uniform")
	body.set_meta("changes_landing_locally", true)
	body.set_meta("does_not_replace_bin_widths", true)
	body.set_meta("home_position", home_position)
	body.set_meta("home_rotation", 0.0)
	body.set_meta("motion_axis", motion_axis)
	body.set_meta("motion_range", motion_range)
	body.set_meta("cycle_seconds", cycle_seconds)
	body.set_meta("phase_offset", phase_offset)
	body.set_meta("row_index", row_index)
	body.set_meta("row_count", row_count)
	body.set_meta("peg_radius", radius)
	body.set_meta("body_size", Vector2(radius * 2.0, radius * 2.0))
	body.set_meta("bounce", MECHANISM_BOUNCE)
	body.set_meta("friction", MECHANISM_FRICTION)

	var shape_node := CollisionShape2D.new()
	shape_node.name = "MovingPegShape"
	var shape := CircleShape2D.new()
	shape.radius = radius
	shape_node.shape = shape
	body.add_child(shape_node)

	var visual := Polygon2D.new()
	visual.name = "MovingPegVisual"
	visual.z_index = 1
	visual.z_as_relative = true
	visual.color = color.lightened(0.12)
	visual.polygon = _circle_polygon(radius, 18)
	body.add_child(visual)

	var ring := Line2D.new()
	ring.name = "MovingPegRing"
	ring.z_index = 2
	ring.z_as_relative = true
	ring.default_color = Color("#f4f0d8")
	ring.width = maxf(1.5, radius * 0.28)
	ring.points = _circle_outline_points(radius * 1.18, 18)
	body.add_child(ring)

	mechanisms.add_child(body)
	_apply_moving_mechanism_transform(body)
	body.reset_physics_interpolation()

func _update_moving_mechanisms() -> void:
	var mechanisms: Node = get_node_or_null("Mechanisms")
	if mechanisms == null:
		return
	for child: Node in mechanisms.get_children():
		if child is AnimatableBody2D and bool(child.get_meta("moving_mechanism", false)):
			_apply_moving_mechanism_transform(child as AnimatableBody2D)

func _apply_moving_mechanism_transform(body: AnimatableBody2D) -> void:
	if bool(body.get_meta("moving_peg", false)):
		_apply_moving_peg_transform(body)

func _apply_moving_peg_transform(body: AnimatableBody2D) -> void:
	var home_position_variant: Variant = body.get_meta("home_position", body.position)
	var home_position: Vector2 = home_position_variant as Vector2 if home_position_variant is Vector2 else body.position
	var axis_variant: Variant = body.get_meta("motion_axis", Vector2.RIGHT)
	var axis: Vector2 = axis_variant as Vector2 if axis_variant is Vector2 else Vector2.RIGHT
	if axis.length() <= 0.001:
		axis = Vector2.RIGHT
	axis = axis.normalized()
	var motion_range: float = maxf(0.0, float(body.get_meta("motion_range", 0.0)))
	var cycle_seconds: float = maxf(0.1, float(body.get_meta("cycle_seconds", 1.0)))
	var phase_offset: float = float(body.get_meta("phase_offset", 0.0))
	var ratio: float = _ping_pong_ratio(_battle_elapsed, cycle_seconds, phase_offset)
	var offset: float = (ratio - 0.5) * 2.0 * motion_range
	var next_position: Vector2 = home_position + axis * offset
	body.transform = Transform2D(0.0, next_position)
	body.set_meta("current_position", next_position)
	body.set_meta("current_rotation", 0.0)
	if body.is_inside_tree():
		body.force_update_transform()

func _ping_pong_ratio(seconds: float, cycle_seconds: float, phase_offset: float) -> float:
	var cycle: float = maxf(0.1, cycle_seconds)
	var unit: float = fposmod(maxf(0.0, seconds) / cycle + phase_offset, 1.0)
	return 1.0 - absf(unit * 2.0 - 1.0)

func _stage_labels(stage: String) -> Array[String]:
	var labels: Array[String] = []
	var labels_variant: Variant = STAGE_BIN_LABELS.get(stage, [])
	if labels_variant is Array:
		for label_variant: Variant in labels_variant:
			labels.append(String(label_variant))
	return labels

func _peg_layout_for_stage(stage: String) -> Array[Vector2]:
	var layout: Array[Vector2] = []
	var layout_variant: Variant = PEG_LAYOUTS.get(stage, [])
	if layout_variant is Array:
		for point_variant: Variant in layout_variant:
			if point_variant is Vector2:
				layout.append(point_variant as Vector2)
	return layout

func _build_unit_gate_blockers(labels: Array[String], color: Color) -> void:
	var static_geometry: Node = get_node_or_null("StaticGeometry")
	if static_geometry == null:
		return
	for index: int in range(labels.size()):
		var slot_id: int = index + 1
		if _unit_gate_blockers.has(slot_id):
			continue
		var blocker := StaticBody2D.new()
		blocker.name = "UnitS%dExposureGateBlocker" % slot_id
		blocker.z_index = 20
		blocker.z_as_relative = false
		blocker.collision_layer = 0
		blocker.collision_mask = 0
		blocker.set_collision_layer_value(PEG_LAYER, true)
		blocker.set_collision_mask_value(BALL_LAYER, true)
		blocker.physics_material_override = _make_physics_material(UNIT_GATE_BOUNCE, UNIT_GATE_FRICTION)
		blocker.set_meta("stage", "Unit")
		blocker.set_meta("slot_id", slot_id)
		blocker.set_meta("unit_gate_blocker", true)
		blocker.set_meta("physics_role", "unit_exposure_rebound_plate")
		blocker.set_meta("bounce", UNIT_GATE_BOUNCE)
		blocker.set_meta("friction", UNIT_GATE_FRICTION)

		var shape_node := CollisionShape2D.new()
		shape_node.name = "GateShape"
		var shape := RectangleShape2D.new()
		shape.size = Vector2(UNIT_GATE_MIN_COLLISION_WIDTH, _scaled(24.0) + _unit_gate_plate_extra_height())
		shape_node.shape = shape
		blocker.add_child(shape_node)

		var visual := Polygon2D.new()
		visual.name = "GatePlate"
		visual.z_index = 21
		visual.z_as_relative = false
		visual.color = color.darkened(0.55)
		blocker.add_child(visual)

		static_geometry.add_child(blocker)
		_unit_gate_blockers[slot_id] = blocker

func _update_unit_gate_blockers() -> void:
	exposure_gate_snapshot = _exposure_snapshot(_battle_elapsed)
	if _unit_gate_blockers.is_empty():
		return
	for slot_id: int in range(1, 5):
		if not _unit_gate_blockers.has(slot_id):
			continue
		var blocker: StaticBody2D = _unit_gate_blockers[slot_id] as StaticBody2D
		var bin: Area2D = _unit_bin(slot_id)
		if blocker == null or bin == null:
			continue
		var bin_size: Vector2 = _bin_size(bin)
		var ratio: float = _slot_exposure_ratio(slot_id, _battle_elapsed)
		var closed_width: float = maxf(0.0, bin_size.x * (1.0 - ratio))
		var plate_extra_height: float = _unit_gate_plate_extra_height()
		var closed_height: float = bin_size.y + plate_extra_height
		var active: bool = closed_width > UNIT_GATE_MIN_COLLISION_WIDTH
		var shape_width: float = maxf(UNIT_GATE_MIN_COLLISION_WIDTH, closed_width)
		var slot_left: float = bin.position.x - bin_size.x * 0.5
		var exposed_width: float = bin_size.x * ratio

		blocker.visible = active
		blocker.position = Vector2(slot_left + exposed_width + shape_width * 0.5, bin.position.y - plate_extra_height * 0.25)
		blocker.set_meta("exposure_ratio", ratio)
		blocker.set_meta("closed_width", closed_width)
		blocker.set_meta("is_closed", active)

		var shape_node: CollisionShape2D = blocker.get_node_or_null("GateShape") as CollisionShape2D
		if shape_node != null:
			shape_node.set_deferred("disabled", not active)
			var rectangle: RectangleShape2D = shape_node.shape as RectangleShape2D
			if rectangle == null:
				rectangle = RectangleShape2D.new()
				shape_node.shape = rectangle
			rectangle.set_deferred("size", Vector2(shape_width, closed_height))
		_update_gate_plate_visual(blocker, Vector2(shape_width, closed_height), ratio)

func _update_gate_plate_visual(blocker: StaticBody2D, plate_size: Vector2, ratio: float) -> void:
	var visual: Polygon2D = blocker.get_node_or_null("GatePlate") as Polygon2D
	if visual == null:
		return
	var visual_height: float = minf(_scaled(MACHINE_BIN_RAIL_HEIGHT, 4.0), 10.0)
	var visual_size := Vector2(plate_size.x, visual_height)
	visual.position = Vector2(0.0, -plate_size.y * 0.5 + visual_height * 0.5)
	visual.color = Color("#6d527a") if ratio > 0.0 else Color("#493750")
	visual.polygon = PackedVector2Array([
		Vector2(-visual_size.x * 0.5, -visual_size.y * 0.5),
		Vector2(visual_size.x * 0.5, -visual_size.y * 0.5),
		Vector2(visual_size.x * 0.5, visual_size.y * 0.5),
		Vector2(-visual_size.x * 0.5, visual_size.y * 0.5),
	])
	blocker.set_meta("blocker_collision_height", plate_size.y)
	blocker.set_meta("blocker_visual_height", visual_height)
	blocker.set_meta("blocker_visual_role", "thin_exposure_gate_strip")

func _add_peg(stage: String, peg_name: String, peg_position: Vector2, color: Color) -> void:
	var peg := StaticBody2D.new()
	peg.name = peg_name
	peg.position = peg_position
	peg.collision_layer = 0
	peg.collision_mask = 0
	peg.set_collision_layer_value(PEG_LAYER, true)
	peg.set_collision_mask_value(BALL_LAYER, true)
	peg.physics_material_override = _make_physics_material(PEG_BOUNCE, PEG_FRICTION)
	peg.set_meta("stage", stage)
	peg.set_meta("physics_role", "peg_bumper")
	peg.set_meta("peg_bumper", true)
	peg.set_meta("bounce", PEG_BOUNCE)
	peg.set_meta("friction", PEG_FRICTION)
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = _peg_radius()
	shape_node.shape = shape
	peg.add_child(shape_node)
	peg.add_child(_make_disc_visual(_peg_radius(), color, 10))
	get_node("StaticGeometry").add_child(peg)

func _add_stage_top_guard(stage: String, rect: Rect2, color: Color) -> void:
	var guard: StaticBody2D = _add_wall(
		stage + "TopBackflowGuard",
		rect.position + Vector2(rect.size.x * 0.5, STAGE_TOP_GUARD_THICKNESS * 0.5),
		Vector2(rect.size.x, STAGE_TOP_GUARD_THICKNESS),
		color.darkened(0.62)
	)
	guard.set_meta("stage", stage)
	guard.set_meta("physics_role", "stage_top_backflow_guard")
	guard.set_meta("stage_top_guard", true)
	guard.set_meta("prevents_upward_stage_escape", true)
	guard.set_meta("guarded_stage_top_y", rect.position.y)

func _add_wall(wall_name: String, wall_position: Vector2, wall_size: Vector2, color: Color) -> StaticBody2D:
	var wall := StaticBody2D.new()
	wall.name = wall_name
	wall.position = wall_position
	wall.collision_layer = 0
	wall.collision_mask = 0
	wall.set_collision_layer_value(PEG_LAYER, true)
	wall.set_collision_mask_value(BALL_LAYER, true)
	wall.physics_material_override = _make_physics_material(WALL_BOUNCE, WALL_FRICTION)
	wall.set_meta("physics_role", "wall_bumper")
	wall.set_meta("bounce", WALL_BOUNCE)
	wall.set_meta("friction", WALL_FRICTION)
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = wall_size
	shape_node.shape = shape
	wall.add_child(shape_node)
	var visual := Polygon2D.new()
	visual.color = color
	visual.polygon = PackedVector2Array([
		Vector2(-wall_size.x * 0.5, -wall_size.y * 0.5),
		Vector2(wall_size.x * 0.5, -wall_size.y * 0.5),
		Vector2(wall_size.x * 0.5, wall_size.y * 0.5),
		Vector2(-wall_size.x * 0.5, wall_size.y * 0.5),
	])
	wall.add_child(visual)
	get_node("StaticGeometry").add_child(wall)
	return wall

func _add_bin(stage: String, label: String, bin_position: Vector2, bin_size: Vector2, index: int, color: Color) -> void:
	var bin := Area2D.new()
	bin.name = _bin_name(stage, label)
	bin.position = bin_position
	bin.collision_layer = 0
	bin.collision_mask = 0
	bin.set_collision_layer_value(BIN_LAYER, true)
	bin.set_collision_mask_value(BALL_LAYER, true)
	bin.set_meta("stage", stage)
	bin.set_meta("label", label)
	bin.set_meta("slot_id", index + 1)
	bin.set_meta("value", _value_for_stage_label(stage, label))
	bin.set_meta("bin_size", bin_size)
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = bin_size
	shape_node.shape = shape
	bin.add_child(shape_node)
	var visual := Polygon2D.new()
	var visual_height: float = _scaled(MACHINE_BIN_RAIL_HEIGHT, 4.0)
	var visual_top: float = bin_size.y * 0.5 - visual_height
	visual.color = color.darkened(0.72)
	bin.set_meta("visual_role", "landing_rail")
	bin.set_meta("visual_height", visual_height)
	visual.polygon = PackedVector2Array([
		Vector2(-bin_size.x * 0.5, visual_top),
		Vector2(bin_size.x * 0.5, visual_top),
		Vector2(bin_size.x * 0.5, visual_top + visual_height),
		Vector2(-bin_size.x * 0.5, visual_top + visual_height),
	])
	bin.add_child(visual)
	bin.body_entered.connect(_on_bin_body_entered.bind(bin))
	get_node("Bins").add_child(bin)
	_stage_bins["%s:%s" % [stage, label]] = bin

func _add_stage_bottom_catcher(stage: String, labels: Array[String], rect: Rect2) -> void:
	var desired_height: float = maxf(_scaled(STAGE_BOTTOM_CATCHER_HEIGHT), _ball_radius() * 3.0)
	var catcher_size := Vector2(rect.size.x, minf(desired_height, rect.size.y * 0.36))
	var catcher := Area2D.new()
	catcher.name = "%sBottomCatchAll" % stage
	catcher.position = Vector2(rect.get_center().x, rect.end.y - catcher_size.y * 0.5)
	catcher.collision_layer = 0
	catcher.collision_mask = 0
	catcher.set_collision_layer_value(BIN_LAYER, true)
	catcher.set_collision_mask_value(BALL_LAYER, true)
	catcher.set_meta("stage", stage)
	catcher.set_meta("stage_catch_all", true)
	catcher.set_meta("labels", labels.duplicate())
	catcher.set_meta("bin_size", catcher_size)
	catcher.set_meta("visual_role", "stage_bottom_catch_all")

	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = catcher_size
	shape_node.shape = shape
	catcher.add_child(shape_node)
	catcher.body_entered.connect(_on_bin_body_entered.bind(catcher))
	get_node("Bins").add_child(catcher)

func _build_launcher_turret(color: Color) -> void:
	var static_geometry: Node = get_node_or_null("StaticGeometry")
	if static_geometry == null:
		return
	if static_geometry.get_node_or_null("LaunchSwingingTurret") != null:
		return
	var turret := Node2D.new()
	turret.name = "LaunchSwingingTurret"
	turret.z_index = 24
	turret.z_as_relative = false
	turret.set_meta("stage", "Launch")
	turret.set_meta("visual_role", "automatic_swinging_launcher_turret")
	turret.set_meta("automatic", true)
	turret.set_meta("player_controlled", false)
	turret.set_meta("swinging", true)
	static_geometry.add_child(turret)

	var sweep := Line2D.new()
	sweep.name = "SwingArc"
	sweep.default_color = color.darkened(0.45)
	sweep.width = 1.4
	sweep.points = _launcher_swing_arc_points()
	turret.add_child(sweep)

	var base := _make_disc_visual(7.5, color.darkened(0.15), 16)
	base.name = "TurretBase"
	turret.add_child(base)

	var barrel := Line2D.new()
	barrel.name = "TurretBarrel"
	barrel.default_color = color
	barrel.width = 5.0
	barrel.points = PackedVector2Array([Vector2.ZERO, Vector2(0.0, LAUNCHER_BARREL_LENGTH)])
	turret.add_child(barrel)

	var muzzle := _make_disc_visual(4.6, Color("#f4f0d8"), 12)
	muzzle.name = "Muzzle"
	muzzle.position = Vector2(0.0, LAUNCHER_BARREL_LENGTH)
	turret.add_child(muzzle)

func _launcher_swing_arc_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	for index: int in range(13):
		var ratio: float = float(index) / 12.0
		var angle: float = lerpf(-LAUNCHER_SWING_MAX_ANGLE, LAUNCHER_SWING_MAX_ANGLE, ratio)
		points.append(_launcher_direction(angle) * (LAUNCHER_BARREL_LENGTH + 7.0))
	return points

func _ensure_preview_ball() -> void:
	if active_ball != null and is_instance_valid(active_ball):
		return
	if _find_first_child_of_type(self, "RigidBody2D") != null:
		return
	var preview := _make_ball(MachineBallPayloadScript.clean("preview"))
	preview.set_meta("chain_id", "preview")
	preview.set_meta("payload", MachineBallPayloadScript.clean("preview"))
	preview.name = "ActiveBall"
	preview.freeze = true
	preview.visible = true
	active_ball = preview
	add_child(preview)
	_position_preview_ball_at_launcher_muzzle()

func _make_ball(ball: Dictionary) -> RigidBody2D:
	var payload: Dictionary = MachineBallPayloadScript.normalize(ball)
	var body: RigidBody2D = MachinePhysicsBallBodyScript.new() as RigidBody2D
	body.gravity_scale = BALL_GRAVITY_SCALE
	body.linear_damp = 0.0
	body.angular_damp = 0.02
	body.can_sleep = false
	body.contact_monitor = true
	body.max_contacts_reported = 4
	body.continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	body.collision_layer = 0
	body.collision_mask = 0
	body.set_collision_layer_value(BALL_LAYER, true)
	body.set_collision_mask_value(PEG_LAYER, true)
	body.physics_material_override = _make_physics_material(BALL_BOUNCE, BALL_FRICTION)
	body.set_meta("physics_role", "machine_ball")
	body.set_meta("bounce", BALL_BOUNCE)
	body.set_meta("friction", BALL_FRICTION)
	body.set_meta("ball_kind", String(payload.get("kind", "clean")))
	body.set_meta("ball_value", int(payload.get("value", 1)))
	body.set_meta("chain_id", String(payload.get("chain_id", "")))
	body.set_meta("payload", payload.duplicate(true))
	body.set_meta("stage", "Launch")
	body.set_meta("tuning_result_id", "Gate")
	body.set_meta("tuning_value", 1)
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = _ball_radius()
	shape_node.shape = shape
	body.add_child(shape_node)
	var ball_color: Color = Color("#f4f0d8") if String(payload.get("kind", "clean")) != "junk" else Color("#6f5f35")
	body.add_child(_make_disc_visual(_ball_radius(), ball_color, 18))
	body.body_entered.connect(_on_ball_body_entered.bind(body))
	return body

func _place_body_for_stage_runtime(body: RigidBody2D, stage: String, battle_elapsed: float) -> void:
	set_battle_elapsed(battle_elapsed)
	var rect: Rect2 = _stage_rect(stage)
	var phase: float = float(_launch_index % 17) / 17.0 * TAU
	var swing_x: float = sin(phase) * rect.size.x * 0.28
	body.set_meta("stage", stage)
	_configure_body_stage_top_guard(body, stage)
	body.set_meta("resolving_stage", false)
	body.set_meta("battle_elapsed", battle_elapsed)
	body.freeze = false
	body.sleeping = false
	if stage == "Launch":
		var launch_angle: float = _launcher_angle_for_current_time()
		var launch_direction: Vector2 = _launcher_direction(launch_angle)
		var launch_origin: Vector2 = _launcher_muzzle_position(launch_angle)
		_last_launch_origin = launch_origin
		_last_launch_velocity = launch_direction * LAUNCHER_MUZZLE_SPEED
		_last_launch_angle = launch_angle
		body.position = launch_origin
		body.linear_velocity = _last_launch_velocity
		body.angular_velocity = launch_angle * 2.2
		body.set_meta("launch_origin", launch_origin)
		body.set_meta("launch_velocity", _last_launch_velocity)
		body.set_meta("launcher_angle", launch_angle)
	else:
		body.position = Vector2(rect.get_center().x + swing_x, _stage_entry_y(stage))
		body.linear_velocity = Vector2(sin(phase) * STAGE_ENTRY_SIDE_SPEED, STAGE_ENTRY_DOWN_SPEED)
		body.angular_velocity = sin(phase) * 1.2
		body.set_meta("last_stage_flow_impulse_seconds", -999.0)
	body.reset_physics_interpolation()

func _target_label_for_verifier_step(stage: String, step: int) -> String:
	match stage:
		"Launch":
			var pattern: Array[String] = ["Tuning", "Tuning", "Split", "Tuning", "Recycle", "Tuning", "Waste", "Tuning"]
			return pattern[(step - 1) % pattern.size()]
		"Tuning":
			var pattern: Array[String] = ["Gate", "Prime", "Gate", "Echo", "Gate", "Surge"]
			return pattern[(step - 1) % pattern.size()]
		"Unit":
			var pattern: Array[String] = ["S1", "S1", "S2", "S1", "S2", "S3", "S1", "S4"]
			return pattern[(step - 1) % pattern.size()]
		_:
			return ""

func _on_bin_body_entered(body: Node2D, bin: Area2D) -> void:
	if not (body is RigidBody2D):
		return
	var rigid_body: RigidBody2D = body as RigidBody2D
	var current_stage: String = String(rigid_body.get_meta("stage", ""))
	var bin_stage: String = String(bin.get_meta("stage", ""))
	if current_stage != bin_stage:
		return
	if bool(rigid_body.get_meta("resolving_stage", false)):
		return
	if bool(bin.get_meta("stage_catch_all", false)):
		var routed_bin: Area2D = _bin_for_stage_x(bin_stage, rigid_body.position.x)
		if routed_bin == null:
			return
		bin = routed_bin
	rigid_body.set_meta("battle_elapsed", _battle_elapsed)
	rigid_body.set_meta("resolving_stage", true)
	if bin_stage == "Unit" and _is_unit_gate_blocking_contact(rigid_body, bin):
		var bounce_record: Dictionary = _record_blocked_unit_bounce(rigid_body, bin)
		if bool(bounce_record.get("terminal", false)):
			call_deferred("_retire_body_after_blocked_unit_gate", rigid_body)
		else:
			call_deferred("_bounce_body_from_blocked_unit_gate", rigid_body, bin)
		return
	if bin_stage == "Tuning":
		var natural_label: String = String(bin.get_meta("label", ""))
		var redirect: Dictionary = _resolve_tuning_redirect(natural_label, rigid_body)
		var final_label: String = String(redirect.get("final_result_id", natural_label))
		if final_label != natural_label:
			_emit_forced_redirect(rigid_body, bin, redirect)
			return
	var result: MachinePhysicsResult = _result_from_bin(rigid_body, bin)
	_record_landing(result)
	landing_resolved.emit(result)
	call_deferred("_advance_body_after_landing", rigid_body, result)

func _on_ball_body_entered(collided_body: Node, ball_body: RigidBody2D) -> void:
	if ball_body == null or not is_instance_valid(ball_body):
		return
	if collided_body == null:
		return
	if bool(collided_body.get_meta("unit_gate_blocker", false)):
		call_deferred("_bounce_body_from_unit_gate_blocker_contact", ball_body, collided_body)
		return
	if bool(collided_body.get_meta("peg_bumper", false)):
		call_deferred("_bounce_body_from_fixed_peg_contact", ball_body, collided_body)

func _bounce_body_from_unit_gate_blocker_contact(body: RigidBody2D, blocker_node: Node) -> void:
	if not is_instance_valid(body) or blocker_node == null:
		return
	var now_seconds: float = float(Time.get_ticks_msec()) / 1000.0
	var last_rebound_seconds: float = float(body.get_meta("last_unit_gate_contact_rebound_seconds", -999.0))
	if now_seconds - last_rebound_seconds < UNIT_GATE_CONTACT_REBOUND_INTERVAL_SECONDS:
		return
	body.set_meta("last_unit_gate_contact_rebound_seconds", now_seconds)

	var blocker: Node2D = blocker_node as Node2D
	var slot_id: int = int(blocker_node.get_meta("slot_id", 1))
	var battle_elapsed: float = float(body.get_meta("battle_elapsed", _battle_elapsed))
	var target_slot_id: int = _open_unit_slot_for_bounce(slot_id, battle_elapsed)
	var target_x: float = _unit_slot_target_x(target_slot_id, battle_elapsed)
	var side_delta: float = target_x - body.position.x
	var side_sign: float = 0.0
	if side_delta < 0.0:
		side_sign = -1.0
	elif side_delta > 0.0:
		side_sign = 1.0
	if is_zero_approx(side_sign):
		side_sign = -1.0 if body.position.x <= (blocker.position.x if blocker != null else body.position.x) else 1.0
	var previous_speed: float = maxf(body.linear_velocity.length(), UNIT_GATE_CONTACT_REBOUND_SPEED)
	var rebound_velocity := Vector2(
		side_sign * maxf(UNIT_GATE_CONTACT_REBOUND_SPEED, previous_speed * 0.75),
		-UNIT_GATE_CONTACT_REBOUND_UP_SPEED
	)

	unit_gate_contact_rebound_count += 1
	last_unit_gate_contact_rebound = {
		"slot_id": slot_id,
		"target_slot_id": target_slot_id,
		"battle_elapsed": battle_elapsed,
		"ball_position_before": body.position,
		"rebound_velocity": rebound_velocity,
		"speed": rebound_velocity.length(),
		"source": "unit_gate_contact",
		"chain_id": String(body.get_meta("chain_id", "")),
	}
	body.set_meta("last_unit_gate_contact_rebound", last_unit_gate_contact_rebound.duplicate(true))
	body.set_meta("stage", "Unit")
	_configure_body_stage_top_guard(body, "Unit")
	body.set_meta("resolving_stage", false)
	body.freeze = false
	body.sleeping = false
	body.position += rebound_velocity.normalized() * UNIT_GATE_CONTACT_REBOUND_NUDGE
	body.linear_velocity = rebound_velocity
	body.angular_velocity = side_sign * 5.5
	body.reset_physics_interpolation()

func _bounce_body_from_fixed_peg_contact(body: RigidBody2D, peg_node: Node) -> void:
	if not is_instance_valid(body) or peg_node == null:
		return
	var now_seconds: float = float(Time.get_ticks_msec()) / 1000.0
	var last_rebound_seconds: float = float(body.get_meta("last_fixed_peg_rebound_seconds", -999.0))
	if now_seconds - last_rebound_seconds < FIXED_PEG_REBOUND_INTERVAL_SECONDS:
		return
	body.set_meta("last_fixed_peg_rebound_seconds", now_seconds)
	var before_velocity: Vector2 = body.linear_velocity
	var normal: Vector2 = _fixed_peg_contact_normal(body, peg_node)
	if normal.length() <= 0.001:
		return
	var incoming: Vector2 = before_velocity
	if incoming.length() < 1.0:
		incoming = -normal * FIXED_PEG_REBOUND_MIN_SPEED
	var reflected: Vector2 = incoming
	if incoming.dot(normal) < 0.0:
		reflected = incoming - normal * (2.0 * incoming.dot(normal))
	else:
		reflected = -normal * maxf(incoming.length(), FIXED_PEG_REBOUND_MIN_SPEED)
	var rebound_speed: float = maxf(reflected.length() * FIXED_PEG_REBOUND_SPEED_MULTIPLIER, FIXED_PEG_REBOUND_MIN_SPEED)
	var after_velocity: Vector2 = reflected.normalized() * rebound_speed
	if normal.y < -0.15 and after_velocity.y > -FIXED_PEG_REBOUND_MIN_UP_SPEED:
		after_velocity.y = -FIXED_PEG_REBOUND_MIN_UP_SPEED
		after_velocity = after_velocity.normalized() * maxf(after_velocity.length(), rebound_speed)
	body.linear_velocity = after_velocity
	body.angular_velocity += clampf(after_velocity.x / 42.0, -6.0, 6.0)
	body.sleeping = false
	body.reset_physics_interpolation()
	fixed_peg_rebound_count += 1
	last_fixed_peg_rebound = {
		"source": "fixed_peg_rebound",
		"stage": String(peg_node.get_meta("stage", body.get_meta("stage", ""))),
		"peg_name": peg_node.name,
		"chain_id": String(body.get_meta("chain_id", "")),
		"normal": normal,
		"before_velocity": before_velocity,
		"after_velocity": after_velocity,
		"min_speed": FIXED_PEG_REBOUND_MIN_SPEED,
		"min_up_speed": FIXED_PEG_REBOUND_MIN_UP_SPEED,
	}
	body.set_meta("last_fixed_peg_rebound", last_fixed_peg_rebound.duplicate(true))

func _fixed_peg_contact_normal(body: RigidBody2D, peg_node: Node) -> Vector2:
	var peg_node_2d: Node2D = peg_node as Node2D
	if peg_node_2d == null:
		return Vector2.ZERO
	var delta: Vector2 = body.global_position - peg_node_2d.global_position
	if delta.length() <= 0.001:
		if body.linear_velocity.length() > 0.001:
			return -body.linear_velocity.normalized()
		return Vector2.UP
	return delta.normalized()

func _resolve_tuning_redirect(natural_result_id: String, body: RigidBody2D) -> Dictionary:
	redirect_requested.emit(natural_result_id, body)
	if _redirect_resolver.is_valid():
		var redirect_variant: Variant = _redirect_resolver.call(natural_result_id)
		if redirect_variant is Dictionary:
			var redirect: Dictionary = redirect_variant as Dictionary
			if not redirect.has("final_result_id"):
				redirect["final_result_id"] = natural_result_id
			if not redirect.has("feedback_state"):
				redirect["feedback_state"] = "Forced Redirect" if String(redirect.get("final_result_id", natural_result_id)) != natural_result_id else "Natural Hit"
			return redirect
	return resolve_redirect_for_verifier(natural_result_id)

func _emit_forced_redirect(body: RigidBody2D, bin: Area2D, redirect: Dictionary) -> void:
	var natural_label: String = String(bin.get_meta("label", ""))
	var final_label: String = String(redirect.get("final_result_id", natural_label))
	var final_bin: Area2D = _stage_bins.get("Tuning:%s" % final_label, bin) as Area2D
	if final_bin == null:
		final_bin = bin
		final_label = natural_label
	var final_center: Vector2 = _bin_center("Tuning", final_label)
	_show_redirect_guide(bin.position, final_center, String(redirect.get("forced_by", "")))
	body.position = final_center + Vector2(0.0, -10.0)
	body.reset_physics_interpolation()
	var result: MachinePhysicsResult = _result_from_bin(body, final_bin)
	result.natural_result_id = natural_label
	result.forced_by = String(redirect.get("forced_by", ""))
	result.feedback_state = "Forced Redirect"
	_record_landing(result)
	landing_resolved.emit(result)
	call_deferred("_advance_body_after_landing", body, result)

func _show_redirect_guide(from_position: Vector2, to_position: Vector2, forced_by: String) -> void:
	var existing: Node = get_node_or_null("RedirectGuide")
	if existing != null:
		remove_child(existing)
		existing.queue_free()
	var guide := Line2D.new()
	guide.name = "RedirectGuide"
	guide.z_index = 30
	guide.default_color = Color("#f4f0d8")
	guide.width = 3.0
	guide.points = PackedVector2Array([from_position, to_position])
	guide.set_meta("feedback_state", "Forced Redirect")
	guide.set_meta("forced_by", forced_by)
	add_child(guide)

func _is_unit_gate_blocking_contact(body: RigidBody2D, bin: Area2D) -> bool:
	var slot_id: int = int(bin.get_meta("slot_id"))
	var battle_elapsed: float = float(body.get_meta("battle_elapsed", _battle_elapsed))
	var ratio: float = _slot_exposure_ratio(slot_id, battle_elapsed)
	if ratio >= 1.0:
		return false
	if _exposure_state != null and not bool(_exposure_state.call("is_slot_open_for_progress", slot_id, battle_elapsed)):
		return true
	if ratio <= 0.0:
		return true

	var bin_size: Vector2 = _bin_size(bin)
	var slot_left: float = bin.global_position.x - bin_size.x * 0.5
	var exposed_right: float = slot_left + bin_size.x * ratio
	return body.global_position.x > exposed_right

func _record_blocked_unit_bounce(body: RigidBody2D, bin: Area2D) -> Dictionary:
	var slot_id: int = int(bin.get_meta("slot_id"))
	var battle_elapsed: float = float(body.get_meta("battle_elapsed", _battle_elapsed))
	var target_slot_id: int = _open_unit_slot_for_bounce(slot_id, battle_elapsed)
	var ratio: float = _slot_exposure_ratio(slot_id, battle_elapsed)
	var per_ball_bounce_count: int = int(body.get_meta("blocked_bounce_count", 0)) + 1
	var terminal: bool = per_ball_bounce_count >= MAX_BLOCKED_BOUNCES_PER_BALL
	var message: String = "Unit：S%d 暴露闸门挡开，球终止" % slot_id if terminal else "Unit：S%d 暴露闸门挡开，球转向 S%d" % [slot_id, target_slot_id]
	blocked_bounce_count += 1
	last_blocked_bounce = {
		"component": "Unit",
		"result_id": "BlockedBounce",
		"slot_id": slot_id,
		"target_slot_id": target_slot_id,
		"battle_elapsed": battle_elapsed,
		"exposure_ratio": ratio,
		"per_ball_bounce_count": per_ball_bounce_count,
		"max_blocked_bounces": MAX_BLOCKED_BOUNCES_PER_BALL,
		"terminal": terminal,
		"source": "physics",
		"chain_id": String(body.get_meta("chain_id", "")),
		"message": message,
	}
	body.set_meta("blocked_bounce_count", per_ball_bounce_count)
	body.set_meta("last_blocked_slot_id", slot_id)
	body.set_meta("blocked_bounce_target_slot_id", target_slot_id)
	body.set_meta("last_blocked_bounce_message", message)
	return last_blocked_bounce.duplicate(true)

func _bounce_body_from_blocked_unit_gate(body: RigidBody2D, _bin: Area2D) -> void:
	if not is_instance_valid(body):
		return
	var battle_elapsed: float = float(body.get_meta("battle_elapsed", _battle_elapsed))
	var target_slot_id: int = int(body.get_meta("blocked_bounce_target_slot_id", _open_unit_slot_for_bounce(1, battle_elapsed)))
	var target_x: float = _unit_slot_target_x(target_slot_id, battle_elapsed)
	body.set_meta("stage", "Unit")
	_configure_body_stage_top_guard(body, "Unit")
	body.set_meta("resolving_stage", false)
	body.position = Vector2(target_x, _stage_entry_y("Unit"))
	body.linear_velocity = Vector2((target_x - _stage_rect("Unit").get_center().x) * 0.2, STAGE_ENTRY_DOWN_SPEED)
	body.angular_velocity = 0.0
	body.freeze = false
	body.sleeping = false
	body.reset_physics_interpolation()

func _retire_body_after_blocked_unit_gate(body: RigidBody2D) -> void:
	if not is_instance_valid(body):
		return
	var slot_id: int = int(body.get_meta("last_blocked_slot_id", 0))
	if slot_id <= 0:
		slot_id = int(body.get_meta("blocked_bounce_target_slot_id", 1))
	var result := MachinePhysicsResult.make(
		"Unit",
		"ExposureBlocked",
		clampi(slot_id, 1, 4),
		0,
		String(body.get_meta("ball_kind", "clean")),
		"physics",
		String(body.get_meta("chain_id", "")),
		float(body.get_meta("battle_elapsed", _battle_elapsed))
	)
	_record_landing(result)
	landing_resolved.emit(result)
	_retire_body(body)

func _result_from_bin(body: RigidBody2D, bin: Area2D) -> MachinePhysicsResult:
	var stage: String = String(bin.get_meta("stage"))
	var label: String = String(bin.get_meta("label"))
	var slot_id: int = int(bin.get_meta("slot_id"))
	var value: int = int(bin.get_meta("value"))
	var result_id: String = label
	if stage == "Unit":
		result_id = "UnitHit"
	var result := MachinePhysicsResult.make(
		stage,
		result_id,
		slot_id if stage == "Unit" else 0,
		value,
		String(body.get_meta("ball_kind", "clean")),
		"physics",
		String(body.get_meta("chain_id", "")),
		float(body.get_meta("battle_elapsed", 0.0))
	)
	return result

func _record_landing(result: MachinePhysicsResult) -> void:
	physics_landing_count += 1
	last_physics_result = result.to_dictionary()

func _advance_body_after_landing(body: RigidBody2D, result: MachinePhysicsResult) -> void:
	if not is_instance_valid(body):
		return
	match result.component:
		"Launch":
			if result.result_id == "Tuning":
				_place_body_for_stage_runtime(body, "Tuning", result.battle_elapsed)
			else:
				_retire_body(body)
		"Tuning":
			body.set_meta("tuning_result_id", result.result_id)
			body.set_meta("tuning_value", maxi(1, result.value))
			_place_body_for_stage_runtime(body, "Unit", result.battle_elapsed)
		"Unit":
			_retire_body(body)
		_:
			_retire_body(body)

func _retire_body(body: RigidBody2D) -> void:
	body.freeze = true
	body.linear_velocity = Vector2.ZERO
	body.angular_velocity = 0.0
	body.modulate = Color(1.0, 1.0, 1.0, 0.45)
	body.set_meta("stage", "Retired")
	if not _retired_balls.has(body):
		_retired_balls.append(body)
	_prune_retired_balls()
	_queue_free_retired_body_after_dwell(body)

func _queue_free_retired_body_after_dwell(body: RigidBody2D) -> void:
	if not is_inside_tree():
		_release_retired_body(body)
		return
	await get_tree().create_timer(RETIRED_BALL_DWELL_SECONDS).timeout
	if not is_instance_valid(self) or not is_inside_tree():
		return
	_release_retired_body(body)

func _release_retired_body(body: RigidBody2D) -> void:
	_retired_balls.erase(body)
	if body == active_ball:
		active_ball = null
	if is_instance_valid(body):
		body.queue_free()
	call_deferred("_ensure_preview_ball_if_empty")

func _prune_retired_balls() -> void:
	while _retired_balls.size() > MAX_RETIRED_BALLS:
		var body: RigidBody2D = _retired_balls.pop_front()
		if body == active_ball:
			active_ball = null
		if is_instance_valid(body):
			body.queue_free()

func _ensure_preview_ball_if_empty() -> void:
	if not is_inside_tree():
		return
	_ensure_preview_ball()

func _remove_preview_ball() -> void:
	for child: Node in get_children():
		if child is RigidBody2D and String(child.get_meta("chain_id", "")) == "preview":
			if child == active_ball:
				active_ball = null
			child.queue_free()

func _stage_rect(stage: String) -> Rect2:
	if _stage_rects.has(stage) and _stage_rects[stage] is Rect2:
		return _stage_rects[stage] as Rect2
	return Rect2(Vector2.ZERO, Vector2(DEFAULT_STAGE_WIDTH, DEFAULT_STAGE_HEIGHT))

func _stage_rect_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for stage: String in ["Launch", "Tuning", "Unit"]:
		var rect: Rect2 = _stage_rect(stage)
		snapshot[stage] = {
			"position": rect.position,
			"size": rect.size,
			"entry_y": _stage_entry_y(stage),
		}
	return snapshot

func _rotated_rectangle_bounds(center: Vector2, rect_size: Vector2, rotation: float) -> Rect2:
	var half: Vector2 = rect_size * 0.5
	var corners: Array[Vector2] = [
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	]
	var min_point := Vector2(INF, INF)
	var max_point := Vector2(-INF, -INF)
	for corner: Vector2 in corners:
		var point: Vector2 = center + corner.rotated(rotation)
		min_point.x = minf(min_point.x, point.x)
		min_point.y = minf(min_point.y, point.y)
		max_point.x = maxf(max_point.x, point.x)
		max_point.y = maxf(max_point.y, point.y)
	return Rect2(min_point, max_point - min_point)

func _stage_entry_y(stage: String) -> float:
	var rect: Rect2 = _stage_rect(stage)
	return rect.position.y + STAGE_TOP_GUARD_THICKNESS + _ball_radius() + STAGE_TOP_GUARD_CLEARANCE

func _bin_center(stage: String, label: String) -> Vector2:
	var key: String = "%s:%s" % [stage, label]
	if _stage_bins.has(key):
		var bin: Area2D = _stage_bins[key] as Area2D
		if bin != null:
			return bin.position
	var rect: Rect2 = _stage_rect(stage)
	return rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 14.0)

func _unit_bin(slot_id: int) -> Area2D:
	var key: String = "Unit:S%d" % slot_id
	if _stage_bins.has(key):
		return _stage_bins[key] as Area2D
	return null

func _update_launcher_turret() -> void:
	var turret: Node2D = get_node_or_null("StaticGeometry/LaunchSwingingTurret") as Node2D
	if turret == null:
		return
	var angle: float = _launcher_angle_for_current_time()
	turret.position = _launcher_pivot_position()
	turret.rotation = angle
	turret.visible = true
	var sweep: Node2D = turret.get_node_or_null("SwingArc") as Node2D
	if sweep != null:
		sweep.rotation = -angle
	turret.set_meta("angle", angle)
	turret.set_meta("swing_angle_min", -LAUNCHER_SWING_MAX_ANGLE)
	turret.set_meta("swing_angle_max", LAUNCHER_SWING_MAX_ANGLE)
	turret.set_meta("barrel_length", LAUNCHER_BARREL_LENGTH)
	turret.set_meta("muzzle_position", _launcher_current_muzzle_position())

func _position_preview_ball_at_launcher_muzzle() -> void:
	if active_ball == null or not is_instance_valid(active_ball):
		return
	if String(active_ball.get_meta("chain_id", "")) != "preview":
		return
	active_ball.position = _launcher_current_muzzle_position()
	active_ball.reset_physics_interpolation()

func _launcher_turret_snapshot() -> Dictionary:
	_update_launcher_turret()
	var turret: Node2D = get_node_or_null("StaticGeometry/LaunchSwingingTurret") as Node2D
	var angle: float = _launcher_angle_for_current_time()
	var visual_muzzle_position: Vector2 = _launcher_visual_muzzle_position_from_node()
	var muzzle_position: Vector2 = _launcher_current_muzzle_position()
	return {
		"visible": turret != null and turret.visible,
		"stage": "Launch",
		"visual_role": "automatic_swinging_launcher_turret",
		"automatic": true,
		"player_controlled": false,
		"swinging": true,
		"swing_cycle_seconds": LAUNCHER_SWING_CYCLE_SECONDS,
		"swing_angle_min": -LAUNCHER_SWING_MAX_ANGLE,
		"swing_angle_max": LAUNCHER_SWING_MAX_ANGLE,
		"current_angle": angle,
		"barrel_length": LAUNCHER_BARREL_LENGTH,
		"pivot_position": _launcher_pivot_position(),
		"muzzle_position": muzzle_position,
		"visual_muzzle_position": visual_muzzle_position,
		"muzzle_matches_visual": visual_muzzle_position is Vector2 and muzzle_position.distance_to(visual_muzzle_position) <= 0.5,
		"muzzle_direction": _launcher_direction(angle),
		"uses_muzzle_for_launch": true,
		"last_launch_origin": _last_launch_origin,
		"last_launch_velocity": _last_launch_velocity,
		"last_launch_angle": _last_launch_angle,
	}

func _launcher_angle_for_current_time() -> float:
	return _launcher_angle_for_phase(_launcher_phase_for_elapsed(_battle_elapsed))

func _launcher_phase_for_elapsed(seconds: float) -> float:
	return fmod(maxf(0.0, seconds), LAUNCHER_SWING_CYCLE_SECONDS) / LAUNCHER_SWING_CYCLE_SECONDS * TAU

func _launcher_angle_for_phase(phase: float) -> float:
	return sin(phase) * LAUNCHER_SWING_MAX_ANGLE

func _launcher_pivot_position() -> Vector2:
	var launch_rect: Rect2 = _stage_rect("Launch")
	return launch_rect.position + Vector2(launch_rect.size.x * 0.5, 18.0)

func _launcher_direction(angle: float) -> Vector2:
	return Vector2(-sin(angle), cos(angle)).normalized()

func _launcher_muzzle_position(angle: float) -> Vector2:
	return _launcher_pivot_position() + _launcher_direction(angle) * LAUNCHER_BARREL_LENGTH

func _launcher_current_muzzle_position() -> Vector2:
	var visual_muzzle_position: Vector2 = _launcher_visual_muzzle_position_from_node()
	if _is_finite_vector2(visual_muzzle_position):
		return visual_muzzle_position
	return _launcher_muzzle_position(_launcher_angle_for_current_time())

func _launcher_visual_muzzle_position_from_node() -> Vector2:
	var turret: Node2D = get_node_or_null("StaticGeometry/LaunchSwingingTurret") as Node2D
	if turret == null:
		return Vector2.INF
	var muzzle: Node2D = turret.get_node_or_null("Muzzle") as Node2D
	if muzzle == null:
		return Vector2.INF
	var static_geometry: Node2D = turret.get_parent() as Node2D
	if static_geometry == null:
		return turret.transform * muzzle.position
	return static_geometry.transform * (turret.transform * muzzle.position)

func _is_finite_vector2(value: Vector2) -> bool:
	return absf(value.x) < 1.0e20 and absf(value.y) < 1.0e20

func _active_ball_position() -> Vector2:
	if active_ball == null or not is_instance_valid(active_ball):
		return Vector2.INF
	return active_ball.position

func _active_ball_chain_id() -> String:
	if active_ball == null or not is_instance_valid(active_ball):
		return ""
	return String(active_ball.get_meta("chain_id", ""))

func _active_ball_at_visible_muzzle() -> bool:
	if active_ball == null or not is_instance_valid(active_ball):
		return false
	var visual_muzzle_position: Vector2 = _launcher_visual_muzzle_position_from_node()
	if not _is_finite_vector2(visual_muzzle_position):
		return false
	return active_ball.position.distance_to(visual_muzzle_position) <= 0.5

func _apply_stage_flow_forces() -> void:
	for child: Node in get_children():
		if not (child is RigidBody2D):
			continue
		var body: RigidBody2D = child as RigidBody2D
		if body.freeze or String(body.get_meta("chain_id", "")) == "preview":
			continue
		var stage: String = String(body.get_meta("stage", ""))
		if stage != "Tuning" and stage != "Unit":
			continue
		if bool(body.get_meta("resolving_stage", false)):
			continue
		_configure_body_stage_top_guard(body, stage)
		_consume_body_stage_backflow_guard_record(body)
		var phase: float = float(body.get_instance_id() % 29) * 0.37 + _battle_elapsed * 4.1
		body.apply_central_force(Vector2(sin(phase) * STAGE_FLOW_SIDE_FORCE, STAGE_FLOW_DOWN_FORCE))
		if body.linear_velocity.length() >= STAGE_STALL_SPEED:
			continue
		var now_seconds: float = float(Time.get_ticks_msec()) / 1000.0
		var last_impulse_seconds: float = float(body.get_meta("last_stage_flow_impulse_seconds", -999.0))
		if now_seconds - last_impulse_seconds < STAGE_STALL_IMPULSE_INTERVAL_SECONDS:
			continue
		var side_sign: float = -1.0 if cos(phase) < 0.0 else 1.0
		body.set_meta("last_stage_flow_impulse_seconds", now_seconds)
		body.apply_central_impulse(Vector2(side_sign * STAGE_STALL_SIDE_IMPULSE, STAGE_STALL_DOWN_IMPULSE))

func _configure_body_stage_top_guard(body: RigidBody2D, stage: String) -> void:
	if body == null or not body.has_method("configure_stage_top_guard"):
		return
	var enabled: bool = stage == "Tuning" or stage == "Unit"
	var global_limit_y: float = to_global(Vector2(0.0, _stage_entry_y(stage))).y
	body.call("configure_stage_top_guard", enabled, global_limit_y, STAGE_BACKFLOW_REBOUND_SPEED, stage)

func _consume_body_stage_backflow_guard_record(body: RigidBody2D) -> void:
	if body == null or not body.has_method("consume_stage_backflow_guard_record"):
		return
	var record: Dictionary = body.call("consume_stage_backflow_guard_record") as Dictionary
	if record.is_empty():
		return
	stage_backflow_guard_count += 1
	last_stage_backflow_guard = record.duplicate(true)
	body.set_meta("last_stage_backflow_guard", last_stage_backflow_guard.duplicate(true))

func _enforce_stage_top_bound(body: RigidBody2D, stage: String) -> void:
	var top_limit_y: float = _stage_entry_y(stage)
	if body.position.y >= top_limit_y:
		return
	stage_backflow_guard_count += 1
	last_stage_backflow_guard = {
		"stage": stage,
		"chain_id": String(body.get_meta("chain_id", "")),
		"position_before": body.position,
		"velocity_before": body.linear_velocity,
		"top_limit_y": top_limit_y,
		"source": "stage_top_backflow_guard",
	}
	body.position.y = top_limit_y
	body.linear_velocity = Vector2(
		body.linear_velocity.x * 0.45,
		maxf(absf(body.linear_velocity.y), STAGE_BACKFLOW_REBOUND_SPEED)
	)
	body.angular_velocity *= 0.5
	body.sleeping = false
	body.set_meta("last_stage_backflow_guard", last_stage_backflow_guard.duplicate(true))
	body.reset_physics_interpolation()

func _ball_stage_snapshot() -> Dictionary:
	var counts: Dictionary = {}
	var samples: Array[Dictionary] = []
	for child: Node in get_children():
		if not (child is RigidBody2D):
			continue
		var body: RigidBody2D = child as RigidBody2D
		var stage: String = String(body.get_meta("stage", ""))
		counts[stage] = int(counts.get(stage, 0)) + 1
		if samples.size() < 8:
			samples.append({
				"name": body.name,
				"stage": stage,
				"position": body.position,
				"velocity": body.linear_velocity,
				"resolving_stage": bool(body.get_meta("resolving_stage", false)),
				"chain_id": String(body.get_meta("chain_id", "")),
				"has_stage_guard_script": body.has_method("configure_stage_top_guard"),
				"stage_guard_enabled": bool(body.get("stage_top_guard_enabled")) if body.has_method("configure_stage_top_guard") else false,
				"stage_guard_limit_y": float(body.get("stage_top_limit_y")) if body.has_method("configure_stage_top_guard") else -INF,
				"integrate_tick_count": int(body.get("integrate_tick_count")) if body.has_method("configure_stage_top_guard") else 0,
			})
	return {
		"counts": counts,
		"samples": samples,
	}

func _unit_gate_visual_snapshot() -> Dictionary:
	var visuals: Dictionary = {}
	for slot_id: int in range(1, 5):
		var blocker: StaticBody2D = _unit_gate_blockers.get(slot_id, null) as StaticBody2D
		var bin: Area2D = _unit_bin(slot_id)
		visuals[slot_id] = {
			"slot_id": slot_id,
			"blocker_visible": blocker != null and blocker.visible,
			"blocker_z_index": blocker.z_index if blocker != null else 0,
			"exposure_ratio": float(blocker.get_meta("exposure_ratio", 0.0)) if blocker != null else 0.0,
			"closed_width": float(blocker.get_meta("closed_width", 0.0)) if blocker != null else 0.0,
			"blocker_visual_height": float(blocker.get_meta("blocker_visual_height", 0.0)) if blocker != null else 0.0,
			"blocker_collision_height": float(blocker.get_meta("blocker_collision_height", 0.0)) if blocker != null else 0.0,
			"blocker_visual_role": String(blocker.get_meta("blocker_visual_role", "")) if blocker != null else "",
			"bin_visual_role": String(bin.get_meta("visual_role", "")) if bin != null else "",
			"bin_visual_height": float(bin.get_meta("visual_height", 0.0)) if bin != null else 0.0,
		}
	return visuals

func _stage_top_guard_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for stage: String in ["Launch", "Tuning", "Unit"]:
		var rect: Rect2 = _stage_rect(stage)
		var guard: StaticBody2D = _stage_top_guard(stage)
		var guard_size: Vector2 = _static_rectangle_size(guard)
		var guard_bottom_y: float = guard.position.y + guard_size.y * 0.5 if guard != null else -INF
		snapshot[stage] = {
			"stage": stage,
			"has_guard": guard != null,
			"physics_role": String(guard.get_meta("physics_role", "")) if guard != null else "",
			"prevents_upward_stage_escape": bool(guard.get_meta("prevents_upward_stage_escape", false)) if guard != null else false,
			"stage_top_y": rect.position.y,
			"guard_top_y": guard.position.y - guard_size.y * 0.5 if guard != null else -INF,
			"guard_bottom_y": guard_bottom_y,
			"ball_contact_limit_y": guard_bottom_y + _ball_radius() if guard != null else -INF,
			"width": guard_size.x,
			"required_width": rect.size.x,
			"full_width": guard_size.x >= rect.size.x - 0.5,
		}
	return snapshot

func _stage_bottom_catcher_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for stage: String in ["Launch", "Tuning", "Unit"]:
		var rect: Rect2 = _stage_rect(stage)
		var catcher: Area2D = get_node_or_null("Bins/%sBottomCatchAll" % stage) as Area2D
		var catcher_size: Vector2 = _area_rectangle_size(catcher)
		snapshot[stage] = {
			"stage": stage,
			"has_catcher": catcher != null,
			"visual_role": String(catcher.get_meta("visual_role", "")) if catcher != null else "",
			"stage_catch_all": bool(catcher.get_meta("stage_catch_all", false)) if catcher != null else false,
			"top_y": catcher.position.y - catcher_size.y * 0.5 if catcher != null else INF,
			"bottom_y": catcher.position.y + catcher_size.y * 0.5 if catcher != null else -INF,
			"width": catcher_size.x,
			"required_width": rect.size.x,
			"height": catcher_size.y,
			"full_width": catcher_size.x >= rect.size.x - 0.5,
		}
	return snapshot

func _stage_top_guard(stage: String) -> StaticBody2D:
	return get_node_or_null("StaticGeometry/%sTopBackflowGuard" % stage) as StaticBody2D

func _static_rectangle_size(body: StaticBody2D) -> Vector2:
	if body == null:
		return Vector2.ZERO
	for child: Node in body.get_children():
		if child is CollisionShape2D:
			var shape_node: CollisionShape2D = child as CollisionShape2D
			var rectangle: RectangleShape2D = shape_node.shape as RectangleShape2D
			if rectangle != null:
				return rectangle.size
	return Vector2.ZERO

func _area_rectangle_size(area: Area2D) -> Vector2:
	if area == null:
		return Vector2.ZERO
	for child: Node in area.get_children():
		if child is CollisionShape2D:
			var shape_node: CollisionShape2D = child as CollisionShape2D
			var rectangle: RectangleShape2D = shape_node.shape as RectangleShape2D
			if rectangle != null:
				return rectangle.size
	return Vector2.ZERO

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
			if bin == null:
				continue
			var width: float = _bin_size(bin).x
			total_width += width
			stage_bins[String(bin.get_meta("label", ""))] = width
		var ratios: Dictionary = {}
		for label: String in stage_bins.keys():
			ratios[label] = float(stage_bins[label]) / maxf(total_width, 1.0)
		snapshot[stage] = ratios
	return snapshot

func _bin_order_snapshot() -> Dictionary:
	return {
		"Launch": _stage_labels("Launch"),
		"Tuning": _stage_labels("Tuning"),
		"Unit": _stage_labels("Unit"),
	}

func _bin_for_stage_x(stage: String, x_position: float) -> Area2D:
	var nearest_bin: Area2D = null
	var nearest_distance: float = INF
	for key_variant: Variant in _stage_bins.keys():
		var key: String = String(key_variant)
		if not key.begins_with(stage + ":"):
			continue
		var candidate: Area2D = _stage_bins[key_variant] as Area2D
		if candidate == null:
			continue
		var candidate_size: Vector2 = _bin_size(candidate)
		var left: float = candidate.position.x - candidate_size.x * 0.5
		var right: float = candidate.position.x + candidate_size.x * 0.5
		if x_position >= left and x_position <= right:
			return candidate
		var distance: float = absf(candidate.position.x - x_position)
		if nearest_bin == null or distance < nearest_distance:
			nearest_bin = candidate
			nearest_distance = distance
	return nearest_bin

func _bin_visual_snapshot() -> Dictionary:
	var visuals: Dictionary = {}
	var keys: Array = _stage_bins.keys()
	keys.sort()
	for key_variant: Variant in keys:
		var key: String = String(key_variant)
		var bin: Area2D = _stage_bins[key_variant] as Area2D
		if bin == null:
			continue
		visuals[key] = {
			"stage": String(bin.get_meta("stage", "")),
			"label": String(bin.get_meta("label", "")),
			"visual_role": String(bin.get_meta("visual_role", "")),
			"visual_height": float(bin.get_meta("visual_height", 0.0)),
		}
	return visuals

func _peg_count_snapshot() -> Dictionary:
	var counts: Dictionary = {
		"Launch": 0,
		"Tuning": 0,
		"Unit": 0,
	}
	var static_geometry: Node = get_node_or_null("StaticGeometry")
	if static_geometry == null:
		return counts
	for child: Node in static_geometry.get_children():
		if not bool(child.get_meta("peg_bumper", false)):
			continue
		var stage: String = String(child.get_meta("stage", ""))
		if counts.has(stage):
			counts[stage] = int(counts[stage]) + 1
	return counts

func _peg_grid_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for stage: String in ["Launch", "Tuning", "Unit"]:
		var layout: Array[Vector2] = _peg_layout_for_stage(stage)
		var min_x: float = INF
		var max_x: float = -INF
		var min_y: float = INF
		var max_y: float = -INF
		var rows: Dictionary = {}
		for point: Vector2 in layout:
			min_x = minf(min_x, point.x)
			max_x = maxf(max_x, point.x)
			min_y = minf(min_y, point.y)
			max_y = maxf(max_y, point.y)
			rows["%.3f" % point.y] = true
		snapshot[stage] = {
			"layout_type": "fixed_template",
			"template_count": layout.size(),
			"expected_count": layout.size(),
			"actual_count": int(_peg_count_snapshot().get(stage, 0)),
			"row_count": rows.size(),
			"min_x_ratio": min_x if layout.size() > 0 else 0.0,
			"max_x_ratio": max_x if layout.size() > 0 else 0.0,
			"min_y_ratio": min_y if layout.size() > 0 else 0.0,
			"max_y_ratio": max_y if layout.size() > 0 else 0.0,
		}
	return snapshot

func _moving_mechanism_count_snapshot() -> Dictionary:
	var counts: Dictionary = {
		"Launch": 0,
		"Tuning": 0,
		"Unit": 0,
	}
	var groups_by_stage: Dictionary = {
		"Launch": {},
		"Tuning": {},
		"Unit": {},
	}
	var mechanisms: Node = get_node_or_null("Mechanisms")
	if mechanisms == null:
		return counts
	for child: Node in mechanisms.get_children():
		if not bool(child.get_meta("moving_mechanism", false)):
			continue
		var stage: String = String(child.get_meta("stage", ""))
		if not groups_by_stage.has(stage):
			continue
		var group_name: String = String(child.get_meta("mechanism_group", child.name))
		var stage_groups: Dictionary = groups_by_stage[stage] as Dictionary
		stage_groups[group_name] = true
	for stage: String in counts.keys():
		var stage_groups: Dictionary = groups_by_stage[stage] as Dictionary
		counts[stage] = stage_groups.size()
	return counts

func _moving_mechanism_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	var mechanisms: Node = get_node_or_null("Mechanisms")
	if mechanisms == null:
		return snapshot
	var grouped_children: Dictionary = {}
	for child: Node in mechanisms.get_children():
		if child is AnimatableBody2D and bool(child.get_meta("moving_mechanism", false)):
			var group_name: String = String(child.get_meta("mechanism_group", child.name))
			var children: Array = grouped_children.get(group_name, []) as Array
			children.append(child)
			grouped_children[group_name] = children
	var names: Array = grouped_children.keys()
	names.sort()
	for mechanism_name_variant: Variant in names:
		var mechanism_name := String(mechanism_name_variant)
		var children: Array = grouped_children.get(mechanism_name, []) as Array
		if children.is_empty():
			continue
		var first_child: Node = children[0] as Node
		if first_child != null and bool(first_child.get_meta("moving_peg", false)):
			snapshot[mechanism_name] = _moving_peg_group_snapshot(mechanism_name, children)
	return snapshot

func _moving_peg_group_snapshot(group_name: String, children: Array) -> Dictionary:
	var first_body: AnimatableBody2D = children[0] as AnimatableBody2D
	if first_body == null:
		return {}
	var stage: String = String(first_body.get_meta("stage", ""))
	var stage_rect: Rect2 = _stage_rect(stage)
	var peg_positions: Array = []
	var row_indices: Dictionary = {}
	var bounds := Rect2()
	var sweep_bounds := Rect2()
	var has_bounds := false
	var has_sweep_bounds := false
	var all_visible := true
	var all_inside := true
	var peg_visuals_visible := true
	var max_body_size := Vector2.ZERO
	var minimum_alpha: float = 1.0
	for child_variant: Variant in children:
		var body: AnimatableBody2D = child_variant as AnimatableBody2D
		if body == null:
			continue
		_apply_moving_mechanism_transform(body)
		var radius: float = maxf(0.0, float(body.get_meta("peg_radius", 0.0)))
		var body_size := Vector2(radius * 2.0, radius * 2.0)
		max_body_size.x = maxf(max_body_size.x, body_size.x)
		max_body_size.y = maxf(max_body_size.y, body_size.y)
		var current_position_variant: Variant = body.get_meta("current_position", body.position)
		var current_position: Vector2 = current_position_variant as Vector2 if current_position_variant is Vector2 else body.position
		peg_positions.append(current_position)
		var peg_bounds := Rect2(current_position - body_size * 0.5, body_size)
		bounds = peg_bounds if not has_bounds else bounds.merge(peg_bounds)
		has_bounds = true
		var peg_sweep_bounds: Rect2 = _moving_peg_sweep_bounds(body, body_size)
		sweep_bounds = peg_sweep_bounds if not has_sweep_bounds else sweep_bounds.merge(peg_sweep_bounds)
		has_sweep_bounds = true
		all_visible = all_visible and body.visible
		all_inside = all_inside and stage_rect.grow(1.0).encloses(peg_bounds)
		row_indices[int(body.get_meta("row_index", 0))] = true
		var visual: Polygon2D = body.get_node_or_null("MovingPegVisual") as Polygon2D
		var ring: Line2D = body.get_node_or_null("MovingPegRing") as Line2D
		peg_visuals_visible = peg_visuals_visible and visual != null and visual.visible and ring != null and ring.visible
		if visual != null:
			minimum_alpha = minf(minimum_alpha, visual.color.a)
	var center: Vector2 = bounds.get_center() if has_bounds else Vector2.INF
	var expected_row_count: int = int(first_body.get_meta("row_count", row_indices.size()))
	var horizontal_visible_coverage_ratio: float = _horizontal_rect_coverage_ratio(bounds, stage_rect) if has_bounds else 0.0
	var horizontal_sweep_coverage_ratio: float = _horizontal_rect_coverage_ratio(sweep_bounds, stage_rect) if has_sweep_bounds else 0.0
	return {
		"node_type": "MovingPegGroup",
		"stage": stage,
		"physics_role": String(first_body.get_meta("physics_role", "")),
		"motion_role": String(first_body.get_meta("motion_role", "")),
		"motion_kind": String(first_body.get_meta("motion_kind", "")),
		"motion_profile": String(first_body.get_meta("motion_profile", "")),
		"uses_physics_time": bool(first_body.get_meta("uses_physics_time", false)),
		"changes_landing_locally": bool(first_body.get_meta("changes_landing_locally", false)),
		"does_not_replace_bin_widths": bool(first_body.get_meta("does_not_replace_bin_widths", false)),
		"cycle_seconds": float(first_body.get_meta("cycle_seconds", 0.0)),
		"motion_range": float(first_body.get_meta("motion_range", 0.0)),
		"motion_axis": first_body.get_meta("motion_axis", Vector2.RIGHT),
		"home_position": first_body.get_meta("home_position", Vector2.INF),
		"visible": all_visible and children.size() > 0,
		"has_large_plate": false,
		"peg_visuals_visible": peg_visuals_visible and children.size() > 0,
		"has_physical_peg_bodies": children.size() > 0,
		"peg_count": children.size(),
		"row_count": expected_row_count,
		"actual_row_count": row_indices.size(),
		"physical_body_count": children.size(),
		"peg_positions": peg_positions,
		"position": center,
		"rotation": 0.0,
		"body_size": bounds.size if has_bounds else Vector2.ZERO,
		"max_body_size": max_body_size,
		"bounds": bounds,
		"sweep_bounds": sweep_bounds,
		"stage_rect": stage_rect,
		"stage_rect_contains_center": stage_rect.has_point(center) if has_bounds else false,
		"stage_rect_intersects_bounds": bounds.intersects(stage_rect.grow(1.0)) if has_bounds else false,
		"all_pegs_inside_stage": all_inside and children.size() > 0,
		"horizontal_visible_coverage_ratio": horizontal_visible_coverage_ratio,
		"horizontal_sweep_coverage_ratio": horizontal_sweep_coverage_ratio,
		"minimum_visible_thickness": minf(max_body_size.x, max_body_size.y),
		"visual_alpha": minimum_alpha,
		"body_z_index": first_body.z_index,
		"body_z_as_relative": first_body.z_as_relative,
	}

func _moving_peg_sweep_bounds(body: AnimatableBody2D, body_size: Vector2) -> Rect2:
	var home_position_variant: Variant = body.get_meta("home_position", body.position)
	var home_position: Vector2 = home_position_variant as Vector2 if home_position_variant is Vector2 else body.position
	var axis_variant: Variant = body.get_meta("motion_axis", Vector2.RIGHT)
	var axis: Vector2 = axis_variant as Vector2 if axis_variant is Vector2 else Vector2.RIGHT
	if axis.length() <= 0.001:
		axis = Vector2.RIGHT
	axis = axis.normalized()
	var motion_range: float = maxf(0.0, float(body.get_meta("motion_range", 0.0)))
	var start_bounds := Rect2(home_position - axis * motion_range - body_size * 0.5, body_size)
	var end_bounds := Rect2(home_position + axis * motion_range - body_size * 0.5, body_size)
	return start_bounds.merge(end_bounds)

func _horizontal_rect_coverage_ratio(rect: Rect2, stage_rect: Rect2) -> float:
	if stage_rect.size.x <= 0.0:
		return 0.0
	var left: float = maxf(rect.position.x, stage_rect.position.x)
	var right: float = minf(rect.end.x, stage_rect.end.x)
	return clampf((right - left) / stage_rect.size.x, 0.0, 1.0)

func _physics_material_snapshot() -> Dictionary:
	var ball_material: PhysicsMaterial = active_ball.physics_material_override if active_ball != null and is_instance_valid(active_ball) else null
	var peg: StaticBody2D = _first_peg_body_for_stage("Launch")
	var wall: StaticBody2D = get_node_or_null("StaticGeometry/LaunchLeftWall") as StaticBody2D
	var gate: StaticBody2D = _unit_gate_blockers.get(2, null) as StaticBody2D
	var mechanism: AnimatableBody2D = _first_moving_mechanism_for_stage("Launch")
	return {
		"ball": _physics_material_to_snapshot(ball_material),
		"peg": _physics_material_to_snapshot(peg.physics_material_override if peg != null else null),
		"wall": _physics_material_to_snapshot(wall.physics_material_override if wall != null else null),
		"unit_gate": _physics_material_to_snapshot(gate.physics_material_override if gate != null else null),
		"moving_mechanism": _physics_material_to_snapshot(mechanism.physics_material_override if mechanism != null else null),
	}

func _first_peg_body_for_stage(stage: String) -> StaticBody2D:
	var static_geometry: Node = get_node_or_null("StaticGeometry")
	if static_geometry == null:
		return null
	for child: Node in static_geometry.get_children():
		if bool(child.get_meta("peg_bumper", false)) and String(child.get_meta("stage", "")) == stage:
			return child as StaticBody2D
	return null

func _first_moving_mechanism_for_stage(stage: String) -> AnimatableBody2D:
	var mechanisms: Node = get_node_or_null("Mechanisms")
	if mechanisms == null:
		return null
	for child: Node in mechanisms.get_children():
		if child is AnimatableBody2D and bool(child.get_meta("moving_mechanism", false)) and String(child.get_meta("stage", "")) == stage:
			return child as AnimatableBody2D
	return null

func _physics_material_to_snapshot(material: PhysicsMaterial) -> Dictionary:
	if material == null:
		return {
			"has_material": false,
			"bounce": 0.0,
			"friction": 1.0,
		}
	return {
		"has_material": true,
		"bounce": material.bounce,
		"friction": material.friction,
	}

func _make_physics_material(bounce: float, friction: float) -> PhysicsMaterial:
	var material := PhysicsMaterial.new()
	material.bounce = bounce
	material.friction = friction
	return material

func _scaled(value: float, min_value: float = 0.0) -> float:
	return maxf(min_value, value * _layout_physics_scale)

func _ball_radius() -> float:
	return _scaled(BALL_RADIUS, 4.0)

func _peg_radius() -> float:
	return _scaled(PEG_RADIUS, 3.0)

func _moving_peg_radius() -> float:
	return _scaled(MOVING_PEG_RADIUS, 4.0)

func _wall_thickness() -> float:
	return _scaled(WALL_THICKNESS, 4.0)

func _mechanism_thickness() -> float:
	return _scaled(MECHANISM_THICKNESS, 10.0)

func _unit_gate_plate_extra_height() -> float:
	return _scaled(UNIT_GATE_PLATE_EXTRA_HEIGHT, 12.0)

func _bin_size(bin: Area2D) -> Vector2:
	var size_variant: Variant = bin.get_meta("bin_size", Vector2.ZERO)
	if size_variant is Vector2:
		var meta_size: Vector2 = size_variant as Vector2
		if meta_size.x > 0.0 and meta_size.y > 0.0:
			return meta_size
	for child: Node in bin.get_children():
		if child is CollisionShape2D:
			var shape_node: CollisionShape2D = child as CollisionShape2D
			var rectangle: RectangleShape2D = shape_node.shape as RectangleShape2D
			if rectangle != null:
				return rectangle.size
	return Vector2(64.0, 24.0)

func _bin_name(stage: String, label: String) -> String:
	if stage == "Tuning" and label == "Gate":
		return "GateBin"
	return "%s%sBin" % [stage, label]

func _value_for_stage_label(stage: String, _label: String) -> int:
	if stage == "Tuning":
		return 1
	if stage == "Unit":
		return 0
	return 0

func _bin_weight_for_label(stage: String, label: String) -> float:
	if stage == "Launch":
		match label:
			"Tuning":
				return 0.65
			"Split", "Recycle":
				return 0.15
			"Waste":
				return 0.05
			_:
				return 1.0
	if stage == "Tuning":
		match label:
			"Gate":
				return 0.55
			"Prime", "Echo", "Surge":
				return 0.15
			_:
				return 1.0
	return 1.0

func _make_disc_visual(radius: float, color: Color, segments: int) -> Polygon2D:
	var visual := Polygon2D.new()
	visual.color = color
	visual.polygon = _circle_polygon(radius, segments)
	return visual

func _circle_polygon(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index: int in range(segments):
		var angle: float = TAU * float(index) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

func _circle_outline_points(radius: float, segments: int) -> PackedVector2Array:
	var points := _circle_polygon(radius, segments)
	if not points.is_empty():
		points.append(points[0])
	return points

func _has_visible_rigidbody_ball() -> bool:
	if active_ball != null and is_instance_valid(active_ball):
		return true
	return _find_first_child_of_type(self, "RigidBody2D") != null

func _has_unit_gate_blockers() -> bool:
	if _unit_gate_blockers.size() < 4:
		return false
	for slot_id: int in range(1, 5):
		if not _unit_gate_blockers.has(slot_id):
			return false
		var blocker: StaticBody2D = _unit_gate_blockers[slot_id] as StaticBody2D
		if blocker == null:
			return false
		var shape_node: CollisionShape2D = blocker.get_node_or_null("GateShape") as CollisionShape2D
		if shape_node == null or not (shape_node.shape is RectangleShape2D):
			return false
	return true

func _max_blocked_bounce_count() -> int:
	return MAX_BLOCKED_BOUNCES_PER_BALL

func _has_exposure_state_contract(candidate: Object) -> bool:
	if candidate == null:
		return false
	for method_name: String in [
		"get_exposure_ratio",
		"is_slot_open_for_progress",
		"is_slot_fully_exposed",
		"snapshot",
		"lowest_progress_legal_slot",
	]:
		if not candidate.has_method(method_name):
			return false
	return true

func _exposure_snapshot(battle_elapsed: float) -> Dictionary:
	if _exposure_state == null:
		return {}
	return _exposure_state.call("snapshot", battle_elapsed) as Dictionary

func _slot_exposure_ratio(slot_id: int, battle_elapsed: float) -> float:
	if _exposure_state == null:
		return 1.0 if slot_id == 1 else 0.0
	return float(_exposure_state.call("get_exposure_ratio", slot_id, battle_elapsed))

func _open_unit_slot_for_bounce(blocked_slot_id: int, battle_elapsed: float) -> int:
	_rebuild_board()
	if _is_slot_safe_bounce_target(blocked_slot_id, battle_elapsed):
		return blocked_slot_id
	var best_slot_id: int = 0
	var best_distance: int = 999
	for slot_id: int in range(1, 5):
		if not _is_slot_safe_bounce_target(slot_id, battle_elapsed):
			continue
		var distance: int = absi(slot_id - blocked_slot_id)
		if best_slot_id == 0 or distance < best_distance or (distance == best_distance and slot_id < best_slot_id):
			best_slot_id = slot_id
			best_distance = distance
	if best_slot_id == 0:
		return 1
	return best_slot_id

func _is_slot_safe_bounce_target(slot_id: int, battle_elapsed: float) -> bool:
	if _exposure_state != null and not bool(_exposure_state.call("is_slot_open_for_progress", slot_id, battle_elapsed)):
		return false
	return _slot_exposed_width(slot_id, battle_elapsed) >= _minimum_safe_exposed_width()

func _slot_exposed_width(slot_id: int, battle_elapsed: float) -> float:
	var bin: Area2D = _unit_bin(slot_id)
	if bin == null:
		return 0.0
	var bin_size: Vector2 = _bin_size(bin)
	return bin_size.x * _slot_exposure_ratio(slot_id, battle_elapsed)

func _minimum_safe_exposed_width() -> float:
	return _ball_radius() * 2.0 + _scaled(UNIT_GATE_BOUNCE_MARGIN, 3.0)

func _unit_slot_target_x(slot_id: int, battle_elapsed: float) -> float:
	var bin: Area2D = _unit_bin(slot_id)
	if bin == null:
		return _stage_rect("Unit").get_center().x
	var bin_size: Vector2 = _bin_size(bin)
	var ratio: float = _slot_exposure_ratio(slot_id, battle_elapsed)
	if ratio > 0.0 and ratio < 1.0:
		var slot_left: float = bin.position.x - bin_size.x * 0.5
		var open_width: float = bin_size.x * ratio
		if open_width < _minimum_safe_exposed_width():
			return bin.position.x
		var ball_radius: float = _ball_radius()
		var local_target: float = clampf(open_width * 0.5, ball_radius + 2.0, maxf(ball_radius + 2.0, open_width - ball_radius - 2.0))
		return slot_left + local_target
	return bin.position.x

func _find_first_child_of_type(node: Node, class_name_text: String) -> Node:
	for child: Node in node.get_children():
		if child.is_class(class_name_text):
			return child
		var nested: Node = _find_first_child_of_type(child, class_name_text)
		if nested != null:
			return nested
	return null

func _copy_for_verifier(result: MachinePhysicsResult) -> MachinePhysicsResult:
	var seeded_result: MachinePhysicsResult = result.duplicate_result()
	seeded_result.source = VERIFIER_SOURCE
	if seeded_result.chain_id.strip_edges().is_empty():
		seeded_result.chain_id = "verifier_seed_chain"
	return seeded_result

func _layout_key(rects: Dictionary) -> String:
	var parts := PackedStringArray()
	var keys: Array = rects.keys()
	keys.sort()
	for key_variant: Variant in keys:
		var key: String = String(key_variant)
		var rect: Rect2 = rects[key] as Rect2
		parts.append("%s:%.1f,%.1f,%.1f,%.1f" % [
			key,
			rect.position.x,
			rect.position.y,
			rect.size.x,
			rect.size.y,
		])
	return "|".join(parts)
