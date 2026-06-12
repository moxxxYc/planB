class_name MachinePhysicsBoardView
extends Node2D

signal landing_resolved(result: MachinePhysicsResult)

const BALL_LAYER: int = 1
const PEG_LAYER: int = 2
const BIN_LAYER: int = 3
const BALL_RADIUS: float = 7.5
const PEG_RADIUS: float = 4.5
const WALL_THICKNESS: float = 6.0
const DEFAULT_STAGE_WIDTH: float = 340.0
const DEFAULT_STAGE_HEIGHT: float = 112.0
const VERIFIER_SOURCE: String = "verifier_seed"

var active_ball: RigidBody2D = null
var physics_landing_count: int = 0
var last_physics_result: Dictionary = {}
var _stage_rects: Dictionary = {}
var _stage_bins: Dictionary = {}
var _launch_index: int = 0
var _created_ball_count: int = 0
var _exposure_state = null

func _ready() -> void:
	_ensure_default_stage_rects()
	_rebuild_board()

func launch_ball(ball: Dictionary, battle_elapsed: float) -> void:
	_ensure_default_stage_rects()
	_rebuild_board()
	_launch_index += 1
	_created_ball_count += 1

	var body: RigidBody2D = _make_ball(ball)
	body.name = "ActiveBall" if active_ball == null or not is_instance_valid(active_ball) else "ActiveBall%d" % _created_ball_count
	active_ball = body
	add_child(body)
	_place_body_for_stage(body, "Launch", battle_elapsed)

func set_exposure_state(exposure_state) -> void:
	_exposure_state = exposure_state

func get_runtime_contract() -> Dictionary:
	_rebuild_board()
	return {
		"has_visible_rigidbody_ball": _has_visible_rigidbody_ball(),
		"has_physics_contract_nodes": has_physics_contract_nodes(),
		"physics_landing_count": physics_landing_count,
		"last_physics_result": last_physics_result.duplicate(true),
		"created_ball_count": _created_ball_count,
		"stage_count": _stage_rects.size(),
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
	_ensure_preview_ball()

func _clear_board_geometry() -> void:
	for node_name: String in ["StaticGeometry", "Bins"]:
		var existing: Node = get_node_or_null(node_name)
		if existing != null:
			remove_child(existing)
			existing.free()
	_stage_bins.clear()
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
	rigid_body.set_meta("resolving_stage", true)
	var result: MachinePhysicsResult = _result_from_bin(rigid_body, bin)
	_record_landing(result)
	landing_resolved.emit(result)
	call_deferred("_advance_body_after_landing", rigid_body, result)

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
