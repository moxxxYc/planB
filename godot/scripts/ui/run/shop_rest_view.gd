class_name ShopRestView
extends VBoxContainer

signal shop_item_bought(modifier_id: String)
signal rest_bought
signal confirmed

const SHOP_ORDER: Array[String] = [
	"front_recycle",
	"surge_buffer",
	"queue_brace",
]

var shop_defs: Dictionary = {}
var session: RunSessionModel = null
var hide_shop: bool = false
var visible_shop_item_ids: Array[String] = []

func _ready() -> void:
	add_theme_constant_override("separation", 12)

func render(
	p_shop_defs: Dictionary,
	p_session: RunSessionModel,
	p_hide_shop: bool = false,
	p_visible_ids: Array[String] = [],
	p_counter_scout_text: String = ""
) -> void:
	shop_defs = p_shop_defs
	session = p_session
	hide_shop = p_hide_shop
	visible_shop_item_ids = p_visible_ids.duplicate()
	_clear_children()

	add_child(_make_label("休整", 26))
	if hide_shop:
		add_child(_make_label("战斗 3 后只开放守护者休息，然后进入战斗 4。", 16))
	else:
		add_child(_make_label("第一次商店：最多购买 1 个中立机器修正。休息独立计算，不占商店购买名额。", 16))
		if not p_counter_scout_text.is_empty():
			add_child(_make_label("反制侦测：%s" % p_counter_scout_text, 15))
		_render_shop_items()

	_render_rest()
	_render_confirm_button()

func get_card_text(modifier_id: String) -> String:
	if not shop_defs.has(modifier_id):
		return ""
	var definition: ModifierDefinition = shop_defs[modifier_id] as ModifierDefinition
	if definition == null:
		return ""
	return definition.to_card_text()

func _render_shop_items() -> void:
	var ordered_ids: Array[String] = visible_shop_item_ids if not visible_shop_item_ids.is_empty() else SHOP_ORDER
	for modifier_id: String in ordered_ids:
		if not shop_defs.has(modifier_id):
			continue
		var definition: ModifierDefinition = shop_defs[modifier_id] as ModifierDefinition
		var button: Button = Button.new()
		button.text = get_card_text(modifier_id)
		if session != null and session.shop_purchase_id == modifier_id:
			button.text = "已购买\n%s" % button.text
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0.0, 118.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_ALL
		button.disabled = (
			session == null
			or definition == null
			or not session.shop_purchase_id.is_empty()
			or session.gold < definition.gold_cost
		)
		_style_card_button(button)
		button.pressed.connect(_on_shop_item_pressed.bind(modifier_id))
		add_child(button)

func _render_rest() -> void:
	var rest_text: String = "守护者 HP：未知"
	var can_rest: bool = false
	if session != null:
		rest_text = "守护者 HP：%d / %d | 休息：3 Gold，恢复 20 HP" % [
			session.guardian_hp,
			session.guardian_max_hp,
		]
		can_rest = session.can_buy_rest()

	var rest_button: Button = Button.new()
	rest_button.text = rest_text if can_rest else "%s | 当前不可休息" % rest_text
	rest_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	rest_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rest_button.custom_minimum_size = Vector2(0.0, 68.0)
	rest_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rest_button.disabled = not can_rest
	_style_card_button(rest_button)
	rest_button.pressed.connect(_on_rest_pressed)
	add_child(rest_button)

func _render_confirm_button() -> void:
	var confirm_button: Button = Button.new()
	confirm_button.text = "进入战斗 4" if hide_shop else "离开商店，进入战斗 3"
	confirm_button.custom_minimum_size = Vector2(0.0, 58.0)
	confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_command_button(confirm_button)
	confirm_button.pressed.connect(_on_confirm_pressed)
	add_child(confirm_button)

func _on_shop_item_pressed(modifier_id: String) -> void:
	shop_item_bought.emit(modifier_id)

func _on_rest_pressed() -> void:
	rest_bought.emit()

func _on_confirm_pressed() -> void:
	confirmed.emit()

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
	var disabled_style := _make_button_style(Color("#1b211d"), Color("#6f6547"), 1)
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_stylebox_override("disabled", disabled_style)
	button.add_theme_color_override("font_color", Color("#e8e1d2"))
	button.add_theme_color_override("font_disabled_color", Color("#a8a497"))

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
