class_name BattlefieldView
extends Control

signal lane_clicked(lane: String)

const PLAYER_BLUE: Color = Color("#56b4e9")
const ENEMY_RED: Color = Color("#e84b4b")
const PANEL_DARK: Color = Color("#20211d")
const TEXT_PRIMARY: Color = Color("#e8e1d2")
const METAL_TRIM: Color = Color("#9b7a4a")
const LANE_DIM: Color = Color("#5a5549")
const DANGER: Color = Color("#ff8a66")
const HIVE_GREEN: Color = Color("#7bcb6b")

var selected_lane: String = "Mid"
var lane_snapshots: Dictionary = {}
var result_text: String = "战斗进行中"
var last_deploy_text: String = "最近部署：暂无"
var player_guardian_hp: int = 100
var endpoint_guardian_hp: int = 120
var endpoint_guardian_max_hp: int = 120

func _ready() -> void:
	custom_minimum_size = Vector2(560.0, 620.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func render(deploy, lanes) -> void:
	selected_lane = deploy.current_lane
	lane_snapshots = {}
	for lane: String in ["Left", "Mid", "Right"]:
		lane_snapshots[lane] = _snapshot_for_lane(lanes, lane)
	result_text = lanes.get_result_text() if lanes.has_method("get_result_text") else "战斗进行中"
	last_deploy_text = _last_deploy_text(lanes.get("deploy_log") as Array if lanes.get("deploy_log") != null else [])
	player_guardian_hp = int(lanes.call("get_player_guardian_hp")) if lanes.has_method("get_player_guardian_hp") else 100
	endpoint_guardian_hp = int(lanes.call("get_endpoint_guardian_hp")) if lanes.has_method("get_endpoint_guardian_hp") else 120
	endpoint_guardian_max_hp = int(lanes.get("endpoint_guardian_max_hp")) if lanes.get("endpoint_guardian_max_hp") != null else 120
	queue_redraw()

func get_lane_button_text(lane: String) -> String:
	var snapshot: Dictionary = lane_snapshots.get(lane, {}) as Dictionary
	var units: int = int(snapshot.get("player_units", 0))
	var danger: int = int(snapshot.get("danger", 0))
	var raiders: int = int(snapshot.get("enemy_raiders", 0))
	var lane_name := _lane_name(lane)
	var pressure_text := " | 受压路线" if lane == "Left" else ""
	var danger_text := " | 危险 %d" % danger if danger > 0 else ""
	var raider_text := " | 突袭 Raider x%d" % raiders if raiders > 0 else ""
	if lane == selected_lane:
		return "[[ %s出兵口 ]] ==> [[ 路线门 ]]\n选中路线 | 双轨生效%s%s%s\n单位：%d" % [
			lane_name,
			pressure_text,
			danger_text,
			raider_text,
			units,
		]
	return "[ %s出兵口 ] ---- [ 路线门 ]\n点击后续 Queue 将走这一路%s%s%s\n单位：%d" % [
		lane_name,
		pressure_text,
		danger_text,
		raider_text,
		units,
	]

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			lane_clicked.emit(_lane_from_y(mouse_event.position.y))
			accept_event()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color("#161a17"), true)
	draw_rect(rect, METAL_TRIM, false, 2.0)
	var font := get_theme_default_font()
	_draw_text(font, Vector2(18.0, 28.0), "三路战场", 18, TEXT_PRIMARY)
	_draw_text(font, Vector2(18.0, 54.0), "直接点击路线选择后续 Queue 落点；已部署单位不会改路。", 13, TEXT_PRIMARY)
	_draw_guardians(font, rect)
	_draw_lanes(font, rect)
	_draw_footer(font, rect)

func _draw_guardians(font: Font, rect: Rect2) -> void:
	var left_center := Vector2(76.0, rect.size.y * 0.5)
	var right_center := Vector2(rect.size.x - 76.0, rect.size.y * 0.5)
	draw_circle(left_center, 34.0, Color("#243238"))
	draw_arc(left_center, 38.0, 0.0, TAU, 40, PLAYER_BLUE, 3.0, true)
	draw_circle(right_center, 34.0, Color("#332525"))
	draw_arc(right_center, 38.0, 0.0, TAU, 40, ENEMY_RED, 3.0, true)
	_draw_text(font, left_center + Vector2(-44.0, 56.0), "Player Guardian", 12, TEXT_PRIMARY)
	_draw_text(font, left_center + Vector2(-36.0, 74.0), "HP %d / 100" % player_guardian_hp, 12, PLAYER_BLUE)
	_draw_text(font, right_center + Vector2(-50.0, 56.0), "Endpoint Guardian", 12, TEXT_PRIMARY)
	_draw_text(font, right_center + Vector2(-38.0, 74.0), "HP %d / %d" % [endpoint_guardian_hp, endpoint_guardian_max_hp], 12, ENEMY_RED)

func _draw_lanes(font: Font, rect: Rect2) -> void:
	var lane_y: Dictionary = {
		"Left": rect.size.y * 0.29,
		"Mid": rect.size.y * 0.50,
		"Right": rect.size.y * 0.71,
	}
	for lane: String in ["Left", "Mid", "Right"]:
		var y: float = float(lane_y[lane])
		var snapshot: Dictionary = lane_snapshots.get(lane, {}) as Dictionary
		var danger: int = int(snapshot.get("danger", 0))
		var is_selected := lane == selected_lane
		var lane_color := PLAYER_BLUE if is_selected else LANE_DIM
		var start := Vector2(118.0, y)
		var end := Vector2(rect.size.x - 118.0, y)
		var control_offset := -74.0 if lane == "Left" else (74.0 if lane == "Right" else 0.0)
		var curve := Curve2D.new()
		curve.add_point(start)
		curve.add_point(Vector2(rect.size.x * 0.5, y + control_offset))
		curve.add_point(end)
		var points := curve.tessellate(5, 8)
		for index: int in range(points.size() - 1):
			draw_line(points[index], points[index + 1], lane_color, 7.0 if is_selected else 4.0, true)
		if danger > 0:
			for index: int in range(danger):
				draw_circle(Vector2(rect.size.x * (0.46 + float(index) * 0.035), y - 18.0), 6.0 + float(index), DANGER)
		_draw_gate(start + Vector2(24.0, 0.0), int(snapshot.get("player_gate_hp", 60)), PLAYER_BLUE)
		_draw_gate(end - Vector2(24.0, 0.0), int(snapshot.get("enemy_gate_hp", 60)), ENEMY_RED)
		_draw_spawn_port(start, is_selected)
		_draw_units(font, snapshot)
		_draw_text(font, Vector2(18.0, y + 4.0), _lane_name(lane), 14, lane_color)
		if bool(snapshot.get("sweep_warning", false)):
			_draw_text(font, Vector2(rect.size.x * 0.42, y - 34.0), "扫击预警", 16, DANGER)

func _draw_gate(center: Vector2, hp: int, color: Color) -> void:
	var gate_rect := Rect2(center - Vector2(8.0, 28.0), Vector2(16.0, 56.0))
	draw_rect(gate_rect, color.darkened(0.35), true)
	draw_rect(gate_rect, color, false, 2.0)
	var hp_ratio := clampf(float(hp) / 60.0, 0.0, 1.0)
	draw_rect(Rect2(gate_rect.position + Vector2(3.0, 4.0 + 48.0 * (1.0 - hp_ratio)), Vector2(10.0, 48.0 * hp_ratio)), color, true)

func _draw_spawn_port(center: Vector2, is_selected: bool) -> void:
	draw_circle(center, 9.0, HIVE_GREEN if is_selected else METAL_TRIM)
	draw_arc(center, 14.0, 0.0, TAU, 24, PLAYER_BLUE if is_selected else LANE_DIM, 2.0, true)

func _draw_units(font: Font, snapshot: Dictionary) -> void:
	var entities: Array = snapshot.get("entities", []) as Array
	for entity_variant: Variant in entities:
		var entity: Dictionary = entity_variant as Dictionary
		var position_ratio := clampf(float(entity.get("position", 0.0)) / 100.0, 0.0, 1.0)
		var lane := String(entity.get("lane", "Mid"))
		var y := _lane_y(lane)
		var x := lerpf(118.0, size.x - 118.0, position_ratio)
		var side := String(entity.get("side", "player"))
		var color := HIVE_GREEN if side == "player" else ENEMY_RED
		draw_circle(Vector2(x, y), 8.0 if side == "player" else 7.0, color)
		_draw_text(font, Vector2(x - 9.0, y - 13.0), str(int(entity.get("hp", 0))), 10, TEXT_PRIMARY)

func _draw_footer(font: Font, rect: Rect2) -> void:
	_draw_text(font, Vector2(18.0, rect.size.y - 54.0), result_text, 14, TEXT_PRIMARY)
	_draw_text(font, Vector2(18.0, rect.size.y - 28.0), last_deploy_text, 13, PLAYER_BLUE)

func _snapshot_for_lane(lanes, lane: String) -> Dictionary:
	if lanes.has_method("get_lane_snapshot"):
		return lanes.call("get_lane_snapshot", lane) as Dictionary
	return {
		"lane": lane,
		"player_units": lanes.get_player_units(lane),
		"danger": lanes.get_lane_danger_level(lane) if lanes.has_method("get_lane_danger_level") else 0,
		"enemy_raiders": lanes.get_enemy_raiders(lane) if lanes.has_method("get_enemy_raiders") else 0,
		"player_gate_hp": 60,
		"enemy_gate_hp": 60,
		"entities": [],
		"sweep_warning": false,
	}

func _lane_from_y(y: float) -> String:
	var local_y := y / maxf(size.y, 1.0)
	if local_y < 0.39:
		return "Left"
	if local_y < 0.61:
		return "Mid"
	return "Right"

func _lane_y(lane: String) -> float:
	match lane:
		"Left":
			return size.y * 0.29
		"Mid":
			return size.y * 0.50
		"Right":
			return size.y * 0.71
		_:
			return size.y * 0.50

func _last_deploy_text(deploy_log: Array) -> String:
	if deploy_log.is_empty():
		return "最近部署：暂无"
	return "最近部署：%s" % _localized_deploy_log(String(deploy_log[deploy_log.size() - 1]))

func _localized_deploy_log(deploy_line: String) -> String:
	var lane := deploy_line.get_slice(":", 0)
	var payload := deploy_line.get_slice(":", 1)
	var unit_id := payload.get_slice(" ", 0)
	var count_text := payload.get_slice("x", 1)
	return "%s %s x%s" % [_lane_name(lane), _unit_name(unit_id), count_text]

func _lane_name(lane: String) -> String:
	match lane:
		"Left":
			return "左路"
		"Mid":
			return "中路"
		"Right":
			return "右路"
		_:
			return lane

func _unit_name(unit_id: String) -> String:
	match unit_id:
		"hive_short_fang":
			return "短牙虫"
		"hive_shield_shell":
			return "盾壳虫"
		"hive_acid_sac":
			return "酸囊虫"
		"hive_crush_shell_beast":
			return "碾壳兽"
		"enemy_grunt":
			return "敌方步虫"
		"enemy_raider":
			return "敌方突袭虫"
		"enemy_brute":
			return "敌方重壳虫"
		_:
			return "未知单位"

func _draw_text(font: Font, draw_position: Vector2, text: String, font_size: int, color: Color) -> void:
	if font == null:
		return
	draw_string(font, draw_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
