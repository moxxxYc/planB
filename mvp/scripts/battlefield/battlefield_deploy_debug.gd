class_name BattlefieldDeployDebug
extends Control

const M1ModelScript := preload("res://scripts/ball_machine/machine_causality_model.gd")
const ModelScript := preload("res://scripts/battlefield/battlefield_deploy_model.gd")
const ViewScript := preload("res://scripts/battlefield/battlefield_deploy_view.gd")

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
	panel.custom_minimum_size = Vector2(430, 0)
	root.add_child(panel)

	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 10)
	panel.add_child(side)

	side.add_child(_make_label("M2 Battlefield / Deploy Lane Debug", 21))
	side.add_child(_make_label("Click a battlefield lane directly to set Deploy Lane.", 13))

	_status_label = _make_label("", 14)
	side.add_child(_status_label)
	_queue_label = _make_label("", 13)
	side.add_child(_queue_label)
	_guardian_label = _make_label("", 13)
	side.add_child(_guardian_label)

	side.add_child(_make_separator())
	side.add_child(_make_label("Queue / Enemy Controls", 15))
	var queue_row := GridContainer.new()
	queue_row.columns = 2
	queue_row.add_theme_constant_override("h_separation", 6)
	queue_row.add_theme_constant_override("v_separation", 6)
	side.add_child(queue_row)
	_add_button(queue_row, "Generate Queue Entry", Callable(self, "_on_generate_queue_pressed"))
	_add_button(queue_row, "Deploy Queue Head", Callable(self, "_on_deploy_pressed"))
	_add_button(queue_row, "Spawn Enemy", Callable(self, "_on_spawn_enemy_pressed"))
	_add_button(queue_row, "Step Battle", Callable(self, "_on_step_pressed"))
	_add_button(queue_row, "Pause / Run", Callable(self, "_on_pause_pressed"))
	_add_button(queue_row, "Reset", Callable(self, "_on_reset_pressed"))

	side.add_child(_make_label("Lane State Debug", 15))
	var state_row := GridContainer.new()
	state_row.columns = 2
	state_row.add_theme_constant_override("h_separation", 6)
	state_row.add_theme_constant_override("v_separation", 6)
	side.add_child(state_row)
	_add_button(state_row, "Force Pushing", Callable(self, "_on_force_state_pressed").bind("pushing"))
	_add_button(state_row, "Force Stalled", Callable(self, "_on_force_state_pressed").bind("stalled"))
	_add_button(state_row, "Force Leaking", Callable(self, "_on_force_state_pressed").bind("leaking"))
	_add_button(state_row, "Break Gate", Callable(self, "_on_force_state_pressed").bind("gate broken"))
	_add_button(state_row, "Force Invading", Callable(self, "_on_force_state_pressed").bind("invading"))
	_add_button(state_row, "Warning T1", Callable(self, "_on_warning_pressed"))

	side.add_child(_make_label("Battle Result Debug", 15))
	var result_row := HBoxContainer.new()
	result_row.add_theme_constant_override("separation", 6)
	side.add_child(result_row)
	_add_button(result_row, "Resolve Win", Callable(self, "_on_resolve_pressed").bind("player_win"))
	_add_button(result_row, "Resolve Loss", Callable(self, "_on_resolve_pressed").bind("player_loss"))

	side.add_child(_make_separator())
	side.add_child(_make_label("Lanes", 15))
	_lane_list = VBoxContainer.new()
	_lane_list.add_theme_constant_override("separation", 3)
	side.add_child(_lane_list)

	side.add_child(_make_label("Units", 15))
	_unit_list = VBoxContainer.new()
	_unit_list.add_theme_constant_override("separation", 3)
	side.add_child(_unit_list)

	side.add_child(_make_label("Event Log", 15))
	_log_list = VBoxContainer.new()
	_log_list.add_theme_constant_override("separation", 3)
	side.add_child(_log_list)


func _refresh() -> void:
	var summary: Dictionary = _model.get_debug_summary()
	_view.set_model(_model)

	_status_label.text = "Selected Deploy Lane: %s | %s | %.1fs" % [
		summary.get("selected_lane_name", "Mid"),
		summary.get("battle_state", "running"),
		float(summary.get("battle_time_seconds", 0.0)),
	]

	var queue_preview: Array = summary.get("queue_preview", [])
	if queue_preview.is_empty():
		_queue_label.text = "Queue head: empty"
	else:
		var head: Dictionary = queue_preview[0]
		_queue_label.text = "Queue head -> %s | %s | source S%d" % [
			head.get("deploy_lane_name", ""),
			head.get("queue_entry_id", ""),
			head.get("source_slot_id", 0),
		]

	_guardian_label.text = "Player Guardian HP %d/%d | Enemy Guardian HP %d/%d" % [
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
			"%s | %s | danger %d | P gate %d | E gate %d" % [
				lane_data.get("lane_name", ""),
				lane_data.get("state", "idle"),
				int(lane_data.get("danger_tier", 0)),
				int(lane_data.get("player_gate_hp", 0)),
				int(lane_data.get("enemy_gate_hp", 0)),
			],
			11
		))

	_clear_container(_unit_list)
	var units: Array = summary.get("units", [])
	if units.is_empty():
		_unit_list.add_child(_make_label("none", 11))
	else:
		var unit_start: int = max(0, units.size() - 6)
		for unit in units.slice(unit_start):
			_unit_list.add_child(_make_label(
				"%s | %s | %s %.1f | HP %d/%d | %s" % [
					unit.get("display_name", ""),
					unit.get("side", ""),
					unit.get("lane_name", ""),
					float(unit.get("path_pos", 0.0)),
					int(unit.get("hp", 0)),
					int(unit.get("max_hp", 0)),
					unit.get("state", ""),
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
				event.get("state", ""),
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
