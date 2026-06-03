extends Control

func _ready() -> void:
	queue_redraw()

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
	var lane_rect := Rect2(Vector2(8, 8), size - Vector2(16, 16))
	draw_rect(lane_rect, Color(0.13, 0.12, 0.11), true)
	draw_rect(lane_rect, Color(0.90, 0.86, 0.70), false, 2.0)

	var labels := ["Prime", "Echo", "Surge"]
	for i in range(3):
		var plate := Rect2(Vector2(36, 58 + i * 72), Vector2(164, 42))
		draw_rect(plate, Color(0.23, 0.21, 0.18), true)
		draw_rect(plate, Color(0.90, 0.86, 0.70), false, 2.0)
		if labels[i] == "Prime":
			draw_rect(Rect2(plate.position + Vector2(120, 8), Vector2(24, 26)), Color(0.95, 0.88, 0.56), true)
		if labels[i] == "Echo":
			draw_circle(plate.position + Vector2(126, 21), 10.0, Color(0.78, 0.82, 1.0, 0.65))
			draw_circle(plate.position + Vector2(140, 21), 10.0, Color(0.78, 0.82, 1.0, 0.35))
		if labels[i] == "Surge":
			_draw_chevrons(plate.position + Vector2(108, 11))

func _draw_chevrons(origin: Vector2) -> void:
	for i in range(3):
		var x := origin.x + i * 14.0
		draw_line(Vector2(x, origin.y), Vector2(x + 8.0, origin.y + 10.0), Color(0.88, 0.92, 1.0), 2.0)
		draw_line(Vector2(x + 8.0, origin.y + 10.0), Vector2(x, origin.y + 20.0), Color(0.88, 0.92, 1.0), 2.0)

