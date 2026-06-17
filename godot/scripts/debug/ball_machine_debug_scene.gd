class_name BallMachineDebugScene
extends Control

const MachineBoardViewScript := preload("res://scripts/ui/machine_board_view.gd")
const MachineBallPayloadScript := preload("res://scripts/model/machine/machine_ball_payload.gd")
const MachineSlotExposureStateScript := preload("res://scripts/model/machine/machine_slot_exposure_state.gd")

const DEFAULT_TIME_SCALE: float = 1.0
const FAST_TIME_SCALE: float = 4.0
const MAX_LOG_LINES: int = 12

@onready var machine_view: MachineBoardViewScript = %MachineBoardView
@onready var status_label: Label = %StatusLabel
@onready var control_rows: VBoxContainer = %ControlRows
@onready var log_label: Label = %LogLabel
@onready var contract_label: Label = %ContractLabel

var machine: MachineSimulator = MachineSimulator.new()
var exposure_state: RefCounted = MachineSlotExposureStateScript.new()
var elapsed: float = 0.0
var running: bool = true
var time_scale: float = DEFAULT_TIME_SCALE
var _manual_chain_index: int = 0
var _run_button: Button = null
var _speed_button: Button = null

func _ready() -> void:
	_ensure_nodes()
	_build_controls()
	_connect_machine_view()
	_sync_machine_runtime()
	set_physics_process(true)
	_render()

func _physics_process(delta: float) -> void:
	if not running:
		return
	advance_debug(delta * time_scale)

func advance_debug(delta: float) -> void:
	_ensure_nodes()
	_connect_machine_view()
	elapsed += maxf(0.0, delta)
	_sync_machine_runtime()
	var launch_requests: Array[Dictionary] = machine.advance_supply(delta)
	for launch_request: Dictionary in launch_requests:
		if machine_view != null:
			machine_view.launch_ball(launch_request, elapsed)
	_render()

func manual_launch_clean_for_verifier() -> void:
	_manual_launch(false)

func manual_launch_junk_for_verifier() -> void:
	_manual_launch(true)

func apply_modifier_for_debug(modifier_id: String, payload: Dictionary = {}) -> void:
	_ensure_nodes()
	machine.apply_modifier(modifier_id, payload)
	_render()

func get_debug_contract() -> Dictionary:
	_ensure_nodes()
	_build_controls()
	_connect_machine_view()
	var machine_contract: Dictionary = machine_view.get_visual_contract_summary() if machine_view != null else {}
	return {
		"scene_scope": "ball_machine_only",
		"has_machine_board": machine_view != null,
		"has_battlefield": false,
		"has_queue_bridge": false,
		"manual_launch_available": has_method("manual_launch_clean_for_verifier"),
		"advance_available": has_method("advance_debug"),
		"control_button_count": _debug_button_count(),
		"machine_contract": machine_contract,
		"launcher_turret_visual_source_count": int(machine_contract.get("launcher_turret_visual_source_count", 0)),
		"schematic_slot_width_ratios": machine_contract.get("schematic_slot_width_ratios", {}),
		"elapsed": elapsed,
		"pool_count": machine.pool.size(),
		"queue_count": machine.queue.size(),
	}

func _build_controls() -> void:
	_ensure_nodes()
	if control_rows == null or control_rows.get_child_count() > 0:
		return
	_run_button = _add_button("暂停", _toggle_running)
	_speed_button = _add_button("速度 x1", _toggle_speed)
	_add_button("步进 0.25s", func() -> void: _step_seconds(0.25))
	_add_button("步进 1s", func() -> void: _step_seconds(1.0))
	_add_button("步进 5s", func() -> void: _step_seconds(5.0))
	_add_separator()
	_add_button("Pool +1 净球", _add_clean_to_pool)
	_add_button("Pool 插入 Junk", _insert_junk_to_pool)
	_add_button("立即发净球", func() -> void: _manual_launch(false))
	_add_button("立即发 Junk", func() -> void: _manual_launch(true))
	_add_button("排出 Queue 队首", _pop_queue_head)
	_add_separator()
	_add_button("Pool 扩容袋", func() -> void: apply_modifier_for_debug("pool_pocket"))
	_add_button("Prime 充能", func() -> void: apply_modifier_for_debug("prime_charge"))
	_add_button("Slot Primer S1", func() -> void: apply_modifier_for_debug("slot_primer", {"slot_id": 1}))
	_add_button("Slot Primer S2", func() -> void: apply_modifier_for_debug("slot_primer", {"slot_id": 2}))
	_add_button("Slot Primer S3", func() -> void: apply_modifier_for_debug("slot_primer", {"slot_id": 3}))
	_add_button("Slot Primer S4", func() -> void: apply_modifier_for_debug("slot_primer", {"slot_id": 4}))
	_add_button("前置回流", func() -> void: apply_modifier_for_debug("front_recycle"))
	_add_button("Surge 缓冲", func() -> void: apply_modifier_for_debug("surge_buffer"))
	_add_button("Queue 支撑", func() -> void: apply_modifier_for_debug("queue_brace"))
	_add_button("废球筛", func() -> void: apply_modifier_for_debug("junk_sieve"))
	_add_button("成对集结", func() -> void: apply_modifier_for_debug("muster_pair"))
	_add_button("Echo 锁存", func() -> void: apply_modifier_for_debug("echo_latch"))
	_add_separator()
	_add_button("武装 Echo Breaker", _arm_echo_breaker)
	_add_button("解除 Echo Breaker", _disarm_echo_breaker)
	_add_button("清空日志", _clear_logs)
	_add_button("重置场景", _reload_scene)

func _add_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	if control_rows != null:
		control_rows.add_child(button)
	return button

func _add_separator() -> void:
	var separator := HSeparator.new()
	if control_rows != null:
		control_rows.add_child(separator)

func _connect_machine_view() -> void:
	_ensure_nodes()
	if machine_view == null:
		return
	if not machine_view.landing_resolved.is_connected(_on_machine_landing_resolved):
		machine_view.landing_resolved.connect(_on_machine_landing_resolved)
	machine_view.set_redirect_resolver(Callable(self, "_resolve_machine_redirect"))

func _sync_machine_runtime() -> void:
	_ensure_nodes()
	machine.set_exposure_state(exposure_state)
	machine.set_battle_elapsed(elapsed)
	if machine_view != null:
		machine_view.set_exposure_state(exposure_state)
		machine_view.set_battle_elapsed(elapsed)

func _on_machine_landing_resolved(result: MachinePhysicsResult) -> void:
	if result == null:
		return
	machine.set_battle_elapsed(maxf(elapsed, result.battle_elapsed))
	machine.apply_physics_result(result)
	_render()

func _resolve_machine_redirect(natural_result_id: String) -> Dictionary:
	return machine.redirect_tuning_result_if_needed(natural_result_id)

func _toggle_running() -> void:
	_ensure_nodes()
	running = not running
	if _run_button != null:
		_run_button.text = "暂停" if running else "继续"
	_render()

func _toggle_speed() -> void:
	_ensure_nodes()
	time_scale = FAST_TIME_SCALE if is_equal_approx(time_scale, DEFAULT_TIME_SCALE) else DEFAULT_TIME_SCALE
	if _speed_button != null:
		_speed_button.text = "速度 x%d" % int(time_scale)
	_render()

func _step_seconds(seconds: float) -> void:
	_ensure_nodes()
	var was_running: bool = running
	running = false
	advance_debug(seconds)
	running = was_running
	if _run_button != null:
		_run_button.text = "暂停" if running else "继续"

func _add_clean_to_pool() -> void:
	_ensure_nodes()
	machine.add_guardian_clean_pool_ball()
	_render()

func _insert_junk_to_pool() -> void:
	_ensure_nodes()
	machine.apply_pool_polluter_junk()
	_render()

func _manual_launch(is_junk: bool) -> void:
	_ensure_nodes()
	_connect_machine_view()
	_manual_chain_index += 1
	var chain_id: String = "debug_manual_%03d" % _manual_chain_index
	var payload: Dictionary = MachineBallPayloadScript.junk(chain_id, "Debug Manual") if is_junk else MachineBallPayloadScript.clean(chain_id, _manual_chain_index)
	machine.event_log.append("Debug:manual_launch %s chain=%s" % [String(payload.get("kind", "clean")), chain_id])
	if machine_view != null:
		machine_view.launch_ball(payload, elapsed)
	_render()

func _pop_queue_head() -> void:
	_ensure_nodes()
	if machine.queue.is_empty():
		machine.event_log.append("Debug:Queue empty")
	else:
		var entry: Dictionary = machine.pop_queue_entry()
		machine.record_queue_deployed()
		machine.event_log.append("Debug:Queue pop %s S%d" % [
			String(entry.get("unit_id", "unknown")),
			int(entry.get("slot_id", 0)),
		])
	_render()

func _arm_echo_breaker() -> void:
	_ensure_nodes()
	machine.arm_echo_breaker()
	_render()

func _disarm_echo_breaker() -> void:
	_ensure_nodes()
	machine.disarm_echo_breaker()
	_render()

func _clear_logs() -> void:
	_ensure_nodes()
	machine.event_log.clear()
	machine.counter_log.clear()
	_render()

func _reload_scene() -> void:
	get_tree().reload_current_scene()

func _render() -> void:
	_ensure_nodes()
	_sync_machine_runtime()
	if machine_view != null:
		machine_view.render(machine)
	if status_label != null:
		status_label.text = "t=%.2fs | %s | Pool %d/%d | Queue %d | Speed x%d | %s" % [
			elapsed,
			"运行" if running else "暂停",
			machine.pool.size(),
			machine.get_pool_capacity(),
			machine.queue.size(),
			int(time_scale),
			machine.get_modifier_marker_text(),
		]
	if log_label != null:
		log_label.text = _recent_log_text()
	if contract_label != null:
		contract_label.text = _contract_text()

func _recent_log_text() -> String:
	var lines := PackedStringArray()
	var combined: Array[String] = []
	for line: String in machine.counter_log:
		combined.append(line)
	for line: String in machine.event_log:
		combined.append(line)
	var start: int = maxi(0, combined.size() - MAX_LOG_LINES)
	for index: int in range(start, combined.size()):
		lines.append(combined[index])
	if lines.is_empty():
		return "暂无机器事件。"
	return "\n".join(lines)

func _contract_text() -> String:
	var contract: Dictionary = machine_view.get_visual_contract_summary() if machine_view != null else {}
	var launcher: Dictionary = contract.get("launcher_turret", {}) as Dictionary
	var widths: Dictionary = contract.get("schematic_slot_width_ratios", {}) as Dictionary
	return "炮台源：%s x%d\n炮台：visible=%s angle=%.0fdeg range=%.0f/%.0fdeg\nlaunch=%s\nvisual=%s match=%s\nball=%s at_muzzle=%s\nLaunch宽度：%s\nTuning宽度：%s\n最近物理：%s" % [
		String(contract.get("launcher_turret_visual_source", "")),
		int(contract.get("launcher_turret_visual_source_count", 0)),
		str(bool(launcher.get("visible", false))),
		rad_to_deg(float(launcher.get("current_angle", 0.0))),
		rad_to_deg(float(launcher.get("swing_angle_min", 0.0))),
		rad_to_deg(float(launcher.get("swing_angle_max", 0.0))),
		str(launcher.get("muzzle_position", Vector2.ZERO)),
		str(launcher.get("visual_muzzle_position", Vector2.ZERO)),
		str(bool(launcher.get("muzzle_matches_visual", false))),
		str(contract.get("active_ball_position", Vector2.ZERO)),
		str(bool(contract.get("active_ball_at_visible_muzzle", false))),
		str(widths.get("Launch", {})),
		str(widths.get("Tuning", {})),
		str(contract.get("last_physics_result", {})),
	]

func _debug_button_count() -> int:
	_ensure_nodes()
	if control_rows == null:
		return 0
	var count: int = 0
	for child: Node in control_rows.get_children():
		if child is Button:
			count += 1
	return count

func _ensure_nodes() -> void:
	if machine_view == null:
		machine_view = get_node_or_null("%MachineBoardView") as MachineBoardViewScript
		if machine_view == null:
			machine_view = find_child("MachineBoardView", true, false) as MachineBoardViewScript
	if status_label == null:
		status_label = get_node_or_null("%StatusLabel") as Label
		if status_label == null:
			status_label = find_child("StatusLabel", true, false) as Label
	if control_rows == null:
		control_rows = get_node_or_null("%ControlRows") as VBoxContainer
		if control_rows == null:
			control_rows = find_child("ControlRows", true, false) as VBoxContainer
	if log_label == null:
		log_label = get_node_or_null("%LogLabel") as Label
		if log_label == null:
			log_label = find_child("LogLabel", true, false) as Label
	if contract_label == null:
		contract_label = get_node_or_null("%ContractLabel") as Label
		if contract_label == null:
			contract_label = find_child("ContractLabel", true, false) as Label
