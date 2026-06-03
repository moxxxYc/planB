extends Control

const AnswerRecord = preload("res://scripts/model/answer_record.gd")

var _frozen_result := false
var _answer_key_visible := false
var _questions_visible := false
var _hidden_preset := ""
var _battle_order := 0
var _events: Array = []
var _questions_created := false

func begin_result(hidden_preset: String, battle_order: int, events: Array) -> void:
	_ensure_question_controls()
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

func question_count() -> int:
	_ensure_question_controls()
	return _nodes_in_group("battle_lab_question").size()

func confidence_count() -> int:
	_ensure_question_controls()
	return _nodes_in_group("battle_lab_confidence").size()

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

func _ensure_question_controls() -> void:
	if _questions_created:
		return
	_questions_created = true
	var panel = find_child("QuestionPanel", true, false)
	if panel == null:
		panel = VBoxContainer.new()
		panel.name = "QuestionPanel"
		add_child(panel)

	var questions := [
		"What was the main axis this battle? / 这场主轴是什么?",
		"How did the enemy disrupt it? / 敌人打断了哪里?",
		"What did Overdrive amplify? / 过载放大了什么?",
		"Why did the frontline change? / 前线为什么变化?",
	]
	for question_text in questions:
		var label := Label.new()
		label.text = question_text
		label.add_to_group("battle_lab_question")
		panel.add_child(label)

		var answer := LineEdit.new()
		answer.placeholder_text = "Record answer before revealing key"
		panel.add_child(answer)

		var confidence := SpinBox.new()
		confidence.min_value = 1
		confidence.max_value = 5
		confidence.value = 3
		confidence.add_to_group("battle_lab_confidence")
		panel.add_child(confidence)

func _nodes_in_group(group_name: String) -> Array:
	var found := []
	_collect_group_nodes(self, group_name, found)
	return found

func _collect_group_nodes(node: Node, group_name: String, found: Array) -> void:
	if node.is_in_group(group_name):
		found.append(node)
	for child in node.get_children():
		_collect_group_nodes(child, group_name, found)
