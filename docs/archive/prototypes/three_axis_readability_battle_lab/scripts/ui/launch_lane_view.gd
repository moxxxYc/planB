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

func get_readability_landmarks() -> Array:
	return [
		"Forge / 产球",
		"Pool / 球池",
		"Launcher / 发射器",
		"Fired Ball / 发出的球",
		"Route / 发球路线",
	]

func get_visual_grammar() -> Dictionary:
	return {
		"shape": "labeled Forge box, FIFO Pool slots, launcher cannon, fired ball, route arrow, return arrow",
		"motion": "Forge pulse feeds Pool, Pool head moves to Launcher, fired ball travels along Route",
		"timing": "Forge/Pool/Launcher rhythm precedes sustained frontline flow",
		"color_only": false,
	}

func debug_label_is_primary() -> bool:
	return false

func _draw() -> void:
	var time_seconds := float(_runtime_state.get("time_seconds", 0.0))
	var launch_phase := fmod(time_seconds * 0.55, 1.0)
	var forge_phase := fmod(time_seconds * 1.0, 1.0)
	var return_phase := fmod(time_seconds * 0.42, 1.0)
	var lane_rect := Rect2(Vector2(8, 8), size - Vector2(16, 16))
	draw_rect(lane_rect, Color(0.10, 0.12, 0.14), true)
	draw_rect(lane_rect, Color(0.85, 0.90, 0.95), false, 2.0)

	_draw_label("发球区 Launch", Vector2(18, 30), 18, Color(0.95, 0.98, 1.0))

	var forge_rect := Rect2(Vector2(24, 54), Vector2(78, 44))
	draw_rect(forge_rect, Color(0.17, 0.21, 0.24), true)
	draw_rect(forge_rect, Color(0.85, 0.90, 0.95), false, 1.5)
	_draw_label("产球 Forge", forge_rect.position + Vector2(6, 18), 12, Color(0.95, 0.98, 1.0))
	draw_circle(forge_rect.position + Vector2(62, 22), 7.0 + sin(time_seconds * 8.0) * 2.0, Color(0.95, 0.95, 0.92))

	var pool_label_pos := Vector2(18, 122)
	_draw_label("球池 Pool - FIFO", pool_label_pos, 13, Color(0.95, 0.98, 1.0))
	var slot_y := 134.0
	var pool_warning := _active_counter_state() == "warning"
	var pool_active := _active_counter_state() == "active"
	for i in range(5):
		var slot := Rect2(Vector2(18 + i * 38, slot_y), Vector2(28, 34))
		draw_rect(slot, Color(0.18, 0.20, 0.23), true)
		draw_rect(slot, Color(0.85, 0.90, 0.95), false, 1.5 if i == 0 else 1.0)
		var bob := sin(time_seconds * 4.0 + i) * 3.0
		if pool_warning and i >= 2:
			draw_circle(slot.get_center(), 9.0, Color(0.55, 0.55, 0.60, 0.45))
			_draw_label("J", slot.position + Vector2(10, 22), 10, Color(0.95, 0.80, 0.80))
		elif pool_active and i >= 2:
			draw_circle(slot.get_center(), 9.0, Color(0.35, 0.35, 0.40))
			_draw_label("J", slot.position + Vector2(10, 22), 10, Color(1.0, 0.70, 0.70))
		else:
			draw_circle(slot.get_center() + Vector2(0, bob), 9.0, Color(0.95, 0.95, 0.92))
		if i == 0:
			_draw_label("head", slot.position + Vector2(-2, 50), 10, Color(0.92, 0.95, 1.0))

	var forge_to_pool_start := forge_rect.position + Vector2(78, 22)
	var forge_to_pool_end := Vector2(40 + forge_phase * 72.0, slot_y - 12)
	_draw_arrow(forge_to_pool_start, forge_to_pool_end, Color(0.70, 0.86, 0.95), 2.0)
	draw_circle(forge_to_pool_end, 5.0, Color(0.95, 0.95, 0.92))

	var launcher_center := Vector2(184, 248)
	_draw_label("发射器", Vector2(140, 218), 13, Color(0.95, 0.98, 1.0))
	_draw_label("Launcher", Vector2(137, 235), 11, Color(0.82, 0.88, 0.95))
	draw_circle(launcher_center, 21.0 + sin(time_seconds * 5.0) * 1.5, Color(0.90, 0.90, 0.86))
	draw_rect(Rect2(launcher_center + Vector2(-44, -8), Vector2(42, 16)), Color(0.20, 0.23, 0.25), true)
	draw_rect(Rect2(launcher_center + Vector2(-44, -8), Vector2(42, 16)), Color(0.85, 0.90, 0.95), false, 1.5)

	var pool_to_launcher_from := Vector2(32 + launch_phase * 92.0, slot_y + 58)
	_draw_arrow(pool_to_launcher_from, launcher_center - Vector2(24, 0), Color(0.92, 0.92, 0.88), 3.0)
	draw_circle(pool_to_launcher_from, 8.0, Color(0.98, 0.98, 0.92))

	_draw_label("发出的球 Fired Ball", Vector2(24, 304), 13, Color(0.95, 0.98, 1.0))
	_draw_label("发球路线 Route -> 调校区", Vector2(24, 344), 13, Color(0.95, 0.98, 1.0))
	var route_start := Vector2(44, 326)
	var route_end := Vector2(size.x - 22.0, 326)
	_draw_arrow(route_start, route_end, Color(0.92, 0.92, 0.88), 3.0)
	draw_circle(route_start.lerp(route_end, launch_phase), 10.0, Color(1.0, 0.98, 0.84))

	_draw_label("回流 Return", Vector2(24, 398), 13, Color(0.76, 0.95, 0.85))
	_draw_arrow(Vector2(190, 420), Vector2(56, 420), Color(0.72, 0.90, 0.82), 3.0)
	draw_circle(Vector2(190 - return_phase * 134.0, 420), 10.0, Color(0.72, 0.90, 0.82))
	if pool_warning:
		_draw_label("Pool Polluter 警告: Junk 将占球池", Vector2(18, 188), 11, Color(1.0, 0.78, 0.72))
	if pool_active:
		_draw_label("Junk 占位: 发射节奏被卡住", Vector2(18, 188), 11, Color(1.0, 0.62, 0.62))
	if _active_overdrive():
		var pulse := 1.0 + sin(time_seconds * 12.0) * 0.08
		draw_circle(launcher_center, 30.0 * pulse, Color(1.0, 0.90, 0.35, 0.30))
		draw_rect(Rect2(Vector2(18, 388), Vector2(196, 42)), Color(0.95, 0.86, 0.40, 0.28), true)
		draw_rect(Rect2(Vector2(18, 388), Vector2(196, 42)), Color(1.0, 0.98, 0.70), false, 2.0)
		_draw_label("Launch Overdrive: Return + Launcher", Vector2(24, 414), 11, Color(1.0, 0.96, 0.62))

func _draw_arrow(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	draw_line(from, to, color, width)
	var direction := (to - from).normalized()
	var normal := Vector2(-direction.y, direction.x)
	draw_line(to, to - direction * 12.0 + normal * 7.0, color, width)
	draw_line(to, to - direction * 12.0 - normal * 7.0, color, width)

func _draw_label(text: String, label_pos: Vector2, font_size: int, color: Color) -> void:
	draw_string(get_theme_default_font(), label_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)

func _has_elapsed_event(event_type: String) -> bool:
	for event in _runtime_state.get("elapsed_events", []):
		if event.get("event_type") == event_type:
			return true
	return false

func _active_counter_state() -> String:
	for event in _runtime_state.get("active_events", []):
		if String(event.get("event_type", "")).begins_with("counter"):
			return event.get("counter_state", "")
	return ""

func _active_overdrive() -> bool:
	for event in _runtime_state.get("active_events", []):
		if event.get("event_type") == "overdrive_activation" and event.get("axis_id") == "launch":
			return true
	return false
