class_name RunResultView
extends VBoxContainer

var summary_text: String = ""

func _ready() -> void:
	add_theme_constant_override("separation", 12)

func render(
	session: RunSessionModel,
	guardian_defs: Dictionary,
	reward_defs: Dictionary,
	shop_defs: Dictionary
) -> void:
	_clear_children()
	summary_text = _build_summary_text(session, guardian_defs, reward_defs, shop_defs)

	add_child(_make_label("结果路由", 26))
	add_child(_make_label(summary_text, 16))

func get_summary_text() -> String:
	return summary_text

func _build_summary_text(
	session: RunSessionModel,
	guardian_defs: Dictionary,
	reward_defs: Dictionary,
	shop_defs: Dictionary
) -> String:
	var guardian_name: String = _guardian_name(session.selected_guardian_id, guardian_defs)
	var reward_name: String = _modifier_name(session.reward_one_id, reward_defs)
	var shop_name: String = _modifier_name(session.shop_purchase_id, shop_defs)
	var counter_text: String = _counter_summary(session.counter_record)
	var next_step: String = "下一步：M3 到此结束，等待后续里程碑确认。"

	return "守护者：%s\n第一次奖励：%s\n第一次商店：%s\nGold：%d\n休息：第一次商店 %d 次，战斗 3 后 %d 次\n最后战斗：%s\n结果：%s\n%s\n%s" % [
		guardian_name,
		reward_name,
		shop_name,
		session.gold,
		session.first_shop_rest_count,
		session.battle_three_rest_count,
		_battle_display_name(session.last_battle),
		_result_display_name(session.last_battle_result),
		counter_text,
		next_step,
	]

func _battle_display_name(battle_id: String) -> String:
	match battle_id:
		RunSessionModel.NODE_BATTLE_1:
			return "战斗 1"
		RunSessionModel.NODE_BATTLE_2:
			return "战斗 2"
		RunSessionModel.NODE_BATTLE_3:
			return "战斗 3"
		_:
			return "未记录"

func _result_display_name(result: String) -> String:
	match result:
		RunSessionModel.RESULT_WIN:
			return "胜利"
		RunSessionModel.RESULT_LOSS:
			return "失败"
		_:
			return "未记录"

func _guardian_name(guardian_id: String, guardian_defs: Dictionary) -> String:
	if guardian_id.is_empty() or not guardian_defs.has(guardian_id):
		return "未选择"
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

func _counter_summary(record: Dictionary) -> String:
	if record.is_empty():
		return "第一次反制：未记录"
	return "第一次反制：%s\n目标组件：%s\n可见结果：%s\n回应链路：%s" % [
		_counter_name(String(record.get("family", ""))),
		String(record.get("target_component", "未记录")),
		String(record.get("visible_effect", "未记录")),
		String(record.get("response_link", "无")),
	]

func _counter_name(counter_id: String) -> String:
	match counter_id:
		"pool_polluter":
			return "Pool Polluter"
		"echo_breaker":
			return "Echo Breaker"
		"stagger_punisher":
			return "Stagger Punisher"
		_:
			return "未记录"

func _make_label(text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#e8e1d2"))
	return label

func _clear_children() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
