class_name MachinePhysicsBoardView
extends Node2D

signal landing_resolved(result: MachinePhysicsResult)

const MachineSlotExposureStateScript := preload("res://scripts/model/machine/machine_slot_exposure_state.gd")

const BALL_LAYER: int = 1
const PEG_LAYER: int = 2
const BIN_LAYER: int = 3
const BALL_RADIUS: float = 7.5
const PEG_RADIUS: float = 4.5
const WALL_THICKNESS: float = 6.0
const DEFAULT_STAGE_WIDTH: float = 340.0
const DEFAULT_STAGE_HEIGHT: float = 112.0
const VERIFIER_SOURCE: String = "verifier_seed"
const RETIRED_BALL_DWELL_SECONDS: float = 0.5
const MAX_RETIRED_BALLS: int = 4
const UNIT_GATE_PLATE_EXTRA_HEIGHT: float = 18.0
const UNIT_GATE_MIN_COLLISION_WIDTH: float = 1.0
const UNIT_GATE_BOUNCE_MARGIN: float = 4.0
const MAX_BLOCKED_BOUNCES_PER_BALL: int = 3

var active_ball: RigidBody2D = null
var physics_landing_count: int = 0
var last_physics_result: Dictionary = {}
var exposure_gate_snapshot: Dictionary = {}
var blocked_bounce_count: int = 0
var last_blocked_bounce: Dictionary = {}
var _stage_rects: Dictionary = {}
var _stage_bins: Dictionary = {}
var _launch_index: int = 0
var _created_ball_count: int = 0
var _battle_elapsed: float = 0.0
var _exposure_state: RefCounted = MachineSlotExposureStateScript.new()
var _unit_gate_blockers: Dictionary = {}
var _retired_balls: Array[RigidBody2D] = []

func _ready() -> void:
	_ensure_default_stage_rects()
	_rebuild_board()

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
	_place_body_for_stage(body, "Launch", battle_elapsed)

func set_exposure_state(exposure_state: RefCounted) -> void:
	if not _has_exposure_state_contract(exposure_state):
		return
	_exposure_state = exposure_state
	_update_unit_gate_blockers()

func set_battle_elapsed(seconds: float) -> void:
	_battle_elapsed = maxf(0.0, seconds)
	_update_unit_gate_blockers()

func get_runtime_contract() -> Dictionary:
	_rebuild_board()
	_ensure_preview_ball()
	return {
		"has_visible_rigidbody_ball": _has_visible_rigidbody_ball(),
		"has_physics_contract_nodes": has_physics_contract_nodes(),
		"physics_landing_count": physics_landing_count,
		"last_physics_result": last_physics_result.duplicate(true),
		"created_ball_count": _created_ball_count,
		"stage_count": _stage_rects.size(),
		"exposure_gate_snapshot": exposure_gate_snapshot.duplicate(true),
		"blocked_bounce_count": blocked_bounce_count,
		"last_blocked_bounce": last_blocked_bounce.duplicate(true),
		"has_unit_gate_blockers": _has_unit_gate_blockers(),
		"unit_gate_blocker_count": _unit_gate_blockers.size(),
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
	_stage_rects = next_rects
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

func _rebuild_board() -> void:
	if get_node_or_null("StaticGeometry") != null:
		_update_unit_gate_blockers()
		return

	var static_geometry := Node2D.new()
	static_geometry.name = "StaticGeometry"
	add_child(static_geometry)
	var bins := Node2D.new()
	bins.name = "Bins"
	add_child(bins)

	_build_stage_geometry("Launch", ["Tuning", "Split", "Recycle", "Waste"], Color("#7bcb6b"))
	_build_stage_geometry("Tuning", ["Gate", "Prime", "Echo", "Surge"], Color("#e6b450"))
	_build_stage_geometry("Unit", ["S1", "S2", "S3", "S4"], Color("#c58be8"))
	_update_unit_gate_blockers()
	_ensure_preview_ball()

func _clear_board_geometry() -> void:
	for node_name: String in ["StaticGeometry", "Bins"]:
		var existing: Node = get_node_or_null(node_name)
		if existing != null:
			remove_child(existing)
			existing.queue_free()
	_stage_bins.clear()
	_unit_gate_blockers.clear()
	if active_ball != null and is_instance_valid(active_ball) and String(active_ball.get_meta("chain_id", "")) == "preview":
		var launch_rect: Rect2 = _stage_rect("Launch")
		active_ball.position = launch_rect.position + Vector2(launch_rect.size.x * 0.5, 18.0)

func _build_stage_geometry(stage: String, labels: Array[String], color: Color) -> void:
	var rect: Rect2 = _stage_rect(stage)
	_add_wall(stage + "LeftWall", rect.position + Vector2(WALL_THICKNESS * 0.5, rect.size.y * 0.5), Vector2(WALL_THICKNESS, rect.size.y), color.darkened(0.35))
	_add_wall(stage + "RightWall", rect.position + Vector2(rect.size.x - WALL_THICKNESS * 0.5, rect.size.y * 0.5), Vector2(WALL_THICKNESS, rect.size.y), color.darkened(0.35))
	for index: int in range(6):
		var x: float = rect.position.x + rect.size.x * (0.18 + 0.13 * float(index))
		var y: float = rect.position.y + rect.size.y * (0.32 + 0.18 * float(index % 2))
		_add_peg("%sPeg%d" % [stage, index], Vector2(x, y), color)

	var bin_width: float = rect.size.x / float(labels.size())
	for index: int in range(labels.size()):
		var label: String = labels[index]
		var center := Vector2(rect.position.x + bin_width * (float(index) + 0.5), rect.position.y + rect.size.y - 14.0)
		_add_bin(stage, label, center, Vector2(bin_width - 8.0, 24.0), index, color)
	if stage == "Unit":
		_build_unit_gate_blockers(labels, color)

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
		blocker.collision_layer = 0
		blocker.collision_mask = 0
		blocker.set_collision_layer_value(PEG_LAYER, true)
		blocker.set_collision_mask_value(BALL_LAYER, true)
		blocker.set_meta("stage", "Unit")
		blocker.set_meta("slot_id", slot_id)
		blocker.set_meta("unit_gate_blocker", true)

		var shape_node := CollisionShape2D.new()
		shape_node.name = "GateShape"
		var shape := RectangleShape2D.new()
		shape.size = Vector2(UNIT_GATE_MIN_COLLISION_WIDTH, 24.0 + UNIT_GATE_PLATE_EXTRA_HEIGHT)
		shape_node.shape = shape
		blocker.add_child(shape_node)

		var visual := Polygon2D.new()
		visual.name = "GatePlate"
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
		var closed_height: float = bin_size.y + UNIT_GATE_PLATE_EXTRA_HEIGHT
		var active: bool = closed_width > UNIT_GATE_MIN_COLLISION_WIDTH
		var shape_width: float = maxf(UNIT_GATE_MIN_COLLISION_WIDTH, closed_width)
		var slot_left: float = bin.position.x - bin_size.x * 0.5
		var exposed_width: float = bin_size.x * ratio

		blocker.visible = active
		blocker.position = Vector2(slot_left + exposed_width + shape_width * 0.5, bin.position.y - UNIT_GATE_PLATE_EXTRA_HEIGHT * 0.25)
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
	visual.color = Color("#6d527a") if ratio > 0.0 else Color("#493750")
	visual.polygon = PackedVector2Array([
		Vector2(-plate_size.x * 0.5, -plate_size.y * 0.5),
		Vector2(plate_size.x * 0.5, -plate_size.y * 0.5),
		Vector2(plate_size.x * 0.5, plate_size.y * 0.5),
		Vector2(-plate_size.x * 0.5, plate_size.y * 0.5),
	])

func _add_peg(peg_name: String, peg_position: Vector2, color: Color) -> void:
	var peg := StaticBody2D.new()
	peg.name = peg_name
	peg.position = peg_position
	peg.collision_layer = 0
	peg.collision_mask = 0
	peg.set_collision_layer_value(PEG_LAYER, true)
	peg.set_collision_mask_value(BALL_LAYER, true)
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = PEG_RADIUS
	shape_node.shape = shape
	peg.add_child(shape_node)
	peg.add_child(_make_disc_visual(PEG_RADIUS, color, 10))
	get_node("StaticGeometry").add_child(peg)

func _add_wall(wall_name: String, wall_position: Vector2, wall_size: Vector2, color: Color) -> void:
	var wall := StaticBody2D.new()
	wall.name = wall_name
	wall.position = wall_position
	wall.collision_layer = 0
	wall.collision_mask = 0
	wall.set_collision_layer_value(PEG_LAYER, true)
	wall.set_collision_mask_value(BALL_LAYER, true)
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
	visual.color = color.darkened(0.55)
	visual.polygon = PackedVector2Array([
		Vector2(-bin_size.x * 0.5, -bin_size.y * 0.5),
		Vector2(bin_size.x * 0.5, -bin_size.y * 0.5),
		Vector2(bin_size.x * 0.5, bin_size.y * 0.5),
		Vector2(-bin_size.x * 0.5, bin_size.y * 0.5),
	])
	bin.add_child(visual)
	bin.body_entered.connect(_on_bin_body_entered.bind(bin))
	get_node("Bins").add_child(bin)
	_stage_bins["%s:%s" % [stage, label]] = bin

func _ensure_preview_ball() -> void:
	if active_ball != null and is_instance_valid(active_ball):
		return
	if _find_first_child_of_type(self, "RigidBody2D") != null:
		return
	var preview := _make_ball({
		"kind": "clean",
		"value": 1,
		"chain_id": "preview",
	})
	preview.name = "ActiveBall"
	preview.freeze = true
	preview.visible = true
	active_ball = preview
	add_child(preview)
	var launch_rect: Rect2 = _stage_rect("Launch")
	preview.position = launch_rect.position + Vector2(launch_rect.size.x * 0.5, 18.0)

func _make_ball(ball: Dictionary) -> RigidBody2D:
	var body := RigidBody2D.new()
	body.gravity_scale = 0.9
	body.linear_damp = 0.02
	body.contact_monitor = true
	body.max_contacts_reported = 4
	body.continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	body.collision_layer = 0
	body.collision_mask = 0
	body.set_collision_layer_value(BALL_LAYER, true)
	body.set_collision_mask_value(PEG_LAYER, true)
	body.set_meta("ball_kind", String(ball.get("kind", "clean")))
	body.set_meta("ball_value", int(ball.get("value", 1)))
	body.set_meta("chain_id", String(ball.get("chain_id", "")))
	body.set_meta("stage", "Launch")
	body.set_meta("tuning_result_id", "Gate")
	body.set_meta("tuning_value", 1)
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = BALL_RADIUS
	shape_node.shape = shape
	body.add_child(shape_node)
	var ball_color: Color = Color("#f4f0d8") if String(ball.get("kind", "clean")) != "junk" else Color("#6f5f35")
	body.add_child(_make_disc_visual(BALL_RADIUS, ball_color, 18))
	return body

func _place_body_for_stage(body: RigidBody2D, stage: String, battle_elapsed: float) -> void:
	set_battle_elapsed(battle_elapsed)
	var rect: Rect2 = _stage_rect(stage)
	var target_label: String = _target_label_for_body(body, stage)
	var target_center: Vector2 = _bin_center(stage, target_label)
	body.set_meta("stage", stage)
	body.set_meta("resolving_stage", false)
	body.set_meta("battle_elapsed", battle_elapsed)
	body.freeze = false
	body.sleeping = false
	body.position = Vector2(target_center.x, rect.position.y + 16.0)
	body.linear_velocity = Vector2((target_center.x - rect.get_center().x) * 0.15, 155.0)
	body.angular_velocity = 0.0
	body.reset_physics_interpolation()

func _target_label_for_body(body: RigidBody2D, stage: String) -> String:
	match stage:
		"Launch":
			var pattern: Array[String] = ["Tuning", "Tuning", "Split", "Tuning", "Recycle", "Tuning", "Waste", "Tuning"]
			return pattern[(_launch_index - 1) % pattern.size()]
		"Tuning":
			var pattern: Array[String] = ["Gate", "Prime", "Gate", "Echo", "Gate", "Surge"]
			return pattern[(_launch_index - 1) % pattern.size()]
		"Unit":
			var pattern: Array[String] = ["S1", "S1", "S2", "S1", "S2", "S3", "S1", "S4"]
			return pattern[(_launch_index - 1) % pattern.size()]
		_:
			return String(body.get_meta("stage", "Launch"))

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
	rigid_body.set_meta("battle_elapsed", _battle_elapsed)
	rigid_body.set_meta("resolving_stage", true)
	if bin_stage == "Unit" and _is_unit_gate_blocking_contact(rigid_body, bin):
		var bounce_record: Dictionary = _record_blocked_unit_bounce(rigid_body, bin)
		if bool(bounce_record.get("terminal", false)):
			call_deferred("_retire_body_after_blocked_unit_gate", rigid_body)
		else:
			call_deferred("_bounce_body_from_blocked_unit_gate", rigid_body, bin)
		return
	var result: MachinePhysicsResult = _result_from_bin(rigid_body, bin)
	_record_landing(result)
	landing_resolved.emit(result)
	call_deferred("_advance_body_after_landing", rigid_body, result)

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
	var unit_rect: Rect2 = _stage_rect("Unit")
	var target_x: float = _unit_slot_target_x(target_slot_id, battle_elapsed)
	body.set_meta("stage", "Unit")
	body.set_meta("resolving_stage", false)
	body.position = Vector2(target_x, unit_rect.position.y + 18.0)
	body.linear_velocity = Vector2((target_x - unit_rect.get_center().x) * 0.2, 160.0)
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
				_place_body_for_stage(body, "Tuning", result.battle_elapsed)
			else:
				_retire_body(body)
		"Tuning":
			body.set_meta("tuning_result_id", result.result_id)
			body.set_meta("tuning_value", maxi(1, result.value))
			_place_body_for_stage(body, "Unit", result.battle_elapsed)
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

func _value_for_stage_label(stage: String, label: String) -> int:
	if stage == "Tuning":
		return 1
	if stage == "Unit":
		return 0
	return 0

func _make_disc_visual(radius: float, color: Color, segments: int) -> Polygon2D:
	var visual := Polygon2D.new()
	visual.color = color
	var points := PackedVector2Array()
	for index: int in range(segments):
		var angle: float = TAU * float(index) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	visual.polygon = points
	return visual

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
	return BALL_RADIUS * 2.0 + UNIT_GATE_BOUNCE_MARGIN

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
		var local_target: float = clampf(open_width * 0.5, BALL_RADIUS + 2.0, maxf(BALL_RADIUS + 2.0, open_width - BALL_RADIUS - 2.0))
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
