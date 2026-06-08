class_name MvpSessionDebug
extends Control

const ModelScript := preload("res://scripts/run/mvp_session_model.gd")

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
	left_panel.custom_minimum_size = Vector2(420, 0)
	root.add_child(left_panel)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	left_panel.add_child(left)

	left.add_child(_make_label("M3 Complete MVP v0 Session", 21))
	left.add_child(_make_label("Debug flow: Guardian Select -> Battles -> Rewards -> Shop/Rest -> Counters -> Endpoint -> Result Page.", 12))

	_guardian_label = _make_label("", 13)
	left.add_child(_guardian_label)
	_status_label = _make_label("", 13)
	left.add_child(_status_label)

	left.add_child(_make_separator())
	left.add_child(_make_label("Guardian Select", 15))
	var guardian_row := HBoxContainer.new()
	guardian_row.add_theme_constant_override("separation", 6)
	left.add_child(guardian_row)
	_add_button(guardian_row, "巢脉母", Callable(self, "_on_guardian_pressed").bind("hive.vein_mother"))
	_add_button(guardian_row, "酸冠母", Callable(self, "_on_guardian_pressed").bind("hive.acid_crown_mother"))

	left.add_child(_make_label("Run Controls", 15))
	var run_grid := GridContainer.new()
	run_grid.columns = 2
	run_grid.add_theme_constant_override("h_separation", 6)
	run_grid.add_theme_constant_override("v_separation", 6)
	left.add_child(run_grid)
	_add_button(run_grid, "Run Win Session", Callable(self, "_on_run_win_pressed"))
	_add_button(run_grid, "Run Loss Session", Callable(self, "_on_run_loss_pressed"))
	_add_button(run_grid, "Reset", Callable(self, "_on_reset_pressed"))

	left.add_child(_make_separator())
	left.add_child(_make_label("Flow", 15))
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
	result_box.add_child(_make_label("Result Page Facts", 17))
	_result_list = VBoxContainer.new()
	_result_list.add_theme_constant_override("separation", 3)
	result_box.add_child(_result_list)

	var telemetry_panel := PanelContainer.new()
	telemetry_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(telemetry_panel)
	var telemetry_box := VBoxContainer.new()
	telemetry_box.add_theme_constant_override("separation", 4)
	telemetry_panel.add_child(telemetry_box)
	telemetry_box.add_child(_make_label("Checkpoint Telemetry", 17))
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
	log_box.add_child(_make_label("Event Log", 17))
	_log_list = VBoxContainer.new()
	_log_list.add_theme_constant_override("separation", 3)
	log_box.add_child(_log_list)


func _refresh() -> void:
	var summary: Dictionary = _model.get_run_summary()
	var guardian: Dictionary = summary.get("chosen_guardian", {})
	_guardian_label.text = "Guardian: %s | axis %s | tactical %s" % [
		guardian.get("display_name", "none"),
		guardian.get("axis_lean", ""),
		guardian.get("tactical_skill", ""),
	]
	_status_label.text = "Step: %s | Gold %d | Guardian HP %d/%d | Main axis %s" % [
		summary.get("current_step", ""),
		int(summary.get("gold", 0)),
		int(summary.get("player_guardian_hp", 0)),
		100,
		summary.get("main_axis", ""),
	]

	_clear_container(_flow_list)
	for step in summary.get("flow_history", []):
		_flow_list.add_child(_make_label("- %s" % step, 11))

	_clear_container(_result_list)
	var result_page: Dictionary = summary.get("result_page", {})
	if result_page.is_empty():
		_result_list.add_child(_make_label("Run a Win or Loss session to populate real result data.", 12))
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
			_result_list.add_child(_make_label("%s: %s" % [key, result_page.get(key, "")], 11))

	_clear_container(_telemetry_list)
	var telemetry: Dictionary = summary.get("telemetry", {})
	if telemetry.is_empty():
		_telemetry_list.add_child(_make_label("No checkpoint telemetry yet.", 12))
	else:
		for key in telemetry.keys().slice(0, min(18, telemetry.size())):
			_telemetry_list.add_child(_make_label("%s: %s" % [key, str(telemetry[key])], 10))

	_clear_container(_log_list)
	var events: Array = summary.get("event_log", [])
	var start_index: int = max(0, events.size() - 12)
	for event in events.slice(start_index):
		_log_list.add_child(_make_label(
			"%s | %s" % [
				event.get("state", ""),
				event.get("description", ""),
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
