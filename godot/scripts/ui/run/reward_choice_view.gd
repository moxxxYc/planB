class_name RewardChoiceView
extends VBoxContainer

signal reward_chosen(modifier_id: String)
signal reward_chosen_with_payload(modifier_id: String, payload: Dictionary)

const REWARD_ORDER: Array[String] = [
	"pool_pocket",
	"prime_charge",
	"slot_primer",
]

var reward_defs: Dictionary = {}

func _ready() -> void:
	add_theme_constant_override("separation", 12)

func render(p_reward_defs: Dictionary) -> void:
	reward_defs = p_reward_defs
	_clear_children()

	add_child(_make_label("第一次奖励", 26))
	add_child(_make_label("选择一个机器轴向修正。它会从下一场战斗开始进入球机表现层。", 16))

	for modifier_id: String in REWARD_ORDER:
		if not reward_defs.has(modifier_id):
			continue
		if modifier_id == "slot_primer":
			add_child(_make_slot_primer_choice())
			continue
		var button: Button = Button.new()
		button.text = get_card_text(modifier_id)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0.0, 132.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_ALL
		_style_card_button(button)
		button.pressed.connect(_on_reward_pressed.bind(modifier_id))
		add_child(button)

func get_card_text(modifier_id: String) -> String:
	if not reward_defs.has(modifier_id):
		return ""
	var definition: ModifierDefinition = reward_defs[modifier_id] as ModifierDefinition
	if definition == null:
		return ""
	return definition.to_card_text()

func _on_reward_pressed(modifier_id: String) -> void:
	reward_chosen.emit(modifier_id)

func _on_reward_pressed_with_payload(modifier_id: String, payload: Dictionary) -> void:
	reward_chosen_with_payload.emit(modifier_id, payload.duplicate(true))

func _make_slot_primer_choice() -> VBoxContainer:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := _make_label(get_card_text("slot_primer"), 16)
	label.custom_minimum_size = Vector2(0.0, 92.0)
	container.add_child(label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for slot_id: int in range(1, 5):
		var slot_button := Button.new()
		slot_button.text = "S%d" % slot_id
		slot_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_button.focus_mode = Control.FOCUS_ALL
		_style_card_button(slot_button)
		slot_button.pressed.connect(_on_reward_pressed_with_payload.bind("slot_primer", {"slot_id": slot_id}))
		row.add_child(slot_button)
	container.add_child(row)
	return container

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
