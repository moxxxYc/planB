extends Control

const AnswerRecord = preload("res://scripts/model/answer_record.gd")

var _frozen_result := false
var _answer_key_visible := false
var _questions_visible := false
var _hidden_preset := ""
var _battle_order := 0
var _events: Array = []

func begin_result(hidden_preset: String, battle_order: int, events: Array) -> void:
	visible = true
	_frozen_result = true
	_answer_key_visible = false
	_questions_visible = true
	_hidden_preset = hidden_preset
	_battle_order = battle_order
	_events = events.duplicate(true)
	var strip = find_child("EventStrip", true, false)
	if strip != null and strip.has_method("set_events"):
		strip.call("set_events", _events)

func has_frozen_result() -> bool:
	return _frozen_result

func is_answer_key_visible() -> bool:
	return _answer_key_visible

func questions_are_visible() -> bool:
	return _questions_visible

func create_answer_record(values: Dictionary) -> Dictionary:
	var merged := values.duplicate()
	merged["hidden_preset"] = merged.get("hidden_preset", _hidden_preset)
	merged["battle_order"] = merged.get("battle_order", _battle_order)
	return AnswerRecord.create(merged)

func export_records_csv(records: Array) -> String:
	var fields := AnswerRecord.required_fields()
	var lines := [",".join(fields)]
	for record in records:
		var row := []
		for field in fields:
			row.append(_csv_cell(record.get(field, "")))
		lines.append(",".join(row))
	return "\n".join(lines)

func _csv_cell(value) -> String:
	var text := str(value)
	if text.find(",") != -1 or text.find("\"") != -1 or text.find("\n") != -1:
		text = "\"" + text.replace("\"", "\"\"") + "\""
	return text

