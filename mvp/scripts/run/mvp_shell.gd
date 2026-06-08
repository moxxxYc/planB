class_name MvpShell
extends Control

const Manifest := preload("res://scripts/data/mvp_definition_manifest.gd")

const UI_SCALE := 1.28

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

	var title := _make_label("PlanB MVP v0 调试入口", 30)
	root.add_child(title)

	root.add_child(_make_label(
		"Godot 4.6 当前 MVP 实现入口。M1 负责机器因果，M2 负责战场与部署路线，M3 串起完整短局调试流程。",
		17
	))

	var term_row := HBoxContainer.new()
	term_row.add_theme_constant_override("separation", 12)
	root.add_child(term_row)
	term_row.add_child(_make_panel("机器三仓", "发射仓 / 调校仓 / 单位仓"))
	term_row.add_child(_make_panel("调校槽", "闸门 / 预充 / 复写 / 脉冲"))
	term_row.add_child(_make_panel("部署路线", "左路 / 中路 / 右路，默认中路"))
	term_row.add_child(_make_panel("蜂巢单位槽", "短牙虫 / 盾壳虫 / 酸囊虫 / 碾壳兽"))

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 10)
	root.add_child(grid)

	_add_catalog_line(grid, "机器组件", "res://resources/machine/")
	_add_catalog_line(grid, "战场路线", "res://resources/battlefield/")
	_add_catalog_line(grid, "蜂巢单位模板", "res://resources/units/")
	_add_catalog_line(grid, "玩家守护者", "res://resources/guardians/")
	_add_catalog_line(grid, "奖励与商店项", "res://resources/economy/")
	_add_catalog_line(grid, "敌人反制家族", "res://resources/enemies/")
	_add_catalog_line(grid, "结算页字段", "res://resources/run/")

	var separator := HSeparator.new()
	root.add_child(separator)

	_step_label = _make_label("", 22)
	root.add_child(_step_label)

	_step_summary = _make_label("", 16)
	root.add_child(_step_summary)

	_add_button(root, "切换调试阶段", Callable(self, "_on_step_pressed"))
	_add_button(root, "打开 M1 机器因果调试", Callable(self, "_on_machine_debug_pressed"))
	_add_button(root, "打开 M2 战场 / 部署路线调试", Callable(self, "_on_battlefield_debug_pressed"))
	_add_button(root, "打开 M3 完整短局调试", Callable(self, "_on_session_debug_pressed"))


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", _scaled_font(font_size))
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
	grid.add_child(_make_label("%d 个调试资源" % count, 15))


func _add_button(parent: Node, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 46)
	button.add_theme_font_size_override("font_size", _scaled_font(15))
	button.pressed.connect(callback)
	parent.add_child(button)


func _on_step_pressed() -> void:
	_step_index = (_step_index + 1) % Manifest.SESSION_STEPS.size()
	_refresh_step()


func _on_machine_debug_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ball_machine/machine_causality_debug.tscn")


func _on_battlefield_debug_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/battlefield/battlefield_deploy_debug.tscn")


func _on_session_debug_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/run/mvp_session_debug.tscn")


func _refresh_step() -> void:
	var step: Dictionary = Manifest.SESSION_STEPS[_step_index]
	_step_label.text = "调试阶段：%s" % step["label"]
	_step_summary.text = str(step["summary"])


func _scaled_font(font_size: int) -> int:
	return int(round(float(font_size) * UI_SCALE))
