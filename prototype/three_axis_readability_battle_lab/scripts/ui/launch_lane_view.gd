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
		"ball_phase": snappedf(fmod(time_seconds * 0.55, 1.0), 0.001),
		"return_pulse": _has_elapsed_event("front_return_arrow"),
		"active_count": _runtime_state.get("active_events", []).size(),
	}

func get_visual_grammar() -> Dictionary:
	return {
		"shape": "round balls, FIFO slots, thick Pool-head outline, forward and return arrows",
		"motion": "small repeated pulses from Pool to Launcher, then return arrows near the front",
		"timing": "frequent low-amplitude rhythm before sustained frontline flow",
		"color_only": false,
	}

func debug_label_is_primary() -> bool:
	return false

func _draw() -> void:
	var time_seconds := float(_runtime_state.get("time_seconds", 0.0))
	var launch_phase := fmod(time_seconds * 0.55, 1.0)
	var return_phase := fmod(time_seconds * 0.42, 1.0)
	var lane_rect := Rect2(Vector2(8, 8), size - Vector2(16, 16))
	draw_rect(lane_rect, Color(0.10, 0.12, 0.14), true)
	draw_rect(lane_rect, Color(0.85, 0.90, 0.95), false, 2.0)

	var slot_y := 84.0
	for i in range(5):
		var slot := Rect2(Vector2(22 + i * 38, slot_y), Vector2(28, 34))
		draw_rect(slot, Color(0.18, 0.20, 0.23), true)
		draw_rect(slot, Color(0.85, 0.90, 0.95), false, 1.5 if i == 0 else 1.0)
		var bob := sin(time_seconds * 4.0 + i) * 3.0
		draw_circle(slot.get_center() + Vector2(0, bob), 9.0, Color(0.95, 0.95, 0.92))

	_draw_arrow(Vector2(54, 156), Vector2(176, 156), Color(0.92, 0.92, 0.88), 3.0)
	_draw_arrow(Vector2(176, 216), Vector2(72, 216), Color(0.72, 0.90, 0.82), 3.0)
	draw_circle(Vector2(54 + launch_phase * 122.0, 156), 10.0, Color(0.98, 0.98, 0.92))
	draw_circle(Vector2(188, 156), 18.0 + sin(time_seconds * 5.0) * 2.0, Color(0.90, 0.90, 0.86))
	draw_circle(Vector2(176 - return_phase * 104.0, 216), 12.0, Color(0.72, 0.90, 0.82))

func _draw_arrow(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	draw_line(from, to, color, width)
	var direction := (to - from).normalized()
	var normal := Vector2(-direction.y, direction.x)
	draw_line(to, to - direction * 12.0 + normal * 7.0, color, width)
	draw_line(to, to - direction * 12.0 - normal * 7.0, color, width)

func _has_elapsed_event(event_type: String) -> bool:
	for event in _runtime_state.get("elapsed_events", []):
		if event.get("event_type") == event_type:
			return true
	return false
