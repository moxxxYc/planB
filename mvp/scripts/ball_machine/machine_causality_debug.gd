class_name MachineCausalityDebug
extends Control

const ModelScript := preload("res://scripts/ball_machine/machine_causality_model.gd")
const ViewScript := preload("res://scripts/ball_machine/machine_causality_view.gd")

const UI_SCALE := 1.24

var _model: RefCounted = ModelScript.new()
var _view: Control
var _supply_label: Label
var _auto_label: Label
var _time_label: Label
var _tuning_label: Label
var _motion_label: Label
var _slot_list: VBoxContainer
var _queue_list: VBoxContainer
var _log_list: VBoxContainer
var _built := false
var _refresh_elapsed: float = 0.0


func _ready() -> void:
	_ensure_built()


func _process(delta: float) -> void:
	if not _built:
		return
	_model.step_simulation(delta)
	_refresh_elapsed += delta
	if _refresh_elapsed >= 0.08:
		_refresh_elapsed = 0.0
		_refresh()
	else:
		_view.queue_redraw()


func verify_scene_build() -> bool:
	_ensure_built()
	return _view != null and _supply_label != null and _log_list != null


func get_debug_summary() -> Dictionary:
	var summary: Dictionary = _model.get_debug_summary()
	summary["debug_controls"] = [
		"Gate",
		"Prime",
		"Echo",
		"Surge",
		"Slot 1",
		"Slot 2",
		"Slot 3",
		"Slot 4",
		"Blocked Bounce",
		"Split Return",
		"Recycle Return",
		"Waste",
		"Logic Settlement",
	]
	return summary


func run_debug_control_for_verification(control_id: String) -> Dictionary:
	_ensure_built()
	match control_id:
		"Gate", "Prime", "Echo", "Surge":
			_on_tuning_pressed(control_id)
		"Slot 1":
			_on_slot_pressed(1)
		"Slot 2":
			_on_slot_pressed(2)
		"Slot 3":
			_on_slot_pressed(3)
		"Slot 4":
			_on_slot_pressed(4)
		"Blocked Bounce":
			_on_blocked_pressed()
		"Split Return":
			_on_state_pressed("Split Return")
		"Recycle Return":
			_on_state_pressed("Recycle Return")
		"Waste":
			_on_state_pressed("Waste")
		"Logic Settlement":
			_on_state_pressed("Logic Settlement")
	return get_debug_summary()


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_layout()
	_model.set_battle_time(0.0)
	_model.set_auto_running(true)
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
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)

	_view = ViewScript.new()
	_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_view)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(540, 0)
	root.add_child(panel)

	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 10)
	panel.add_child(side)

	side.add_child(_make_label("M1 机器因果调试", 23))
	_supply_label = _make_label("", 14)
	side.add_child(_supply_label)
	_auto_label = _make_label("", 13)
	side.add_child(_auto_label)
	_time_label = _make_label("", 14)
	side.add_child(_time_label)
	_tuning_label = _make_label("", 14)
	side.add_child(_tuning_label)
	_motion_label = _make_label("", 13)
	side.add_child(_motion_label)

	side.add_child(_make_separator())
	side.add_child(_make_label("自动球机", 16))
	var auto_row := HBoxContainer.new()
	auto_row.add_theme_constant_override("separation", 6)
	side.add_child(auto_row)
	_add_button(auto_row, "运行 / 暂停", Callable(self, "_on_auto_toggle_pressed"))
	_add_button(auto_row, "步进 0.5 秒", Callable(self, "_on_step_pressed"))

	side.add_child(_make_label("战斗时间", 16))
	var time_row := HBoxContainer.new()
	time_row.add_theme_constant_override("separation", 6)
	side.add_child(time_row)
	for seconds in [0, 24, 54, 96]:
		_add_button(time_row, "%d 秒" % seconds, Callable(self, "_on_time_pressed").bind(seconds))

	side.add_child(_make_label("调校结果", 16))
	var tuning_row := GridContainer.new()
	tuning_row.columns = 4
	tuning_row.add_theme_constant_override("h_separation", 6)
	side.add_child(tuning_row)
	for tuning_result in _model.TUNING_RESULTS:
		_add_button(
			tuning_row,
			_display_tuning(tuning_result),
			Callable(self, "_on_tuning_pressed").bind(tuning_result)
		)

	side.add_child(_make_label("单位槽命中", 16))
	var slot_row := GridContainer.new()
	slot_row.columns = 4
	slot_row.add_theme_constant_override("h_separation", 6)
	side.add_child(slot_row)
	for slot_id in [1, 2, 3, 4]:
		_add_button(slot_row, "槽 %d" % slot_id, Callable(self, "_on_slot_pressed").bind(slot_id))

	side.add_child(_make_label("物理状态", 16))
	var state_row := GridContainer.new()
	state_row.columns = 2
	state_row.add_theme_constant_override("h_separation", 6)
	state_row.add_theme_constant_override("v_separation", 6)
	side.add_child(state_row)
	_add_button(state_row, "阻挡反弹", Callable(self, "_on_blocked_pressed"))
	_add_button(state_row, "分裂回流", Callable(self, "_on_state_pressed").bind("Split Return"))
	_add_button(state_row, "回收回流", Callable(self, "_on_state_pressed").bind("Recycle Return"))
	_add_button(state_row, "废弃", Callable(self, "_on_state_pressed").bind("Waste"))
	_add_button(state_row, "逻辑结算", Callable(self, "_on_state_pressed").bind("Logic Settlement"))
	_add_button(state_row, "重置", Callable(self, "_on_reset_pressed"))

	side.add_child(_make_separator())
	side.add_child(_make_label("单位进度", 16))
	_slot_list = VBoxContainer.new()
	_slot_list.add_theme_constant_override("separation", 3)
	side.add_child(_slot_list)

	side.add_child(_make_label("队列", 16))
	_queue_list = VBoxContainer.new()
	_queue_list.add_theme_constant_override("separation", 3)
	side.add_child(_queue_list)

	side.add_child(_make_label("事件日志", 16))
	_log_list = VBoxContainer.new()
	_log_list.add_theme_constant_override("separation", 3)
	side.add_child(_log_list)


func _refresh() -> void:
	_view.set_model(_model)

	var supply: Dictionary = _model.get_supply_summary()
	_supply_label.text = "造球器 / 球池 / 发射器：球池 %d / %d，发射器运行中" % [
		supply["pool_count"],
		supply["pool_capacity"],
	]
	var motion: Dictionary = _model.get_motion_summary()
	_auto_label.text = "自动球机：%s | 炮台摆动 %.1f°" % [
		"运行中" if motion["auto_running"] else "暂停",
		rad_to_deg(float(motion["cannon_angle"])),
	]
	_time_label.text = "战斗时间：%.0f 秒" % _model.battle_time_seconds
	_tuning_label.text = "当前调校：%s" % _display_tuning(_model.selected_tuning_result)
	_motion_label.text = "当前运动：%s | 阶段 %.0f%% | 链 %s" % [
		_display_board(str(motion["active_board"])),
		float(motion["phase_progress"]) * 100.0,
		str(motion["chain_id"]),
	]

	_clear_container(_slot_list)
	for slot in _model.get_unit_slots():
		var accepting := "开放" if slot["accepting_hit"] else "被挡"
		_slot_list.add_child(_make_label(
			"槽 %d：%d / %d，暴露 %.0f%%，%s" % [
				slot["slot_id"],
				slot["progress_current"],
				slot["progress_required"],
				float(slot["exposure_ratio"]) * 100.0,
				accepting,
			],
			12
		))

	_clear_container(_queue_list)
	if _model.queue_entries.is_empty():
		_queue_list.add_child(_make_label("空", 12))
	else:
		var queue_start: int = max(0, _model.queue_entries.size() - 4)
		var recent_entries: Array = _model.queue_entries.slice(queue_start)
		for entry in recent_entries:
			_queue_list.add_child(_make_label(
				"%s | 来源槽 %d | %s | %s" % [
					entry["queue_entry_id"],
					entry["source_slot_id"],
					_display_tuning(entry["tuning_result"]),
					_display_chain(entry["trigger_chain"]),
				],
				11
			))

	_clear_container(_log_list)
	var start_index: int = max(0, _model.event_log.size() - 9)
	for index in range(start_index, _model.event_log.size()):
		var event: Dictionary = _model.event_log[index]
		_log_list.add_child(_make_label(
			"%s | %s | %s" % [
				event["chain_id"],
				_display_state(event["state"]),
				event["description"],
			],
			11
		))


func _on_time_pressed(seconds: int) -> void:
	_model.set_battle_time(float(seconds))
	_refresh()


func _on_auto_toggle_pressed() -> void:
	var motion: Dictionary = _model.get_motion_summary()
	_model.set_auto_running(not bool(motion["auto_running"]))
	_refresh()


func _on_step_pressed() -> void:
	_model.set_auto_running(false)
	for _index in range(10):
		_model.step_simulation(0.05)
	_refresh()


func _on_tuning_pressed(tuning_result: String) -> void:
	_model.set_auto_running(false)
	_model.force_tuning_result(tuning_result)
	_refresh()


func _on_slot_pressed(slot_id: int) -> void:
	_model.set_auto_running(false)
	_model.force_unit_slot_queue(slot_id, _model.selected_tuning_result)
	_refresh()


func _on_blocked_pressed() -> void:
	_model.set_auto_running(false)
	_model.force_blocked_bounce(4)
	_refresh()


func _on_state_pressed(state: String) -> void:
	_model.set_auto_running(false)
	_model.force_settlement_state(state)
	_refresh()


func _on_reset_pressed() -> void:
	_model.reset()
	_model.set_auto_running(true)
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
	button.custom_minimum_size = Vector2(0, 36)
	button.add_theme_font_size_override("font_size", _scaled_font(13))
	button.pressed.connect(callback)
	parent.add_child(button)


func _clear_container(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.free()


func _display_tuning(tuning_result: String) -> String:
	match tuning_result:
		"Gate":
			return "闸门"
		"Prime":
			return "预充"
		"Echo":
			return "复写"
		"Surge":
			return "脉冲"
	return tuning_result


func _display_state(state: String) -> String:
	match state:
		"Natural Hit":
			return "自然命中"
		"Blocked Bounce":
			return "阻挡反弹"
		"Valid Unit Hit":
			return "有效单位命中"
		"Split Return":
			return "分裂回流"
		"Recycle Return":
			return "回收回流"
		"Waste":
			return "废弃"
		"Logic Settlement":
			return "逻辑结算"
	return state


func _display_board(board_name: String) -> String:
	match board_name:
		"Launch":
			return "发射仓"
		"Tuning":
			return "调校仓"
		"Unit":
			return "单位仓"
		"Forge":
			return "造球器"
		"Pool":
			return "球池"
		"Launcher":
			return "发射器"
	return board_name


func _display_chain(chain: String) -> String:
	return chain \
		.replace("Launch", "发射仓") \
		.replace("Tuning", "调校仓") \
		.replace("Unit", "单位仓") \
		.replace("Queue", "队列")


func _scaled_font(font_size: int) -> int:
	return int(round(float(font_size) * UI_SCALE))
