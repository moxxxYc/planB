extends RefCounted

const MachineSimulator = preload("res://scripts/systems/machine_simulator.gd")

func test_launch_flood_has_machine_trace_before_frontline_flow() -> bool:
	var events := _events_for("launch_flood")
	return _assert_trace_before_frontline(
		events,
		["pool_refill", "front_return_arrow", "launcher_cadence_spike"],
		"sustained_flow"
	)

func test_tuning_echo_has_machine_trace_before_repeated_hit() -> bool:
	var events := _events_for("tuning_echo")
	return _assert_trace_before_frontline(
		events,
		["echo_hot_slot", "echo_copy_afterimage", "surge_chevrons"],
		"repeated_heavy_hit"
	)

func test_unit_queue_burst_has_machine_trace_before_grouped_push() -> bool:
	var events := _events_for("unit_queue_burst")
	return _assert_trace_before_frontline(
		events,
		["unit_slot_fill", "queue_stack", "squad_bracket"],
		"batch_charge_release"
	)

func test_first_readable_traces_respect_deadlines() -> bool:
	var simulator = MachineSimulator.new()
	var launch_time := _first_event_time(simulator.build_events("launch_flood"), "pool_refill")
	var tuning_time := _first_event_time(simulator.build_events("tuning_echo"), "echo_hot_slot")
	var unit_time := _first_event_time(simulator.build_events("unit_queue_burst"), "unit_slot_fill")

	if launch_time > 10.0:
		push_error("Launch first readable trace must happen by 10s, got %s" % launch_time)
		return false
	if tuning_time > 15.0:
		push_error("Tuning first readable trace must happen by 15s, got %s" % tuning_time)
		return false
	if unit_time > 15.0:
		push_error("Unit first readable trace must happen by 15s, got %s" % unit_time)
		return false
	return true

func test_event_records_include_required_fields() -> bool:
	for preset_id in ["launch_flood", "tuning_echo", "unit_queue_burst"]:
		var events := _events_for(preset_id)
		if events.is_empty():
			push_error("%s emitted no events" % preset_id)
			return false
		for event in events:
			for key in ["time", "lane", "event_type", "preset_id", "axis_id", "counter_id", "frontline_signature", "readability_tag"]:
				if not event.has(key):
					push_error("%s event missing key %s: %s" % [preset_id, key, event])
					return false
	return true

func test_event_records_do_not_use_generic_output_labels() -> bool:
	for preset_id in ["launch_flood", "tuning_echo", "unit_queue_burst"]:
		var events := _events_for(preset_id)
		for event in events:
			var event_text := "%s %s" % [event.get("event_type", ""), event.get("readability_tag", "")]
			if event_text.find("more_units") != -1 or event_text.find("stronger") != -1:
				push_error("Generic output label found in %s: %s" % [preset_id, event])
				return false
	return true

func _events_for(preset_id: String) -> Array:
	var simulator = MachineSimulator.new()
	return simulator.build_events(preset_id)

func _assert_trace_before_frontline(events: Array, trace_types: Array, signature: String) -> bool:
	var frontline_time := _first_frontline_time(events, signature)
	if frontline_time < 0.0:
		push_error("Missing frontline signature: %s" % signature)
		return false

	for trace_type in trace_types:
		var trace_time := _first_event_time(events, trace_type)
		if trace_time < 0.0:
			push_error("Missing machine trace: %s" % trace_type)
			return false
		if trace_time >= frontline_time:
			push_error("Trace %s at %s must precede frontline at %s" % [trace_type, trace_time, frontline_time])
			return false
	return true

func _first_frontline_time(events: Array, signature: String) -> float:
	for event in events:
		if event.get("lane") == "frontline" and event.get("frontline_signature") == signature:
			return event.get("time")
	return -1.0

func _first_event_time(events: Array, event_type: String) -> float:
	for event in events:
		if event.get("event_type") == event_type:
			return event.get("time")
	return -1.0
