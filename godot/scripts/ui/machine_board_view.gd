class_name MachineBoardView
extends Control

const FORGE_CYCLE_SECONDS: float = 2.2
const LAUNCHER_CYCLE_SECONDS: float = 1.3
const QUEUE_PREVIEW_COUNT: int = 3
const SLOT_REQUIREMENTS: Dictionary = {1: 3, 2: 5, 3: 8, 4: 12}

const COLOR_BG: Color = Color("#171a18")
const COLOR_PANEL: Color = Color("#2a2d29")
const COLOR_TRIM: Color = Color("#9b7a4a")
const COLOR_TEXT: Color = Color("#e8e1d2")
const COLOR_MUTED: Color = Color("#7f8178")
const COLOR_LAUNCH: Color = Color("#7bcb6b")
const COLOR_TUNING: Color = Color("#e6b450")
const COLOR_UNIT: Color = Color("#c58be8")
const COLOR_ACTIVE: Color = Color("#f4f0d8")
const COLOR_QUEUE: Color = Color("#56b4e9")

const MIN_VIEW_SIZE: Vector2 = Vector2(380.0, 600.0)
const SUPPLY_STRIP_HEIGHT: float = 164.0
const POOL_BALL_RADIUS: float = 16.0
const POOL_BALL_RING_RADIUS: float = 20.0
const ACTIVE_BALL_RADIUS: float = 14.0
const ACTIVE_BALL_RING_RADIUS: float = 19.0

var forge_ratio: float = 0.0
var launcher_ratio: float = 0.0
var pool_count: int = 0
var pool_capacity: int = 5
var pool_balls: Array[String] = []
var queue_count: int = 0
var slot_progress: Dictionary = {1: 0, 2: 0, 3: 0, 4: 0}
var last_launch_result: String = ""
var last_tuning_result: String = ""
var last_queue_unit: String = ""
var active_board_index: int = 0

func _ready() -> void:
	custom_minimum_size = MIN_VIEW_SIZE
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)
	queue_redraw()

func render(machine) -> void:
	forge_ratio = clampf(machine.forge_progress / FORGE_CYCLE_SECONDS, 0.0, 1.0)
	launcher_ratio = clampf(machine.launcher_progress / LAUNCHER_CYCLE_SECONDS, 0.0, 1.0)
	pool_count = machine.pool.size()
	pool_balls = []
	for ball: Dictionary in machine.pool:
		pool_balls.append(String(ball.get("kind", "clean")))
	pool_capacity = _machine_pool_capacity(machine)
	queue_count = machine.queue.size()
	slot_progress = {
		1: int(machine.slot_progress.get(1, 0)),
		2: int(machine.slot_progress.get(2, 0)),
		3: int(machine.slot_progress.get(3, 0)),
		4: int(machine.slot_progress.get(4, 0)),
	}
	_update_recent_results(machine.event_log)
	active_board_index = _active_board_from_ratio(launcher_ratio)
	queue_redraw()

func get_visual_contract_summary() -> Dictionary:
	return {
		"board_count": 3,
		"pool_slot_count": pool_capacity,
		"queue_preview_count": QUEUE_PREVIEW_COUNT,
		"unit_slot_count": 4,
		"has_active_ball": true,
		"pool_count": pool_count,
		"queue_count": queue_count,
		"active_board_index": active_board_index,
		"last_launch_result": last_launch_result,
		"last_tuning_result": last_tuning_result,
		"machine_board_min_height": MIN_VIEW_SIZE.y,
		"supply_strip_height": SUPPLY_STRIP_HEIGHT,
		"pool_ball_radius": POOL_BALL_RADIUS,
		"pool_ball_ring_radius": POOL_BALL_RING_RADIUS,
		"active_ball_radius": ACTIVE_BALL_RADIUS,
		"active_ball_ring_radius": ACTIVE_BALL_RING_RADIUS,
	}

func _on_resized() -> void:
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, COLOR_BG, true)
	draw_rect(rect, COLOR_TRIM, false, 2.0)
	_draw_supply_strip(rect)
	_draw_machine_boards(rect)
	_draw_queue_preview(rect)

func _draw_supply_strip(rect: Rect2) -> void:
	var font := get_theme_default_font()
	var left := rect.position.x + 14.0
	var top := rect.position.y + 14.0
	var width := rect.size.x - 28.0
	var strip_rect := Rect2(left, top, width, SUPPLY_STRIP_HEIGHT)

	draw_rect(strip_rect, COLOR_PANEL, true)
	draw_rect(strip_rect, COLOR_LAUNCH, false, 2.0)

	_draw_text(font, Vector2(left + 12.0, top + 22.0), "供给球仓", 15, COLOR_TEXT)
	_draw_text(font, Vector2(left + 96.0, top + 22.0), "Forge / Pool / Launcher", 12, COLOR_MUTED)
	_draw_text(font, Vector2(left + width - 92.0, top + 22.0), "Pool %d / %d" % [pool_count, pool_capacity], 13, COLOR_ACTIVE)

	var bar_width := maxf(88.0, width * 0.34)
	_draw_text(font, Vector2(left + 12.0, top + 46.0), "Forge 造球 %.0f%%" % (forge_ratio * 100.0), 11, COLOR_MUTED)
	_draw_bar(Rect2(left + 12.0, top + 52.0, bar_width, 8.0), forge_ratio, COLOR_LAUNCH)
	_draw_text(font, Vector2(left + width - bar_width - 12.0, top + 46.0), "Launcher 发射 %.0f%%" % (launcher_ratio * 100.0), 11, COLOR_MUTED)
	_draw_bar(Rect2(left + width - bar_width - 12.0, top + 52.0, bar_width, 8.0), launcher_ratio, COLOR_TUNING)

	var pool_rect := Rect2(left + 12.0, top + 72.0, width - 24.0, 76.0)
	draw_rect(pool_rect, COLOR_BG, true)
	draw_rect(pool_rect, COLOR_TRIM, false, 1.5)
	_draw_text(font, pool_rect.position + Vector2(12.0, 22.0), "Pool 球仓", 13, COLOR_TEXT)

	var slot_gap := 12.0
	var visible_capacity: int = maxi(1, pool_capacity)
	var total_slot_width := float(visible_capacity) * POOL_BALL_RADIUS * 2.0 + float(visible_capacity - 1) * slot_gap
	var pool_left := pool_rect.position.x + maxf(0.0, (pool_rect.size.x - total_slot_width) * 0.5)
	var pool_y := pool_rect.position.y + 52.0
	var first_ball_x := pool_left + POOL_BALL_RADIUS
	var last_ball_x := first_ball_x + float(visible_capacity - 1) * (POOL_BALL_RADIUS * 2.0 + slot_gap)

	draw_line(Vector2(pool_rect.position.x + 18.0, pool_y), Vector2(first_ball_x - POOL_BALL_RING_RADIUS - 10.0, pool_y), COLOR_LAUNCH, 3.0, true)
	draw_line(Vector2(last_ball_x + POOL_BALL_RING_RADIUS + 10.0, pool_y), Vector2(pool_rect.end.x - 18.0, pool_y), COLOR_TUNING, 3.0, true)
	for index: int in range(visible_capacity):
		var center := Vector2(first_ball_x + float(index) * (POOL_BALL_RADIUS * 2.0 + slot_gap), pool_y)
		var filled := index < pool_count
		var kind := String(pool_balls[index]) if index < pool_balls.size() else ""
		draw_circle(center, POOL_BALL_RING_RADIUS, COLOR_TRIM)
		if filled and kind == "junk":
			draw_circle(center, POOL_BALL_RADIUS, Color("#6f5f35"))
			draw_line(center + Vector2(-9.0, -9.0), center + Vector2(9.0, 9.0), COLOR_ACTIVE, 2.0, true)
			draw_line(center + Vector2(9.0, -9.0), center + Vector2(-9.0, 9.0), COLOR_ACTIVE, 2.0, true)
		else:
			draw_circle(center, POOL_BALL_RADIUS, COLOR_LAUNCH if filled else COLOR_PANEL)
		if filled:
			draw_arc(center, POOL_BALL_RING_RADIUS + 3.0, 0.0, TAU, 24, COLOR_ACTIVE, 2.0, true)

func _draw_machine_boards(rect: Rect2) -> void:
	var board_top := rect.position.y + SUPPLY_STRIP_HEIGHT + 32.0
	var board_gap := 12.0
	var queue_height := 64.0
	var available_height := rect.size.y - board_top - queue_height - board_gap * 2.0 - 18.0
	var board_height := maxf(96.0, available_height / 3.0)
	var board_rect := Rect2(rect.position.x + 14.0, board_top, rect.size.x - 28.0, board_height)

	_draw_board(board_rect, "Launch", "进 Tuning / Split / 回收 / Waste", COLOR_LAUNCH, active_board_index == 0)
	_draw_launch_slots(board_rect)

	board_rect.position.y += board_height + board_gap
	_draw_board(board_rect, "Tuning", "Gate / Prime / Echo / Surge", COLOR_TUNING, active_board_index == 1)
	_draw_tuning_slots(board_rect)

	board_rect.position.y += board_height + board_gap
	_draw_board(board_rect, "Unit", "S1 / S2 / S3 / S4", COLOR_UNIT, active_board_index == 2)
	_draw_unit_slots(board_rect)

func _draw_board(board_rect: Rect2, title: String, subtitle: String, accent: Color, is_active: bool) -> void:
	var font := get_theme_default_font()
	var border_width := 3.0 if is_active else 1.5
	draw_rect(board_rect, COLOR_PANEL, true)
	draw_rect(board_rect, accent if is_active else COLOR_TRIM, false, border_width)
	_draw_text(font, board_rect.position + Vector2(10.0, 18.0), title, 15, accent)
	_draw_text(font, board_rect.position + Vector2(90.0, 18.0), subtitle, 12, COLOR_MUTED)
	_draw_pegs(board_rect, accent)
	if is_active:
		_draw_active_ball(board_rect, accent)

func _draw_pegs(board_rect: Rect2, accent: Color) -> void:
	var peg_y := board_rect.position.y + board_rect.size.y * 0.42
	for row: int in range(2):
		for index: int in range(5):
			var x := board_rect.position.x + 42.0 + float(index) * ((board_rect.size.x - 84.0) / 4.0)
			if row == 1:
				x += 18.0
			var y := peg_y + float(row) * 18.0
			draw_circle(Vector2(x, y), 3.0, accent.darkened(0.15))

func _draw_active_ball(board_rect: Rect2, accent: Color) -> void:
	var local_ratio := fmod(launcher_ratio * 3.0, 1.0)
	var x := board_rect.position.x + board_rect.size.x * (0.18 + 0.64 * local_ratio)
	var wobble := sin(local_ratio * TAU) * board_rect.size.x * 0.08
	var y := board_rect.position.y + board_rect.size.y * (0.28 + 0.46 * local_ratio)
	var center := Vector2(x + wobble, y)
	draw_line(center - Vector2(36.0, 16.0), center - Vector2(10.0, 5.0), accent.darkened(0.25), 4.0, true)
	draw_line(center - Vector2(22.0, 10.0), center, accent, 2.5, true)
	draw_circle(center, ACTIVE_BALL_RADIUS, COLOR_ACTIVE)
	draw_arc(center, ACTIVE_BALL_RING_RADIUS, 0.0, TAU, 28, accent, 2.5, true)

func _draw_launch_slots(board_rect: Rect2) -> void:
	var labels: Array[String] = ["Tuning", "Split", "回收", "Waste"]
	_draw_result_slots(board_rect, labels, COLOR_LAUNCH, last_launch_result)

func _draw_tuning_slots(board_rect: Rect2) -> void:
	var labels: Array[String] = ["Gate", "Prime", "Echo", "Surge"]
	_draw_result_slots(board_rect, labels, COLOR_TUNING, last_tuning_result)

func _draw_result_slots(board_rect: Rect2, labels: Array[String], accent: Color, active_label: String) -> void:
	var font := get_theme_default_font()
	var gap := 6.0
	var slot_width := (board_rect.size.x - 20.0 - gap * 3.0) / 4.0
	var slot_y := board_rect.position.y + board_rect.size.y - 24.0
	for index: int in range(labels.size()):
		var label := labels[index]
		var slot_rect := Rect2(board_rect.position.x + 10.0 + float(index) * (slot_width + gap), slot_y, slot_width, 16.0)
		var is_active := active_label == label or (label == "Tuning" and active_label == "Tuning")
		draw_rect(slot_rect, accent.darkened(0.25) if is_active else COLOR_BG, true)
		draw_rect(slot_rect, accent if is_active else COLOR_TRIM, false, 1.0)
		_draw_text(font, slot_rect.position + Vector2(4.0, 12.0), label, 10, COLOR_TEXT)

func _draw_unit_slots(board_rect: Rect2) -> void:
	var font := get_theme_default_font()
	var gap := 8.0
	var slot_width := (board_rect.size.x - 20.0 - gap * 3.0) / 4.0
	var slot_y := board_rect.position.y + board_rect.size.y - 31.0
	for slot_id: int in range(1, 5):
		var progress: int = int(slot_progress.get(slot_id, 0))
		var required: int = int(SLOT_REQUIREMENTS[slot_id])
		var ratio := clampf(float(progress) / float(required), 0.0, 1.0)
		var slot_rect := Rect2(board_rect.position.x + 10.0 + float(slot_id - 1) * (slot_width + gap), slot_y, slot_width, 23.0)
		draw_rect(slot_rect, COLOR_BG, true)
		draw_rect(Rect2(slot_rect.position, Vector2(slot_rect.size.x * ratio, slot_rect.size.y)), COLOR_UNIT.darkened(0.2), true)
		draw_rect(slot_rect, COLOR_UNIT, false, 1.0)
		_draw_text(font, slot_rect.position + Vector2(5.0, 16.0), "S%d %d/%d" % [slot_id, progress, required], 10, COLOR_TEXT)

func _draw_queue_preview(rect: Rect2) -> void:
	var font := get_theme_default_font()
	var left := rect.position.x + 14.0
	var bottom := rect.position.y + rect.size.y - 54.0
	var width := rect.size.x - 28.0
	_draw_text(font, Vector2(left, bottom), "队列预览", 14, COLOR_QUEUE)
	for index: int in range(QUEUE_PREVIEW_COUNT):
		var item_rect := Rect2(left + 78.0 + float(index) * 58.0, bottom - 15.0, 46.0, 24.0)
		var filled := index < queue_count
		draw_rect(item_rect, COLOR_QUEUE.darkened(0.25) if filled else COLOR_PANEL, true)
		draw_rect(item_rect, COLOR_QUEUE if filled else COLOR_TRIM, false, 1.0)
		_draw_text(font, item_rect.position + Vector2(8.0, 16.0), "单位" if filled else "空", 10, COLOR_TEXT if filled else COLOR_MUTED)
	if not last_queue_unit.is_empty():
		_draw_text(font, Vector2(left + width - 150.0, bottom + 1.0), "最近入队：%s" % _unit_name(last_queue_unit), 11, COLOR_TEXT)

func _draw_bar(bar_rect: Rect2, ratio: float, fill_color: Color) -> void:
	draw_rect(bar_rect, COLOR_PANEL, true)
	draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * ratio, bar_rect.size.y)), fill_color, true)
	draw_rect(bar_rect, COLOR_TRIM, false, 1.0)

func _draw_text(font: Font, draw_position: Vector2, text: String, font_size: int, color: Color) -> void:
	if font == null:
		return
	draw_string(font, draw_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)

func _active_board_from_ratio(ratio: float) -> int:
	if pool_count <= 0 and ratio < 0.15:
		return 0
	if ratio < 0.34:
		return 0
	if ratio < 0.67:
		return 1
	return 2

func _machine_pool_capacity(machine) -> int:
	if machine.has_method("get_pool_capacity"):
		return maxi(1, int(machine.call("get_pool_capacity")))

	var capacity_value: Variant = machine.get("pool_capacity")
	if capacity_value != null:
		return maxi(1, int(capacity_value))
	return 5

func _update_recent_results(event_log: Array[String]) -> void:
	last_launch_result = ""
	last_tuning_result = ""
	last_queue_unit = ""
	for index: int in range(event_log.size() - 1, -1, -1):
		var log_line: String = event_log[index]
		if last_queue_unit.is_empty() and log_line.begins_with("Unit:QueueEntry"):
			last_queue_unit = _extract_unit_id(log_line)
		if last_tuning_result.is_empty() and log_line.begins_with("Tuning:"):
			last_tuning_result = log_line.get_slice(":", 1).get_slice(" ", 0)
		if last_launch_result.is_empty() and log_line.begins_with("Launch:"):
			last_launch_result = log_line.get_slice(":", 1).get_slice(" ", 0)
		if not last_queue_unit.is_empty() and not last_tuning_result.is_empty() and not last_launch_result.is_empty():
			return

func _extract_unit_id(log_line: String) -> String:
	var marker := "\"unit_id\": \""
	var start := log_line.find(marker)
	if start == -1:
		return ""
	start += marker.length()
	var end := log_line.find("\"", start)
	if end == -1:
		return ""
	return log_line.substr(start, end - start)

func _unit_name(unit_id: String) -> String:
	match unit_id:
		"hive_short_fang":
			return "短牙"
		"hive_shield_shell":
			return "盾壳"
		"hive_acid_sac":
			return "酸囊"
		"hive_crush_shell_beast":
			return "碾壳兽"
		_:
			return "未知单位"
