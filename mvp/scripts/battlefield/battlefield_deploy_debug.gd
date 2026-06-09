class_name BattlefieldDeployDebug
extends Control

const M1ModelScript := preload("res://scripts/ball_machine/machine_causality_model.gd")
const ModelScript := preload("res://scripts/battlefield/battlefield_deploy_model.gd")
const ViewScript := preload("res://scripts/battlefield/battlefield_deploy_view.gd")
const UI_SCALE := 1.22

var _m1_model: RefCounted = M1ModelScript.new()
var _model: RefCounted = ModelScript.new()
var _view: Control
var _status_label: Label
var _queue_label: Label
var _guardian_label: Label
var _lane_list: VBoxContainer
var _unit_list: VBoxContainer
var _log_list: VBoxContainer
var _auto_run := true
var _next_slot := 1
var _built := false


func _ready() -> void:
	_ensure_built()


func _process(delta: float) -> void:
	if not _built or not _auto_run:
		return
	_model.tick(min(delta, 0.05))
	_refresh()


func verify_scene_build() -> bool:
	_ensure_built()
	return (
		_view != null
		and _status_label != null
		and _lane_list != null
		and _log_list != null
	)


func get_debug_summary() -> Dictionary:
	_ensure_built()
	return _model.get_debug_summary()


func run_debug_control_for_verification(control_id: String) -> Dictionary:
	_ensure_built()
	match control_id:
		"Click Left":
			_on_lane_clicked("Left")
		"Click Mid":
			_on_lane_clicked("Mid")
		"Click Right":
			_on_lane_clicked("Right")
		"Generate Queue Entry":
			_on_generate_queue_pressed()
		"Deploy Queue Head":
			_on_deploy_pressed()
		"Spawn Enemy":
			_on_spawn_enemy_pressed()
		"Step Battle":
			_on_step_pressed()
		"Resolve Win":
			_on_resolve_pressed("player_win")
		"Resolve Loss":
			_on_resolve_pressed("player_loss")
	_refresh()
	return get_debug_summary()


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_layout()
	_refresh()


func _build_layout() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	_view = ViewScript.new()
	_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_view.lane_clicked.connect(_on_lane_clicked)
	root.add_child(_view)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(540, 0)
	root.add_child(panel)

	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 10)
	panel.add_child(side)

	side.add_child(_make_label("M2 战场 / 部署路线调试", 21))
	side.add_child(_make_label("直接点击战场路线即可切换部署路线。", 13))

	_status_label = _make_label("", 14)
	side.add_child(_status_label)
	_queue_label = _make_label("", 13)
	side.add_child(_queue_label)
	_guardian_label = _make_label("", 13)
	side.add_child(_guardian_label)

	side.add_child(_make_separator())
	side.add_child(_make_label("队列 / 敌人控制", 15))
	var queue_row := GridContainer.new()
	queue_row.columns = 2
	queue_row.add_theme_constant_override("h_separation", 6)
	queue_row.add_theme_constant_override("v_separation", 6)
	side.add_child(queue_row)
	_add_button(queue_row, "生成队列条目", Callable(self, "_on_generate_queue_pressed"))
	_add_button(queue_row, "部署队首", Callable(self, "_on_deploy_pressed"))
	_add_button(queue_row, "生成敌人", Callable(self, "_on_spawn_enemy_pressed"))
	_add_button(queue_row, "推进战斗", Callable(self, "_on_step_pressed"))
	_add_button(queue_row, "暂停 / 运行", Callable(self, "_on_pause_pressed"))
	_add_button(queue_row, "重置", Callable(self, "_on_reset_pressed"))

	side.add_child(_make_label("路线状态调试", 15))
	var state_row := GridContainer.new()
	state_row.columns = 2
	state_row.add_theme_constant_override("h_separation", 6)
	state_row.add_theme_constant_override("v_separation", 6)
	side.add_child(state_row)
	_add_button(state_row, "强制推进", Callable(self, "_on_force_state_pressed").bind("pushing"))
	_add_button(state_row, "强制僵持", Callable(self, "_on_force_state_pressed").bind("stalled"))
	_add_button(state_row, "强制漏怪", Callable(self, "_on_force_state_pressed").bind("leaking"))
	_add_button(state_row, "击破路闸", Callable(self, "_on_force_state_pressed").bind("gate broken"))
	_add_button(state_row, "强制入侵", Callable(self, "_on_force_state_pressed").bind("invading"))
	_add_button(state_row, "预警 1 级", Callable(self, "_on_warning_pressed"))

	side.add_child(_make_label("战斗结果调试", 15))
	var result_row := HBoxContainer.new()
	result_row.add_theme_constant_override("separation", 6)
	side.add_child(result_row)
	_add_button(result_row, "结算胜利", Callable(self, "_on_resolve_pressed").bind("player_win"))
	_add_button(result_row, "结算失败", Callable(self, "_on_resolve_pressed").bind("player_loss"))

	side.add_child(_make_separator())
	side.add_child(_make_label("路线", 15))
	_lane_list = VBoxContainer.new()
	_lane_list.add_theme_constant_override("separation", 3)
	side.add_child(_lane_list)

	side.add_child(_make_label("单位", 15))
	_unit_list = VBoxContainer.new()
	_unit_list.add_theme_constant_override("separation", 3)
	side.add_child(_unit_list)

	side.add_child(_make_label("事件日志", 15))
	_log_list = VBoxContainer.new()
	_log_list.add_theme_constant_override("separation", 3)
	side.add_child(_log_list)


func _refresh() -> void:
	var summary: Dictionary = _model.get_debug_summary()
	_view.set_model(_model)

	_status_label.text = "部署路线：%s | %s | %.1f 秒" % [
		_display_lane(summary.get("selected_lane_name", "Mid")),
		_display_battle_state(summary.get("battle_state", "running")),
		float(summary.get("battle_time_seconds", 0.0)),
	]

	var queue_preview: Array = summary.get("queue_preview", [])
	if queue_preview.is_empty():
		_queue_label.text = "队首：空"
	else:
		var head: Dictionary = queue_preview[0]
		_queue_label.text = "队首 -> %s | %s | 来源槽 %d" % [
			_display_lane(head.get("deploy_lane_name", "")),
			head.get("queue_entry_id", ""),
			head.get("source_slot_id", 0),
		]

	_guardian_label.text = "玩家守护者生命 %d/%d | 敌方守护者生命 %d/%d" % [
		int(summary.get("player_guardian_hp", 0)),
		int(summary.get("player_guardian_max_hp", 1)),
		int(summary.get("enemy_guardian_hp", 0)),
		int(summary.get("enemy_guardian_max_hp", 1)),
	]

	_clear_container(_lane_list)
	var lanes: Dictionary = summary.get("lanes", {})
	for lane_id in [&"left", &"mid", &"right"]:
		var lane_data: Dictionary = lanes.get(lane_id, {})
		_lane_list.add_child(_make_label(
			"%s | %s | 危险 %d | 我方闸 %d | 敌方闸 %d" % [
				_display_lane(lane_data.get("lane_name", "")),
				_display_lane_state(lane_data.get("state", "idle")),
				int(lane_data.get("danger_tier", 0)),
				int(lane_data.get("player_gate_hp", 0)),
				int(lane_data.get("enemy_gate_hp", 0)),
			],
			11
		))

	_clear_container(_unit_list)
	var units: Array = summary.get("units", [])
	if units.is_empty():
		_unit_list.add_child(_make_label("无", 11))
	else:
		var unit_start: int = max(0, units.size() - 6)
		for unit in units.slice(unit_start):
			_unit_list.add_child(_make_label(
				"%s | %s | %s %.1f | 生命 %d/%d | %s" % [
					unit.get("display_name", ""),
					_display_side(unit.get("side", "")),
					_display_lane(unit.get("lane_name", "")),
					float(unit.get("path_pos", 0.0)),
					int(unit.get("hp", 0)),
					int(unit.get("max_hp", 0)),
					_display_unit_state(unit.get("state", "")),
				],
				10
			))

	_clear_container(_log_list)
	var recent_log: Array = summary.get("event_log", [])
	var log_start: int = max(0, recent_log.size() - 9)
	for event in recent_log.slice(log_start):
		_log_list.add_child(_make_label(
			"%.1f | %s | %s" % [
				float(event.get("time", 0.0)),
				_display_event_state(event.get("state", "")),
				event.get("description", ""),
			],
			10
		))


func _on_lane_clicked(lane_name: String) -> void:
	_model.select_lane(lane_name)
	_refresh()


func _on_generate_queue_pressed() -> void:
	var tuning_result := "Prime" if _next_slot == 2 else "Gate"
	var queue_entry: Dictionary = _m1_model.force_unit_slot_queue(_next_slot, tuning_result)
	if not queue_entry.is_empty():
		_model.enqueue_machine_queue_entry(queue_entry)
	_next_slot += 1
	if _next_slot > 4:
		_next_slot = 1
	_refresh()


func _on_deploy_pressed() -> void:
	_model.deploy_next_queue_entry()
	_refresh()


func _on_spawn_enemy_pressed() -> void:
	_model.spawn_enemy(_model.get_selected_lane_name(), "Enemy Grunt", 22.0)
	_refresh()


func _on_step_pressed() -> void:
	for _index in range(12):
		_model.tick(0.25)
	_refresh()


func _on_pause_pressed() -> void:
	_auto_run = not _auto_run
	_refresh()


func _on_reset_pressed() -> void:
	_model.reset()
	_m1_model.reset()
	_next_slot = 1
	_refresh()


func _on_force_state_pressed(state: String) -> void:
	_model.force_lane_state_for_debug(_model.get_selected_lane_name(), state)
	_refresh()


func _on_warning_pressed() -> void:
	_model.set_public_warning(_model.get_selected_lane_name(), 1)
	_refresh()


func _on_resolve_pressed(result_state: String) -> void:
	_model.force_battle_result_for_debug(result_state)
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


func _display_lane(lane) -> String:
	match str(lane):
		"Left", "left":
			return "左路"
		"Mid", "mid":
			return "中路"
		"Right", "right":
			return "右路"
	return str(lane)


func _display_battle_state(state) -> String:
	match str(state):
		"running":
			return "进行中"
		"player_win":
			return "玩家胜利"
		"player_loss":
			return "玩家失败"
	return str(state)


func _display_lane_state(state) -> String:
	match str(state):
		"idle":
			return "空闲"
		"pushing":
			return "推进"
		"stalled":
			return "僵持"
		"leaking":
			return "漏怪"
		"gate broken":
			return "路闸破损"
		"invading":
			return "入侵"
	return str(state)


func _display_unit_state(state) -> String:
	match str(state):
		"marching":
			return "行军"
		"unit attacking":
			return "攻击单位"
		"attacking gate":
			return "攻击路闸"
		"attacking guardian":
			return "攻击守护者"
		"dead":
			return "阵亡"
	return str(state)


func _display_event_state(state) -> String:
	match str(state):
		"battle reset":
			return "战场重置"
		"lane selected":
			return "选择路线"
		"queue entry added":
			return "队列加入"
		"queue deployed":
			return "队列部署"
		"enemy spawned":
			return "敌人出现"
		"lane warning":
			return "路线预警"
		"gate broken":
			return "路闸击破"
		"battle resolved":
			return "战斗结算"
		"unit spawned":
			return "单位出现"
		"unit attacking":
			return "单位攻击"
		"gate damaged":
			return "路闸受击"
		"guardian damaged":
			return "守护者受击"
		"unit died":
			return "单位阵亡"
	return str(state)


func _display_side(side) -> String:
	match str(side):
		"player":
			return "玩家侧"
		"enemy":
			return "敌方侧"
	return str(side)


func _scaled_font(font_size: int) -> int:
	return int(round(float(font_size) * UI_SCALE))
