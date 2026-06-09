class_name MachineCausalityView
extends Control

const ModelScript := preload("res://scripts/ball_machine/machine_causality_model.gd")

const COLOR_BG := Color("#171a18")
const COLOR_PANEL := Color("#252923")
const COLOR_PANEL_DIM := Color("#1c201d")
const COLOR_TEXT := Color("#e8e1d2")
const COLOR_LAUNCH := Color("#7bcb6b")
const COLOR_TUNING := Color("#e6b450")
const COLOR_UNIT := Color("#c58be8")
const COLOR_ACTIVE := Color("#f4f0d8")
const COLOR_WARNING := Color("#e84b4b")
const COLOR_BLOCKER := Color(0.9, 0.9, 0.9, 0.28)
const TEXT_SCALE := 1.22
const DESIGN_SIZE := Vector2(760, 640)

var model: RefCounted = null


func _ready() -> void:
	custom_minimum_size = Vector2(560, 500)


func set_model(next_model: RefCounted) -> void:
	model = next_model
	queue_redraw()


func _draw() -> void:
	if model == null:
		return

	var bounds := Rect2(Vector2.ZERO, size)
	draw_rect(bounds, COLOR_BG, true)
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var draw_scale: float = min(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	var draw_offset: Vector2 = (size - DESIGN_SIZE * draw_scale) * 0.5
	draw_set_transform(draw_offset, 0.0, Vector2(draw_scale, draw_scale))

	var supply: Dictionary = model.get_supply_summary()
	var motion: Dictionary = model.get_motion_summary()
	var active_board := str(motion.get("active_board", "Launch"))
	_draw_supply(Rect2(24, 18, 690, 72), supply)
	_draw_board(
		Rect2(24, 108, 690, 128),
		"Launch",
		["Tuning", "Split", "Recycle", "Waste"],
		COLOR_LAUNCH,
		active_board == "Launch"
	)
	_draw_board(
		Rect2(24, 254, 690, 128),
		"Tuning",
		model.TUNING_RESULTS,
		COLOR_TUNING,
		active_board == "Tuning"
	)
	_draw_unit_board(Rect2(24, 400, 690, 178), active_board == "Unit")
	_draw_queue_bridge(Rect2(438, 590, 276, 38))
	_draw_active_ball()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_supply(rect: Rect2, supply: Dictionary) -> void:
	var motion: Dictionary = model.get_motion_summary()
	draw_rect(rect, COLOR_PANEL, true)
	draw_rect(rect, COLOR_LAUNCH, false, 2.0)
	_draw_text("造球器 / 球池 / 发射器", rect.position + Vector2(14, 24), 18, COLOR_TEXT)
	_draw_text("造球器", rect.position + Vector2(18, 57), 14, COLOR_LAUNCH)

	var pool_origin := rect.position + Vector2(116, 44)
	var pool_count: int = supply.get("pool_count", 0)
	var pool_capacity: int = supply.get("pool_capacity", 5)
	for index in range(pool_capacity):
		var pos: Vector2 = pool_origin + Vector2(index * 24.0, 0.0)
		var color: Color = COLOR_LAUNCH if index < pool_count else Color(0.45, 0.48, 0.44, 1.0)
		draw_circle(pos, 8.0, color)
		draw_arc(pos, 10.0, 0.0, TAU, 24, COLOR_TEXT, 1.0)

	_draw_text("球池 %d / %d" % [pool_count, pool_capacity], rect.position + Vector2(258, 57), 14, COLOR_TEXT)
	_draw_text("发射器", rect.position + Vector2(390, 57), 14, COLOR_LAUNCH)
	var pivot := rect.position + Vector2(490, 46)
	var cannon_angle := -0.22 + float(motion.get("cannon_angle", 0.0))
	var barrel_end := pivot + Vector2(cos(cannon_angle), sin(cannon_angle)) * 78.0
	draw_line(pivot, barrel_end, COLOR_ACTIVE, 4.0)
	draw_circle(barrel_end, 6.0, COLOR_ACTIVE)
	draw_arc(pivot, 42.0, -0.62, 0.18, 18, COLOR_LAUNCH.darkened(0.12), 1.5)


func _draw_board(rect: Rect2, title: String, slots: Array, accent: Color, is_active: bool) -> void:
	var panel_color := COLOR_PANEL_DIM if is_active else Color("#151916")
	var border_width := 3.0 if is_active else 1.0
	draw_rect(rect, panel_color, true)
	draw_rect(rect, accent, false, border_width)
	_draw_text(_display_board(title), rect.position + Vector2(14, 24), 18, accent)
	if is_active:
		_draw_text("ACTIVE BALL", rect.position + Vector2(rect.size.x - 128, 24), 11, COLOR_ACTIVE)

	for row in range(3):
		for col in range(8):
			var peg_pos := rect.position + Vector2(96 + col * 58 + ((row % 2) * 22), 38 + row * 24)
			var peg_color := Color(0.62, 0.62, 0.57, 1.0) if is_active else Color(0.38, 0.4, 0.36, 1.0)
			draw_circle(peg_pos, 4.5, peg_color)

	var slot_width: float = (rect.size.x - 28.0) / float(slots.size())
	for index in range(slots.size()):
		var slot_rect := Rect2(
			rect.position + Vector2(14 + index * slot_width, rect.size.y - 42),
			Vector2(slot_width - 8, 28)
		)
		var slot_name: String = slots[index]
		var fill: Color = accent.darkened(0.32)
		if title == "Tuning" and slot_name == model.selected_tuning_result:
			fill = accent
		draw_rect(slot_rect, fill, true)
		draw_rect(slot_rect, accent, false, 1.0)
		_draw_text(_display_slot(slot_name), slot_rect.position + Vector2(6, 20), 12, COLOR_TEXT)


func _draw_unit_board(rect: Rect2, is_active: bool) -> void:
	var panel_color := COLOR_PANEL_DIM if is_active else Color("#151916")
	var border_width := 3.0 if is_active else 1.0
	draw_rect(rect, panel_color, true)
	draw_rect(rect, COLOR_UNIT, false, border_width)
	_draw_text("单位仓", rect.position + Vector2(14, 24), 18, COLOR_UNIT)
	if is_active:
		_draw_text("ACTIVE BALL", rect.position + Vector2(rect.size.x - 128, 24), 11, COLOR_ACTIVE)

	for row in range(3):
		for col in range(8):
			var peg_pos := rect.position + Vector2(96 + col * 58 + ((row % 2) * 22), 38 + row * 21)
			var peg_color := Color(0.62, 0.62, 0.57, 1.0) if is_active else Color(0.38, 0.4, 0.36, 1.0)
			draw_circle(peg_pos, 4.0, peg_color)

	var slots: Array = model.get_unit_slots()
	var slot_width: float = (rect.size.x - 28.0) / 4.0
	for index in range(slots.size()):
		var slot: Dictionary = slots[index]
		var slot_rect := Rect2(
			rect.position + Vector2(14 + index * slot_width, rect.size.y - 78),
			Vector2(slot_width - 8, 62)
		)
		var exposed_ratio: float = slot["exposure_ratio"]
		draw_rect(slot_rect, COLOR_UNIT.darkened(0.42), true)
		draw_rect(slot_rect, COLOR_UNIT, false, 1.0)

		if exposed_ratio < 1.0:
			var blocker_width: float = slot_rect.size.x * (1.0 - exposed_ratio)
			var blocker := Rect2(
				slot_rect.position + Vector2(slot_rect.size.x - blocker_width, 0),
				Vector2(blocker_width, slot_rect.size.y)
			)
			draw_rect(blocker, COLOR_BLOCKER, true)
			draw_line(blocker.position, blocker.position + Vector2(0, blocker.size.y), COLOR_WARNING, 2.0)

		var progress_current: int = slot["progress_current"]
		var progress_required: int = slot["progress_required"]
		var progress_ratio: float = clamp(float(progress_current) / float(progress_required), 0.0, 1.0)
		var progress_rect := Rect2(
			slot_rect.position + Vector2(6, slot_rect.size.y - 13),
			Vector2((slot_rect.size.x - 12) * progress_ratio, 7)
		)
		draw_rect(progress_rect, COLOR_ACTIVE, true)

		_draw_text("槽 %d" % slot["slot_id"], slot_rect.position + Vector2(6, 18), 13, COLOR_TEXT)
		_draw_text(
			"%d / %d" % [progress_current, progress_required],
			slot_rect.position + Vector2(6, 35),
			12,
			COLOR_TEXT
		)
		_draw_text(
			"%.0f 秒全开" % slot["full_exposure_seconds"],
			slot_rect.position + Vector2(6, 52),
			11,
			COLOR_TEXT.darkened(0.18)
		)

	_draw_text(
		"暴露基线：0 / 24 / 54 / 96 秒",
		rect.position + Vector2(352, 24),
		13,
		COLOR_TEXT
	)


func _draw_queue_bridge(rect: Rect2) -> void:
	draw_rect(rect, Color("#20211d"), true)
	draw_rect(rect, COLOR_UNIT, false, 1.0)
	var queue_entries: Array = model.queue_entries
	var text := "队列为空"
	if not queue_entries.is_empty():
		var entry: Dictionary = queue_entries[queue_entries.size() - 1]
		text = "%s  槽%d  %s" % [
			entry.get("queue_entry_id", ""),
			entry.get("source_slot_id", 0),
			_display_slot(entry.get("tuning_result", "")),
		]
	_draw_text(text, rect.position + Vector2(10, 25), 13, COLOR_TEXT)


func _draw_active_ball() -> void:
	var motion: Dictionary = model.get_motion_summary()
	var ball: Dictionary = model.active_ball
	var center: Vector2 = motion.get("ball_position", _active_ball_position(ball))
	var state: String = ball.get("state", "")
	var trail: Array = motion.get("trail", [])
	for index in range(1, trail.size()):
		var ratio := float(index) / float(max(1, trail.size() - 1))
		var trail_color := COLOR_ACTIVE
		trail_color.a = 0.18 + ratio * 0.42
		draw_line(trail[index - 1], trail[index], trail_color, 2.0 + ratio * 1.2)

	var color := COLOR_ACTIVE
	if state == "Blocked Bounce":
		color = COLOR_WARNING
	draw_circle(center, 10.0, color)
	draw_arc(center, 14.0, 0.0, TAU, 28, COLOR_TEXT, 2.0)
	if bool(motion.get("in_flight", false)):
		draw_arc(center, 22.0, -0.8, 0.9, 16, color, 2.0)
	else:
		draw_line(center - Vector2(28, 11), center - Vector2(8, 4), color, 2.0)
	_draw_text("当前球", center + Vector2(16, 4), 12, COLOR_TEXT)
	if state == "Blocked Bounce":
		draw_arc(center + Vector2(18, -4), 18.0, PI * 0.05, PI * 0.8, 18, COLOR_WARNING, 2.0)


func _active_ball_position(ball: Dictionary) -> Vector2:
	var board: String = ball.get("board", "Launch")
	var target: String = ball.get("target", "")
	match board:
		"Forge":
			return Vector2(70, 60)
		"Pool":
			return Vector2(170, 62)
		"Launcher":
			return Vector2(560, 26)
		"Tuning":
			var tuning_index: int = max(0, int(model.TUNING_RESULTS.find(target)))
			return Vector2(124 + tuning_index * 166, 352)
		"Unit":
			var slot_id: int = _slot_id_from_target(target)
			return Vector2(106 + (slot_id - 1) * 166, 512)
		_:
			return Vector2(576, 208)


func _slot_id_from_target(target: String) -> int:
	for slot_id in [1, 2, 3, 4]:
		if target.contains(str(slot_id)):
			return slot_id
	return 1


func _draw_text(text: String, draw_position: Vector2, font_size: int, color: Color) -> void:
	draw_string(
		get_theme_default_font(),
		draw_position,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		_scaled_font(font_size),
		color
	)


func _display_board(board_name: String) -> String:
	match board_name:
		"Launch":
			return "发射仓"
		"Tuning":
			return "调校仓"
		"Unit":
			return "单位仓"
	return board_name


func _display_slot(slot_name: String) -> String:
	match slot_name:
		"Gate":
			return "闸门"
		"Prime":
			return "预充"
		"Echo":
			return "复写"
		"Surge":
			return "脉冲"
		"Tuning":
			return "调校"
		"Split":
			return "分裂"
		"Recycle":
			return "回收"
		"Waste":
			return "废弃"
	return slot_name


func _scaled_font(font_size: int) -> int:
	return int(round(float(font_size) * TEXT_SCALE))
