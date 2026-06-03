extends Control

const BattleSequence = preload("res://scripts/systems/battle_sequence.gd")
const MachineSimulator = preload("res://scripts/systems/machine_simulator.gd")
const CounterController = preload("res://scripts/systems/counter_controller.gd")
const OverdriveController = preload("res://scripts/systems/overdrive_controller.gd")
const ResultScreenScene = preload("res://scenes/ui/result_screen.tscn")

var _sequence = BattleSequence.new()
var _machine_simulator = MachineSimulator.new()
var _counter_controller = CounterController.new()
var _overdrive_controller = OverdriveController.new()
var _runtime_started := false
var _scheduled_events: Array = []
var _active_events: Array = []
var _elapsed_events: Array = []
var _result_screen: Control
var _result_screen_started := false

func _ready() -> void:
	if has_node("CausalChain"):
		$CausalChain.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ensure_runtime_started()
	set_process(true)

func _process(delta: float) -> void:
	_ensure_runtime_started()
	if _sequence.state == BattleSequence.STATE_BATTLE_RUNNING:
		_sequence.tick(delta)
	_refresh_runtime_state()

func axis_order() -> Array[String]:
	return ["launch", "tuning", "unit"]

func debug_label_is_primary() -> bool:
	return false

func advance_for_test(delta: float) -> void:
	_process(delta)

func get_motion_snapshot() -> Dictionary:
	_ensure_runtime_started()
	var launch = find_child("LaunchLane", true, false)
	var frontline = find_child("FrontlineView", true, false)
	var counter_event := _active_counter_event()
	var overdrive_event := _active_overdrive_event()
	return {
		"preset_id": _sequence.current_preset_id(),
		"time_seconds": _sequence.current_time_seconds(),
		"active_event_count": _active_events.size(),
		"elapsed_event_count": _elapsed_events.size(),
		"active_counter_state": counter_event.get("counter_state", ""),
		"active_counter_target": counter_event.get("target_component", ""),
		"overdrive_axis": overdrive_event.get("axis_id", ""),
		"overdrive_component": overdrive_event.get("component_id", ""),
		"launch_snapshot": launch.call("get_motion_snapshot") if launch != null and launch.has_method("get_motion_snapshot") else {},
		"frontline_snapshot": frontline.call("get_motion_snapshot") if frontline != null and frontline.has_method("get_motion_snapshot") else {},
	}

func result_screen_is_visible() -> bool:
	_ensure_runtime_started()
	return _result_screen != null and _result_screen.visible

func result_screen_question_count() -> int:
	_ensure_runtime_started()
	if _result_screen == null or not _result_screen.has_method("question_count"):
		return 0
	return _result_screen.call("question_count")

func result_screen_confidence_count() -> int:
	_ensure_runtime_started()
	if _result_screen == null or not _result_screen.has_method("confidence_count"):
		return 0
	return _result_screen.call("confidence_count")

func _ensure_runtime_started() -> void:
	if _runtime_started:
		return
	_ensure_result_screen()
	_sequence.start_internal_order()
	_runtime_started = true
	_rebuild_scheduled_events()
	_refresh_runtime_state()

func _rebuild_scheduled_events() -> void:
	var preset_id := _sequence.current_preset_id()
	_scheduled_events = []
	_scheduled_events.append_array(_machine_simulator.build_events(preset_id))
	var preset_counter := _counter_for_preset(preset_id)
	_scheduled_events.append_array(_counter_controller.build_counter_events(preset_counter))
	var overdrive_event := _overdrive_for_preset(preset_id)
	if not overdrive_event.is_empty():
		_scheduled_events.append(overdrive_event)
	_scheduled_events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("time", 0.0)) < float(b.get("time", 0.0)))

func _refresh_runtime_state() -> void:
	var time_seconds := _sequence.current_time_seconds()
	_elapsed_events = []
	_active_events = []
	for event in _scheduled_events:
		var event_time := float(event.get("time", 0.0))
		if event_time <= time_seconds:
			_elapsed_events.append(event)
		if event_time <= time_seconds and event_time >= time_seconds - 3.0:
			_active_events.append(event)

	var runtime_state := {
		"preset_id": _sequence.current_preset_id(),
		"time_seconds": time_seconds,
		"active_events": _active_events,
		"elapsed_events": _elapsed_events,
	}
	for view_name in ["LaunchLane", "TuningLane", "UnitLane", "FrontlineView"]:
		var view = find_child(view_name, true, false)
		if view != null and view.has_method("set_runtime_state"):
			view.call("set_runtime_state", runtime_state)
	_maybe_show_result_screen()

func _ensure_result_screen() -> void:
	if _result_screen != null:
		return
	_result_screen = ResultScreenScene.instantiate()
	_result_screen.name = "ResultScreen"
	_result_screen.visible = false
	add_child(_result_screen)

func _maybe_show_result_screen() -> void:
	if _result_screen_started:
		return
	if _sequence.state != BattleSequence.STATE_RESULT_PENDING:
		return
	_ensure_result_screen()
	_result_screen_started = true
	if _result_screen.has_method("begin_result"):
		_result_screen.call("begin_result", _sequence.current_preset_id(), 1, _elapsed_events)

func _active_counter_event() -> Dictionary:
	for event in _active_events:
		if String(event.get("event_type", "")).begins_with("counter"):
			return event
	return {}

func _active_overdrive_event() -> Dictionary:
	for event in _active_events:
		if event.get("event_type") == "overdrive_activation":
			return event
	return {}

func _counter_for_preset(preset_id: String) -> String:
	match preset_id:
		"launch_flood":
			return "pool_polluter"
		"tuning_echo":
			return "echo_breaker"
		"unit_queue_burst":
			return "stagger_punisher"
		_:
			return ""

func _overdrive_for_preset(preset_id: String) -> Dictionary:
	var axis_state := {}
	match preset_id:
		"launch_flood":
			axis_state = {"return_balls": true}
		"tuning_echo":
			axis_state = {"echo_window": true}
		"unit_queue_burst":
			axis_state = {"squad_chain": true}
		_:
			return {}
	var event := _overdrive_controller.activate(preset_id, axis_state)
	event["time"] = 45.0
	return event
