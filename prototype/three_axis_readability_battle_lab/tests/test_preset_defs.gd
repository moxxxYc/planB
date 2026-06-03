extends RefCounted

const AxisIds = preload("res://scripts/model/axis_ids.gd")
const PresetDefs = preload("res://scripts/model/preset_defs.gd")

func test_axis_ids_are_exact() -> bool:
	var axis_ids := AxisIds.all_axis_ids()
	return _assert_array_equals(axis_ids, ["launch", "tuning", "unit"], "axis ids")

func test_tuning_slot_ids_are_exact() -> bool:
	var tuning_slot_ids := AxisIds.all_tuning_slot_ids()
	return _assert_array_equals(tuning_slot_ids, ["prime", "echo", "surge"], "tuning slot ids")

func test_preset_ids_are_exact() -> bool:
	var preset_ids := PresetDefs.all_preset_ids()
	return _assert_array_equals(preset_ids, ["launch_flood", "tuning_echo", "unit_queue_burst"], "preset ids")

func test_each_preset_has_one_axis_counter_signature_and_overdrive() -> bool:
	for preset_id in PresetDefs.all_preset_ids():
		var preset := PresetDefs.get_preset(preset_id)
		if not _assert_has_string(preset, "primary_axis_id", preset_id):
			return false
		if not _assert_has_string(preset, "counter_id", preset_id):
			return false
		if not _assert_has_string(preset, "frontline_signature", preset_id):
			return false
		if not _assert_has_string(preset, "overdrive_label", preset_id):
			return false
	return true

func test_preset_mappings_are_exact() -> bool:
	var expected := {
		"launch_flood": {
			"primary_axis_id": "launch",
			"counter_id": "pool_polluter",
			"frontline_signature": "sustained_flow",
			"overdrive_label": "Launch Overdrive",
		},
		"tuning_echo": {
			"primary_axis_id": "tuning",
			"counter_id": "echo_breaker",
			"frontline_signature": "repeated_heavy_hit",
			"overdrive_label": "Tuning Overdrive",
		},
		"unit_queue_burst": {
			"primary_axis_id": "unit",
			"counter_id": "stagger_punisher",
			"frontline_signature": "batch_charge_release",
			"overdrive_label": "Unit Overdrive",
		},
	}

	for preset_id in expected:
		var preset := PresetDefs.get_preset(preset_id)
		for key in expected[preset_id]:
			if preset.get(key) != expected[preset_id][key]:
				push_error("%s.%s expected %s, got %s" % [preset_id, key, expected[preset_id][key], preset.get(key)])
				return false
	return true

func test_battle_duration_is_exactly_75_seconds() -> bool:
	for preset_id in PresetDefs.all_preset_ids():
		var preset := PresetDefs.get_preset(preset_id)
		if not is_equal_approx(preset.get("battle_duration_seconds"), 75.0):
			push_error("%s has wrong duration: %s" % [preset_id, preset.get("battle_duration_seconds")])
			return false
	return true

func test_presets_do_not_include_out_of_scope_fields() -> bool:
	var banned_fields := [
		"shop",
		"race",
		"races",
		"relic",
		"relics",
		"gold",
		"economy",
		"event",
		"events",
		"elite",
		"boss",
	]

	for preset_id in PresetDefs.all_preset_ids():
		var preset := PresetDefs.get_preset(preset_id)
		for field in banned_fields:
			if preset.has(field):
				push_error("%s contains out-of-scope field: %s" % [preset_id, field])
				return false
	return true

func _assert_has_string(value: Dictionary, key: String, context: String) -> bool:
	if not value.has(key):
		push_error("%s missing key: %s" % [context, key])
		return false
	if typeof(value[key]) != TYPE_STRING or value[key].is_empty():
		push_error("%s.%s must be a non-empty string" % [context, key])
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
