class_name SecondRewardChoiceView
extends VBoxContainer

signal reward_chosen(modifier_id: String)

var current_axis: String = ""
var candidate_records: Array[Dictionary] = []
var candidate_defs: Dictionary = {}

func _ready() -> void:
	add_theme_constant_override("separation", 12)

func render(
	p_current_axis: String,
	p_candidate_records: Array[Dictionary],
	p_candidate_defs: Dictionary
) -> void:
	current_axis = p_current_axis
	candidate_records = p_candidate_records.duplicate(true)
	candidate_defs = p_candidate_defs
	_clear_children()

	add_child(_make_label("第二次奖励", 26))
	add_child(_make_label("当前主轴：%s。选择一个免费机器修正：深化主轴，或补上已经暴露的问题。" % current_axis, 16))

	for record: Dictionary in candidate_records:
		var modifier_id: String = String(record.get("modifier_id", ""))
		if modifier_id.is_empty() or not candidate_defs.has(modifier_id):
			continue
		var button: Button = Button.new()
		button.text = get_card_text(modifier_id)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0.0, 138.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_ALL
		_style_card_button(button)
		button.pressed.connect(_on_reward_pressed.bind(modifier_id))
		add_child(button)

func get_card_text(modifier_id: String) -> String:
	for record: Dictionary in candidate_records:
		if String(record.get("modifier_id", "")) != modifier_id:
			continue
		var definition: ModifierDefinition = candidate_defs.get(modifier_id, null) as ModifierDefinition
		if definition == null:
			return ""
		return "%s\n%s\n候选来源：%s" % [
			definition.to_card_text(),
			String(record.get("offer_role_label", "")),
			String(record.get("reason", "")),
		]
	return ""

func _on_reward_pressed(modifier_id: String) -> void:
	reward_chosen.emit(modifier_id)

func _make_label(text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#e8e1d2"))
	return label

func _style_card_button(button: Button) -> void:
	var normal_style := _make_button_style(Color("#222720"), Color("#9b7a4a"), 2)
	var hover_style := _make_button_style(Color("#2a3028"), Color("#56b4e9"), 3)
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_color_override("font_color", Color("#e8e1d2"))
	button.add_theme_color_override("font_hover_color", Color("#f4f0d8"))

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
