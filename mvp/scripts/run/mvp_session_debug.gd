class_name MvpSessionDebug
extends Control

const ModelScript := preload("res://scripts/run/mvp_session_model.gd")
const UI_SCALE := 1.22

var _model: RefCounted = ModelScript.new()
var _guardian_label: Label
var _status_label: Label
var _flow_list: VBoxContainer
var _result_list: VBoxContainer
var _telemetry_list: VBoxContainer
var _log_list: VBoxContainer
var _built := false


func _ready() -> void:
	_ensure_built()


func verify_scene_build() -> bool:
	_ensure_built()
	return (
		_guardian_label != null
		and _status_label != null
		and _flow_list != null
		and _result_list != null
		and _telemetry_list != null
	)


func run_full_debug_session_for_verification() -> Dictionary:
	_ensure_built()
	var result: Dictionary = _model.run_debug_win_session("hive.vein_mother")
	_refresh()
	return result


func get_debug_summary() -> Dictionary:
	_ensure_built()
	return _model.get_run_summary()


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_model.start_new_run("hive.vein_mother")
	_build_layout()
	_refresh()


func _build_layout() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(540, 0)
	root.add_child(left_panel)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	left_panel.add_child(left)

	left.add_child(_make_label("M3 完整 MVP v0 短局", 21))
	left.add_child(_make_label("调试流程：守护者选择 -> 战斗 -> 奖励 -> 商店 / 休整 -> 反制 -> 终点 -> 结算页。", 12))

	_guardian_label = _make_label("", 13)
	left.add_child(_guardian_label)
	_status_label = _make_label("", 13)
	left.add_child(_status_label)

	left.add_child(_make_separator())
	left.add_child(_make_label("守护者选择", 15))
	var guardian_row := HBoxContainer.new()
	guardian_row.add_theme_constant_override("separation", 6)
	left.add_child(guardian_row)
	_add_button(guardian_row, "巢脉母", Callable(self, "_on_guardian_pressed").bind("hive.vein_mother"))
	_add_button(guardian_row, "酸冠母", Callable(self, "_on_guardian_pressed").bind("hive.acid_crown_mother"))

	left.add_child(_make_label("短局控制", 15))
	var run_grid := GridContainer.new()
	run_grid.columns = 2
	run_grid.add_theme_constant_override("h_separation", 6)
	run_grid.add_theme_constant_override("v_separation", 6)
	left.add_child(run_grid)
	_add_button(run_grid, "运行胜利局", Callable(self, "_on_run_win_pressed"))
	_add_button(run_grid, "运行失败局", Callable(self, "_on_run_loss_pressed"))
	_add_button(run_grid, "重置", Callable(self, "_on_reset_pressed"))

	left.add_child(_make_separator())
	left.add_child(_make_label("流程", 15))
	_flow_list = VBoxContainer.new()
	_flow_list.add_theme_constant_override("separation", 2)
	left.add_child(_flow_list)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	root.add_child(right)

	var result_panel := PanelContainer.new()
	result_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(result_panel)
	var result_box := VBoxContainer.new()
	result_box.add_theme_constant_override("separation", 4)
	result_panel.add_child(result_box)
	result_box.add_child(_make_label("结算页事实", 17))
	_result_list = VBoxContainer.new()
	_result_list.add_theme_constant_override("separation", 3)
	result_box.add_child(_result_list)

	var telemetry_panel := PanelContainer.new()
	telemetry_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(telemetry_panel)
	var telemetry_box := VBoxContainer.new()
	telemetry_box.add_theme_constant_override("separation", 4)
	telemetry_panel.add_child(telemetry_box)
	telemetry_box.add_child(_make_label("检查点遥测", 17))
	_telemetry_list = VBoxContainer.new()
	_telemetry_list.add_theme_constant_override("separation", 3)
	telemetry_box.add_child(_telemetry_list)

	var log_panel := PanelContainer.new()
	log_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(log_panel)
	var log_box := VBoxContainer.new()
	log_box.add_theme_constant_override("separation", 4)
	log_panel.add_child(log_box)
	log_box.add_child(_make_label("事件日志", 17))
	_log_list = VBoxContainer.new()
	_log_list.add_theme_constant_override("separation", 3)
	log_box.add_child(_log_list)


func _refresh() -> void:
	var summary: Dictionary = _model.get_run_summary()
	var guardian: Dictionary = summary.get("chosen_guardian", {})
	_guardian_label.text = "守护者：%s | 轴 %s | 战术 %s" % [
		guardian.get("display_name", "无"),
		_display_axis(guardian.get("axis_lean", "")),
		guardian.get("tactical_skill", ""),
	]
	_status_label.text = "阶段：%s | 金币 %d | 守护者生命 %d/%d | 主轴 %s" % [
		_display_step(summary.get("current_step", "")),
		int(summary.get("gold", 0)),
		int(summary.get("player_guardian_hp", 0)),
		100,
		_display_axis(summary.get("main_axis", "")),
	]

	_clear_container(_flow_list)
	for step in summary.get("flow_history", []):
		_flow_list.add_child(_make_label("- %s" % _display_step(step), 11))

	_clear_container(_result_list)
	var result_page: Dictionary = summary.get("result_page", {})
	if result_page.is_empty():
		_result_list.add_child(_make_label("运行胜利局或失败局后会填充真实本局数据。", 12))
	else:
		for key in [
			"chosen_guardian",
			"main_axis",
			"key_rewards",
			"shop_rest_choice",
			"counter_target",
			"deploy_lane_impact",
			"endpoint_payoff_or_break_reason",
			"next_run_watch_tag",
		]:
			_result_list.add_child(_make_label(
				"%s：%s" % [_display_result_key(key), _display_value(result_page.get(key, ""))],
				11
			))

	_clear_container(_telemetry_list)
	var telemetry: Dictionary = summary.get("telemetry", {})
	if telemetry.is_empty():
		_telemetry_list.add_child(_make_label("还没有检查点遥测。", 12))
	else:
		for key in telemetry.keys().slice(0, min(18, telemetry.size())):
			_telemetry_list.add_child(_make_label(
				"%s：%s" % [_display_telemetry_key(key), _display_value(telemetry[key])],
				10
			))

	_clear_container(_log_list)
	var events: Array = summary.get("event_log", [])
	var start_index: int = max(0, events.size() - 12)
	for event in events.slice(start_index):
		_log_list.add_child(_make_label(
			"%s | %s" % [
				_display_event_state(event.get("state", "")),
				_display_value(event.get("description", "")),
			],
			10
		))


func _on_guardian_pressed(guardian_id: String) -> void:
	_model.start_new_run(guardian_id)
	_refresh()


func _on_run_win_pressed() -> void:
	var guardian_id := str(_model.chosen_guardian.get("guardian_id", "hive.vein_mother"))
	_model.run_debug_win_session(guardian_id)
	_refresh()


func _on_run_loss_pressed() -> void:
	var guardian_id := str(_model.chosen_guardian.get("guardian_id", "hive.acid_crown_mother"))
	_model.run_debug_loss_session(guardian_id)
	_refresh()


func _on_reset_pressed() -> void:
	_model.start_new_run("hive.vein_mother")
	_refresh()


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", _scaled_font(font_size))
	return label


func _make_separator() -> HSeparator:
	var separator := HSeparator.new()
	separator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return separator


func _add_button(parent: Node, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 38)
	button.add_theme_font_size_override("font_size", _scaled_font(13))
	button.pressed.connect(callback)
	parent.add_child(button)


func _clear_container(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.free()


func _display_step(step) -> String:
	match str(step):
		"Guardian Select":
			return "守护者选择"
		"Battle 1":
			return "第一战"
		"First Reward":
			return "第一奖励"
		"Battle 2":
			return "第二战"
		"Shop / Gold / Rest":
			return "商店 / 金币 / 休整"
		"Battle 3 with counter":
			return "第三战（带反制）"
		"Battle 4":
			return "第四战"
		"Second Reward":
			return "第二奖励"
		"Battle 5":
			return "第五战"
		"Endpoint Prep":
			return "终点准备"
		"Endpoint":
			return "终点"
		"Result Page":
			return "结算页"
	return str(step)


func _display_axis(axis) -> String:
	match str(axis):
		"Launch":
			return "发射"
		"Tuning":
			return "调校"
		"Unit":
			return "单位"
	return str(axis)


func _display_result_key(key) -> String:
	match str(key):
		"chosen_guardian":
			return "选择的守护者"
		"main_axis":
			return "主轴"
		"key_rewards":
			return "关键奖励"
		"shop_rest_choice":
			return "商店 / 休整选择"
		"counter_target":
			return "反制目标"
		"deploy_lane_impact":
			return "部署路线影响"
		"endpoint_payoff_or_break_reason":
			return "终点收益 / 失败原因"
		"next_run_watch_tag":
			return "下局观察标签"
	return str(key)


func _display_telemetry_key(key) -> String:
	match str(key):
		"gold_faucet.debug_first_pass":
			return "金币水龙头（调试首版）"
		"guardian.choice_id":
			return "守护者选择 ID"
		"guardian.choice_read":
			return "守护者选择读数"
		"battle1.machine_chain_sample":
			return "第一战机器链样本"
		"battle1.exposure_gate_snapshot":
			return "第一战暴露闸快照"
		"battle1.deploy_lane_selection":
			return "第一战部署路线选择"
		"battle1.lane_danger_snapshot":
			return "第一战路线危险快照"
		"guardian.hp_pressure_events":
			return "守护者生命压力"
		"reward1.choice_id":
			return "第一奖励选择"
		"reward1.axis":
			return "第一奖励轴"
		"reward1.component_operation":
			return "第一奖励组件操作"
		"reward1.battlefield_expectation":
			return "第一奖励战场预期"
		"reward1.battlefield_result":
			return "第一奖励战场结果"
		"shop1.gold_before":
			return "商店前金币"
		"shop1.purchase_id":
			return "商店购买"
		"shop1.purchase_role":
			return "商店购买职责"
		"shop1.gold_after":
			return "商店后金币"
		"shop1.neutral_purchase_cap":
			return "中立购买上限"
		"shop1.inventory":
			return "商店库存"
		"rest_windows":
			return "休整窗口"
		"counter1.family":
			return "反制家族"
		"counter1.target_component":
			return "反制目标组件"
		"counter1.visible_effect":
			return "反制可见效果"
		"counter1.response_link":
			return "反制响应链接"
		"second_offer.current_axis":
			return "第二奖励当前轴"
		"second_offer.candidates":
			return "第二奖励候选"
		"second_offer.choice_id":
			return "第二奖励选择"
		"second_offer.choice_role":
			return "第二奖励职责"
		"session.decision_windows":
			return "本局决策窗口"
		"session.consecutive_no_explained_decision_battles":
			return "连续无解释决策战斗数"
		"endpoint.outcome":
			return "终点结果"
		"endpoint.primary_axis_payoff":
			return "终点主轴收益"
		"endpoint.main_break_reason":
			return "终点失败原因"
		"endpoint.deploy_lane_impact":
			return "终点部署路线影响"
		"endpoint.guardian_hp":
			return "终点守护者生命"
		"endpoint.next_run_watch_tag":
			return "下局观察标签"
		"guardian.outcome":
			return "守护者结果"
		"unit.visible_contribution_slots":
			return "可见贡献单位槽"
		"unit.key_queue_entries_by_slot":
			return "单位槽关键队列条目"
		"unit.dominant_slot_share":
			return "主导单位槽占比"
	return str(key)


func _display_event_state(state) -> String:
	match str(state):
		"guardian selected":
			return "选择守护者"
		"battle resolved":
			return "战斗结算"
		"gold faucet":
			return "金币水龙头"
		"first reward selected":
			return "第一奖励"
		"shop purchase":
			return "商店购买"
		"counter warning":
			return "反制预警"
		"second reward selected":
			return "第二奖励"
		"endpoint prep":
			return "终点准备"
		"endpoint resolved":
			return "终点结算"
		"result page":
			return "结算页"
	return str(state)


func _display_value(value) -> String:
	if value is Dictionary:
		var parts: Array[String] = []
		for key in (value as Dictionary).keys().slice(0, min(5, (value as Dictionary).size())):
			parts.append("%s=%s" % [_display_telemetry_key(key), _display_value((value as Dictionary)[key])])
		if (value as Dictionary).size() > parts.size():
			parts.append("...")
		return "{%s}" % ", ".join(parts)
	if value is Array:
		var values := value as Array
		var parts: Array[String] = []
		for item in values.slice(0, min(4, values.size())):
			parts.append(_display_value(item))
		if values.size() > parts.size():
			parts.append("...")
		return "[%s]" % ", ".join(parts)
	var text := str(value)
	return text \
		.replace("Guardian Select", "守护者选择") \
		.replace("First Reward", "第一奖励") \
		.replace("Second Reward", "第二奖励") \
		.replace("Endpoint Prep", "终点准备") \
		.replace("Result Page", "结算页") \
		.replace("Shop / Gold / Rest", "商店 / 金币 / 休整") \
		.replace("Battle 3 with counter", "第三战（带反制）") \
		.replace("Guardian", "守护者") \
		.replace("Launch", "发射") \
		.replace("Tuning", "调校") \
		.replace("Unit", "单位") \
		.replace("Pool", "球池") \
		.replace("Junk", "废球") \
		.replace("Recycle", "回收") \
		.replace("Queue", "队列") \
		.replace("Slot", "单位槽") \
		.replace("Gate", "闸门") \
		.replace("Prime", "预充") \
		.replace("Echo", "复写") \
		.replace("Surge", "脉冲") \
		.replace("Left", "左路") \
		.replace("Mid", "中路") \
		.replace("Right", "右路") \
		.replace("player_win", "玩家胜利") \
		.replace("player_loss", "玩家失败") \
		.replace("win", "胜利") \
		.replace("loss", "失败") \
		.replace("Anchor", "锚点") \
		.replace("Patch", "补洞") \
		.replace("Pivot", "转轴") \
		.replace("Deepen", "深化") \
		.replace("Rest", "休整") \
		.replace("reached_endpoint", "到达终点") \
		.replace("victory", "胜利") \
		.replace("ending_hp", "结束生命")


func _scaled_font(font_size: int) -> int:
	return int(round(float(font_size) * UI_SCALE))
