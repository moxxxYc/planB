extends RefCounted

const EventRecord = preload("res://scripts/model/event_record.gd")
const PresetDefs = preload("res://scripts/model/preset_defs.gd")

func build_events(preset_id: String) -> Array:
	match preset_id:
		PresetDefs.LAUNCH_FLOOD:
			return _launch_flood_events()
		PresetDefs.TUNING_ECHO:
			return _tuning_echo_events()
		PresetDefs.UNIT_QUEUE_BURST:
			return _unit_queue_burst_events()
		_:
			return []

func _launch_flood_events() -> Array:
	var preset := PresetDefs.get_preset(PresetDefs.LAUNCH_FLOOD)
	return [
		_event(1.0, "launch", "pool_refill", preset, "pool_rhythm", "Pool fills in visible FIFO rhythm."),
		_event(3.9, "launch", "launcher_fire", preset, "head_launch", "Highlighted Pool head fires forward."),
		_event(5.7, "launch", "front_return_arrow", preset, "return_near_front", "Front Return feeds near the Pool front."),
		_event(8.4, "launch", "launcher_cadence_spike", preset, "launch_cadence", "Launcher cadence visibly tightens."),
		_event(9.8, "frontline", "frontline_pressure", preset, "smooth_flow", "Small arrivals move the pressure line smoothly."),
		_event(18.0, "launch", "front_return_arrow", preset, "return_near_front", "Repeated return arrows sustain the feed."),
		_event(19.3, "frontline", "frontline_pressure", preset, "smooth_flow", "Sustained flow continues without one dominant impact."),
	]

func _tuning_echo_events() -> Array:
	var preset := PresetDefs.get_preset(PresetDefs.TUNING_ECHO)
	return [
		_event(4.0, "tuning", "prime_plaque", preset, "prime_value", "Prime value plaque appears before the Unit hit."),
		_event(6.5, "tuning", "echo_hot_slot", preset, "echo_window", "Echo slot becomes hot before the copy."),
		_event(8.6, "tuning", "echo_copy_afterimage", preset, "copy_afterimage", "A ghost copy follows the hit."),
		_event(9.4, "tuning", "surge_chevrons", preset, "surge_queue", "Surge chevrons mark deployment caused by this hit."),
		_event(11.0, "frontline", "frontline_pressure", preset, "stepped_repeat", "Repeated hit causes a stepped frontline jump."),
		_event(24.0, "tuning", "echo_copy_afterimage", preset, "copy_afterimage", "Second copy trace repeats the high-value wave."),
		_event(25.4, "frontline", "frontline_pressure", preset, "stepped_repeat", "Another repeated hit moves the line in a step."),
	]

func _unit_queue_burst_events() -> Array:
	var preset := PresetDefs.get_preset(PresetDefs.UNIT_QUEUE_BURST)
	return [
		_event(4.5, "unit", "unit_slot_fill", preset, "slot_chunks", "Unit slot fills in visible chunks."),
		_event(8.0, "unit", "queue_stack", preset, "same_unit_stack", "Same-unit queue entries stack together."),
		_event(12.0, "unit", "squad_bracket", preset, "squad_grouping", "A squad bracket forms before release."),
		_event(14.5, "unit", "charge_gap", preset, "quiet_charge", "A short gap makes the charge readable."),
		_event(17.5, "frontline", "frontline_pressure", preset, "grouped_push", "Grouped squad release pushes as one batch."),
		_event(35.0, "unit", "queue_stack", preset, "same_unit_stack", "Second queue stack builds another grouped release."),
		_event(39.5, "frontline", "frontline_pressure", preset, "grouped_push", "Batch pressure returns as a grouped push."),
	]

func _event(
	time: float,
	lane: String,
	event_type: String,
	preset: Dictionary,
	readability_tag: String,
	component_id: String
) -> Dictionary:
	return EventRecord.make(
		time,
		lane,
		event_type,
		preset.id,
		preset.primary_axis_id,
		preset.counter_id,
		preset.frontline_signature,
		readability_tag,
		component_id
	)

