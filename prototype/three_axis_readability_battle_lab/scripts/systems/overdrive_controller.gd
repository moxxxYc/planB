extends RefCounted

const EventRecord = preload("res://scripts/model/event_record.gd")
const PresetDefs = preload("res://scripts/model/preset_defs.gd")

func definition_for_preset(preset_id: String) -> Dictionary:
	var preset := PresetDefs.get_preset(preset_id)
	if preset.is_empty():
		return {}
	return {
		"preset_id": preset_id,
		"axis_id": preset.primary_axis_id,
		"label": preset.overdrive_label,
	}

func is_eligible(preset_id: String, axis_state: Dictionary) -> bool:
	match preset_id:
		PresetDefs.LAUNCH_FLOOD:
			return axis_state.get("return_balls", false) \
				or axis_state.get("pool_pressure", false) \
				or axis_state.get("launcher_throughput", false)
		PresetDefs.TUNING_ECHO:
			return axis_state.get("echo_hot_state", false) \
				or axis_state.get("echo_window", false)
		PresetDefs.UNIT_QUEUE_BURST:
			return axis_state.get("squad_chain", false) \
				or axis_state.get("same_unit_queue_buildup", false)
		_:
			return false

func activate(preset_id: String, axis_state: Dictionary) -> Dictionary:
	var preset := PresetDefs.get_preset(preset_id)
	if preset.is_empty():
		return {}

	var eligible := is_eligible(preset_id, axis_state)
	var component_id := _amplified_component(preset_id, axis_state, eligible)
	var effect_kind := _effect_kind(preset_id, eligible)
	var event := EventRecord.make(
		0.0,
		preset.primary_axis_id,
		"overdrive_activation",
		preset.id,
		preset.primary_axis_id,
		preset.counter_id,
		preset.frontline_signature,
		"axis_bound_overdrive" if eligible else "low_yield_axis_flicker",
		component_id
	)
	event["overdrive_label"] = preset.overdrive_label
	event["overdrive_yield"] = "axis_amplification" if eligible else "low_yield"
	event["effect_kind"] = effect_kind
	event["is_axis_bound"] = true
	return event

func _amplified_component(preset_id: String, axis_state: Dictionary, eligible: bool) -> String:
	if not eligible:
		return "unrelated_axis_state"
	match preset_id:
		PresetDefs.LAUNCH_FLOOD:
			if axis_state.get("return_balls", false):
				return "return_arrows"
			if axis_state.get("pool_pressure", false):
				return "pool_slots"
			return "launcher_cadence"
		PresetDefs.TUNING_ECHO:
			return "echo_afterimages"
		PresetDefs.UNIT_QUEUE_BURST:
			return "squad_bracket"
		_:
			return ""

func _effect_kind(preset_id: String, eligible: bool) -> String:
	if not eligible:
		return "weak_axis_flicker"
	match preset_id:
		PresetDefs.LAUNCH_FLOOD:
			return "return_and_launcher_cadence"
		PresetDefs.TUNING_ECHO:
			return "echo_afterimage_persistence"
		PresetDefs.UNIT_QUEUE_BURST:
			return "squad_chain_release"
		_:
			return ""

