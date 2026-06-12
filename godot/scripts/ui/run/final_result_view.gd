class_name FinalResultView
extends VBoxContainer

var summary_text: String = ""

func _ready() -> void:
	add_theme_constant_override("separation", 12)

func render(
	session: RunSessionModel,
	guardian_defs: Dictionary,
	reward_defs: Dictionary,
	shop_defs: Dictionary,
	second_reward_defs: Dictionary
) -> void:
	_clear_children()
	var record: Dictionary = session.build_final_result_record()
	summary_text = _build_summary_text(record, guardian_defs, reward_defs, shop_defs, second_reward_defs)
	add_child(_make_label("最终结果", 28))
	add_child(_make_label(summary_text, 16))

func get_summary_text() -> String:
	return summary_text

func _build_summary_text(
	record: Dictionary,
	guardian_defs: Dictionary,
	reward_defs: Dictionary,
	shop_defs: Dictionary,
	second_reward_defs: Dictionary
) -> String:
	var guardian_id := String(record.get("guardian.choice_id", record.get("guardian_id", "")))
	var reward_id := String(record.get("reward1.choice_id", record.get("reward1_id", "")))
	var shop_id := String(record.get("shop1.purchase_id", record.get("shop1_purchase_id", "")))
	var second_reward_id := String(record.get("second_offer.choice_id", ""))
	return "主要机器轴：%s\n关键选择：Guardian %s；奖励 %s / %s；商店 %s\nGuardian 选择：%s\n关键奖励：第一次 %s；第二次 %s\n关键商店：%s\nUnit 槽贡献：%s\n主要反制：第一次 %s 攻击 %s，效果 %s；第二次 %s\n敌方反制：%s\nDeploy Lane 影响：%s\n部署路线影响：%s\n守护者压力：%s\n终点战结论：%s；主轴兑现：%s；断裂原因：%s；HP：%s\n休整与 Gold：购买 %d 次，花费 %d Gold，恢复 %d HP\n下一局观察：%s" % [
		String(record.get("reward1.axis", "未记录")),
		_guardian_name(guardian_id, guardian_defs),
		_modifier_name(reward_id, reward_defs),
		_modifier_name(second_reward_id, second_reward_defs),
		_modifier_name(shop_id, shop_defs),
		_guardian_name(guardian_id, guardian_defs),
		_modifier_name(reward_id, reward_defs),
		_modifier_name(second_reward_id, second_reward_defs),
		_modifier_name(shop_id, shop_defs),
		_unit_contribution_text(record.get("unit.visible_contribution_slots", [])),
		_counter_name(String(record.get("counter1.family", ""))),
		String(record.get("counter1.target_component", "未记录")),
		String(record.get("counter1.visible_effect", "未记录")),
		_counter_name(String(record.get("counter2.family", ""))),
		_counter_name(String(record.get("counter1.family", ""))),
		String(record.get("endpoint.deploy_lane_impact", "未记录")),
		String(record.get("endpoint.deploy_lane_impact", "未记录")),
		_pressure_text(record.get("guardian.hp_pressure_events", [])),
		String(record.get("endpoint.outcome", "未记录")),
		String(record.get("endpoint.primary_axis_payoff", "未记录")),
		String(record.get("endpoint.main_break_reason", "未记录")),
		String(record.get("endpoint.guardian_hp", "未记录")),
		int(record.get("rest.total_purchases", 0)),
		int(record.get("rest.total_gold_spent", 0)),
		int(record.get("rest.total_hp_restored", 0)),
		String(record.get("endpoint.next_run_watch_tag", "未记录")),
	]

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

func _pressure_text(value: Variant) -> String:
	if value is Array:
		var events: Array = value as Array
		if events.is_empty():
			return "无明显 HP 压力事件"
		var text := PackedStringArray()
		for event: Variant in events:
			text.append(String(event))
		return "；".join(text)
	return String(value)

func _unit_contribution_text(value: Variant) -> String:
	if value is Array:
		var parts := PackedStringArray()
		for entry_variant: Variant in value as Array:
			if entry_variant is Dictionary:
				var entry: Dictionary = entry_variant as Dictionary
				parts.append("S%d %s" % [int(entry.get("slot_id", 0)), String(entry.get("visible_result", "已记录"))])
		if not parts.is_empty():
			return "；".join(parts)
	if value is Dictionary:
		return JSON.stringify(value)
	return "未记录"

func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
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
