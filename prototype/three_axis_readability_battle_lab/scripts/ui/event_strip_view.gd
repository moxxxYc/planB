extends Control

const LANES := ["axis_events", "counter", "overdrive", "frontline"]

var events: Array = []

func lane_ids() -> Array:
	return LANES.duplicate()

func set_events(value: Array) -> void:
	events = value.duplicate(true)
	queue_redraw()

func debug_label_is_primary() -> bool:
	return false

func _draw() -> void:
	var lane_height: float = size.y / float(max(LANES.size(), 1))
	if lane_height < 1.0:
		lane_height = 1.0
	for i in range(LANES.size()):
		var lane_rect := Rect2(Vector2(0, i * lane_height), Vector2(size.x, lane_height - 4.0))
		draw_rect(lane_rect, Color(0.08 + i * 0.025, 0.09, 0.10), true)
		draw_rect(lane_rect, Color(0.55, 0.60, 0.65), false, 1.0)

		var x := 18.0
		for event in events:
			if _lane_matches_event(LANES[i], event):
				draw_circle(Vector2(x, lane_rect.position.y + lane_height * 0.5), 5.0, Color(0.88, 0.90, 0.84))
				x += 18.0

func _lane_matches_event(lane_id: String, event: Dictionary) -> bool:
	match lane_id:
		"axis_events":
			return event.get("lane") in ["launch", "tuning", "unit"]
		"counter":
			return String(event.get("event_type", "")).begins_with("counter")
		"overdrive":
			return event.get("event_type") == "overdrive_activation"
		"frontline":
			return event.get("lane") == "frontline"
		_:
			return false
