class_name MachineStripView
extends VBoxContainer

const MachineBoardViewScript := preload("res://scripts/ui/machine_board_view.gd")

const FORGE_CYCLE_SECONDS: float = 2.2
const LAUNCHER_CYCLE_SECONDS: float = 1.3
const MAX_POOL_SIZE: int = 5
const LOG_LINE_COUNT: int = 3

@onready var machine_board: MachineBoardViewScript = %MachineBoardView
@onready var forge_label: Label = %ForgeLabel
@onready var forge_bar: ProgressBar = %ForgeProgressBar
@onready var launcher_label: Label = %LauncherLabel
@onready var launcher_bar: ProgressBar = %LauncherProgressBar
@onready var pool_label: Label = %PoolLabel
@onready var tuning_label: Label = %TuningLabel
@onready var unit_label: Label = %UnitLabel
@onready var queue_hint_label: Label = %QueueHintLabel
@onready var log_label: Label = %MachineLogLabel

func _ready() -> void:
	_ensure_nodes()
	add_theme_constant_override("separation", 8)
	_configure_machine_panel_layout()
	log_label.add_theme_color_override("font_color", Color("#c8c0ad"))

func render(machine) -> void:
	_ensure_nodes()
	var forge_ratio: float = clampf(machine.forge_progress / FORGE_CYCLE_SECONDS, 0.0, 1.0)
	var launcher_ratio: float = clampf(machine.launcher_progress / LAUNCHER_CYCLE_SECONDS, 0.0, 1.0)

	machine_board.render(machine)
	forge_bar.value = forge_ratio * 100.0
	launcher_bar.value = launcher_ratio * 100.0
	forge_label.text = "Forge 造球 %.0f%% -> Pool" % (forge_ratio * 100.0)
	launcher_label.text = "Launcher 发射 %.0f%% -> Tuning" % (launcher_ratio * 100.0)
	pool_label.text = "Pool 球池 %d / %d 颗净球" % [machine.pool.size(), MAX_POOL_SIZE]
	tuning_label.text = "Tuning 槽：Gate / Prime / Echo / Surge"
	unit_label.text = "Unit 槽：S1 %d/3 | S2 %d/5 | S3 %d/8 | S4 %d/12" % [
		int(machine.slot_progress.get(1, 0)),
		int(machine.slot_progress.get(2, 0)),
		int(machine.slot_progress.get(3, 0)),
		int(machine.slot_progress.get(4, 0)),
	]
	queue_hint_label.text = "Queue 待部署条目：%d" % machine.queue.size()
	log_label.text = _recent_log_text(machine.event_log)

func get_visual_contract_summary() -> Dictionary:
	_ensure_nodes()
	return machine_board.get_visual_contract_summary()

func get_readable_log_text() -> String:
	_ensure_nodes()
	return log_label.text

func _recent_log_text(event_log: Array[String]) -> String:
	if event_log.is_empty():
		return "机器预热中：Forge 造球进入 Pool，Launcher 将球送入 Tuning，Unit 槽满后进入 Queue。"

	var lines := PackedStringArray()
	var start_index: int = maxi(0, event_log.size() - LOG_LINE_COUNT)
	for index: int in range(start_index, event_log.size()):
		lines.append(_localized_log_line(event_log[index]))
	return "\n".join(lines)

func _localized_log_line(log_line: String) -> String:
	if log_line.begins_with("Launch.Forge added"):
		return "Launch：Forge 加入 1 颗净球"
	if log_line.begins_with("Launch.Pool full rejected"):
		return "Launch：Pool 已满，回流球丢失"
	if log_line.begins_with("Launch.Waste"):
		return "Launch：球进入 Waste，未产生有效结算"
	if log_line.begins_with("Launch:"):
		return _localized_launch_line(log_line)
	if log_line.begins_with("Tuning:"):
		return _localized_tuning_line(log_line)
	if log_line.begins_with("Unit:QueueEntry"):
		return "Unit：槽满，%s进入 Queue" % _unit_name(_extract_unit_id(log_line))
	return "机器状态更新"

func _localized_launch_line(log_line: String) -> String:
	var result := log_line.get_slice(":", 1).get_slice(" ", 0)
	match result:
		"Tuning":
			return "Launch：球进入 Tuning"
		"Split":
			return "Launch：Split 分流，补入 Pool"
		"Recycle":
			return "Launch：回收，球返回 Pool"
		"Waste":
			return "Launch：球进入 Waste，未产生有效结算"
		_:
			return "Launch：球完成一次路线判定"

func _localized_tuning_line(log_line: String) -> String:
	var result := log_line.get_slice(":", 1).get_slice(" ", 0)
	var slot_label := _slot_label(_extract_debug_int(log_line, "slot=", 0))
	var value := _extract_debug_int(log_line, "value=", 0)
	match result:
		"Gate":
			return "Tuning：Gate 命中，%s 获得 %d 点进度" % [slot_label, value]
		"Prime":
			return "Tuning：Prime 命中，%s 获得 %d 点强化进度" % [slot_label, value]
		"Echo":
			return "Tuning：Echo 命中，%s 获得 %d 点进度并复制一次" % [slot_label, value]
		"Surge":
			return "Tuning：Surge 命中，%s 获得 %d 点冲刺进度" % [slot_label, value]
		_:
			return "Tuning：单位槽获得进度"

func _extract_debug_int(log_line: String, marker: String, fallback: int) -> int:
	var start := log_line.find(marker)
	if start == -1:
		return fallback
	start += marker.length()
	var end := start
	while end < log_line.length() and log_line.substr(end, 1).is_valid_int():
		end += 1
	if end == start:
		return fallback
	return int(log_line.substr(start, end - start))

func _slot_label(slot_id: int) -> String:
	if slot_id <= 0:
		return "Unit 槽"
	return "S%d" % slot_id

func _extract_unit_id(log_line: String) -> String:
	var marker := "\"unit_id\": \""
	var start := log_line.find(marker)
	if start == -1:
		return ""
	start += marker.length()
	var end := log_line.find("\"", start)
	if end == -1:
		return ""
	return log_line.substr(start, end - start)

func _unit_name(unit_id: String) -> String:
	match unit_id:
		"hive_short_fang":
			return "短牙"
		"hive_shield_shell":
			return "盾壳"
		"hive_acid_sac":
			return "酸囊"
		"hive_crush_shell_beast":
			return "碾壳兽"
		_:
			return "未知单位"

func _configure_machine_panel_layout() -> void:
	var redundant_readouts: Array[Control] = [
		forge_label,
		forge_bar,
		launcher_label,
		launcher_bar,
		pool_label,
		tuning_label,
		unit_label,
		queue_hint_label,
	]
	for readout: Control in redundant_readouts:
		readout.visible = false
	log_label.custom_minimum_size = Vector2(0.0, 64.0)
	log_label.size_flags_vertical = Control.SIZE_FILL

func _ensure_nodes() -> void:
	if machine_board == null:
		machine_board = get_node("MachineBoardView") as MachineBoardViewScript
	if forge_label == null:
		forge_label = get_node("ForgeLabel") as Label
	if forge_bar == null:
		forge_bar = get_node("ForgeProgressBar") as ProgressBar
	if launcher_label == null:
		launcher_label = get_node("LauncherLabel") as Label
	if launcher_bar == null:
		launcher_bar = get_node("LauncherProgressBar") as ProgressBar
	if pool_label == null:
		pool_label = get_node("PoolLabel") as Label
	if tuning_label == null:
		tuning_label = get_node("TuningLabel") as Label
	if unit_label == null:
		unit_label = get_node("UnitLabel") as Label
	if queue_hint_label == null:
		queue_hint_label = get_node("QueueHintLabel") as Label
	if log_label == null:
		log_label = get_node("MachineLogLabel") as Label
