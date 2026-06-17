class_name GuardianContractView
extends VBoxContainer

signal guardian_selected(guardian_id: String)
signal guardian_confirmed

const GUARDIAN_ORDER: Array[String] = [
	"hive_vein_mother",
	"hive_acid_crown_mother",
]

var guardian_defs: Dictionary = {}
var selected_guardian_id: String = ""

func _ready() -> void:
	add_theme_constant_override("separation", 12)

func render(p_guardian_defs: Dictionary, p_selected_id: String) -> void:
	guardian_defs = p_guardian_defs
	selected_guardian_id = p_selected_id
	_clear_children()

	var title_label: Label = _make_label("守护者契约", 26)
	add_child(title_label)
	add_child(_make_label("选择本次短局的守护者。契约只决定本局机器倾向和风险读法，不是可直接操作单位。", 16))

	for guardian_id: String in GUARDIAN_ORDER:
		if not guardian_defs.has(guardian_id):
			continue
		var button: Button = Button.new()
		button.text = "%s%s" % [
			"已选择\n" if guardian_id == selected_guardian_id else "",
			get_card_text(guardian_id),
		]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0.0, 150.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_ALL
		_style_card_button(button, guardian_id == selected_guardian_id)
		button.pressed.connect(_on_guardian_pressed.bind(guardian_id))
		add_child(button)

	var confirm_button: Button = Button.new()
	confirm_button.text = "确认契约，进入战斗 1"
	confirm_button.custom_minimum_size = Vector2(0.0, 58.0)
	confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_button.disabled = selected_guardian_id.is_empty()
	_style_command_button(confirm_button)
	confirm_button.pressed.connect(_on_confirm_pressed)
	add_child(confirm_button)

func get_card_text(guardian_id: String) -> String:
	if not guardian_defs.has(guardian_id):
		return ""
	var definition: GuardianDefinition = guardian_defs[guardian_id] as GuardianDefinition
	if definition == null:
		return ""
	return definition.to_card_text()

func _on_guardian_pressed(guardian_id: String) -> void:
	guardian_selected.emit(guardian_id)

func _on_confirm_pressed() -> void:
	guardian_confirmed.emit()

func _make_label(text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#e8e1d2"))
	return label

func _style_card_button(button: Button, is_selected: bool) -> void:
	var normal_style := _make_button_style(Color("#222720"), Color("#56b4e9") if is_selected else Color("#9b7a4a"), 3 if is_selected else 2)
	var hover_style := _make_button_style(Color("#2a3028"), Color("#56b4e9"), 3)
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_color_override("font_color", Color("#e8e1d2"))
	button.add_theme_color_override("font_hover_color", Color("#f4f0d8"))

func _style_command_button(button: Button) -> void:
	var normal_style := _make_button_style(Color("#243238"), Color("#56b4e9"), 2)
	var hover_style := _make_button_style(Color("#2c4048"), Color("#56b4e9"), 3)
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)

func _make_button_style(background: Color, border: Color, border_width: int) -> StyleBoxFlat:
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
	style.content_margin_left = 16.0
	style.content_margin_top = 14.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 14.0
	return style

func _clear_children() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
