extends RefCounted

const EventRecord = preload("res://scripts/model/event_record.gd")
const PresetDefs = preload("res://scripts/model/preset_defs.gd")

const WARNING_DURATION_SECONDS := 2.5
const ACTIVE_DURATION_SECONDS := 3.0
const RECOVERY_DURATION_SECONDS := 2.0

const WARNING_START_SECONDS := 30.0

func build_counter_events(counter_id: String) -> Array:
	match counter_id:
		PresetDefs.POOL_POLLUTER:
			return _pool_polluter_events()
		PresetDefs.ECHO_BREAKER:
			return _echo_breaker_events()
		PresetDefs.STAGGER_PUNISHER:
			return _stagger_punisher_events()
		_:
			return []

func _pool_polluter_events() -> Array:
	var preset := PresetDefs.get_preset(PresetDefs.LAUNCH_FLOOD)
	return [
		_counter_event(WARNING_START_SECONDS, "warning", WARNING_DURATION_SECONDS, "launch", "counter_warning", preset, "pool_slots", "ghost_junk_slots", "future_slots_striped", 0),
		_counter_event(32.5, "active", ACTIVE_DURATION_SECONDS, "launch", "counter_active", preset, "pool_slots", "junk_capacity_occupancy", "polluted_pool_slots", 3),
		_counter_event(35.5, "recovery", RECOVERY_DURATION_SECONDS, "launch", "counter_recovery", preset, "pool_slots", "rhythm_stutter_trace", "polluted_slots_clear", 0),
		_counter_event(37.5, "complete", 0.0, "launch", "counter_complete", preset, "pool_slots", "rhythm_recovered", "pool_cleared", 0),
	]

func _echo_breaker_events() -> Array:
	var preset := PresetDefs.get_preset(PresetDefs.TUNING_ECHO)
	return [
		_counter_event(WARNING_START_SECONDS, "warning", WARNING_DURATION_SECONDS, "tuning", "counter_warning", preset, "echo_window", "break_mark", "echo_window_marked", 0),
		_counter_event(32.5, "active", ACTIVE_DURATION_SECONDS, "tuning", "counter_active", preset, "echo_window", "copy_swallowed", "copy_afterimage_collapses", 0),
		_counter_event(35.5, "recovery", RECOVERY_DURATION_SECONDS, "tuning", "counter_recovery", preset, "echo_window", "failed_copy_afterimage", "shrunken_echo_trace", 0),
		_counter_event(37.5, "complete", 0.0, "tuning", "counter_complete", preset, "echo_window", "echo_window_reopened", "echo_slot_clear", 0),
	]

func _stagger_punisher_events() -> Array:
	var preset := PresetDefs.get_preset(PresetDefs.UNIT_QUEUE_BURST)
	return [
		_counter_event(WARNING_START_SECONDS, "warning", WARNING_DURATION_SECONDS, "unit", "counter_warning", preset, "charge_gap", "gap_timer", "no_deployment_timer", 0),
		_counter_event(32.5, "active", ACTIVE_DURATION_SECONDS, "unit", "counter_active", preset, "charge_gap", "gap_hit", "gap_pressure_lands", 0),
		_counter_event(35.5, "recovery", RECOVERY_DURATION_SECONDS, "unit", "counter_recovery", preset, "charge_gap", "gap_hit_marker", "charge_gap_trace", 0),
		_counter_event(37.5, "complete", 0.0, "unit", "counter_complete", preset, "charge_gap", "squad_can_answer", "gap_pressure_resolved", 0),
	]

func _counter_event(
	time: float,
	state: String,
	duration: float,
	lane: String,
	event_type: String,
	preset: Dictionary,
	target_component: String,
	effect_kind: String,
	readability_tag: String,
	junk_count: int
) -> Dictionary:
	var event := EventRecord.make(
		time,
		lane,
		event_type,
		preset.id,
		preset.primary_axis_id,
		preset.counter_id,
		preset.frontline_signature,
		readability_tag,
		target_component
	)
	event["counter_state"] = state
	event["duration_seconds"] = duration
	event["target_component"] = target_component
	event["effect_kind"] = effect_kind
	event["is_component_local"] = true
	event["junk_count"] = junk_count
	return event

