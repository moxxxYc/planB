extends Control

const BattleSequence = preload("res://scripts/systems/battle_sequence.gd")
const MachineSimulator = preload("res://scripts/systems/machine_simulator.gd")
const CounterController = preload("res://scripts/systems/counter_controller.gd")
const OverdriveController = preload("res://scripts/systems/overdrive_controller.gd")
const ResultScreenScene = preload("res://scenes/ui/result_screen.tscn")
const PresetDefs = preload("res://scripts/model/preset_defs.gd")

var _sequence = BattleSequence.new()
var _machine_simulator = MachineSimulator.new()
var _counter_controller = CounterController.new()
var _overdrive_controller = OverdriveController.new()
var _runtime_started := false
var _scheduled_events: Array = []
var _manual_events: Array = []
var _active_events: Array = []
var _elapsed_events: Array = []
var _result_screen: Control
var _result_screen_started := false
var _overdrive_button: Button
var _last_overdrive_click_time := -999.0
var _overdrive_response_until := -999.0
var _overdrive_response_axis := ""

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

func start_preset_for_test(preset_id: String) -> void:
	_sequence = BattleSequence.new()
	_sequence.start_fixed_order([preset_id])
	_runtime_started = true
	_result_screen_started = false
	_manual_events = []
	_last_overdrive_click_time = -999.0
	_overdrive_response_until = -999.0
	_overdrive_response_axis = ""
	if _result_screen != null:
		_result_screen.visible = false
	_rebuild_scheduled_events()
	_refresh_runtime_state()

func press_overdrive_for_test() -> void:
	_activate_overdrive_from_button()

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

func get_overdrive_ui_snapshot() -> Dictionary:
	_ensure_runtime_started()
	_ensure_overdrive_button()
	var definition := _current_overdrive_definition()
	var current_time := _sequence.current_time_seconds()
	return {
		"button_present": _overdrive_button != null,
		"axis_id": definition.get("axis_id", ""),
		"anchor_lane": _lane_name_for_axis(definition.get("axis_id", "")),
		"button_parent": _overdrive_button.get_parent().name if _overdrive_button != null and _overdrive_button.get_parent() != null else "",
		"label": _overdrive_button.text if _overdrive_button != null else "",
		"target_component": definition.get("component_id", ""),
		"is_global_rescue": false,
		"visual_response_active": current_time <= _overdrive_response_until,
		"visual_response_age_seconds": current_time - _last_overdrive_click_time,
		"visual_response_axis": _overdrive_response_axis,
	}

func get_result_layout_snapshot() -> Dictionary:
	_ensure_runtime_started()
	if _result_screen != null and _result_screen.has_method("get_layout_snapshot"):
		return _result_screen.call("get_layout_snapshot")
	return {}

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
		_ensure_overdrive_button()
		return
	_ensure_result_screen()
	_sequence.start_internal_order()
	_runtime_started = true
	_rebuild_scheduled_events()
	_ensure_overdrive_button()
	_refresh_runtime_state()

func _rebuild_scheduled_events() -> void:
	var preset_id := _sequence.current_preset_id()
	_scheduled_events = []
	_scheduled_events.append_array(_machine_simulator.build_events(preset_id))
	var preset_counter := _counter_for_preset(preset_id)
	_scheduled_events.append_array(_counter_controller.build_counter_events(preset_counter))
	_scheduled_events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("time", 0.0)) < float(b.get("time", 0.0)))

func _refresh_runtime_state() -> void:
	var time_seconds := _sequence.current_time_seconds()
	_elapsed_events = []
	_active_events = []
	var all_events := _scheduled_events.duplicate(true)
	all_events.append_array(_manual_events)
	all_events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("time", 0.0)) < float(b.get("time", 0.0)))
	for event in all_events:
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
	_update_overdrive_button()
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

func _ensure_overdrive_button() -> void:
	if _overdrive_button == null:
		_overdrive_button = find_child("OverdriveButton", true, false)
	if _overdrive_button == null:
		return
	if not _overdrive_button.pressed.is_connected(_on_overdrive_button_pressed):
		_overdrive_button.pressed.connect(_on_overdrive_button_pressed)
	_update_overdrive_button()

func _update_overdrive_button() -> void:
	if _overdrive_button == null:
		return
	var definition := _current_overdrive_definition()
	var axis_id := String(definition.get("axis_id", ""))
	var lane = find_child(_lane_name_for_axis(axis_id), true, false)
	if lane != null and _overdrive_button.get_parent() != lane:
		_overdrive_button.owner = null
		var old_parent := _overdrive_button.get_parent()
		if old_parent != null:
			old_parent.remove_child(_overdrive_button)
		lane.add_child(_overdrive_button)
	_overdrive_button.text = String(definition.get("overdrive_label", "Axis Overdrive"))
	_overdrive_button.tooltip_text = "Amplifies %s component: %s" % [axis_id, definition.get("component_id", "")]
	_overdrive_button.disabled = false
	_overdrive_button.position = Vector2(18, 434)
	_overdrive_button.size = Vector2(196, 42)
	var responding := _sequence.current_time_seconds() <= _overdrive_response_until
	_overdrive_button.modulate = Color(1.0, 0.94, 0.42) if responding else Color(1.0, 1.0, 1.0)
	_overdrive_button.scale = Vector2(1.04, 1.04) if responding else Vector2.ONE

func _on_overdrive_button_pressed() -> void:
	_activate_overdrive_from_button()

func _activate_overdrive_from_button() -> void:
	_ensure_runtime_started()
	var event := _build_overdrive_event(_sequence.current_preset_id(), _sequence.current_time_seconds())
	if event.is_empty():
		return
	event["input_source"] = "axis_button"
	_manual_events.append(event)
	_last_overdrive_click_time = _sequence.current_time_seconds()
	_overdrive_response_until = _last_overdrive_click_time + 0.75
	_overdrive_response_axis = event.get("axis_id", "")
	_refresh_runtime_state()

func _current_overdrive_definition() -> Dictionary:
	return _build_overdrive_event(_sequence.current_preset_id(), _sequence.current_time_seconds())

func _build_overdrive_event(preset_id: String, time_seconds: float) -> Dictionary:
	var axis_state := _overdrive_axis_state(preset_id)
	if axis_state.is_empty():
		return {}
	var event := _overdrive_controller.activate(preset_id, axis_state)
	event["time"] = time_seconds
	return event

func _overdrive_axis_state(preset_id: String) -> Dictionary:
	match preset_id:
		PresetDefs.LAUNCH_FLOOD:
			return {"return_balls": true}
		PresetDefs.TUNING_ECHO:
			return {"echo_window": true}
		PresetDefs.UNIT_QUEUE_BURST:
			return {"squad_chain": true}
		_:
			return {}

func _lane_name_for_axis(axis_id: String) -> String:
	match axis_id:
		"launch":
			return "LaunchLane"
		"tuning":
			return "TuningLane"
		"unit":
			return "UnitLane"
		_:
			return ""
