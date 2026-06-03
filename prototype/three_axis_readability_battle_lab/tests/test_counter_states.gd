extends RefCounted

const CounterController = preload("res://scripts/systems/counter_controller.gd")

func test_every_counter_has_warning_active_recovery_and_complete() -> bool:
	for counter_id in ["pool_polluter", "echo_breaker", "stagger_punisher"]:
		var states := _states_for(counter_id)
		if not _assert_array_equals(states, ["warning", "active", "recovery", "complete"], counter_id):
			return false
	return true

func test_counter_state_durations_are_exact() -> bool:
	for counter_id in ["pool_polluter", "echo_breaker", "stagger_punisher"]:
		var events := CounterController.new().build_counter_events(counter_id)
		if not _assert_duration(events, "warning", 2.5, counter_id):
			return false
		if not _assert_duration(events, "active", 3.0, counter_id):
			return false
		if not _assert_duration(events, "recovery", 2.0, counter_id):
			return false
	return true

func test_pool_polluter_targets_pool_and_inserts_junk() -> bool:
	var active := _event_for_state("pool_polluter", "active")
	return _assert_event_fields(active, {
		"target_component": "pool_slots",
		"effect_kind": "junk_capacity_occupancy",
		"junk_count": 3,
		"is_component_local": true,
	})

func test_echo_breaker_targets_echo_window_and_swallows_copy() -> bool:
	var active := _event_for_state("echo_breaker", "active")
	return _assert_event_fields(active, {
		"target_component": "echo_window",
		"effect_kind": "copy_swallowed",
		"is_component_local": true,
	})

func test_stagger_punisher_targets_charge_gap() -> bool:
	var active := _event_for_state("stagger_punisher", "active")
	return _assert_event_fields(active, {
		"target_component": "charge_gap",
		"effect_kind": "gap_hit",
		"is_component_local": true,
	})

func test_warnings_are_not_generic_full_screen_alerts() -> bool:
	for counter_id in ["pool_polluter", "echo_breaker", "stagger_punisher"]:
		var warning := _event_for_state(counter_id, "warning")
		if warning.get("target_component", "") == "screen":
			push_error("%s warning targets full screen" % counter_id)
			return false
		if warning.get("readability_tag", "") == "generic_alert":
			push_error("%s warning uses generic alert tag" % counter_id)
			return false
	return true

func _states_for(counter_id: String) -> Array:
	var events := CounterController.new().build_counter_events(counter_id)
	var states := []
	for event in events:
		states.append(event.get("counter_state"))
	return states

func _event_for_state(counter_id: String, state: String) -> Dictionary:
	var events := CounterController.new().build_counter_events(counter_id)
	for event in events:
		if event.get("counter_state") == state:
			return event
	return {}

func _assert_duration(events: Array, state: String, expected: float, counter_id: String) -> bool:
	var event := {}
	for candidate in events:
		if candidate.get("counter_state") == state:
			event = candidate
			break
	if event.is_empty():
		push_error("%s missing state %s" % [counter_id, state])
		return false
	if not is_equal_approx(event.get("duration_seconds", -1.0), expected):
		push_error("%s %s duration expected %s, got %s" % [counter_id, state, expected, event.get("duration_seconds")])
		return false
	return true

func _assert_event_fields(event: Dictionary, expected: Dictionary) -> bool:
	if event.is_empty():
		push_error("Expected event, got empty dictionary")
		return false
	for key in expected:
		if event.get(key) != expected[key]:
			push_error("Field %s expected %s, got %s in %s" % [key, expected[key], event.get(key), event])
			return false
	return true

func _assert_array_equals(actual: Array, expected: Array, label: String) -> bool:
	if actual.size() != expected.size():
		push_error("%s expected size %d, got %d: %s" % [label, expected.size(), actual.size(), actual])
		return false
	for i in range(expected.size()):
		if actual[i] != expected[i]:
			push_error("%s expected %s, got %s" % [label, expected, actual])
			return false
	return true
