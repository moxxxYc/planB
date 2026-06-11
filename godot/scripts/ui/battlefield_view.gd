class_name BattlefieldView
extends VBoxContainer

signal lane_clicked(lane: String)

const PLAYER_BLUE: Color = Color("#56b4e9")
const PANEL_DARK: Color = Color("#20211d")
const PANEL_NEUTRAL: Color = Color("#2a2d29")
const TEXT_PRIMARY: Color = Color("#e8e1d2")
const METAL_TRIM: Color = Color("#9b7a4a")

@onready var left_button: Button = %LeftLane
@onready var mid_button: Button = %MidLane
@onready var right_button: Button = %RightLane
@onready var summary_label: Label = %BattleSummaryLabel
@onready var last_deploy_label: Label = %LastDeployLabel

var _selected_style: StyleBoxFlat
var _selected_hover_style: StyleBoxFlat
var _normal_style: StyleBoxFlat
var _normal_hover_style: StyleBoxFlat

func _ready() -> void:
	_ensure_nodes()
	_ensure_styles()
	add_theme_constant_override("separation", 12)
	_connect_buttons()

func render(deploy, lanes) -> void:
	_ensure_nodes()
	_ensure_styles()
	_render_lane_button(left_button, "Left", deploy.current_lane, lanes.get_player_units("Left"))
	_render_lane_button(mid_button, "Mid", deploy.current_lane, lanes.get_player_units("Mid"))
	_render_lane_button(right_button, "Right", deploy.current_lane, lanes.get_player_units("Right"))
	summary_label.text = "%s\n己方单位 | 左路 %d | 中路 %d | 右路 %d" % [
		lanes.get_result_text(),
		lanes.get_player_units("Left"),
		lanes.get_player_units("Mid"),
		lanes.get_player_units("Right"),
	]
	last_deploy_label.text = _last_deploy_text(lanes.deploy_log)

func get_lane_button_text(lane: String) -> String:
	_ensure_nodes()
	var button: Button = _button_for_lane(lane)
	if button == null:
		return ""
	return button.text

func _on_left_pressed() -> void:
	lane_clicked.emit("Left")

func _on_mid_pressed() -> void:
	lane_clicked.emit("Mid")

func _on_right_pressed() -> void:
	lane_clicked.emit("Right")

func _render_lane_button(button: Button, lane: String, current_lane: String, units: int) -> void:
	var is_selected: bool = lane == current_lane
	button.text = _lane_body_text(lane, units, is_selected)
	if is_selected:
		_apply_lane_style(button, _selected_style, _selected_hover_style)
	else:
		_apply_lane_style(button, _normal_style, _normal_hover_style)

func _apply_lane_style(button: Button, normal_style: StyleBoxFlat, hover_style: StyleBoxFlat) -> void:
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_color_override("font_color", TEXT_PRIMARY)
	button.add_theme_color_override("font_hover_color", TEXT_PRIMARY)
	button.add_theme_color_override("font_pressed_color", TEXT_PRIMARY)

func _make_lane_style(background: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 12.0
	style.content_margin_top = 12.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 12.0
	return style

func _lane_body_text(lane: String, units: int, is_selected: bool) -> String:
	var lane_name := _lane_name(lane)
	var pressure_text := " | 受压路线" if lane == "Left" else ""
	if is_selected:
		return "[[ %s出兵口 ]] ==> [[ 路线门 ]]\n选中路线 | 双轨生效%s\n单位：%d" % [
			lane_name,
			pressure_text,
			units,
		]

	return "[ %s出兵口 ] ---- [ 路线门 ]\n点击后续 Queue 将走这一路%s\n单位：%d" % [
		lane_name,
		pressure_text,
		units,
	]

func _button_for_lane(lane: String) -> Button:
	match lane:
		"Left":
			return left_button
		"Mid":
			return mid_button
		"Right":
			return right_button
		_:
			push_error("Unknown lane button: %s" % lane)
			return null

func _last_deploy_text(deploy_log: Array[String]) -> String:
	if deploy_log.is_empty():
		return "最近部署：暂无"
	return "最近部署：%s" % _localized_deploy_log(deploy_log[deploy_log.size() - 1])

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
			return "短牙"
		"hive_shield_shell":
			return "盾壳"
		"hive_acid_sac":
			return "酸囊"
		"hive_crush_shell_beast":
			return "碾壳兽"
		_:
			return "未知单位"

func _ensure_nodes() -> void:
	if left_button == null:
		left_button = get_node("LeftLane") as Button
	if mid_button == null:
		mid_button = get_node("MidLane") as Button
	if right_button == null:
		right_button = get_node("RightLane") as Button
	if summary_label == null:
		summary_label = get_node("BattleSummaryLabel") as Label
	if last_deploy_label == null:
		last_deploy_label = get_node("LastDeployLabel") as Label

func _ensure_styles() -> void:
	if _selected_style != null:
		return
	_selected_style = _make_lane_style(PANEL_DARK, PLAYER_BLUE, 4)
	_selected_hover_style = _make_lane_style(Color("#243238"), PLAYER_BLUE, 4)
	_normal_style = _make_lane_style(PANEL_NEUTRAL, METAL_TRIM, 2)
	_normal_hover_style = _make_lane_style(Color("#30352f"), METAL_TRIM, 2)

func _connect_buttons() -> void:
	if not left_button.pressed.is_connected(_on_left_pressed):
		left_button.pressed.connect(_on_left_pressed)
	if not mid_button.pressed.is_connected(_on_mid_pressed):
		mid_button.pressed.connect(_on_mid_pressed)
	if not right_button.pressed.is_connected(_on_right_pressed):
		right_button.pressed.connect(_on_right_pressed)
