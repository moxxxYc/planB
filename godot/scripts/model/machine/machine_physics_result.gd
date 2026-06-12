class_name MachinePhysicsResult
extends RefCounted

var component: String = ""
var result_id: String = ""
var slot_id: int = 0
var value: int = 0
var ball_kind: String = "clean"
var source: String = "physics"

static func make(
	p_component: String,
	p_result_id: String,
	p_slot_id: int = 0,
	p_value: int = 0,
	p_ball_kind: String = "clean",
	p_source: String = "physics"
) -> MachinePhysicsResult:
	var result := MachinePhysicsResult.new()
	result.component = p_component
	result.result_id = p_result_id
	result.slot_id = p_slot_id
	result.value = p_value
	result.ball_kind = p_ball_kind
	result.source = p_source
	return result
