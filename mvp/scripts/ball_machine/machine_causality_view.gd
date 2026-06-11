class_name MachineCausalityView
extends Control

const ModelScript := preload("res://scripts/ball_machine/machine_causality_model.gd")

const COLOR_BG := Color("#171a18")
const COLOR_PANEL := Color("#252923")
const COLOR_PANEL_DIM := Color("#1c201d")
const COLOR_TEXT := Color("#e8e1d2")
const COLOR_MUTED := Color("#a7a093")
const COLOR_LAUNCH := Color("#7bcb6b")
const COLOR_TUNING := Color("#e6b450")
const COLOR_UNIT := Color("#c58be8")
const COLOR_ACTIVE := Color("#f4f0d8")
const COLOR_WARNING := Color("#e84b4b")
const COLOR_BLOCKER := Color(0.9, 0.9, 0.9, 0.28)
const COLOR_PEG := Color("#c9c4ad")
const COLOR_PEG_HOT := Color("#fff2a5")
const COLOR_EFFECT_BG := Color(0.08, 0.09, 0.08, 0.86)
const TEXT_SCALE := 1.18
const DESIGN_SIZE := Vector2(760, 960)
const DEFAULT_BALL_RADIUS := 6.0
const DEFAULT_PEG_RADIUS := 7.0
const SLOT_INSET := 14.0
const SLOT_GAP := 8.0
const LAUNCH_SLOT_NAMES := ["Tuning", "Split", "Recycle", "Waste"]
const LAUNCH_SLOT_WEIGHTS := [65.0, 15.0, 15.0, 5.0]
const TUNING_SLOT_WEIGHTS := [55.0, 15.0, 15.0, 15.0]

var model: RefCounted = null
var ball_radius := DEFAULT_BALL_RADIUS
var peg_radius := DEFAULT_PEG_RADIUS


func _ready() -> void:
	custom_minimum_size = Vector2(560, 500)


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
	_draw_supply(Rect2(24, 28, 236, 54), supply)
	_draw_board(
		Rect2(24, 150, 690, 180),
		"Launch",
		["Tuning", "Split", "Recycle", "Waste"],
		COLOR_LAUNCH,
		active_board == "Launch"
	)
	_draw_board(
		Rect2(24, 370, 690, 180),
		"Tuning",
		model.TUNING_RESULTS,
		COLOR_TUNING,
		active_board == "Tuning"
	)
	_draw_unit_board(Rect2(24, 590, 690, 250), active_board == "Unit")
	_draw_queue_bridge(Rect2(438, 872, 276, 42))
	_draw_recent_effect_feedback()
	_draw_active_ball()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_supply(rect: Rect2, supply: Dictionary) -> void:
	draw_rect(rect, COLOR_PANEL, true)
	draw_rect(rect, COLOR_LAUNCH, false, 2.0)
	_draw_text("发射仓队列", rect.position + Vector2(12, 21), 15, COLOR_TEXT)

	var pool_origin := rect.position + Vector2(112, 36)
	var pool_count: int = supply.get("pool_count", 0)
	var pool_capacity: int = supply.get("pool_capacity", 5)
	var forge_time := float(supply.get("forge_time_remaining", 0.0))
	var launcher_time := float(supply.get("launcher_time_remaining", 0.0))
	for index in range(pool_capacity):
		var pos: Vector2 = pool_origin + Vector2(index * 16.0, 0.0)
		var color: Color = COLOR_LAUNCH if index < pool_count else Color(0.45, 0.48, 0.44, 1.0)
		draw_circle(pos, 4.6, color)
		draw_arc(pos, 6.4, 0.0, TAU, 18, COLOR_TEXT, 0.8)

	_draw_text("%d / %d" % [pool_count, pool_capacity], rect.position + Vector2(198, 40), 11, COLOR_TEXT)
	_draw_text("Forge %.1fs" % forge_time, rect.position + Vector2(12, 43), 9, COLOR_MUTED)
	_draw_text("Launcher %.1fs" % launcher_time, rect.position + Vector2(266, 43), 9, COLOR_MUTED)


func _draw_board(rect: Rect2, title: String, slots: Array, accent: Color, is_active: bool) -> void:
	var panel_color := COLOR_PANEL_DIM if is_active else Color("#151916")
	var border_width := 3.0 if is_active else 1.0
	draw_rect(rect, panel_color, true)
	draw_rect(rect, accent, false, border_width)
	_draw_text(_display_board(title), rect.position + Vector2(14, 24), 18, accent)
	if is_active:
		_draw_text("活跃球", rect.position + Vector2(rect.size.x - 86, 24), 11, COLOR_ACTIVE)

	if title == "Launch":
		_draw_launcher(rect, is_active)

	_draw_pegs(rect, is_active, 4, 7, peg_radius)

	for segment in _slot_segments(title, slots, rect):
		var slot_rect: Rect2 = segment["rect"]
		var slot_name: String = segment["name"]
		var fill: Color = accent.darkened(0.32)
		if title == "Tuning" and slot_name == model.selected_tuning_result:
			fill = accent
		draw_rect(slot_rect, fill, true)
		draw_rect(slot_rect, accent, false, 1.0)
		var font_size := 12
		var label := _display_slot(slot_name)
		if slot_rect.size.x < 38.0:
			label = _display_slot_short(slot_name)
			font_size = 10
		_draw_text(label, slot_rect.position + Vector2(5, 20), font_size, COLOR_TEXT)


func _draw_unit_board(rect: Rect2, is_active: bool) -> void:
	var panel_color := COLOR_PANEL_DIM if is_active else Color("#151916")
	var border_width := 3.0 if is_active else 1.0
	draw_rect(rect, panel_color, true)
	draw_rect(rect, COLOR_UNIT, false, border_width)
	_draw_text("单位仓", rect.position + Vector2(14, 24), 18, COLOR_UNIT)
	if is_active:
		_draw_text("活跃球", rect.position + Vector2(rect.size.x - 86, 24), 11, COLOR_ACTIVE)

	_draw_pegs(rect, is_active, 5, 7, max(3.0, peg_radius * 0.92))

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


func _slot_segments(title: String, slots: Array, rect: Rect2) -> Array[Dictionary]:
	var weights: Array = []
	if title == "Launch":
		weights = LAUNCH_SLOT_WEIGHTS
	elif title == "Tuning":
		weights = TUNING_SLOT_WEIGHTS
	else:
		for _slot in slots:
			weights.append(1.0)

	var total_weight := 0.0
	for weight in weights:
		total_weight += float(weight)

	var segments: Array[Dictionary] = []
	var cursor := rect.position.x + SLOT_INSET
	var available_width := rect.size.x - SLOT_INSET * 2.0
	for index in range(slots.size()):
		var segment_width := available_width * float(weights[index]) / total_weight
		var visible_width: float = max(0.0, segment_width - SLOT_GAP)
		segments.append({
			"name": str(slots[index]),
			"rect": Rect2(
				Vector2(cursor, rect.position.y + rect.size.y - 42.0),
				Vector2(visible_width, 28.0)
			),
		})
		cursor += segment_width
	return segments


func _slot_center(title: String, slot_name: String, rect: Rect2) -> Vector2:
	var slots: Array = LAUNCH_SLOT_NAMES if title == "Launch" else model.TUNING_RESULTS
	for segment in _slot_segments(title, slots, rect):
		if str(segment["name"]) == slot_name:
			var slot_rect: Rect2 = segment["rect"]
			return slot_rect.position + slot_rect.size * 0.5
	return Vector2(rect.position.x + SLOT_INSET, rect.position.y + rect.size.y - 28.0)


func _draw_launcher(rect: Rect2, is_active: bool) -> void:
	var motion: Dictionary = model.get_motion_summary()
	var pivot: Vector2 = motion.get("launcher_pivot", rect.position + Vector2(68, 26))
	var barrel_end: Vector2 = motion.get("launcher_muzzle", pivot + Vector2(0, 48))
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
	elif state == "Split Return" or state == "Recycle Return":
		color = COLOR_LAUNCH
	elif state == "Waste":
		color = Color(0.42, 0.43, 0.40, 1.0)
	elif state == "Valid Unit Hit":
		color = COLOR_UNIT
	elif state == "Logic Settlement":
		color = COLOR_TUNING
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


func _draw_recent_effect_feedback() -> void:
	var event := _latest_effect_event()
	if event.is_empty():
		return

	var component := str(event.get("component", ""))
	var state := str(event.get("state", ""))
	var data: Dictionary = event.get("data", {})
	var label := ""
	var anchor := Vector2.ZERO
	var accent := COLOR_ACTIVE

	match state:
		"Split Return":
			label = "分裂 +2"
			anchor = _launch_effect_position("Split")
			accent = COLOR_LAUNCH
		"Recycle Return":
			label = "回收 +1"
			anchor = _launch_effect_position("Recycle")
			accent = COLOR_LAUNCH
		"Waste":
			label = "废弃"
			anchor = _launch_effect_position("Waste")
			accent = COLOR_WARNING
		"Valid Unit Hit":
			var slot_id := int(data.get("slot_id", 1))
			var progress_added := int(data.get("progress_added", 1))
			label = "Unit +%d" % progress_added
			anchor = _unit_effect_position(slot_id)
			accent = COLOR_UNIT
		"Logic Settlement":
			if component != "Tuning":
				return
			var tuning_result := str(data.get("tuning_result", model.selected_tuning_result))
			label = _tuning_effect_label(tuning_result, data)
			if label.is_empty():
				return
			anchor = _tuning_effect_position(tuning_result)
			accent = COLOR_TUNING
		"Blocked Bounce":
			var slot_id := int(data.get("slot_id", 1))
			label = "挡板"
			anchor = _unit_effect_position(slot_id)
			accent = COLOR_WARNING
		_:
			return

	_draw_effect_badge(anchor, label, accent)


func _latest_effect_event() -> Dictionary:
	var event_log: Array = model.event_log
	for index in range(event_log.size() - 1, -1, -1):
		var event: Dictionary = event_log[index]
		var state := str(event.get("state", ""))
		if [
			"Split Return",
			"Recycle Return",
			"Waste",
			"Valid Unit Hit",
			"Logic Settlement",
			"Blocked Bounce",
		].has(state):
			return event
	return {}


func _draw_effect_badge(anchor: Vector2, label: String, accent: Color) -> void:
	var rect := Rect2(anchor + Vector2(-42, -34), Vector2(84, 24))
	draw_rect(rect, COLOR_EFFECT_BG, true)
	draw_rect(rect, accent, false, 1.5)
	draw_line(anchor + Vector2(0, -10), anchor + Vector2(0, 5), accent, 2.0)
	draw_circle(anchor, 6.0, accent)
	_draw_text(label, rect.position + Vector2(8, 17), 11, COLOR_TEXT)


func _launch_effect_position(slot_name: String) -> Vector2:
	match slot_name:
		"Tuning", "Tuning Path":
			return _slot_center(
				"Launch",
				"Tuning",
				Rect2(24, 150, 690, 180)
			)
		"Split":
			return _slot_center(
				"Launch",
				"Split",
				Rect2(24, 150, 690, 180)
			)
		"Recycle", "Miss + Recycle":
			return _slot_center(
				"Launch",
				"Recycle",
				Rect2(24, 150, 690, 180)
			)
		"Waste":
			return _slot_center(
				"Launch",
				"Waste",
				Rect2(24, 150, 690, 180)
			)
	return _slot_center("Launch", "Tuning", Rect2(24, 150, 690, 180))


func _tuning_effect_position(tuning_result: String) -> Vector2:
	return _slot_center("Tuning", tuning_result, Rect2(24, 370, 690, 180))


func _unit_effect_position(slot_id: int) -> Vector2:
	return Vector2(106 + (slot_id - 1) * 166, 750)


func _tuning_effect_label(tuning_result: String, data: Dictionary) -> String:
	match tuning_result:
		"Prime":
			return "预充 +%d" % int(data.get("progress_value", 2))
		"Echo":
			return "复写 x2"
		"Surge":
			return "脉冲 0.25s"
	return ""


func _active_ball_position(ball: Dictionary) -> Vector2:
	var board: String = ball.get("board", "Launch")
	var target: String = ball.get("target", "")
	match board:
		"Forge":
			return Vector2(58, 44)
		"Pool":
			return Vector2(128, 54)
		"Launcher":
			var motion: Dictionary = model.get_motion_summary()
			return motion.get("launcher_muzzle", Vector2(92, 224))
		"Tuning":
			return _tuning_effect_position(target)
		"Unit":
			var slot_id: int = _slot_id_from_target(target)
			return Vector2(106 + (slot_id - 1) * 166, 750)
		_:
			return Vector2(576, 250)


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


func _display_slot_short(slot_name: String) -> String:
	match slot_name:
		"Tuning":
			return "调"
		"Split":
			return "分"
		"Recycle":
			return "回"
		"Waste":
			return "废"
		"Gate":
			return "闸"
		"Prime":
			return "预"
		"Echo":
			return "复"
		"Surge":
			return "脉"
	return slot_name.left(1)


func _scaled_font(font_size: int) -> int:
	return int(round(float(font_size) * TEXT_SCALE))
