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
const COLOR_PEG := Color("#c9c4ad")
const COLOR_PEG_HOT := Color("#fff2a5")
const TEXT_SCALE := 1.18
const DESIGN_SIZE := Vector2(760, 640)
const DEFAULT_BALL_RADIUS := 6.0
const DEFAULT_PEG_RADIUS := 7.0
const SIZE_CONTROL_WIDTH := 176.0

var model: RefCounted = null
var ball_radius := DEFAULT_BALL_RADIUS
var peg_radius := DEFAULT_PEG_RADIUS

var _ball_size_label: Label
var _peg_size_label: Label
var _ball_size_slider: HSlider
var _peg_size_slider: HSlider


func _ready() -> void:
	custom_minimum_size = Vector2(560, 500)
	_build_size_controls()


func set_model(next_model: RefCounted) -> void:
	model = next_model
	queue_redraw()


func get_size_control_values() -> Dictionary:
	return {
		"ball_radius": ball_radius,
		"peg_radius": peg_radius,
	}


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
	_draw_supply(Rect2(24, 18, 236, 54), supply)
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
	draw_rect(rect, COLOR_PANEL, true)
	draw_rect(rect, COLOR_LAUNCH, false, 2.0)
	_draw_text("发射仓队列", rect.position + Vector2(12, 21), 15, COLOR_TEXT)

	var pool_origin := rect.position + Vector2(112, 36)
	var pool_count: int = supply.get("pool_count", 0)
	var pool_capacity: int = supply.get("pool_capacity", 5)
	for index in range(pool_capacity):
		var pos: Vector2 = pool_origin + Vector2(index * 16.0, 0.0)
		var color: Color = COLOR_LAUNCH if index < pool_count else Color(0.45, 0.48, 0.44, 1.0)
		draw_circle(pos, 4.6, color)
		draw_arc(pos, 6.4, 0.0, TAU, 18, COLOR_TEXT, 0.8)

	_draw_text("%d / %d" % [pool_count, pool_capacity], rect.position + Vector2(198, 40), 11, COLOR_TEXT)


func _draw_board(rect: Rect2, title: String, slots: Array, accent: Color, is_active: bool) -> void:
	var panel_color := COLOR_PANEL_DIM if is_active else Color("#151916")
	var border_width := 3.0 if is_active else 1.0
	draw_rect(rect, panel_color, true)
	draw_rect(rect, accent, false, border_width)
	_draw_text(_display_board(title), rect.position + Vector2(14, 24), 18, accent)
	if is_active:
		_draw_text("ACTIVE BALL", rect.position + Vector2(rect.size.x - 128, 24), 11, COLOR_ACTIVE)

	if title == "Launch":
		_draw_launcher(rect, is_active)

	_draw_pegs(rect, is_active, 3, 7, peg_radius)

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

	_draw_pegs(rect, is_active, 4, 7, max(3.0, peg_radius * 0.92))

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


func _build_size_controls() -> void:
	var panel := PanelContainer.new()
	panel.name = "SizeControls"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.anchor_left = 1.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -SIZE_CONTROL_WIDTH - 8.0
	panel.offset_top = 8.0
	panel.offset_right = -8.0
	panel.offset_bottom = 134.0
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)

	_ball_size_label = _make_control_label("")
	box.add_child(_ball_size_label)
	_ball_size_slider = _make_size_slider(DEFAULT_BALL_RADIUS)
	_ball_size_slider.value_changed.connect(_on_ball_radius_changed)
	box.add_child(_ball_size_slider)

	_peg_size_label = _make_control_label("")
	box.add_child(_peg_size_label)
	_peg_size_slider = _make_size_slider(DEFAULT_PEG_RADIUS)
	_peg_size_slider.value_changed.connect(_on_peg_radius_changed)
	box.add_child(_peg_size_slider)

	var reset_button := Button.new()
	reset_button.text = "重置尺寸"
	reset_button.custom_minimum_size = Vector2(0, 26)
	reset_button.add_theme_font_size_override("font_size", 10)
	reset_button.pressed.connect(_on_reset_size_pressed)
	box.add_child(reset_button)

	_update_size_control_labels()


func _make_control_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 10)
	return label


func _make_size_slider(value: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 3.0
	slider.max_value = 14.0
	slider.step = 0.5
	slider.value = value
	slider.custom_minimum_size = Vector2(0, 18)
	return slider


func _on_ball_radius_changed(value: float) -> void:
	ball_radius = value
	_update_size_control_labels()
	queue_redraw()


func _on_peg_radius_changed(value: float) -> void:
	peg_radius = value
	_update_size_control_labels()
	queue_redraw()


func _on_reset_size_pressed() -> void:
	ball_radius = DEFAULT_BALL_RADIUS
	peg_radius = DEFAULT_PEG_RADIUS
	if _ball_size_slider != null:
		_ball_size_slider.set_value_no_signal(ball_radius)
	if _peg_size_slider != null:
		_peg_size_slider.set_value_no_signal(peg_radius)
	_update_size_control_labels()
	queue_redraw()


func _update_size_control_labels() -> void:
	if _ball_size_label != null:
		_ball_size_label.text = "球半径 %.1f" % ball_radius
	if _peg_size_label != null:
		_peg_size_label.text = "钉子半径 %.1f" % peg_radius


func _draw_launcher(rect: Rect2, is_active: bool) -> void:
	var motion: Dictionary = model.get_motion_summary()
	var pivot := rect.position + Vector2(68, 26)
	var sway := sin(float(motion.get("cannon_angle", 0.0))) * 0.13
	var angle := PI * 0.5 + sway
	var barrel_end := pivot + Vector2(cos(angle), sin(angle)) * 48.0
	var color := COLOR_ACTIVE if is_active else COLOR_LAUNCH
	draw_arc(pivot, 19.0, 0.0, TAU, 24, COLOR_LAUNCH.darkened(0.12), 2.0)
	draw_line(pivot, barrel_end, color, 5.0)
	draw_circle(pivot, 8.0, COLOR_PANEL)
	draw_arc(pivot, 10.0, 0.0, TAU, 24, COLOR_TEXT, 1.2)
	draw_circle(barrel_end, 5.0, color)
	_draw_text("发球器", rect.position + Vector2(24, 48), 10, COLOR_LAUNCH)


func _draw_pegs(
	rect: Rect2,
	is_active: bool,
	row_count: int,
	col_count: int,
	radius: float
) -> void:
	var peg_color := COLOR_PEG if is_active else Color(0.48, 0.5, 0.45, 1.0)
	var glow_color := COLOR_PEG_HOT
	glow_color.a = 0.18 if is_active else 0.08
	for row in range(row_count):
		for col in range(col_count):
			var x_step: float = (rect.size.x - 168.0) / float(max(1, col_count - 1))
			var peg_pos := rect.position + Vector2(
				96.0 + col * x_step + ((row % 2) * x_step * 0.42),
				42.0 + row * 23.0
			)
			if peg_pos.x > rect.end.x - 38.0:
				continue
			draw_circle(peg_pos, radius + 3.0, glow_color)
			draw_circle(peg_pos, radius, peg_color)
			draw_arc(peg_pos, radius + 1.8, 0.0, TAU, 20, COLOR_TEXT, 1.0)


func _draw_active_ball() -> void:
	var motion: Dictionary = model.get_motion_summary()
	var ball: Dictionary = model.active_ball
	var center: Vector2 = motion.get("ball_position", _active_ball_position(ball))
	var state: String = ball.get("state", "")
	var trail: Array = motion.get("trail", [])
	for index in range(1, trail.size()):
		var ratio := float(index) / float(max(1, trail.size() - 1))
		var trail_color := COLOR_ACTIVE
		trail_color.a = 0.10 + ratio * 0.34
		draw_line(trail[index - 1], trail[index], trail_color, 1.0 + ratio * 1.1)
		if index % 4 == 0:
			var contact_color := COLOR_PEG_HOT
			contact_color.a = 0.24 + ratio * 0.24
			draw_arc(trail[index], 9.0 + ratio * 4.0, 0.0, TAU, 18, contact_color, 1.2)

	var color := COLOR_ACTIVE
	if state == "Blocked Bounce":
		color = COLOR_WARNING
	draw_circle(center, ball_radius, color)
	draw_arc(center, ball_radius + 3.0, 0.0, TAU, 24, COLOR_TEXT, 1.6)
	if bool(motion.get("in_flight", false)):
		draw_arc(center, ball_radius + 9.0, -0.8, 0.9, 16, color, 1.6)
	else:
		draw_line(
			center - Vector2(ball_radius + 12.0, ball_radius * 0.7),
			center - Vector2(ball_radius + 1.0, ball_radius * 0.3),
			color,
			1.5
		)
	_draw_text("球", center + Vector2(ball_radius + 5.0, 4), 10, COLOR_TEXT)
	if state == "Blocked Bounce":
		draw_arc(
			center + Vector2(ball_radius + 8.0, -5),
			ball_radius + 8.0,
			PI * 0.05,
			PI * 0.8,
			18,
			COLOR_WARNING,
			1.8
		)


func _active_ball_position(ball: Dictionary) -> Vector2:
	var board: String = ball.get("board", "Launch")
	var target: String = ball.get("target", "")
	match board:
		"Forge":
			return Vector2(58, 44)
		"Pool":
			return Vector2(128, 54)
		"Launcher":
			return Vector2(92, 132)
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
