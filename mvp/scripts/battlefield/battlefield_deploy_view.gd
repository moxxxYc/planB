class_name BattlefieldDeployView
extends Control

signal lane_clicked(lane_name: String)

const COLOR_BG := Color("#151719")
const COLOR_PANEL := Color("#202326")
const COLOR_LANE := Color("#3a4045")
const COLOR_TEXT := Color("#ece6d8")
const COLOR_DIM_TEXT := Color("#a8a296")
const COLOR_PLAYER := Color("#62c9cf")
const COLOR_PLAYER_DARK := Color("#285e64")
const COLOR_ENEMY := Color("#e35d4f")
const COLOR_ENEMY_DARK := Color("#71312c")
const COLOR_GATE := Color("#d4c48f")
const COLOR_BASE := Color("#6f7880")
const COLOR_QUEUE := Color("#f0d35e")

const LANE_ORDER := ["Left", "Mid", "Right"]

var model: RefCounted = null
var _lane_rects: Dictionary = {}


func _ready() -> void:
	custom_minimum_size = Vector2(840, 640)
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_model(next_model: RefCounted) -> void:
	model = next_model
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return

	for lane_name in _lane_rects.keys():
		var rect: Rect2 = _lane_rects[lane_name]
		if rect.has_point(mouse_event.position):
			lane_clicked.emit(str(lane_name))
			accept_event()
			return


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BG, true)
	if model == null:
		_draw_text("No battlefield model", Vector2(24, 32), 18, COLOR_TEXT)
		return

	var summary: Dictionary = model.get_debug_summary()
	_draw_header(summary)
	_draw_guardians(summary)
	_draw_lanes(summary)
	_draw_units(summary)


func _draw_header(summary: Dictionary) -> void:
	var queue_preview: Array = summary.get("queue_preview", [])
	var queue_text := "Queue head: empty"
	if not queue_preview.is_empty():
		var head: Dictionary = queue_preview[0]
		queue_text = "Queue head -> %s | S%d | %s" % [
			head.get("deploy_lane_name", ""),
			head.get("source_slot_id", 0),
			head.get("tuning_result", ""),
		]

	_draw_text(
		"Deploy Lane: %s" % summary.get("selected_lane_name", "Mid"),
		Vector2(24, 28),
		20,
		COLOR_PLAYER
	)
	_draw_text(queue_text, Vector2(24, 56), 15, COLOR_QUEUE)
	_draw_text(
		"Battle: %s | %.1fs" % [
			summary.get("battle_state", "running"),
			float(summary.get("battle_time_seconds", 0.0)),
		],
		Vector2(24, 80),
		14,
		COLOR_DIM_TEXT
	)


func _draw_guardians(summary: Dictionary) -> void:
	var top_y := 112.0
	var player_hp := int(summary.get("player_guardian_hp", 0))
	var player_max := int(summary.get("player_guardian_max_hp", 1))
	var enemy_hp := int(summary.get("enemy_guardian_hp", 0))
	var enemy_max := int(summary.get("enemy_guardian_max_hp", 1))

	draw_circle(Vector2(44, top_y + 190), 28, COLOR_BASE)
	draw_arc(Vector2(44, top_y + 190), 31, 0.0, TAU, 36, COLOR_PLAYER, 3.0)
	_draw_text("Player Guardian", Vector2(18, top_y + 232), 12, COLOR_TEXT)
	_draw_text("HP %d / %d" % [player_hp, player_max], Vector2(18, top_y + 250), 12, COLOR_PLAYER)

	var enemy_x := size.x - 48.0
	draw_circle(Vector2(enemy_x, top_y + 190), 28, COLOR_BASE)
	draw_arc(Vector2(enemy_x, top_y + 190), 31, 0.0, TAU, 36, COLOR_ENEMY, 3.0)
	_draw_text("Enemy Guardian", Vector2(enemy_x - 82, top_y + 232), 12, COLOR_TEXT)
	_draw_text("HP %d / %d" % [enemy_hp, enemy_max], Vector2(enemy_x - 82, top_y + 250), 12, COLOR_ENEMY)


func _draw_lanes(summary: Dictionary) -> void:
	_lane_rects.clear()
	var lanes: Dictionary = summary.get("lanes", {})
	var selected_lane := str(summary.get("selected_lane_name", "Mid"))
	var start_x := 78.0
	var end_x := size.x - 82.0
	var top_y := 128.0
	var lane_height := 92.0
	var lane_gap := 20.0

	for index in range(LANE_ORDER.size()):
		var lane_name: String = LANE_ORDER[index]
		var lane_id := StringName(lane_name.to_lower())
		var lane_data: Dictionary = lanes.get(lane_id, {})
		var y: float = top_y + index * (lane_height + lane_gap)
		var rect := Rect2(Vector2(start_x, y), Vector2(end_x - start_x, lane_height))
		_lane_rects[lane_name] = rect

		draw_rect(rect, COLOR_PANEL, true)
		draw_rect(rect, COLOR_LANE, false, 1.0)
		draw_line(
			Vector2(start_x + 18.0, y + lane_height * 0.5),
			Vector2(end_x - 18.0, y + lane_height * 0.5),
			COLOR_LANE,
			5.0
		)

		if lane_name == selected_lane:
			draw_rect(rect.grow(-4.0), COLOR_PLAYER, false, 3.0)
			draw_rect(rect.grow(-10.0), COLOR_PLAYER_DARK, false, 2.0)
			_draw_deploy_arrows(rect)

		_draw_lane_gate(rect, 0.08, int(lane_data.get("player_gate_hp", 0)), "P Gate")
		_draw_lane_gate(rect, 0.92, int(lane_data.get("enemy_gate_hp", 0)), "E Gate")
		_draw_lane_danger(rect, int(lane_data.get("danger_tier", 0)))

		_draw_text(lane_name, rect.position + Vector2(12, 22), 16, COLOR_TEXT)
		_draw_text(
			"%s | danger %d" % [
				lane_data.get("state", "idle"),
				int(lane_data.get("danger_tier", 0)),
			],
			rect.position + Vector2(12, lane_height - 14),
			12,
			COLOR_DIM_TEXT
		)


func _draw_units(summary: Dictionary) -> void:
	var units: Array = summary.get("units", [])
	for unit in units:
		var lane_name := str(unit.get("lane_name", "Mid"))
		if not _lane_rects.has(lane_name):
			continue
		var rect: Rect2 = _lane_rects[lane_name]
		var path_pos: float = clamp(float(unit.get("path_pos", 0.0)), 0.0, 100.0)
		var x: float = lerp(rect.position.x + 18.0, rect.end.x - 18.0, path_pos / 100.0)
		var is_player := str(unit.get("side", "")) == "player"
		var y: float = rect.position.y + rect.size.y * (0.66 if is_player else 0.34)
		var color: Color = COLOR_PLAYER if is_player else COLOR_ENEMY
		var radius := 8.0
		if int(unit.get("max_hp", 1)) >= 20:
			radius = 12.0

		draw_circle(Vector2(x, y), radius, color)
		draw_arc(Vector2(x, y), radius + 2.5, 0.0, TAU, 24, COLOR_TEXT, 1.5)
		if str(unit.get("state", "")) != "marching":
			draw_arc(Vector2(x, y), radius + 7.0, PI * 0.1, PI * 1.2, 18, color, 2.0)

		_draw_text(
			"%s %d/%d" % [
				str(unit.get("display_name", "")),
				int(unit.get("hp", 0)),
				int(unit.get("max_hp", 0)),
			],
			Vector2(x - 34.0, y - radius - 8.0),
			10,
			COLOR_TEXT
		)


func _draw_deploy_arrows(rect: Rect2) -> void:
	var y := rect.position.y + rect.size.y * 0.5
	for x in [rect.position.x + 32.0, rect.end.x - 52.0]:
		var points := PackedVector2Array([
			Vector2(x, y),
			Vector2(x + 20.0, y - 8.0),
			Vector2(x + 20.0, y + 8.0),
		])
		draw_colored_polygon(points, COLOR_PLAYER)


func _draw_lane_gate(rect: Rect2, ratio: float, hp: int, label: String) -> void:
	var x: float = lerp(rect.position.x + 18.0, rect.end.x - 18.0, ratio)
	var gate_rect := Rect2(Vector2(x - 7.0, rect.position.y + 22.0), Vector2(14.0, rect.size.y - 44.0))
	var color: Color = COLOR_GATE if hp > 0 else COLOR_ENEMY_DARK
	draw_rect(gate_rect, color, true)
	draw_rect(gate_rect, COLOR_TEXT, false, 1.0)
	_draw_text("%s %d" % [label, hp], gate_rect.position + Vector2(-22.0, -6.0), 9, COLOR_DIM_TEXT)


func _draw_lane_danger(rect: Rect2, tier: int) -> void:
	if tier <= 0:
		return
	for index in range(tier):
		var center := rect.position + Vector2(rect.size.x - 28.0 - index * 20.0, 18.0)
		var points := PackedVector2Array([
			center + Vector2(0.0, -8.0),
			center + Vector2(9.0, 8.0),
			center + Vector2(-9.0, 8.0),
		])
		draw_colored_polygon(points, COLOR_ENEMY)
		draw_polyline(points, COLOR_TEXT, 1.0, true)
	if tier >= 3:
		draw_rect(rect.grow(-2.0), COLOR_ENEMY, false, 2.0)


func _draw_text(text: String, draw_position: Vector2, font_size: int, color: Color) -> void:
	draw_string(
		get_theme_default_font(),
		draw_position,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		color
	)
