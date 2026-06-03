extends Control

func _ready() -> void:
	queue_redraw()

func available_signatures() -> Array[String]:
	return ["sustained_flow", "repeated_heavy_hit", "batch_charge_release"]

func debug_label_is_primary() -> bool:
	return false

func _draw() -> void:
	var lane_rect := Rect2(Vector2(8, 8), size - Vector2(16, 16))
	draw_rect(lane_rect, Color(0.12, 0.10, 0.13), true)
	draw_rect(lane_rect, Color(0.86, 0.82, 0.92), false, 2.0)

	draw_line(Vector2(28, 78), Vector2(size.x - 28, 78), Color(0.86, 0.82, 0.92), 2.0)
	for i in range(8):
		draw_circle(Vector2(40 + i * 20, 78), 5.0, Color(0.86, 0.82, 0.92))

	draw_line(Vector2(28, 152), Vector2(size.x - 28, 152), Color(0.95, 0.78, 0.70), 2.0)
	for i in range(3):
		var x := 70 + i * 48
		draw_rect(Rect2(Vector2(x, 135), Vector2(18, 34)), Color(0.95, 0.78, 0.70, 0.55), false, 2.0)

	var group_origin := Vector2(62, 222)
	for i in range(5):
		draw_rect(Rect2(group_origin + Vector2(i * 18, 0), Vector2(12, 12)), Color(0.72, 0.92, 0.78), true)
	draw_rect(Rect2(group_origin - Vector2(10, 10), Vector2(112, 34)), Color(0.72, 0.92, 0.78), false, 2.0)

