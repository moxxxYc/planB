class_name MachinePhysicsBoardView
extends Node2D

signal landing_resolved(result: MachinePhysicsResult)

const BALL_LAYER: int = 1
const PEG_LAYER: int = 2

var deterministic_sequence: Array[MachinePhysicsResult] = [
	MachinePhysicsResult.make("Tuning", "Gate", 1, 1, "clean", "physics"),
	MachinePhysicsResult.make("Tuning", "Prime", 1, 2, "clean", "physics"),
	MachinePhysicsResult.make("Tuning", "Echo", 2, 1, "clean", "physics"),
]
var _sequence_index: int = 0
var active_ball: RigidBody2D = null

func _ready() -> void:
	_build_physics_board()

func emit_deterministic_landing() -> MachinePhysicsResult:
	if deterministic_sequence.is_empty():
		var fallback := MachinePhysicsResult.make("Tuning", "Gate", 1, 1)
		landing_resolved.emit(fallback)
		return fallback
	var result: MachinePhysicsResult = deterministic_sequence[_sequence_index % deterministic_sequence.size()]
	_sequence_index += 1
	landing_resolved.emit(result)
	return result

func has_physics_contract_nodes() -> bool:
	_build_physics_board()
	return get_node_or_null("ActiveBall") is RigidBody2D and get_node_or_null("Peg0") is StaticBody2D and get_node_or_null("GateBin") is Area2D

func _build_physics_board() -> void:
	if active_ball != null:
		return
	active_ball = RigidBody2D.new()
	active_ball.name = "ActiveBall"
	active_ball.gravity_scale = 0.6
	active_ball.contact_monitor = true
	active_ball.max_contacts_reported = 4
	active_ball.position = Vector2(0.0, -80.0)
	active_ball.collision_layer = BALL_LAYER
	active_ball.collision_mask = PEG_LAYER
	var ball_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	ball_shape.shape = circle
	active_ball.add_child(ball_shape)
	add_child(active_ball)

	for index: int in range(5):
		_add_peg(index, Vector2(-48.0 + float(index) * 24.0, -30.0 + float(index % 2) * 18.0))
	_add_bin("GateBin", Vector2(-48.0, 70.0), "Gate", 1, 1)
	_add_bin("PrimeBin", Vector2(0.0, 70.0), "Prime", 1, 2)
	_add_bin("EchoBin", Vector2(48.0, 70.0), "Echo", 2, 1)

func _add_peg(index: int, peg_position: Vector2) -> void:
	var peg := StaticBody2D.new()
	peg.name = "Peg%d" % index
	peg.position = peg_position
	peg.collision_layer = PEG_LAYER
	peg.collision_mask = BALL_LAYER
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 5.0
	shape_node.shape = shape
	peg.add_child(shape_node)
	add_child(peg)

func _add_bin(bin_name: String, bin_position: Vector2, result_id: String, slot_id: int, value: int) -> void:
	var bin := Area2D.new()
	bin.name = bin_name
	bin.position = bin_position
	bin.collision_layer = PEG_LAYER
	bin.collision_mask = BALL_LAYER
	bin.set_meta("result_id", result_id)
	bin.set_meta("slot_id", slot_id)
	bin.set_meta("value", value)
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(28.0, 18.0)
	shape_node.shape = shape
	bin.add_child(shape_node)
	bin.body_entered.connect(_on_bin_body_entered.bind(bin))
	add_child(bin)

func _on_bin_body_entered(_body: Node2D, bin: Area2D) -> void:
	var result := MachinePhysicsResult.make(
		"Tuning",
		String(bin.get_meta("result_id")),
		int(bin.get_meta("slot_id")),
		int(bin.get_meta("value")),
		"clean",
		"physics"
	)
	landing_resolved.emit(result)
