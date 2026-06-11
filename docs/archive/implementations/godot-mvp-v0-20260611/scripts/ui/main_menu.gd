class_name MvpMainMenu
extends Control

const PLAYABLE_SCENE_PATH := "res://scenes/run/mvp_playable_session.tscn"
const LOGO_PATH := "res://assets/ui/planb_logo.png"
const KEY_ART_PATH := "res://assets/ui/menu_key_art.png"

const COLOR_BG := Color("#151916")
const COLOR_PANEL := Color("#20231f")
const COLOR_TEXT := Color("#e8e1d2")
const COLOR_TEXT_DIM := Color("#a8a296")
const COLOR_PLAYER := Color("#56b4e9")
const COLOR_LAUNCH := Color("#7bcb6b")
const COLOR_TUNING := Color("#e6b450")
const COLOR_UNIT := Color("#c58be8")
const UI_SCALE := 1.12

var _built := false
var _logo_texture: Texture2D
var _key_art_texture: Texture2D
var _start_button: Button
var _quit_button: Button
var _asset_status: Dictionary = {}


func _ready() -> void:
	_ensure_built()


func get_menu_contract_summary() -> Dictionary:
	_ensure_built()
	return {
		"playable_scene": PLAYABLE_SCENE_PATH,
		"has_start_button": _start_button != null,
		"has_quit_button": _quit_button != null,
		"asset_status": _asset_status.duplicate(),
	}


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_load_assets()
	_build_layout()


func _load_assets() -> void:
	_logo_texture = _load_texture(LOGO_PATH)
	_key_art_texture = _load_texture(KEY_ART_PATH)


func _load_texture(path: String) -> Texture2D:
	var resource := ResourceLoader.load(path)
	if not resource is Texture2D:
		_asset_status[path] = false
		return null
	var texture := resource as Texture2D
	_asset_status[path] = texture != null
	return texture


func _build_layout() -> void:
	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = COLOR_BG
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_right", 44)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 38)
	margin.add_child(body)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 24)
	body.add_child(left)

	var logo := TextureRect.new()
	logo.texture = _logo_texture
	logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(520, 170)
	left.add_child(logo)

	var axis_row := HBoxContainer.new()
	axis_row.add_theme_constant_override("separation", 10)
	left.add_child(axis_row)
	axis_row.add_child(_make_axis_chip("Launch", COLOR_LAUNCH))
	axis_row.add_child(_make_axis_chip("Tuning", COLOR_TUNING))
	axis_row.add_child(_make_axis_chip("Unit", COLOR_UNIT))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(spacer)

	_start_button = _make_menu_button("开始新短局", COLOR_PLAYER)
	_start_button.pressed.connect(_on_start_pressed)
	left.add_child(_start_button)

	_quit_button = _make_menu_button("退出", COLOR_TEXT_DIM)
	_quit_button.pressed.connect(_on_quit_pressed)
	left.add_child(_quit_button)

	var right_panel := PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(590, 0)
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(right_panel)

	var key_art := TextureRect.new()
	key_art.texture = _key_art_texture
	key_art.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	key_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	key_art.custom_minimum_size = Vector2(560, 780)
	right_panel.add_child(key_art)


func _make_axis_chip(text: String, color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", _scaled_font(16))
	label.add_theme_color_override("font_color", color)
	label.custom_minimum_size = Vector2(0, 38)
	panel.add_child(label)
	return panel


func _make_menu_button(text: String, accent: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 62)
	button.add_theme_font_size_override("font_size", _scaled_font(21))
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", accent)
	return button


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(PLAYABLE_SCENE_PATH)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _scaled_font(font_size: int) -> int:
	return int(round(float(font_size) * UI_SCALE))
