extends Control

const PresetDefs = preload("res://scripts/model/preset_defs.gd")

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
	var primary_signature := _primary_signature()
	return {
		"time_seconds": time_seconds,
		"flow_offset": snappedf(fmod(time_seconds * 16.0, 20.0), 0.001),
		"primary_signature": primary_signature,
		"signature_weights": _signature_weights(primary_signature),
		"active_count": _runtime_state.get("active_events", []).size(),
	}

func available_signatures() -> Array[String]:
	return ["sustained_flow", "repeated_heavy_hit", "batch_charge_release"]

func get_readability_landmarks() -> Array:
	return [
		"Sustained Flow / 持续水位",
		"Repeated Heavy Hit / 重复重击",
		"Batch Push / 成组推进",
		"Pressure Line / 战线",
	]

func debug_label_is_primary() -> bool:
	return false

func _draw() -> void:
	var time_seconds := float(_runtime_state.get("time_seconds", 0.0))
	var primary_signature := _primary_signature()
	var lane_rect := Rect2(Vector2(8, 8), size - Vector2(16, 16))
	draw_rect(lane_rect, Color(0.12, 0.10, 0.13), true)
	draw_rect(lane_rect, Color(0.86, 0.82, 0.92), false, 2.0)

	_draw_label("前线 Frontline", Vector2(18, 30), 18, Color(0.92, 0.88, 1.0))
	_draw_label("战线 Pressure Line", Vector2(18, 52), 12, Color(0.80, 0.76, 0.88))

	var primary_rect := Rect2(Vector2(24, 82), Vector2(size.x - 48.0, 258))
	draw_rect(primary_rect, Color(0.07, 0.07, 0.08), true)
	draw_rect(primary_rect, Color(1.0, 0.96, 0.72), false, 2.5)
	_draw_label("P0 当前: %s" % _signature_label(primary_signature), primary_rect.position + Vector2(12, 28), 14, Color(1.0, 0.96, 0.72))
	_draw_signature(primary_signature, primary_rect.grow(-18.0), time_seconds, true)

	var inactive_y := 382.0
	_draw_label("低权重参考 / not competing", Vector2(24, inactive_y - 16.0), 10, Color(0.58, 0.58, 0.62))
	var slot_width: float = max(84.0, (size.x - 64.0) / 3.0)
	var slot_index := 0
	for signature_id in available_signatures():
		if signature_id == primary_signature:
			continue
		var slot_rect := Rect2(Vector2(24 + slot_index * (slot_width + 8.0), inactive_y), Vector2(slot_width, 74))
		draw_rect(slot_rect, Color(0.07, 0.07, 0.08, 0.55), true)
		draw_rect(slot_rect, Color(0.42, 0.42, 0.46), false, 1.0)
		_draw_label(_short_signature_label(signature_id), slot_rect.position + Vector2(8, 18), 9, Color(0.50, 0.50, 0.54))
		_draw_signature(signature_id, slot_rect.grow(-10.0), time_seconds, false)
		slot_index += 1

func _draw_signature(signature_id: String, rect: Rect2, time_seconds: float, primary: bool) -> void:
	match signature_id:
		PresetDefs.SUSTAINED_FLOW:
			_draw_sustained_flow(rect, time_seconds, primary)
		PresetDefs.REPEATED_HEAVY_HIT:
			_draw_repeated_heavy_hit(rect, time_seconds, primary)
		PresetDefs.BATCH_CHARGE_RELEASE:
			_draw_batch_push(rect, time_seconds, primary)

func _draw_sustained_flow(rect: Rect2, time_seconds: float, primary: bool) -> void:
	var alpha := 1.0 if primary else 0.25
	var width := 4.0 if primary else 1.5
	var y := rect.position.y + rect.size.y * 0.55
	var left := rect.position.x + 8.0
	var right := rect.end.x - 8.0
	draw_line(Vector2(left, y), Vector2(right, y), Color(0.82, 0.90, 1.0, alpha), width)
	var flow_offset := fmod(time_seconds * (28.0 if primary else 10.0), 28.0)
	for i in range(10 if primary else 4):
		var x := left + fmod(i * 32.0 + flow_offset, max(1.0, right - left))
		draw_circle(Vector2(x, y), 7.0 if primary else 3.0, Color(0.82, 0.90, 1.0, alpha))
	if primary:
		_draw_label("持续流: 小球连续推高压力线", Vector2(left, y + 42.0), 12, Color(0.82, 0.90, 1.0))

func _draw_repeated_heavy_hit(rect: Rect2, time_seconds: float, primary: bool) -> void:
	var alpha := 1.0 if primary else 0.25
	var width := 4.0 if primary else 1.5
	var y := rect.position.y + rect.size.y * 0.55
	var left := rect.position.x + 10.0
	var right := rect.end.x - 10.0
	draw_line(Vector2(left, y), Vector2(right, y), Color(1.0, 0.76, 0.66, alpha), width)
	var active_hit := int(floor(fmod(time_seconds * 1.8, 3.0)))
	for i in range(3):
		var hit_size := 32.0 if primary and i == active_hit else 22.0
		var x := left + 42.0 + i * 62.0
		draw_rect(Rect2(Vector2(x, y - hit_size * 0.5), Vector2(hit_size, hit_size)), Color(1.0, 0.76, 0.66, alpha), false, width)
		draw_line(Vector2(x - 8.0, y - 32.0), Vector2(x + hit_size + 8.0, y + 32.0), Color(1.0, 0.76, 0.66, alpha), 2.0 if primary else 1.0)
	if primary:
		_draw_label("重复重击: 同一打击被复写成多次命中", Vector2(left, y + 48.0), 12, Color(1.0, 0.76, 0.66))

func _draw_batch_push(rect: Rect2, time_seconds: float, primary: bool) -> void:
	var alpha := 1.0 if primary else 0.25
	var width := 4.0 if primary else 1.5
	var release_phase := fmod(time_seconds * 0.55, 1.0)
	var y := rect.position.y + rect.size.y * 0.55
	var left := rect.position.x + 18.0
	var push := release_phase * (rect.size.x * 0.38 if primary else rect.size.x * 0.18)
	var group_origin := Vector2(left + push, y - 12.0)
	for i in range(6 if primary else 3):
		draw_rect(Rect2(group_origin + Vector2(i * 18.0, 0), Vector2(12, 12)), Color(0.72, 1.0, 0.78, alpha), true)
	draw_rect(Rect2(group_origin - Vector2(10, 12), Vector2(132 if primary else 70, 36)), Color(0.72, 1.0, 0.78, alpha), false, width)
	draw_line(Vector2(rect.end.x - 34.0, rect.position.y + 28.0), Vector2(rect.end.x - 34.0, rect.end.y - 18.0), Color(0.72, 1.0, 0.78, alpha), width)
	if primary:
		var charge_width: float = max(16.0, release_phase * 120.0)
		draw_rect(Rect2(Vector2(left, rect.position.y + 42.0), Vector2(charge_width, 10)), Color(0.72, 1.0, 0.78, 0.75), true)
		_draw_label("批量冲锋: 安静蓄队后整组推出", Vector2(left, y + 48.0), 12, Color(0.72, 1.0, 0.78))

func _primary_signature() -> String:
	match _runtime_state.get("preset_id", PresetDefs.LAUNCH_FLOOD):
		PresetDefs.LAUNCH_FLOOD:
			return PresetDefs.SUSTAINED_FLOW
		PresetDefs.TUNING_ECHO:
			return PresetDefs.REPEATED_HEAVY_HIT
		PresetDefs.UNIT_QUEUE_BURST:
			return PresetDefs.BATCH_CHARGE_RELEASE
		_:
			return PresetDefs.SUSTAINED_FLOW

func _signature_weights(primary_signature: String) -> Dictionary:
	var weights := {}
	for signature_id in available_signatures():
		weights[signature_id] = 1.0 if signature_id == primary_signature else 0.18
	return weights

func _signature_label(signature_id: String) -> String:
	match signature_id:
		PresetDefs.SUSTAINED_FLOW:
			return "持续水位 Sustained Flow"
		PresetDefs.REPEATED_HEAVY_HIT:
			return "重复重击 Repeated Heavy Hit"
		PresetDefs.BATCH_CHARGE_RELEASE:
			return "成组推进 Batch Push"
		_:
			return signature_id

func _short_signature_label(signature_id: String) -> String:
	match signature_id:
		PresetDefs.SUSTAINED_FLOW:
			return "Flow"
		PresetDefs.REPEATED_HEAVY_HIT:
			return "Repeat Hit"
		PresetDefs.BATCH_CHARGE_RELEASE:
			return "Batch"
		_:
			return signature_id

func _draw_label(text: String, label_pos: Vector2, font_size: int, color: Color) -> void:
	draw_string(get_theme_default_font(), label_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
