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
		"echo_phase": snappedf(fmod(time_seconds * 0.35, 1.0), 0.001),
		"active_count": _runtime_state.get("active_events", []).size(),
	}

func get_readability_landmarks() -> Array:
	return [
		"Prime / 预充",
		"Echo / 复写",
		"Surge / 脉冲",
		"Copy Afterimage / 复写残影",
	]

func get_visual_grammar() -> Dictionary:
	return {
		"shape": "slot plates, Prime plaque, Echo ghost afterimages, Surge chevrons",
		"motion": "copy afterimage appears after the hit, then chevrons move toward Unit",
		"timing": "delayed repeated pulse before stepped frontline impact",
		"color_only": false,
	}

func debug_label_is_primary() -> bool:
	return false

func _draw() -> void:
	var time_seconds := float(_runtime_state.get("time_seconds", 0.0))
	var echo_phase := fmod(time_seconds * 0.35, 1.0)
	var lane_rect := Rect2(Vector2(8, 8), size - Vector2(16, 16))
	draw_rect(lane_rect, Color(0.13, 0.12, 0.11), true)
	draw_rect(lane_rect, Color(0.90, 0.86, 0.70), false, 2.0)

	_draw_label("调校区 Tuning", Vector2(18, 30), 18, Color(0.98, 0.94, 0.76))
	_draw_label("球命中槽位后改变出兵", Vector2(18, 50), 12, Color(0.86, 0.82, 0.68))

	var labels := ["Prime", "Echo", "Surge"]
	for i in range(3):
		var plate := Rect2(Vector2(28, 86 + i * 82), Vector2(178, 48))
		draw_rect(plate, Color(0.23, 0.21, 0.18), true)
		draw_rect(plate, Color(0.90, 0.86, 0.70), false, 2.0)
		var label := ""
		match labels[i]:
			"Prime":
				label = "Prime 预充"
			"Echo":
				label = "Echo 复写"
			"Surge":
				label = "Surge 脉冲"
		_draw_label(label, plate.position + Vector2(8, 20), 13, Color(0.98, 0.94, 0.76))
		if labels[i] == "Prime":
			draw_rect(Rect2(plate.position + Vector2(120, 8), Vector2(24, 26)), Color(0.95, 0.88, 0.56), true)
		if labels[i] == "Echo":
			draw_circle(plate.position + Vector2(116 + echo_phase * 20.0, 21), 10.0, Color(0.78, 0.82, 1.0, 0.70))
			draw_circle(plate.position + Vector2(140 + echo_phase * 12.0, 21), 10.0, Color(0.78, 0.82, 1.0, 0.35))
			_draw_label("复写残影", plate.position + Vector2(92, 42), 10, Color(0.78, 0.82, 1.0))
		if labels[i] == "Surge":
			_draw_chevrons(plate.position + Vector2(108 + echo_phase * 10.0, 11))

func _draw_chevrons(origin: Vector2) -> void:
	for i in range(3):
		var x := origin.x + i * 14.0
		draw_line(Vector2(x, origin.y), Vector2(x + 8.0, origin.y + 10.0), Color(0.88, 0.92, 1.0), 2.0)
		draw_line(Vector2(x + 8.0, origin.y + 10.0), Vector2(x, origin.y + 20.0), Color(0.88, 0.92, 1.0), 2.0)

func _draw_label(text: String, label_pos: Vector2, font_size: int, color: Color) -> void:
	draw_string(get_theme_default_font(), label_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
