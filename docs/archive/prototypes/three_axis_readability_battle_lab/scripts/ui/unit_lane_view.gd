extends Control

var _runtime_state := {
	"time_seconds": 0.0,
	"active_events": [],
	"elapsed_events": [],
}

func _ready() -> void:
	queue_redraw()

func set_runtime_state(state: Dictionary) -> void:
	_runtime_state = state.duplicate(true)
	queue_redraw()

func get_motion_snapshot() -> Dictionary:
	var time_seconds := float(_runtime_state.get("time_seconds", 0.0))
	return {
		"time_seconds": time_seconds,
		"charge_phase": snappedf(fmod(time_seconds * 0.22, 1.0), 0.001),
		"active_count": _runtime_state.get("active_events", []).size(),
	}

func get_readability_landmarks() -> Array:
	return [
		"Unit Slots / 出兵槽",
		"Queue / 队列",
		"Squad Bracket / 小队框",
		"Deploy / 出兵",
	]

func get_visual_grammar() -> Dictionary:
	return {
		"shape": "square slot tiles, fill chunks, queue stack, squad bracket",
		"motion": "quiet buildup followed by one bracketed group release",
		"timing": "charge gap before grouped frontline push",
		"color_only": false,
	}

func debug_label_is_primary() -> bool:
	return false

func _draw() -> void:
	var time_seconds := float(_runtime_state.get("time_seconds", 0.0))
	var charge_phase := fmod(time_seconds * 0.22, 1.0)
	var overdrive_active := _active_overdrive()
	var lane_rect := Rect2(Vector2(8, 8), size - Vector2(16, 16))
	draw_rect(lane_rect, Color(0.09, 0.13, 0.11), true)
	draw_rect(lane_rect, Color(0.74, 0.92, 0.78), false, 2.0)

	_draw_label("出兵区 Unit", Vector2(18, 30), 18, Color(0.80, 1.0, 0.84))
	_draw_label("填槽 -> 入队 -> 成组出兵", Vector2(18, 50), 12, Color(0.70, 0.88, 0.74))
	_draw_label("出兵槽 Unit Slots", Vector2(24, 82), 12, Color(0.82, 1.0, 0.86))
	for i in range(4):
		var slot := Rect2(Vector2(28 + i * 44, 96), Vector2(34, 34))
		draw_rect(slot, Color(0.18, 0.25, 0.20), true)
		draw_rect(slot, Color(0.74, 0.92, 0.78), false, 1.5)
		for chunk in range(i + 1):
			draw_rect(Rect2(slot.position + Vector2(5 + chunk * 7, 22), Vector2(5, 6)), Color(0.74, 0.92, 0.78), true)

	_draw_label("队列 Queue", Vector2(82, 158), 13, Color(0.82, 1.0, 0.86))
	for i in range(4):
		draw_rect(Rect2(Vector2(82 + charge_phase * 18.0, 178 + i * 22), Vector2(72, 14)), Color(0.68, 0.86, 0.72), true)

	_draw_label("小队框 Squad", Vector2(68, 282), 13, Color(0.92, 1.0, 0.90))
	var bracket_left := Vector2(68 + charge_phase * 12.0, 298)
	var bracket_right := Vector2(166 + charge_phase * 12.0, 390)
	draw_line(bracket_left, Vector2(bracket_left.x, bracket_right.y), Color(0.92, 1.0, 0.90), 3.0)
	draw_line(Vector2(bracket_right.x, bracket_left.y), bracket_right, Color(0.92, 1.0, 0.90), 3.0)
	draw_line(bracket_left, bracket_left + Vector2(18, 0), Color(0.92, 1.0, 0.90), 3.0)
	draw_line(Vector2(bracket_left.x, bracket_right.y), Vector2(bracket_left.x + 18, bracket_right.y), Color(0.92, 1.0, 0.90), 3.0)
	draw_line(Vector2(bracket_right.x - 18, bracket_left.y), Vector2(bracket_right.x, bracket_left.y), Color(0.92, 1.0, 0.90), 3.0)
	draw_line(Vector2(bracket_right.x - 18, bracket_right.y), bracket_right, Color(0.92, 1.0, 0.90), 3.0)
	if overdrive_active:
		var pulse := 1.0 + sin(time_seconds * 12.0) * 0.08
		draw_rect(Rect2(Vector2(58, 288), Vector2(126, 112)).grow(6.0 * pulse), Color(1.0, 0.94, 0.42), false, 3.0)
		_draw_label("Unit Overdrive: squad release", Vector2(24, 410), 11, Color(1.0, 0.94, 0.42))
	_draw_label("出兵 Deploy ->", Vector2(96 + charge_phase * 20.0, 430), 13, Color(0.92, 1.0, 0.90))

func _draw_label(text: String, label_pos: Vector2, font_size: int, color: Color) -> void:
	draw_string(get_theme_default_font(), label_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)

func _active_overdrive() -> bool:
	for event in _runtime_state.get("active_events", []):
		if event.get("event_type") == "overdrive_activation" and event.get("axis_id") == "unit":
			return true
	return false
