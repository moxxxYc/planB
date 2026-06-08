class_name MvpShell
extends Control

const Manifest := preload("res://scripts/data/mvp_definition_manifest.gd")

var _step_index := 0
var _step_label: Label
var _step_summary: Label


func _ready() -> void:
	_build_layout()
	_refresh_step()


func _build_layout() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	var title := _make_label("PlanB MVP v0 - Current-Docs Project Skeleton", 28)
	root.add_child(title)

	root.add_child(_make_label(
		"Godot 4.6 shell for M0 only. It names current docs, terms, data placeholders, "
		+ "and a debug session stepper without implementing M1-M3 gameplay.",
		16
	))

	var term_row := HBoxContainer.new()
	term_row.add_theme_constant_override("separation", 12)
	root.add_child(term_row)
	term_row.add_child(_make_panel("Machine", "Launch / Tuning / Unit"))
	term_row.add_child(_make_panel("Tuning", "Gate / Prime / Echo / Surge"))
	term_row.add_child(_make_panel("Deploy Lane", "Left / Mid / Right, default Mid"))
	term_row.add_child(_make_panel("Hive Slots", "短牙虫 / 盾壳虫 / 酸囊虫 / 碾壳兽"))

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 10)
	root.add_child(grid)

	_add_catalog_line(grid, "Machine components", "res://resources/machine/")
	_add_catalog_line(grid, "Battle lanes", "res://resources/battlefield/")
	_add_catalog_line(grid, "Hive unit templates", "res://resources/units/")
	_add_catalog_line(grid, "Player Guardians", "res://resources/guardians/")
	_add_catalog_line(grid, "Rewards and shop items", "res://resources/economy/")
	_add_catalog_line(grid, "Counter families", "res://resources/enemies/")
	_add_catalog_line(grid, "Result fields", "res://resources/run/")

	var separator := HSeparator.new()
	root.add_child(separator)

	_step_label = _make_label("", 22)
	root.add_child(_step_label)

	_step_summary = _make_label("", 16)
	root.add_child(_step_summary)

	var button := Button.new()
	button.text = "Step Session State"
	button.pressed.connect(_on_step_pressed)
	root.add_child(button)


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _make_panel(title: String, body: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label := _make_label("%s\n%s" % [title, body], 15)
	panel.add_child(label)
	return panel


func _add_catalog_line(grid: GridContainer, label_text: String, prefix: String) -> void:
	grid.add_child(_make_label(label_text, 15))
	var count := Manifest.count_required_resources_with_prefix(prefix)
	grid.add_child(_make_label("%d placeholder resource(s)" % count, 15))


func _on_step_pressed() -> void:
	_step_index = (_step_index + 1) % Manifest.SESSION_STEPS.size()
	_refresh_step()


func _refresh_step() -> void:
	var step: Dictionary = Manifest.SESSION_STEPS[_step_index]
	_step_label.text = "Debug State: %s" % step["label"]
	_step_summary.text = str(step["summary"])
