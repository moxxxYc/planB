class_name MachinePhysicsResult
extends RefCounted

var component: String = ""
var result_id: String = ""
var slot_id: int = 0
var value: int = 0
var ball_kind: String = "clean"
var source: String = "physics"
var chain_id: String = ""
var battle_elapsed: float = 0.0
var natural_result_id: String = ""
var forced_by: String = ""
var feedback_state: String = "Natural Hit"

static func make(
	p_component: String,
	p_result_id: String,
	p_slot_id: int = 0,
	p_value: int = 0,
	p_ball_kind: String = "clean",
	p_source: String = "physics",
	p_chain_id: String = "",
	p_battle_elapsed: float = 0.0,
	p_natural_result_id: String = "",
	p_forced_by: String = "",
	p_feedback_state: String = ""
) -> MachinePhysicsResult:
	var result := MachinePhysicsResult.new()
	result.component = p_component
	result.result_id = p_result_id
	result.slot_id = p_slot_id
	result.value = p_value
	result.ball_kind = p_ball_kind
	result.source = p_source
	result.chain_id = p_chain_id
	result.battle_elapsed = p_battle_elapsed
	result.natural_result_id = p_result_id if p_natural_result_id.is_empty() else p_natural_result_id
	result.forced_by = p_forced_by
	result.feedback_state = "Forced Redirect" if not p_forced_by.is_empty() and p_feedback_state.is_empty() else ("Natural Hit" if p_feedback_state.is_empty() else p_feedback_state)
	return result

func to_dictionary() -> Dictionary:
	return {
		"component": component,
		"result_id": result_id,
		"slot_id": slot_id,
		"value": value,
		"ball_kind": ball_kind,
		"source": source,
		"chain_id": chain_id,
		"battle_elapsed": battle_elapsed,
		"natural_result_id": natural_result_id,
		"forced_by": forced_by,
		"feedback_state": feedback_state,
	}

func duplicate_result() -> MachinePhysicsResult:
	return MachinePhysicsResult.make(
		component,
		result_id,
		slot_id,
		value,
		ball_kind,
		source,
		chain_id,
		battle_elapsed,
		natural_result_id,
		forced_by,
		feedback_state
	)
