extends Control

func _ready() -> void:
	queue_redraw()

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
	var lane_rect := Rect2(Vector2(8, 8), size - Vector2(16, 16))
	draw_rect(lane_rect, Color(0.09, 0.13, 0.11), true)
	draw_rect(lane_rect, Color(0.74, 0.92, 0.78), false, 2.0)

	for i in range(4):
		var slot := Rect2(Vector2(28 + i * 44, 62), Vector2(34, 34))
		draw_rect(slot, Color(0.18, 0.25, 0.20), true)
		draw_rect(slot, Color(0.74, 0.92, 0.78), false, 1.5)
		for chunk in range(i + 1):
			draw_rect(Rect2(slot.position + Vector2(5 + chunk * 7, 22), Vector2(5, 6)), Color(0.74, 0.92, 0.78), true)

	for i in range(4):
		draw_rect(Rect2(Vector2(82, 140 + i * 22), Vector2(72, 14)), Color(0.68, 0.86, 0.72), true)

	var bracket_left := Vector2(68, 132)
	var bracket_right := Vector2(166, 224)
	draw_line(bracket_left, Vector2(bracket_left.x, bracket_right.y), Color(0.92, 1.0, 0.90), 3.0)
	draw_line(Vector2(bracket_right.x, bracket_left.y), bracket_right, Color(0.92, 1.0, 0.90), 3.0)
	draw_line(bracket_left, bracket_left + Vector2(18, 0), Color(0.92, 1.0, 0.90), 3.0)
	draw_line(Vector2(bracket_left.x, bracket_right.y), Vector2(bracket_left.x + 18, bracket_right.y), Color(0.92, 1.0, 0.90), 3.0)
	draw_line(Vector2(bracket_right.x - 18, bracket_left.y), Vector2(bracket_right.x, bracket_left.y), Color(0.92, 1.0, 0.90), 3.0)
	draw_line(Vector2(bracket_right.x - 18, bracket_right.y), bracket_right, Color(0.92, 1.0, 0.90), 3.0)

