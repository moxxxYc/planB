class_name EndpointPrepView
extends VBoxContainer

signal rest_bought
signal confirmed

var session: RunSessionModel = null

func _ready() -> void:
	add_theme_constant_override("separation", 14)

func render(p_session: RunSessionModel) -> void:
	session = p_session
	_clear_children()
	add_child(_make_label("终点前整备", 28))
	add_child(_make_label("不开放商店，不获得 Gold。这里只决定是否用 Gold 换守护者 HP，然后进入终点战。", 16))
	add_child(_make_label("当前 Gold：%d" % session.gold, 18))
	add_child(_make_label("守护者 HP：%d / %d" % [session.guardian_hp, session.guardian_max_hp], 18))
	add_child(_make_label("剩余休整次数：%d / 2" % session.get_endpoint_prep_rest_limit_remaining(), 16))
	_render_rest_button()
	_render_confirm_button()

func _render_rest_button() -> void:
	var button := Button.new()
	button.text = "休整：3 Gold，恢复 20 HP" if session.can_buy_rest() else "休整：当前不可用"
	button.disabled = not session.can_buy_rest()
	button.custom_minimum_size = Vector2(0.0, 72.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_on_rest_pressed)
	_style_button(button, Color("#222720"), Color("#9b7a4a"))
	add_child(button)

func _render_confirm_button() -> void:
	var button := Button.new()
	button.text = "进入终点战"
	button.custom_minimum_size = Vector2(0.0, 72.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_on_confirm_pressed)
	_style_button(button, Color("#243238"), Color("#56b4e9"))
	add_child(button)

func _on_rest_pressed() -> void:
	rest_bought.emit()

func _on_confirm_pressed() -> void:
	confirmed.emit()

func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#e8e1d2"))
	return label

func _style_button(button: Button, background: Color, border: Color) -> void:
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = background
	normal_style.border_color = border
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.corner_radius_top_left = 6
	normal_style.corner_radius_top_right = 6
	normal_style.corner_radius_bottom_left = 6
	normal_style.corner_radius_bottom_right = 6
	normal_style.content_margin_left = 16.0
	normal_style.content_margin_top = 14.0
	normal_style.content_margin_right = 16.0
	normal_style.content_margin_bottom = 14.0
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", normal_style)
	button.add_theme_stylebox_override("pressed", normal_style)
	button.add_theme_color_override("font_color", Color("#e8e1d2"))

func _clear_children() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
