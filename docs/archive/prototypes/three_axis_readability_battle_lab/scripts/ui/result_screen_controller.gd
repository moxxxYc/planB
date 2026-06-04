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
	queue_redraw()

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

func get_layout_snapshot() -> Dictionary:
	var event_strip = find_child("EventStrip", true, false)
	var frozen = find_child("FrozenBattlePanel", true, false)
	var questions = find_child("QuestionPanel", true, false)
	return {
		"answer_key_visible": _answer_key_visible,
		"has_frozen_battle_view": frozen != null,
		"event_strip_rect": _global_rect_for(event_strip),
		"frozen_battle_rect": _global_rect_for(frozen),
		"answer_panel_rect": _global_rect_for(questions),
		"event_strip_above_answer_fields": _global_rect_for(event_strip).end.y <= _global_rect_for(questions).position.y,
	}

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
	panel.add_theme_constant_override("separation", 8)

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
		answer.custom_minimum_size = Vector2(0, 30)
		panel.add_child(answer)

		var confidence := SpinBox.new()
		confidence.min_value = 1
		confidence.max_value = 5
		confidence.value = 3
		confidence.custom_minimum_size = Vector2(0, 28)
		confidence.add_to_group("battle_lab_confidence")
		panel.add_child(confidence)

func _draw() -> void:
	if not visible:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.045, 0.05, 0.96), true)
	var event_strip = find_child("EventStrip", true, false)
	var frozen = find_child("FrozenBattlePanel", true, false)
	var questions = find_child("QuestionPanel", true, false)
	_draw_panel(_local_rect_for(event_strip), "Event Strip / 事件带")
	_draw_panel(_local_rect_for(frozen), "Frozen Battle View / 战斗冻结视图")
	_draw_panel(_local_rect_for(questions), "Blind Answers / 盲答记录")
	_draw_frozen_battle(_local_rect_for(frozen))

func _draw_panel(rect: Rect2, title: String) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	draw_rect(rect, Color(0.08, 0.09, 0.10), true)
	draw_rect(rect, Color(0.62, 0.66, 0.70), false, 1.5)
	_draw_label(title, rect.position + Vector2(12, 22), 13, Color(0.88, 0.90, 0.92))

func _draw_frozen_battle(rect: Rect2) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var lane_top := rect.position.y + 54.0
	var lane_height := 70.0
	var lane_width := rect.size.x - 48.0
	var labels := ["Launch", "Tuning", "Unit", "Frontline"]
	for i in range(labels.size()):
		var lane_rect := Rect2(Vector2(rect.position.x + 24.0, lane_top + i * 92.0), Vector2(lane_width, lane_height))
		draw_rect(lane_rect, Color(0.12, 0.13, 0.15), true)
		draw_rect(lane_rect, Color(0.42, 0.46, 0.50), false, 1.0)
		_draw_label(labels[i], lane_rect.position + Vector2(10, 22), 12, Color(0.80, 0.84, 0.88))
		for mark in range(5):
			var x := lane_rect.position.x + 104.0 + mark * 44.0
			if labels[i] == "Launch":
				draw_circle(Vector2(x, lane_rect.position.y + 40.0), 7.0, Color(0.86, 0.88, 0.84))
			elif labels[i] == "Tuning":
				draw_rect(Rect2(Vector2(x - 8.0, lane_rect.position.y + 30.0), Vector2(16, 20)), Color(0.86, 0.82, 0.62), false, 2.0)
			elif labels[i] == "Unit":
				draw_rect(Rect2(Vector2(x - 8.0, lane_rect.position.y + 32.0), Vector2(16, 16)), Color(0.68, 0.86, 0.70), true)
			else:
				draw_line(Vector2(x - 12.0, lane_rect.position.y + 40.0), Vector2(x + 18.0, lane_rect.position.y + 40.0), Color(0.78, 0.80, 0.86), 2.0)

func _draw_label(text: String, label_pos: Vector2, font_size: int, color: Color) -> void:
	draw_string(get_theme_default_font(), label_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)

func _global_rect_for(node: Node) -> Rect2:
	if node == null or not node is Control:
		return Rect2()
	var control := node as Control
	return Rect2(control.global_position, control.size)

func _local_rect_for(node: Node) -> Rect2:
	if node == null or not node is Control:
		return Rect2()
	var control := node as Control
	return Rect2(control.position, control.size)

func _nodes_in_group(group_name: String) -> Array:
	var found := []
	_collect_group_nodes(self, group_name, found)
	return found

func _collect_group_nodes(node: Node, group_name: String, found: Array) -> void:
	if node.is_in_group(group_name):
		found.append(node)
	for child in node.get_children():
		_collect_group_nodes(child, group_name, found)
