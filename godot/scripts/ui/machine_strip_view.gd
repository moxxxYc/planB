class_name MachineStripView
extends VBoxContainer

signal landing_resolved(result: MachinePhysicsResult)

const MachineBoardViewScript := preload("res://scripts/ui/machine_board_view.gd")

const FORGE_CYCLE_SECONDS: float = 2.2
const LAUNCHER_CYCLE_SECONDS: float = 1.3
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
	_connect_machine_board()
	add_theme_constant_override("separation", 8)
	_configure_machine_panel_layout()
	log_label.add_theme_color_override("font_color", Color("#c8c0ad"))

func render(machine, counter_target_component: String = "") -> void:
	_ensure_nodes()
	var forge_ratio: float = clampf(machine.forge_progress / FORGE_CYCLE_SECONDS, 0.0, 1.0)
	var launcher_ratio: float = clampf(machine.launcher_progress / LAUNCHER_CYCLE_SECONDS, 0.0, 1.0)

	machine_board.render(machine, counter_target_component)
	var pool_capacity: int = _machine_pool_capacity(machine)
	forge_bar.value = forge_ratio * 100.0
	launcher_bar.value = launcher_ratio * 100.0
	forge_label.text = "Forge 造球 %.0f%% -> Pool" % (forge_ratio * 100.0)
	launcher_label.text = "Launcher 发射 %.0f%% -> Tuning" % (launcher_ratio * 100.0)
	pool_label.text = "Pool 球池 %d / %d 颗净球" % [machine.pool.size(), pool_capacity]
	tuning_label.text = "Tuning 槽：Gate / Prime / Echo / Surge"
	unit_label.text = "Unit 槽：S1 %d/3 | S2 %d/5 | S3 %d/8 | S4 %d/12" % [
		int(machine.slot_progress.get(1, 0)),
		int(machine.slot_progress.get(2, 0)),
		int(machine.slot_progress.get(3, 0)),
		int(machine.slot_progress.get(4, 0)),
	]
	queue_hint_label.text = "Queue 待部署条目：%d" % machine.queue.size()
	var counter_log: Array[String] = []
	var counter_log_value: Variant = machine.get("counter_log")
	if counter_log_value is Array:
		for line_variant: Variant in counter_log_value:
			counter_log.append(String(line_variant))
	log_label.text = _recent_log_text(machine.event_log, counter_log)

func get_visual_contract_summary() -> Dictionary:
	_ensure_nodes()
	return machine_board.get_visual_contract_summary()

func launch_ball(ball: Dictionary, battle_elapsed: float) -> void:
	_ensure_nodes()
	machine_board.launch_ball(ball, battle_elapsed)

func set_exposure_state(exposure_state) -> void:
	_ensure_nodes()
	machine_board.set_exposure_state(exposure_state)

func emit_seeded_landing_for_verifier(result: MachinePhysicsResult) -> MachinePhysicsResult:
	_ensure_nodes()
	return machine_board.emit_seeded_landing_for_verifier(result)

func run_seeded_chain_for_verifier(results: Array[MachinePhysicsResult]) -> void:
	_ensure_nodes()
	machine_board.run_seeded_chain_for_verifier(results)

func get_runtime_contract() -> Dictionary:
	_ensure_nodes()
	return machine_board.get_runtime_contract()

func get_readable_log_text() -> String:
	_ensure_nodes()
	return log_label.text

func _machine_pool_capacity(machine) -> int:
	if machine.has_method("get_pool_capacity"):
		return maxi(1, int(machine.call("get_pool_capacity")))

	var capacity_value: Variant = machine.get("pool_capacity")
	if capacity_value != null:
		return maxi(1, int(capacity_value))
	return 5

func _recent_log_text(event_log: Array[String], counter_log: Array[String] = []) -> String:
	if event_log.is_empty():
		return "机器预热中：Forge 造球进入 Pool，Launcher 将球送入 Tuning，Unit 槽满后进入 Queue。"

	var lines := PackedStringArray()
	var counter_start: int = maxi(0, counter_log.size() - 2)
	for index: int in range(counter_start, counter_log.size()):
		lines.append(_localized_log_line(counter_log[index]))
	var start_index: int = maxi(0, event_log.size() - LOG_LINE_COUNT)
	for index: int in range(start_index, event_log.size()):
		var localized_line: String = _localized_log_line(event_log[index])
		if not lines.has(localized_line):
			lines.append(localized_line)
		if lines.size() >= LOG_LINE_COUNT:
			break
	return "\n".join(lines)

func _localized_log_line(log_line: String) -> String:
	if log_line.contains("Pool Polluter Junk 插入"):
		return "反制：Pool 污染者将 Junk 插入 Pool"
	if log_line.contains("Pool Polluter 上限已满"):
		return "反制：Pool 污染者已到插入上限"
	if log_line.contains("Pool Polluter 因 Pool 已满"):
		return "反制：Pool 已满，Pool 污染者未插入 Junk"
	if log_line.contains("Junk Sieve 过滤 Junk"):
		return "补洞：废球筛过滤 Junk，Pool 污染被清理"
	if log_line.contains("Junk Sieve 过滤 Pool 头部 Junk"):
		return "补洞：废球筛过滤 Pool 头部 Junk"
	if log_line.contains("Junk 发射后无有效 Unit"):
		return "反制：Junk 发射，未产生有效 Unit 结算"
	if log_line.contains("Echo Breaker Echo 复制降级"):
		return "反制：Echo 破坏者让 Echo 复制降级为 Gate"
	if log_line.contains("Echo Breaker 已锁定 Echo 槽"):
		return "反制：Echo 破坏者锁定 Echo 槽"
	if log_line.contains("Echo Breaker 活跃期结束"):
		return "反制：Echo 破坏者活跃结束，未触发"
	if log_line.contains("Surge Buffer stored"):
		return "补洞：Surge 缓冲储存 1 次同槽加速"
	if log_line.contains("Surge Buffer") and log_line.contains("charge consumed"):
		return "补洞：Surge 缓冲被同槽 Queue 条目消耗"
	if log_line.contains("Queue Brace"):
		return "补洞：Queue 支撑补强最低进度槽"
	if log_line.contains("Muster Pair 同槽成对"):
		return "Unit：成对集结让同槽成对出兵"
	if log_line.contains("Echo Latch ghost hit"):
		return "Tuning：Echo 锁存显示幽影命中"
	if log_line.contains("Front Recycle returned"):
		return "Launch：前置回流把净球放回 Pool 前段"
	if log_line.contains("Front Recycle front recycle rejected"):
		return "Launch：Pool 已满，前置回流未能放回净球"
	if log_line.begins_with("物理落点"):
		return log_line
	if log_line.begins_with("Unit："):
		return log_line
	if log_line.begins_with("Launch.Forge added"):
		return "Launch：Forge 加入 1 颗净球"
	if log_line.begins_with("Launch.Launcher fired"):
		return "Launch：Launcher 将 Pool 头球送入可见物理板"
	if log_line.begins_with("Launch.Pool full rejected"):
		return "Launch：Pool 已满，回流球丢失"
	if log_line.begins_with("Launch.Waste"):
		return "Launch：球进入废弃口，未产生有效结算"
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
			return "Launch：分流，补入 Pool"
		"Recycle":
			return "Launch：回收，球返回 Pool"
		"Waste":
			return "Launch：球进入废弃口，未产生有效结算"
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
			return "短牙虫"
		"hive_shield_shell":
			return "盾壳虫"
		"hive_acid_sac":
			return "酸囊虫"
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
	_connect_machine_board()

func _connect_machine_board() -> void:
	if machine_board == null:
		return
	if not machine_board.landing_resolved.is_connected(_on_machine_board_landing_resolved):
		machine_board.landing_resolved.connect(_on_machine_board_landing_resolved)

func _on_machine_board_landing_resolved(result: MachinePhysicsResult) -> void:
	landing_resolved.emit(result)
