class_name MachineCausalityDebug
extends Control

const ModelScript := preload("res://scripts/ball_machine/machine_causality_model.gd")
const ViewScript := preload("res://scripts/ball_machine/machine_causality_view.gd")

var _model: RefCounted = ModelScript.new()
var _view: Control
var _supply_label: Label
var _time_label: Label
var _tuning_label: Label
var _slot_list: VBoxContainer
var _queue_list: VBoxContainer
var _log_list: VBoxContainer
var _built := false


func _ready() -> void:
	_ensure_built()


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
	_model.force_unit_slot_queue(1, "Gate")
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
	panel.custom_minimum_size = Vector2(430, 0)
	root.add_child(panel)

	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 10)
	panel.add_child(side)

	side.add_child(_make_label("M1 Machine Causality", 22))
	_supply_label = _make_label("", 14)
	side.add_child(_supply_label)
	_time_label = _make_label("", 14)
	side.add_child(_time_label)
	_tuning_label = _make_label("", 14)
	side.add_child(_tuning_label)

	side.add_child(_make_separator())
	side.add_child(_make_label("Battle Time", 15))
	var time_row := HBoxContainer.new()
	time_row.add_theme_constant_override("separation", 6)
	side.add_child(time_row)
	for seconds in [0, 24, 54, 96]:
		_add_button(time_row, "%ds" % seconds, Callable(self, "_on_time_pressed").bind(seconds))

	side.add_child(_make_label("Tuning Result", 15))
	var tuning_row := GridContainer.new()
	tuning_row.columns = 4
	tuning_row.add_theme_constant_override("h_separation", 6)
	side.add_child(tuning_row)
	for tuning_result in _model.TUNING_RESULTS:
		_add_button(
			tuning_row,
			tuning_result,
			Callable(self, "_on_tuning_pressed").bind(tuning_result)
		)

	side.add_child(_make_label("Unit Slot Hit", 15))
	var slot_row := GridContainer.new()
	slot_row.columns = 4
	slot_row.add_theme_constant_override("h_separation", 6)
	side.add_child(slot_row)
	for slot_id in [1, 2, 3, 4]:
		_add_button(slot_row, "Slot %d" % slot_id, Callable(self, "_on_slot_pressed").bind(slot_id))

	side.add_child(_make_label("Physical State", 15))
	var state_row := GridContainer.new()
	state_row.columns = 2
	state_row.add_theme_constant_override("h_separation", 6)
	state_row.add_theme_constant_override("v_separation", 6)
	side.add_child(state_row)
	_add_button(state_row, "Blocked Bounce", Callable(self, "_on_blocked_pressed"))
	_add_button(state_row, "Split Return", Callable(self, "_on_state_pressed").bind("Split Return"))
	_add_button(state_row, "Recycle Return", Callable(self, "_on_state_pressed").bind("Recycle Return"))
	_add_button(state_row, "Waste", Callable(self, "_on_state_pressed").bind("Waste"))
	_add_button(state_row, "Logic Settlement", Callable(self, "_on_state_pressed").bind("Logic Settlement"))
	_add_button(state_row, "Reset", Callable(self, "_on_reset_pressed"))

	side.add_child(_make_separator())
	side.add_child(_make_label("Unit Progress", 15))
	_slot_list = VBoxContainer.new()
	_slot_list.add_theme_constant_override("separation", 3)
	side.add_child(_slot_list)

	side.add_child(_make_label("Queue", 15))
	_queue_list = VBoxContainer.new()
	_queue_list.add_theme_constant_override("separation", 3)
	side.add_child(_queue_list)

	side.add_child(_make_label("Event Log", 15))
	_log_list = VBoxContainer.new()
	_log_list.add_theme_constant_override("separation", 3)
	side.add_child(_log_list)


func _refresh() -> void:
	_view.set_model(_model)

	var supply: Dictionary = _model.get_supply_summary()
	_supply_label.text = "Forge / Pool / Launcher: Pool %d / %d, Launcher active" % [
		supply["pool_count"],
		supply["pool_capacity"],
	]
	_time_label.text = "Battle time: %.0fs" % _model.battle_time_seconds
	_tuning_label.text = "Current Tuning: %s" % _model.selected_tuning_result

	_clear_container(_slot_list)
	for slot in _model.get_unit_slots():
		var accepting := "open" if slot["accepting_hit"] else "blocked"
		_slot_list.add_child(_make_label(
			"S%d %d / %d, exposure %.0f%%, %s" % [
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
		_queue_list.add_child(_make_label("empty", 12))
	else:
		var queue_start: int = max(0, _model.queue_entries.size() - 4)
		var recent_entries: Array = _model.queue_entries.slice(queue_start)
		for entry in recent_entries:
			_queue_list.add_child(_make_label(
				"%s | source S%d | %s | %s" % [
					entry["queue_entry_id"],
					entry["source_slot_id"],
					entry["tuning_result"],
					entry["trigger_chain"],
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
				event["state"],
				event["description"],
			],
			11
		))


func _on_time_pressed(seconds: int) -> void:
	_model.set_battle_time(float(seconds))
	_refresh()


func _on_tuning_pressed(tuning_result: String) -> void:
	_model.force_tuning_result(tuning_result)
	_refresh()


func _on_slot_pressed(slot_id: int) -> void:
	_model.force_unit_slot_queue(slot_id, _model.selected_tuning_result)
	_refresh()


func _on_blocked_pressed() -> void:
	_model.force_blocked_bounce(4)
	_refresh()


func _on_state_pressed(state: String) -> void:
	_model.force_settlement_state(state)
	_refresh()


func _on_reset_pressed() -> void:
	_model.reset()
	_refresh()


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _make_separator() -> HSeparator:
	var separator := HSeparator.new()
	separator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return separator


func _add_button(parent: Node, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)


func _clear_container(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.free()
