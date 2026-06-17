class_name RunHudView
extends PanelContainer

var summary_label: Label = null

func _ready() -> void:
	custom_minimum_size = Vector2(0.0, 60.0)
	_apply_panel_style()
	_ensure_label()

func render(
	session: RunSessionModel,
	guardian_defs: Dictionary,
	reward_defs: Dictionary,
	shop_defs: Dictionary,
	second_reward_defs: Dictionary
) -> void:
	_ensure_label()
	summary_label.text = "守护者：%s | HP：%d/%d | 终点 HP：%d/%d | Gold：%d | 第一次奖励：%s | 第一次商店：%s | 第二次奖励：%s | 侦测反制：%s" % [
		_guardian_name(session.selected_guardian_id, guardian_defs),
		session.guardian_hp,
		session.guardian_max_hp,
		session.endpoint_guardian_hp,
		session.endpoint_guardian_max_hp,
		session.gold,
		_modifier_name(session.reward_one_id, reward_defs),
		_modifier_name(session.shop_purchase_id, shop_defs),
		_modifier_name(session.second_reward_id, second_reward_defs),
		_counter_name(session.planned_counter_id),
	]

func get_text() -> String:
	_ensure_label()
	return summary_label.text

func _ensure_label() -> void:
	if summary_label != null:
		return
	summary_label = Label.new()
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	summary_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_label.add_theme_color_override("font_color", Color("#e8e1d2"))
	summary_label.add_theme_font_size_override("font_size", 16)
	add_child(summary_label)

func _apply_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#20251f")
	style.border_color = Color("#56b4e9")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 16.0
	style.content_margin_top = 10.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 10.0
	add_theme_stylebox_override("panel", style)

func _guardian_name(guardian_id: String, guardian_defs: Dictionary) -> String:
	if guardian_id.is_empty() or not guardian_defs.has(guardian_id):
		return "未签订"
	var definition: GuardianDefinition = guardian_defs[guardian_id] as GuardianDefinition
	if definition == null:
		return guardian_id
	return definition.display_name

func _modifier_name(modifier_id: String, modifier_defs: Dictionary) -> String:
	if modifier_id.is_empty():
		return "无"
	if not modifier_defs.has(modifier_id):
		return modifier_id
	var definition: ModifierDefinition = modifier_defs[modifier_id] as ModifierDefinition
	if definition == null:
		return modifier_id
	return definition.display_name

func _counter_name(counter_id: String) -> String:
	match counter_id:
		"pool_polluter":
			return "Pool 污染者"
		"echo_breaker":
			return "Echo 破坏者"
		"stagger_punisher":
			return "断档惩罚者"
		_:
			return "未侦测"
