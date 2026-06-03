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
		"flow_offset": snappedf(fmod(time_seconds * 16.0, 20.0), 0.001),
		"active_count": _runtime_state.get("active_events", []).size(),
	}

func available_signatures() -> Array[String]:
	return ["sustained_flow", "repeated_heavy_hit", "batch_charge_release"]

func debug_label_is_primary() -> bool:
	return false

func _draw() -> void:
	var time_seconds := float(_runtime_state.get("time_seconds", 0.0))
	var flow_offset := fmod(time_seconds * 16.0, 20.0)
	var step_offset: float = floor(fmod(time_seconds * 0.8, 3.0)) * 12.0
	var batch_offset: float = max(0.0, sin(time_seconds * 1.2)) * 30.0
	var lane_rect := Rect2(Vector2(8, 8), size - Vector2(16, 16))
	draw_rect(lane_rect, Color(0.12, 0.10, 0.13), true)
	draw_rect(lane_rect, Color(0.86, 0.82, 0.92), false, 2.0)

	draw_line(Vector2(28, 78), Vector2(size.x - 28, 78), Color(0.86, 0.82, 0.92), 2.0)
	for i in range(8):
		draw_circle(Vector2(40 + i * 20 + flow_offset, 78), 5.0, Color(0.86, 0.82, 0.92))

	draw_line(Vector2(28, 152), Vector2(size.x - 28, 152), Color(0.95, 0.78, 0.70), 2.0)
	for i in range(3):
		var x: float = 70.0 + i * 48.0 + step_offset
		draw_rect(Rect2(Vector2(x, 135), Vector2(18, 34)), Color(0.95, 0.78, 0.70, 0.55), false, 2.0)

	var group_origin := Vector2(62 + batch_offset, 222)
	for i in range(5):
		draw_rect(Rect2(group_origin + Vector2(i * 18, 0), Vector2(12, 12)), Color(0.72, 0.92, 0.78), true)
	draw_rect(Rect2(group_origin - Vector2(10, 10), Vector2(112, 34)), Color(0.72, 0.92, 0.78), false, 2.0)
