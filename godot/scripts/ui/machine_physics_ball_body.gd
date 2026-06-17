class_name MachinePhysicsBallBody
extends RigidBody2D

var stage_top_guard_enabled: bool = false
var stage_top_limit_y: float = -INF
var stage_backflow_rebound_speed: float = 240.0
var stage_name: String = ""
var integrate_tick_count: int = 0
var _pending_backflow_guard_record: Dictionary = {}

func configure_stage_top_guard(enabled: bool, limit_y: float, rebound_speed: float, stage: String) -> void:
	stage_top_guard_enabled = enabled
	stage_top_limit_y = limit_y
	stage_backflow_rebound_speed = rebound_speed
	stage_name = stage

func consume_stage_backflow_guard_record() -> Dictionary:
	if _pending_backflow_guard_record.is_empty():
		return {}
	var record: Dictionary = _pending_backflow_guard_record.duplicate(true)
	_pending_backflow_guard_record.clear()
	return record

func force_stage_top_guard_check_for_verifier() -> Dictionary:
	_apply_stage_top_guard(position, linear_velocity)
	return consume_stage_backflow_guard_record()

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	integrate_tick_count += 1
	_apply_stage_top_guard(state.transform.origin, state.linear_velocity, state)

func _apply_stage_top_guard(position_value: Vector2, velocity_value: Vector2, state: PhysicsDirectBodyState2D = null) -> void:
	if not stage_top_guard_enabled:
		return
	if position_value.y >= stage_top_limit_y:
		return
	var corrected_velocity := Vector2(
		velocity_value.x * 0.45,
		maxf(absf(velocity_value.y), stage_backflow_rebound_speed)
	)
	_pending_backflow_guard_record = {
		"stage": stage_name,
		"chain_id": String(get_meta("chain_id", "")),
		"position_before": position_value,
		"velocity_before": velocity_value,
		"top_limit_y": stage_top_limit_y,
		"source": "stage_top_backflow_guard",
	}
	if state != null:
		var transform_value: Transform2D = state.transform
		transform_value.origin.y = stage_top_limit_y
		state.transform = transform_value
		state.linear_velocity = corrected_velocity
	else:
		position.y = stage_top_limit_y
		linear_velocity = corrected_velocity
		reset_physics_interpolation()
	angular_velocity *= 0.5
	sleeping = false
