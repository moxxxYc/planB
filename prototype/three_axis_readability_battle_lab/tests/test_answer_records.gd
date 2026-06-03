extends RefCounted

const AnswerRecord = preload("res://scripts/model/answer_record.gd")
const BattleSequence = preload("res://scripts/systems/battle_sequence.gd")

func test_result_screen_loads_after_battle_end() -> bool:
	var sequence = BattleSequence.new()
	sequence.start_internal_order()
	sequence.tick(75.0)
	if sequence.state != BattleSequence.STATE_RESULT_PENDING:
		push_error("Expected result pending after battle end")
		return false
	var scene := load("res://scenes/ui/result_screen.tscn")
	if scene == null or not scene.can_instantiate():
		push_error("result_screen.tscn must load")
		return false
	var root = scene.instantiate()
	var visible: bool = root.visible
	root.free()
	return visible

func test_result_screen_freezes_before_questions_and_hides_answer_key() -> bool:
	var root = load("res://scenes/ui/result_screen.tscn").instantiate()
	root.call("begin_result", "launch_flood", 1, [])
	var passed: bool = root.call("has_frozen_result") \
		and not root.call("is_answer_key_visible") \
		and root.call("questions_are_visible")
	root.free()
	if not passed:
		push_error("Result screen must freeze, show questions, and hide answer key")
		return false
	return true

func test_event_strip_has_exact_four_lanes() -> bool:
	var scene := load("res://scenes/ui/event_strip.tscn")
	if scene == null or not scene.can_instantiate():
		push_error("event_strip.tscn must load")
		return false
	var root = scene.instantiate()
	var lanes: Array = root.call("lane_ids")
	var passed := _assert_array_equals(lanes, ["axis_events", "counter", "overdrive", "frontline"], "event strip lanes")
	root.free()
	return passed

func test_answer_record_contains_required_fields() -> bool:
	var record := _valid_record()
	for key in AnswerRecord.required_fields():
		if not record.has(key):
			push_error("Record missing required field: %s" % key)
			return false
	return true

func test_answer_record_rejects_invalid_confidence_values() -> bool:
	var record := _valid_record()
	record["confidence_axis_1_to_5"] = 6
	if AnswerRecord.validate(record).is_empty():
		push_error("Confidence 6 should be rejected")
		return false
	record["confidence_axis_1_to_5"] = 0
	if AnswerRecord.validate(record).is_empty():
		push_error("Confidence 0 should be rejected")
		return false
	record["confidence_axis_1_to_5"] = 3
	return AnswerRecord.validate(record).is_empty()

func test_result_controller_exports_records_without_backend() -> bool:
	var root = load("res://scenes/ui/result_screen.tscn").instantiate()
	var record := _valid_record()
	var exported: String = root.call("export_records_csv", [record])
	root.free()
	if exported.find("player_id,battle_order,hidden_preset") == -1:
		push_error("CSV header missing required fields: %s" % exported)
		return false
	if exported.find("p1,1,launch_flood") == -1:
		push_error("CSV row missing record values: %s" % exported)
		return false
	return true

func _valid_record() -> Dictionary:
	return AnswerRecord.create({
		"player_id": "p1",
		"battle_order": 1,
		"hidden_preset": "launch_flood",
		"answer_axis": "Launch",
		"answer_counter": "Pool slots were polluted by Junk",
		"answer_overdrive": "Launch return arrows",
		"answer_frontline_cause": "Pool rhythm created sustained flow",
		"confidence_axis_1_to_5": 4,
		"confidence_counter_1_to_5": 4,
		"confidence_overdrive_1_to_5": 3,
		"confidence_frontline_1_to_5": 4,
		"observer_notes": "Named Pool and flow.",
		"correct_count_0_to_4": 3,
		"unit_only_bias_flag": false,
		"overdrive_panic_flag": false,
	})

func _assert_array_equals(actual: Array, expected: Array, label: String) -> bool:
	if actual.size() != expected.size():
		push_error("%s expected size %d, got %d: %s" % [label, expected.size(), actual.size(), actual])
		return false
	for i in range(expected.size()):
		if actual[i] != expected[i]:
			push_error("%s expected %s, got %s" % [label, expected, actual])
			return false
	return true
