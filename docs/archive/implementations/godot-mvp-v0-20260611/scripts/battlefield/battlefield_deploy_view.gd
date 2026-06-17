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
const TEXT_SCALE := 1.18
const SPRITE_PATHS := {
	"hive.short_fang": "res://assets/sprites/hive_short_fang.png",
	"hive.shield_shell": "res://assets/sprites/hive_shield_shell.png",
	"hive.acid_sac": "res://assets/sprites/hive_acid_sac.png",
	"hive.crush_shell_beast": "res://assets/sprites/hive_crush_shell_beast.png",
	"enemy.grunt": "res://assets/sprites/enemy_grunt.png",
	"enemy.raider": "res://assets/sprites/enemy_raider.png",
	"enemy.brute": "res://assets/sprites/enemy_brute.png",
	"guardian.vein_mother": "res://assets/sprites/guardian_vein_mother.png",
	"guardian.acid_crown_mother": "res://assets/sprites/guardian_acid_crown_mother.png",
}

var model: RefCounted = null
var _lane_rects: Dictionary = {}
var _spawn_port_centers: Dictionary = {}
var _guardian_center := Vector2.ZERO
var _sprite_textures: Dictionary = {}


func _ready() -> void:
	custom_minimum_size = Vector2(660, 500)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_load_sprite_textures()


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
		_draw_text("没有战场模型", Vector2(24, 32), 18, COLOR_TEXT)
		return

	var summary: Dictionary = model.get_state_snapshot()
	_draw_header(summary)
	_draw_lanes(summary)
	_draw_base_buffers(summary)
	_draw_guardians(summary)
	_draw_units(summary)


func get_player_facing_contract_snapshot() -> Dictionary:
	var selected_lane := "Mid"
	if model != null:
		var summary: Dictionary = model.get_state_snapshot()
		selected_lane = str(summary.get("selected_lane_name", "Mid"))
	var guardian_probe := Vector2(50.0, max(240.0, size.y * 0.54))
	var spawn_probe := Vector2(120.0, max(240.0, size.y * 0.54))
	return {
		"selected_spawn_port": selected_lane,
		"bridge_target": selected_lane,
		"spawn_port_count": 3,
		"guardian_separate_from_spawn_ports": guardian_probe.distance_to(spawn_probe) > 48.0,
	}


func get_spawn_port_position(lane_name: String) -> Vector2:
	var lane_index := LANE_ORDER.find(lane_name)
	if lane_index < 0:
		lane_index = LANE_ORDER.find("Mid")
	var rect := _lane_rect_for_index(lane_index)
	return Vector2(rect.position.x + 8.0, rect.position.y + rect.size.y * 0.5)


func _draw_header(summary: Dictionary) -> void:
	var queue_preview: Array = summary.get("queue_preview", [])
	var queue_text := "队首：空"
	if not queue_preview.is_empty():
		var head: Dictionary = queue_preview[0]
		queue_text = "队首 -> %s | 槽 %d | %s" % [
			_display_lane(head.get("deploy_lane_name", "")),
			head.get("source_slot_id", 0),
			_display_tuning(head.get("tuning_result", "")),
		]

	_draw_text(
		"部署路线：%s" % _display_lane(summary.get("selected_lane_name", "Mid")),
		Vector2(24, 28),
		20,
		COLOR_PLAYER
	)
	_draw_text(queue_text, Vector2(24, 56), 15, COLOR_QUEUE)
	_draw_text(
		"战斗：%s | %.1f 秒" % [
			_display_battle_state(summary.get("battle_state", "running")),
			float(summary.get("battle_time_seconds", 0.0)),
		],
		Vector2(24, 80),
		14,
		COLOR_DIM_TEXT
	)


func _draw_guardians(summary: Dictionary) -> void:
	var player_hp := int(summary.get("player_guardian_hp", 0))
	var player_max := int(summary.get("player_guardian_max_hp", 1))
	var enemy_hp := int(summary.get("enemy_guardian_hp", 0))
	var enemy_max := int(summary.get("enemy_guardian_max_hp", 1))
	var mid_y := _base_buffer_rect().get_center().y

	var player_guardian_sprite := "guardian.vein_mother"
	if str(summary.get("player_guardian_template_id", "")) == "hive.acid_crown_mother":
		player_guardian_sprite = "guardian.acid_crown_mother"
	_guardian_center = Vector2(50.0, mid_y)
	_draw_guardian_sprite(player_guardian_sprite, _guardian_center, COLOR_PLAYER)
	_draw_text("玩家守护者", Vector2(18, mid_y + 46.0), 12, COLOR_TEXT)
	_draw_text("生命 %d / %d" % [player_hp, player_max], Vector2(18, mid_y + 64.0), 12, COLOR_PLAYER)

	var enemy_x := size.x - 48.0
	_draw_guardian_sprite(
		"guardian.acid_crown_mother",
		Vector2(enemy_x, mid_y),
		COLOR_ENEMY
	)
	_draw_text("敌方守护者", Vector2(enemy_x - 82, mid_y + 46.0), 12, COLOR_TEXT)
	_draw_text("生命 %d / %d" % [enemy_hp, enemy_max], Vector2(enemy_x - 82, mid_y + 64.0), 12, COLOR_ENEMY)


func _draw_lanes(summary: Dictionary) -> void:
	_lane_rects.clear()
	_spawn_port_centers.clear()
	var lanes: Dictionary = summary.get("lanes", {})
	var selected_lane := str(summary.get("selected_lane_name", "Mid"))

	for index in range(LANE_ORDER.size()):
		var lane_name: String = LANE_ORDER[index]
		var lane_id := StringName(lane_name.to_lower())
		var lane_data: Dictionary = lanes.get(lane_id, {})
		var rect := _lane_rect_for_index(index)
		_lane_rects[lane_name] = rect

		draw_rect(rect, COLOR_PANEL, true)
		draw_rect(rect, COLOR_LANE, false, 1.0)
		var lane_mid_y := rect.position.y + rect.size.y * 0.5
		var curve_offset := 34.0 * float(index - 1)
		var points := PackedVector2Array([
			Vector2(rect.position.x + 18.0, lane_mid_y),
			Vector2(lerp(rect.position.x, rect.end.x, 0.36), lane_mid_y + curve_offset),
			Vector2(lerp(rect.position.x, rect.end.x, 0.66), lane_mid_y - curve_offset * 0.45),
			Vector2(rect.end.x - 18.0, lane_mid_y),
		])
		draw_polyline(points, COLOR_LANE, 5.0)

		if lane_name == selected_lane:
			draw_rect(rect.grow(-4.0), COLOR_PLAYER, false, 3.0)
			draw_rect(rect.grow(-10.0), COLOR_PLAYER_DARK, false, 2.0)
			_draw_deploy_arrows(rect)

		_draw_lane_gate(rect, 0.02, int(lane_data.get("player_gate_hp", 0)), "出兵口")
		_draw_lane_gate(rect, 0.92, int(lane_data.get("enemy_gate_hp", 0)), "敌方闸")
		_draw_lane_danger(rect, int(lane_data.get("danger_tier", 0)))
		_draw_spawn_port(rect, lane_name == selected_lane, lane_name)

		_draw_text(_display_lane(lane_name), rect.position + Vector2(12, 22), 16, COLOR_TEXT)
		_draw_text(
			"%s | 危险 %d" % [
				_display_lane_state(lane_data.get("state", "idle")),
				int(lane_data.get("danger_tier", 0)),
			],
			rect.position + Vector2(12, rect.size.y - 14),
			12,
			COLOR_DIM_TEXT
		)


func _lane_rect_for_index(index: int) -> Rect2:
	var start_x := 120.0
	var end_x := size.x - 120.0
	var top_y: float = max(126.0, size.y * 0.16)
	var bottom_margin: float = max(118.0, size.y * 0.12)
	var lane_gap: float = max(24.0, size.y * 0.035)
	var available_height: float = max(360.0, size.y - top_y - bottom_margin)
	var lane_height: float = max(112.0, (available_height - lane_gap * 2.0) / 3.0)
	var y: float = top_y + index * (lane_height + lane_gap)
	return Rect2(Vector2(start_x, y), Vector2(end_x - start_x, lane_height))


func _draw_base_buffers(_summary: Dictionary) -> void:
	var player_base := _base_buffer_rect()
	var enemy_base := Rect2(Vector2(size.x - 134.0, player_base.position.y), player_base.size)
	draw_rect(player_base, Color(COLOR_PLAYER_DARK, 0.28), true)
	draw_rect(player_base, COLOR_PLAYER, false, 2.0)
	draw_rect(enemy_base, Color(COLOR_ENEMY_DARK, 0.24), true)
	draw_rect(enemy_base, COLOR_ENEMY, false, 2.0)
	draw_line(Vector2(78.0, player_base.position.y + 18.0), Vector2(78.0, player_base.end.y - 18.0), COLOR_PLAYER_DARK, 2.0)
	var mid_y := player_base.get_center().y
	_draw_text("基地缓冲区", Vector2(52.0, mid_y - 92.0), 10, COLOR_DIM_TEXT)
	_draw_text("Guardian", Vector2(22.0, mid_y - 44.0), 10, COLOR_TEXT)
	_draw_text("出兵口", Vector2(92.0, mid_y - 44.0), 10, COLOR_PLAYER)


func _base_buffer_rect() -> Rect2:
	var first_lane := _lane_rect_for_index(0)
	var last_lane := _lane_rect_for_index(2)
	var top := first_lane.position.y
	var bottom := last_lane.end.y
	return Rect2(Vector2(18.0, top), Vector2(116.0, bottom - top))


func _draw_spawn_port(rect: Rect2, selected: bool, lane_name: String) -> void:
	var center := Vector2(rect.position.x + 8.0, rect.position.y + rect.size.y * 0.5)
	_spawn_port_centers[lane_name] = center
	var color := COLOR_PLAYER if selected else COLOR_GATE
	draw_circle(center, 8.0, color)
	draw_arc(center, 13.0, 0.0, TAU, 24, color, 2.0)
	if selected:
		draw_arc(center, 19.0, 0.0, TAU, 32, COLOR_PLAYER, 2.5)
		draw_line(Vector2(0.0, center.y), center + Vector2(-16.0, 0.0), COLOR_PLAYER, 2.0)


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

		_draw_unit_sprite(unit, Vector2(x, y), radius, color)
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


func _draw_guardian_sprite(sprite_id: String, center: Vector2, accent: Color) -> void:
	var texture := _sprite_textures.get(sprite_id) as Texture2D
	if texture == null:
		draw_circle(center, 28, COLOR_BASE)
		draw_arc(center, 31, 0.0, TAU, 36, accent, 3.0)
		return

	var sprite_rect := Rect2(center - Vector2(33, 33), Vector2(66, 66))
	draw_texture_rect(texture, sprite_rect, false)
	draw_arc(center, 34, 0.0, TAU, 36, accent, 3.0)


func _draw_unit_sprite(unit: Dictionary, center: Vector2, radius: float, fallback_color: Color) -> void:
	var texture := _sprite_textures.get(str(unit.get("template_id", ""))) as Texture2D
	if texture == null:
		draw_circle(center, radius, fallback_color)
		draw_arc(center, radius + 2.5, 0.0, TAU, 24, COLOR_TEXT, 1.5)
		return

	var sprite_size := Vector2(radius * 4.3, radius * 3.5)
	if int(unit.get("max_hp", 1)) >= 20:
		sprite_size = Vector2(radius * 4.8, radius * 3.8)
	var sprite_rect := Rect2(center - sprite_size * 0.5, sprite_size)
	draw_texture_rect(texture, sprite_rect, false)
	draw_arc(center, max(sprite_size.x, sprite_size.y) * 0.33, 0.0, TAU, 24, COLOR_TEXT, 1.2)


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


func _load_sprite_textures() -> void:
	for sprite_id in SPRITE_PATHS.keys():
		var texture := _load_texture_from_file(str(SPRITE_PATHS[sprite_id]))
		if texture != null:
			_sprite_textures[str(sprite_id)] = texture


func _load_texture_from_file(path: String) -> Texture2D:
	var resource := ResourceLoader.load(path)
	if not resource is Texture2D:
		return null
	return resource as Texture2D


func _display_lane(lane) -> String:
	match str(lane):
		"Left", "left":
			return "左路"
		"Mid", "mid":
			return "中路"
		"Right", "right":
			return "右路"
	return str(lane)


func _display_tuning(tuning_result) -> String:
	match str(tuning_result):
		"Gate":
			return "闸门"
		"Prime":
			return "预充"
		"Echo":
			return "复写"
		"Surge":
			return "脉冲"
	return str(tuning_result)


func _display_battle_state(state) -> String:
	match str(state):
		"running":
			return "进行中"
		"player_win":
			return "玩家胜利"
		"player_loss":
			return "玩家失败"
	return str(state)


func _display_lane_state(state) -> String:
	match str(state):
		"idle":
			return "空闲"
		"pushing":
			return "推进"
		"stalled":
			return "僵持"
		"leaking":
			return "漏怪"
		"gate broken":
			return "路闸破损"
		"invading":
			return "入侵"
	return str(state)


func _scaled_font(font_size: int) -> int:
	return int(round(float(font_size) * TEXT_SCALE))
