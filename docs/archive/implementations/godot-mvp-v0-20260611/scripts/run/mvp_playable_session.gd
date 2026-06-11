class_name MvpPlayableSession
extends Control

const SessionModelScript := preload("res://scripts/run/mvp_session_model.gd")
const MachineViewScript := preload("res://scripts/ball_machine/machine_causality_view.gd")
const BattlefieldViewScript := preload("res://scripts/battlefield/battlefield_deploy_view.gd")

const UI_SCALE := 1.08
const BATTLE_DURATION_SECONDS := 9.0
const ENDPOINT_DURATION_SECONDS := 7.0
const SIMULATION_SPEED := 2.6
const SIMULATION_SPEED_OPTIONS := [0.5, 1.0, 2.0, 4.0]
const DEFAULT_VIEWPORT_SIZE := Vector2i(1600, 900)
const AUDIO_MIX_RATE := 22050
const AUDIO_CUE_FREQUENCIES := {
	"launch": 392.0,
	"tuning_hit": 523.25,
	"unit_created": 659.25,
	"deploy": 330.0,
	"lane_danger": 196.0,
	"victory": 783.99,
	"reward_picked": 587.33,
	"result": 440.0,
}
const AUDIO_CUE_DURATIONS := {
	"launch": 0.07,
	"tuning_hit": 0.08,
	"unit_created": 0.11,
	"deploy": 0.07,
	"lane_danger": 0.12,
	"victory": 0.16,
	"reward_picked": 0.12,
	"result": 0.18,
}

class QueueBridgeVisual:
	extends Control

	const COLOR_BG := Color("#171a18")
	const COLOR_LINE := Color("#62c9cf")
	const COLOR_DIM := Color("#4e5a5f")
	const COLOR_TEXT := Color("#ece6d8")
	const LANE_ORDER := ["Left", "Mid", "Right"]

	var selected_lane := "Mid"
	var queue_label := "等待 Unit"

	func _ready() -> void:
		custom_minimum_size = Vector2(0, 150)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_bridge_state(next_lane: String, next_queue_label: String) -> void:
		selected_lane = next_lane
		queue_label = next_queue_label
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), COLOR_BG, true)
		var source := Vector2(22.0, size.y * 0.5)
		draw_circle(source, 8.0, COLOR_LINE)
		draw_arc(source, 13.0, 0.0, TAU, 24, COLOR_LINE, 2.0)
		draw_string(get_theme_default_font(), source + Vector2(-4.0, -18.0), "Q", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, COLOR_TEXT)
		for index in range(LANE_ORDER.size()):
			var lane_name: String = LANE_ORDER[index]
			var target := Vector2(size.x - 20.0, 30.0 + index * 42.0)
			var color := COLOR_LINE if lane_name == selected_lane else COLOR_DIM
			draw_line(source, target, color, 3.0 if lane_name == selected_lane else 1.0)
			draw_circle(target, 7.0, color)
			draw_string(
				get_theme_default_font(),
				target + Vector2(-48.0, 4.0),
				_display_lane(lane_name),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1.0,
				11,
				COLOR_TEXT if lane_name == selected_lane else COLOR_DIM
			)
		draw_string(get_theme_default_font(), Vector2(8.0, size.y - 12.0), queue_label, HORIZONTAL_ALIGNMENT_LEFT, size.x - 16.0, 10, COLOR_TEXT)

	func _display_lane(lane_name: String) -> String:
		match lane_name:
			"Left":
				return "左"
			"Mid":
				return "中"
			"Right":
				return "右"
		return lane_name


class BridgeConnectorOverlay:
	extends Node2D

	const COLOR_LINE := Color("#62c9cf")
	const COLOR_GLOW := Color("#b7f7ff")

	var bridge_panel: Control
	var battlefield_view: Control
	var selected_lane := "Mid"

	func set_connector_targets(
		next_bridge_panel: Control,
		next_battlefield_view: Control,
		next_selected_lane: String
	) -> void:
		bridge_panel = next_bridge_panel
		battlefield_view = next_battlefield_view
		selected_lane = next_selected_lane
		queue_redraw()

	func _process(_delta: float) -> void:
		if bridge_panel != null and battlefield_view != null:
			queue_redraw()

	func _draw() -> void:
		if bridge_panel == null or battlefield_view == null:
			return
		if not bridge_panel.visible or not battlefield_view.visible:
			return
		if not battlefield_view.has_method("get_spawn_port_position"):
			return

		var bridge_source := _to_local_canvas(
			bridge_panel.get_global_transform_with_canvas() * Vector2(
				bridge_panel.size.x,
				bridge_panel.size.y * 0.5
			)
		)
		var spawn_local: Vector2 = battlefield_view.call("get_spawn_port_position", selected_lane)
		var spawn_target := _to_local_canvas(
			battlefield_view.get_global_transform_with_canvas() * spawn_local
		)
		var control_a := Vector2(lerp(bridge_source.x, spawn_target.x, 0.35), bridge_source.y)
		var control_b := Vector2(lerp(bridge_source.x, spawn_target.x, 0.72), spawn_target.y)
		var points := PackedVector2Array([
			bridge_source,
			control_a,
			control_b,
			spawn_target,
		])
		draw_polyline(points, Color(COLOR_LINE, 0.24), 9.0)
		draw_polyline(points, COLOR_LINE, 3.5)
		draw_circle(spawn_target, 7.0, COLOR_GLOW)
		draw_arc(spawn_target, 13.0, 0.0, TAU, 24, COLOR_LINE, 2.0)

	func get_contract_snapshot() -> Dictionary:
		if bridge_panel == null or battlefield_view == null:
			return {}
		if not battlefield_view.has_method("get_spawn_port_position"):
			return {}
		var bridge_source := _to_local_canvas(
			bridge_panel.get_global_transform_with_canvas() * Vector2(
				bridge_panel.size.x,
				bridge_panel.size.y * 0.5
			)
		)
		var spawn_local: Vector2 = battlefield_view.call("get_spawn_port_position", selected_lane)
		var spawn_target := _to_local_canvas(
			battlefield_view.get_global_transform_with_canvas() * spawn_local
		)
		return {
			"selected_lane": selected_lane,
			"source_is_bridge_panel": bridge_panel != null,
			"target_is_battlefield_spawn_port": battlefield_view != null,
			"source_x": bridge_source.x,
			"target_x": spawn_target.x,
			"target_y": spawn_target.y,
			"crosses_from_bridge_to_battlefield": spawn_target.x > bridge_source.x,
		}

	func _to_local_canvas(canvas_position: Vector2) -> Vector2:
		return get_global_transform_with_canvas().affine_inverse() * canvas_position

var _session: RefCounted = SessionModelScript.new()
var _machine_view: Control
var _bridge_panel: PanelContainer
var _bridge_list: VBoxContainer
var _bridge_visual: QueueBridgeVisual
var _bridge_connector_overlay: BridgeConnectorOverlay
var _battlefield_view: Control
var _contract_page: PanelContainer
var _contract_choice_panel: VBoxContainer
var _run_page: HBoxContainer
var _action_panel: PanelContainer
var _battle_page: VBoxContainer
var _simulation_speed_bar: HBoxContainer
var _simulation_speed_buttons: Dictionary = {}
var _post_battle_page: PanelContainer
var _post_battle_list: VBoxContainer
var _status_label: Label
var _phase_label: Label
var _choice_panel: VBoxContainer
var _readability_list: VBoxContainer
var _flow_list: VBoxContainer
var _log_list: VBoxContainer
var _result_panel: PanelContainer
var _result_list: VBoxContainer
var _built := false

var _phase := "guardian"
var _visible_step := "Guardian Select"
var _battle_running := false
var _battle_number := 0
var _battle_elapsed := 0.0
var _simulation_speed_multiplier := 1.0
var _current_lane := "Mid"
var _forwarded_machine_entries := 0
var _deployed_start_index := 0
var _selected_shop_purchase_id := ""
var _last_machine_event_count := 0
var _last_battlefield_event_count := 0
var _audio_players: Dictionary = {}
var _audio_events: Array[String] = []
var _audio_cue_counts: Dictionary = {}
var _transition_beats: Array[String] = []
var _phase_status_mismatches: Array[String] = []


func _ready() -> void:
	_ensure_built()


func _process(delta: float) -> void:
	if _battle_running:
		_advance_battle(delta)


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_audio_bank()
	_build_layout()
	_show_guardian_choices()
	_refresh()


func _build_layout() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	_phase_label = _make_label("PlanB MVP v0 可玩短局", 20)
	root.add_child(_phase_label)
	_status_label = _make_label("", 12)
	root.add_child(_status_label)

	_contract_page = PanelContainer.new()
	_contract_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_contract_page)

	var contract_margin := MarginContainer.new()
	contract_margin.add_theme_constant_override("margin_left", 64)
	contract_margin.add_theme_constant_override("margin_top", 44)
	contract_margin.add_theme_constant_override("margin_right", 64)
	contract_margin.add_theme_constant_override("margin_bottom", 44)
	_contract_page.add_child(contract_margin)

	_contract_choice_panel = VBoxContainer.new()
	_contract_choice_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contract_choice_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_contract_choice_panel.add_theme_constant_override("separation", 14)
	contract_margin.add_child(_contract_choice_panel)

	_run_page = HBoxContainer.new()
	_run_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_run_page.add_theme_constant_override("separation", 8)
	root.add_child(_run_page)

	_action_panel = PanelContainer.new()
	_action_panel.custom_minimum_size = Vector2(300, 0)
	_run_page.add_child(_action_panel)

	_choice_panel = VBoxContainer.new()
	_choice_panel.add_theme_constant_override("separation", 6)
	_action_panel.add_child(_choice_panel)

	_readability_list = VBoxContainer.new()
	_readability_list.add_theme_constant_override("separation", 2)
	_flow_list = VBoxContainer.new()
	_flow_list.add_theme_constant_override("separation", 2)
	_log_list = VBoxContainer.new()
	_log_list.add_theme_constant_override("separation", 2)

	_battle_page = VBoxContainer.new()
	_battle_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_battle_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_battle_page.add_theme_constant_override("separation", 8)
	_run_page.add_child(_battle_page)

	_simulation_speed_bar = HBoxContainer.new()
	_simulation_speed_bar.add_theme_constant_override("separation", 6)
	_battle_page.add_child(_simulation_speed_bar)
	_build_simulation_speed_bar()

	var views := HBoxContainer.new()
	views.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	views.size_flags_vertical = Control.SIZE_EXPAND_FILL
	views.add_theme_constant_override("separation", 8)
	_battle_page.add_child(views)

	_machine_view = MachineViewScript.new()
	_machine_view.custom_minimum_size = Vector2(480, 500)
	_machine_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_machine_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_machine_view.size_flags_stretch_ratio = 38.0
	views.add_child(_machine_view)

	_bridge_panel = PanelContainer.new()
	_bridge_panel.custom_minimum_size = Vector2(178, 500)
	_bridge_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bridge_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_bridge_panel.size_flags_stretch_ratio = 14.0
	views.add_child(_bridge_panel)

	_bridge_list = VBoxContainer.new()
	_bridge_list.add_theme_constant_override("separation", 8)
	_bridge_panel.add_child(_bridge_list)

	_battlefield_view = BattlefieldViewScript.new()
	_battlefield_view.custom_minimum_size = Vector2(600, 500)
	_battlefield_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_battlefield_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_battlefield_view.size_flags_stretch_ratio = 48.0
	_battlefield_view.lane_clicked.connect(_on_lane_clicked)
	views.add_child(_battlefield_view)

	_bridge_connector_overlay = BridgeConnectorOverlay.new()
	_bridge_connector_overlay.z_index = 20
	views.add_child(_bridge_connector_overlay)

	_result_panel = PanelContainer.new()
	_result_panel.custom_minimum_size = Vector2(0, 118)
	_battle_page.add_child(_result_panel)

	_result_list = VBoxContainer.new()
	_result_list.add_theme_constant_override("separation", 3)
	_result_panel.add_child(_result_list)

	_post_battle_page = PanelContainer.new()
	_post_battle_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_post_battle_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_run_page.add_child(_post_battle_page)

	var post_margin := MarginContainer.new()
	post_margin.add_theme_constant_override("margin_left", 56)
	post_margin.add_theme_constant_override("margin_top", 40)
	post_margin.add_theme_constant_override("margin_right", 56)
	post_margin.add_theme_constant_override("margin_bottom", 40)
	_post_battle_page.add_child(post_margin)

	_post_battle_list = VBoxContainer.new()
	_post_battle_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_post_battle_list.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_post_battle_list.add_theme_constant_override("separation", 12)
	post_margin.add_child(_post_battle_list)


func _show_guardian_choices() -> void:
	_set_visible_phase("guardian", "Guardian Select")
	_show_contract_page()
	_battle_running = false
	_clear_container(_contract_choice_panel)
	_contract_choice_panel.add_child(_make_label("选择守护者契约", 20))
	_contract_choice_panel.add_child(_make_label("选择本局机器偏向与基地兜底方式", 13))
	for guardian in _session.get_available_guardians():
		var guardian_id := str(guardian.get("guardian_id", ""))
		var label := "签订契约，开始 Battle 1：%s | %s轴 | %s" % [
			guardian.get("display_name", ""),
			_display_axis(guardian.get("axis_lean", "")),
			guardian.get("tactical_skill", ""),
		]
		_add_button(_contract_choice_panel, label, Callable(self, "_on_guardian_choice").bind(guardian_id))


func _on_guardian_choice(guardian_id: String) -> void:
	_reset_feel_runtime()
	_session.start_new_run(guardian_id)
	_session.telemetry["playable.guardian_choice_source"] = "player"
	_session.battlefield_model.set_player_guardian_template_id(guardian_id)
	_current_lane = "Mid"
	_forwarded_machine_entries = _session.machine_model.queue_entries.size()
	_last_machine_event_count = _session.machine_model.event_log.size()
	_start_battle(1)


func _start_battle(battle_number: int) -> void:
	_set_visible_phase("battle", _battle_step_label(battle_number))
	_show_run_page()
	_battle_number = battle_number
	_battle_elapsed = 0.0
	_battle_running = true
	var counter_id := ""
	if battle_number == 3:
		counter_id = _session.get_counter_id_for_current_axis()
	_session.begin_playable_battle(battle_number, _current_lane, counter_id)
	_last_battlefield_event_count = 0
	_sync_audio_from_battlefield_events()
	_forwarded_machine_entries = _session.machine_model.queue_entries.size()
	_deployed_start_index = _session.battlefield_model.get_deployed_units_history().size()
	_show_battle_status(_battle_step_label(battle_number))


func _start_endpoint() -> void:
	_set_visible_phase("endpoint", "Endpoint")
	_show_run_page()
	_battle_number = 6
	_battle_elapsed = 0.0
	_battle_running = true
	_session.begin_playable_endpoint(_current_lane)
	_last_battlefield_event_count = 0
	_sync_audio_from_battlefield_events()
	_forwarded_machine_entries = _session.machine_model.queue_entries.size()
	_deployed_start_index = _session.battlefield_model.get_deployed_units_history().size()
	_show_battle_status("Endpoint")


func _show_battle_status(_title: String) -> void:
	_show_battle_screen_page()
	_clear_container(_choice_panel)
	_refresh()


func _advance_battle(delta: float) -> void:
	var step: float = max(0.0, delta) * SIMULATION_SPEED * _simulation_speed_multiplier
	_battle_elapsed += step
	_session.machine_model.step_simulation(step)
	_sync_audio_from_machine_events()
	_forward_machine_queue_entries()
	_session.battlefield_model.tick(step)
	_sync_audio_from_battlefield_events()
	if _is_terminal_battle_state():
		_complete_current_battle()
		return

	_refresh()
	if _battle_elapsed >= _current_battle_duration_seconds():
		_complete_current_battle()


func _forward_machine_queue_entries() -> void:
	var queue_entries: Array = _session.machine_model.queue_entries
	while _forwarded_machine_entries < queue_entries.size():
		var entry: Dictionary = queue_entries[_forwarded_machine_entries]
		_session.battlefield_model.enqueue_machine_queue_entry(entry)
		_forwarded_machine_entries += 1
	_session.telemetry["playable.queue_entries_forwarded"] = _forwarded_machine_entries


func _complete_current_battle() -> bool:
	var deployed := _deployed_units_since_battle_start()
	var outcome := str(_session.battlefield_model.get_battle_state())
	if outcome != "player_win" and outcome != "player_loss":
		return false

	_battle_running = false
	if _phase == "endpoint":
		var player_wins := outcome == "player_win"
		_session.finish_playable_endpoint(player_wins, deployed)
		_session.telemetry["playable.endpoint_source"] = "battlefield_terminal_state"
		_session.build_result_page()
		_record_transition_beat("endpoint_to_result")
		_show_result_page()
		return true

	var battle_result: Dictionary = _session.finish_playable_battle(_battle_number, outcome, deployed)
	if battle_result.is_empty():
		_battle_running = true
		return false
	_play_audio_cue("victory")
	match _battle_number:
		1:
			_record_transition_beat("battle_1_to_first_reward")
			_show_first_reward_choices()
		2:
			_record_transition_beat("battle_2_to_shop")
			_show_shop_choices()
		3:
			_start_battle(4)
		4:
			_record_transition_beat("battle_4_to_second_reward")
			_show_second_reward_choices()
		5:
			_record_transition_beat("battle_5_to_endpoint_prep")
			_show_endpoint_prep_choices()
		_:
			_show_result_page()
	return true


func _deployed_units_since_battle_start() -> Array[Dictionary]:
	var history: Array[Dictionary] = _session.battlefield_model.get_deployed_units_history()
	var results: Array[Dictionary] = []
	for index in range(_deployed_start_index, history.size()):
		results.append(history[index])
	return results


func _show_first_reward_choices() -> void:
	_set_visible_phase("first_reward", "First Reward")
	_begin_post_battle_page("第一次奖励", "战斗胜利。选择一个机器轴锚点，下一战会看这个选择是否读得出来。")
	for reward in _session.get_first_reward_choices():
		var reward_id := str(reward.get("modifier_id", ""))
		_add_post_choice(
			_post_battle_list,
			str(reward.get("display_name", "")),
			"%s轴 | %s" % [
				_display_axis(reward.get("warehouse", "")),
				reward.get("operation", "")
			],
			Callable(self, "_on_first_reward_choice").bind(reward_id)
		)
	_refresh()


func _on_first_reward_choice(reward_id: String) -> void:
	_play_audio_cue("reward_picked")
	_session.choose_first_reward(reward_id)
	_session.telemetry["playable.first_reward_choice_source"] = "player"
	_start_battle(2)


func _show_shop_choices() -> void:
	_set_visible_phase("shop", "Shop / Gold / Rest")
	_begin_post_battle_page(
		"商店 / 休整",
		"Gold %d。先选择一个中立机器修正，之后决定是否花费 Gold 休整。" % _session.gold
	)
	for item in _session.get_shop_choices():
		var modifier_id := str(item.get("modifier_id", ""))
		_add_post_choice(
			_post_battle_list,
			"购买 %s" % item.get("display_name", ""),
			"%s | %d Gold" % [
				_display_role(item.get("role_tag", "")),
				int(item.get("price", 0)),
			],
			Callable(self, "_on_shop_purchase_choice").bind(modifier_id)
		)
	_refresh()


func _on_shop_purchase_choice(modifier_id: String) -> void:
	_selected_shop_purchase_id = modifier_id
	_begin_post_battle_page("休整", "休整花费 3 Gold，恢复 20 Player Guardian HP。")
	_add_post_choice(_post_battle_list, "休整", "花费 3 Gold，恢复 20 HP", Callable(self, "_on_rest_choice").bind(true))
	_add_post_choice(_post_battle_list, "不休整", "保留 Gold，直接进入下一战", Callable(self, "_on_rest_choice").bind(false))


func _on_rest_choice(buy_rest: bool) -> void:
	_session.choose_shop_purchase(_selected_shop_purchase_id, buy_rest)
	_session.telemetry["playable.shop_choice_source"] = "player"
	_session.telemetry["playable.rest_choice_source"] = "player"
	_selected_shop_purchase_id = ""
	_start_battle(3)


func _show_second_reward_choices() -> void:
	_set_visible_phase("second_reward", "Second Reward")
	_begin_post_battle_page("第二次奖励", "深化主轴，或者补上前几战暴露出来的机器短板。")
	for reward in _session.get_second_reward_choices():
		var modifier_id := str(reward.get("modifier_id", ""))
		_add_post_choice(
			_post_battle_list,
			str(reward.get("display_name", "")),
			"%s | %s" % [
				reward.get("offer_role", ""),
				reward.get("reason", ""),
			],
			Callable(self, "_on_second_reward_choice").bind(modifier_id)
		)
	_refresh()


func _on_second_reward_choice(modifier_id: String) -> void:
	_play_audio_cue("reward_picked")
	_session.choose_second_reward(modifier_id)
	_session.telemetry["playable.second_reward_choice_source"] = "player"
	_start_battle(5)


func _show_endpoint_prep_choices() -> void:
	_set_visible_phase("endpoint_prep", "Endpoint Prep")
	_begin_post_battle_page("终点前整备", "此处不卖第二次商店，只允许休整或直接进入终点。")
	_add_post_choice(_post_battle_list, "终点前休整", "花费 Gold，换取进入终点前的容错", Callable(self, "_on_endpoint_rest_choice").bind(true))
	_add_post_choice(_post_battle_list, "直接进入终点", "保留 Gold，马上进入 Endpoint", Callable(self, "_on_endpoint_rest_choice").bind(false))
	_refresh()


func _on_endpoint_rest_choice(buy_rest: bool) -> void:
	_session.run_endpoint_prep(buy_rest)
	_session.telemetry["playable.rest_choice_source"] = "player"
	_start_endpoint()


func _show_result_page() -> void:
	_set_visible_phase("result", "Result Page")
	_show_post_battle_page()
	_play_audio_cue("result")
	_clear_container(_post_battle_list)
	_post_battle_list.add_child(_make_label("本局结算", 22))
	_post_battle_list.add_child(_make_label("查看本局主轴、关键选择、路线压力和下一局观察。", 12))
	_populate_result_summary(_post_battle_list)
	_refresh()


func _on_lane_clicked(lane_name: String) -> void:
	_current_lane = lane_name
	_session.battlefield_model.select_lane(lane_name)
	_session.telemetry["playable.deploy_lane_choice_source"] = "player"
	_play_audio_cue("deploy")
	_refresh()


func _refresh() -> void:
	if _machine_view != null:
		_machine_view.set_model(_session.machine_model)
	if _battlefield_view != null:
		_battlefield_view.set_model(_session.battlefield_model)

	var summary: Dictionary = _session.get_run_summary()
	_phase_label.text = "PlanB MVP v0 可玩短局 | %s" % _display_phase(_phase)
	_status_label.text = "阶段：%s | Gold %d | Guardian HP %d/100 | Deploy Lane %s | 主轴 %s" % [
		_display_step(_visible_step),
		int(summary.get("gold", 0)),
		int(summary.get("player_guardian_hp", 100)),
		_display_lane(_current_lane),
		_display_axis(summary.get("main_axis", "")),
	]

	_clear_container(_flow_list)
	for step in summary.get("flow_history", []):
		_flow_list.add_child(_make_label("- %s" % _display_step(step), 10))

	_clear_container(_log_list)
	var events: Array = summary.get("event_log", [])
	var start_index: int = max(0, events.size() - 8)
	for event in events.slice(start_index):
		_log_list.add_child(_make_label(
			_display_event_description(str(event.get("description", ""))),
			9
		))

	_refresh_readability_panel(summary)
	_refresh_bridge_panel(summary)

	_clear_container(_result_list)
	var result_page: Dictionary = summary.get("result_page", {})
	if result_page.is_empty():
		_result_list.add_child(_make_label("", 1))
	else:
		for key in [
			"chosen_guardian",
			"main_axis",
			"most_impactful_reward",
			"key_battlefield_turn",
			"weakest_link",
			"enemy_counter_impact",
			"next_run_suggestion",
			"key_rewards",
			"shop_rest_choice",
			"counter_target",
			"deploy_lane_impact",
			"endpoint_payoff_or_break_reason",
			"next_run_watch_tag",
		]:
			_result_list.add_child(_make_label(
				"%s：%s" % [_display_result_key(key), result_page.get(key, "")],
				10
			))
	_record_phase_status_check()


func _refresh_bridge_panel(summary: Dictionary) -> void:
	if _bridge_list == null:
		return
	_clear_container(_bridge_list)
	_bridge_list.add_child(_make_label("Queue Bridge", 14))
	var queue_bridge: Dictionary = summary.get("queue_to_lane_bridge", {})
	var queue_label := "队首：等待 Unit"
	if not queue_bridge.is_empty():
		queue_label = "队首：%s" % queue_bridge.get("queue_head", "空")
	_bridge_visual = QueueBridgeVisual.new()
	_bridge_visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bridge_visual.set_bridge_state(_current_lane, queue_label)
	_bridge_list.add_child(_bridge_visual)
	_bridge_list.add_child(_make_label("当前出兵口：%s" % _display_lane(_current_lane), 11))
	_bridge_list.add_child(_make_label("已部署单位不随切路改变。", 9))
	if _bridge_connector_overlay != null:
		_bridge_connector_overlay.set_connector_targets(_bridge_panel, _battlefield_view, _current_lane)


func _show_contract_page() -> void:
	if _contract_page != null:
		_contract_page.visible = true
	if _run_page != null:
		_run_page.visible = false


func _show_run_page() -> void:
	if _contract_page != null:
		_contract_page.visible = false
	if _run_page != null:
		_run_page.visible = true


func _show_battle_screen_page() -> void:
	_show_run_page()
	if _action_panel != null:
		_action_panel.visible = false
	if _battle_page != null:
		_battle_page.visible = true
	if _post_battle_page != null:
		_post_battle_page.visible = false
	if _result_panel != null:
		_result_panel.visible = false
	_refresh_simulation_speed_buttons()


func _show_post_battle_page() -> void:
	_show_run_page()
	if _action_panel != null:
		_action_panel.visible = false
	if _battle_page != null:
		_battle_page.visible = false
	if _post_battle_page != null:
		_post_battle_page.visible = true
	if _result_panel != null:
		_result_panel.visible = false


func _begin_post_battle_page(title: String, description: String) -> void:
	_show_post_battle_page()
	_clear_container(_post_battle_list)
	_post_battle_list.add_child(_make_label(title, 22))
	_post_battle_list.add_child(_make_label(description, 12))


func _populate_result_summary(parent: Node) -> void:
	var summary: Dictionary = _session.get_run_summary()
	var result_page: Dictionary = summary.get("result_page", {})
	if result_page.is_empty():
		parent.add_child(_make_label("结算数据尚未生成。", 11))
		return
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
		parent.add_child(_make_label(
			"%s：%s" % [_display_result_key(key), result_page.get(key, "")],
			11
		))


func _refresh_readability_panel(summary: Dictionary) -> void:
	_clear_container(_readability_list)
	var battle_records: Dictionary = summary.get("battle_readability_records", {})
	var first_commitment: Dictionary = summary.get("first_reward_commitment", {})
	var next_causality: Dictionary = summary.get("next_battle_causality", {})
	var queue_bridge: Dictionary = summary.get("queue_to_lane_bridge", {})

	if battle_records.has("battle_1"):
		var battle1: Dictionary = battle_records["battle_1"]
		_readability_list.add_child(_make_label(
			"Battle 1：%s -> %s -> %s" % [
				battle1.get("machine_component", ""),
				battle1.get("queue_head", ""),
				_display_lane(battle1.get("selected_deploy_lane", "")),
			],
			9
		))
		_readability_list.add_child(_make_label(str(battle1.get("battlefield_outcome", "")), 9))
	else:
		_readability_list.add_child(_make_label(
			"Battle 1 目标：读出机器 -> 队列 -> Deploy Lane -> 战场结果。",
			9
		))

	if not first_commitment.is_empty():
		_readability_list.add_child(_make_label(
			"First Reward：%s轴，%s" % [
				_display_axis(first_commitment.get("axis", "")),
				first_commitment.get("component_operation", ""),
			],
			9
		))
		_readability_list.add_child(_make_label(
			"下一战观察：%s" % first_commitment.get("next_battle_watch", ""),
			9
		))

	if not next_causality.is_empty():
		_readability_list.add_child(_make_label(
			"Reward 后反馈：%s" % next_causality.get("observed_battlefield_signal", ""),
			9
		))

	if not queue_bridge.is_empty():
		_readability_list.add_child(_make_label(
			"Queue-to-Lane：%s -> %s；已部署不改路。" % [
				queue_bridge.get("queue_head", ""),
				_display_lane(queue_bridge.get("current_deploy_lane", "")),
			],
			9
		))


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", _scaled_font(font_size))
	return label


func _add_button(parent: Node, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 36)
	button.add_theme_font_size_override("font_size", _scaled_font(11))
	button.pressed.connect(callback)
	parent.add_child(button)


func _add_post_choice(parent: Node, title: String, detail: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = "%s\n%s" % [title, detail]
	button.custom_minimum_size = Vector2(0, 74)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", _scaled_font(12))
	button.pressed.connect(callback)
	parent.add_child(button)


func _build_simulation_speed_bar() -> void:
	_simulation_speed_bar.add_child(_make_label("全局倍速", 11))
	for speed_value in SIMULATION_SPEED_OPTIONS:
		var button := Button.new()
		button.text = _format_simulation_speed(speed_value)
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(58, 30)
		button.add_theme_font_size_override("font_size", _scaled_font(10))
		button.pressed.connect(Callable(self, "_on_simulation_speed_pressed").bind(float(speed_value)))
		_simulation_speed_bar.add_child(button)
		_simulation_speed_buttons[float(speed_value)] = button
	_refresh_simulation_speed_buttons()


func _on_simulation_speed_pressed(speed_value: float) -> void:
	_set_simulation_speed_multiplier(speed_value)


func _set_simulation_speed_multiplier(speed_value: float) -> void:
	if not SIMULATION_SPEED_OPTIONS.has(speed_value):
		return
	_simulation_speed_multiplier = speed_value
	_refresh_simulation_speed_buttons()


func _refresh_simulation_speed_buttons() -> void:
	for speed_value in _simulation_speed_buttons.keys():
		var button := _simulation_speed_buttons[speed_value] as Button
		if button != null:
			button.button_pressed = abs(float(speed_value) - _simulation_speed_multiplier) < 0.001


func _format_simulation_speed(speed_value: float) -> String:
	if abs(speed_value - round(speed_value)) < 0.001:
		return "%dx" % int(round(speed_value))
	return "%.1fx" % speed_value


func _make_separator() -> HSeparator:
	var separator := HSeparator.new()
	separator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return separator


func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.free()


func _build_audio_bank() -> void:
	for cue_id in AUDIO_CUE_FREQUENCIES.keys():
		var cue_name := str(cue_id)
		var player := AudioStreamPlayer.new()
		player.name = "AudioCue%s" % _cue_node_suffix(cue_name)
		player.stream = _make_tone_stream(
			float(AUDIO_CUE_FREQUENCIES[cue_name]),
			float(AUDIO_CUE_DURATIONS[cue_name])
		)
		player.volume_db = -15.0
		_audio_players[cue_name] = player
		add_child(player)


func _make_tone_stream(frequency: float, duration: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = AUDIO_MIX_RATE
	stream.stereo = false

	var frame_count: int = max(1, int(round(duration * AUDIO_MIX_RATE)))
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	for frame in range(frame_count):
		var progress := float(frame) / float(max(1, frame_count - 1))
		var envelope := 1.0 - progress
		var wave := sin(float(frame) * TAU * frequency / float(AUDIO_MIX_RATE))
		var sample := int(clamp(wave * envelope * 0.34, -1.0, 1.0) * 32767.0)
		var encoded := sample
		if encoded < 0:
			encoded = 65536 + encoded
		data[frame * 2] = encoded & 0xff
		data[frame * 2 + 1] = (encoded >> 8) & 0xff

	stream.data = data
	return stream


func _play_audio_cue(cue_id: String) -> void:
	if not _audio_players.has(cue_id):
		return
	_audio_events.append(cue_id)
	_audio_cue_counts[cue_id] = int(_audio_cue_counts.get(cue_id, 0)) + 1
	if not is_inside_tree():
		return
	var player := _audio_players[cue_id] as AudioStreamPlayer
	if player != null:
		player.stop()
		player.play()


func _current_battle_duration_seconds() -> float:
	return ENDPOINT_DURATION_SECONDS if _phase == "endpoint" else BATTLE_DURATION_SECONDS


func _is_terminal_battle_state() -> bool:
	var outcome := str(_session.battlefield_model.get_battle_state())
	return outcome == "player_win" or outcome == "player_loss"


func _sync_audio_from_machine_events() -> void:
	var events: Array = _session.machine_model.event_log
	while _last_machine_event_count < events.size():
		var event: Dictionary = events[_last_machine_event_count]
		_last_machine_event_count += 1
		var component := str(event.get("component", ""))
		var state := str(event.get("state", ""))
		match component:
			"Launcher", "Launch":
				_play_audio_cue("launch")
			"Tuning":
				if state == "Natural Hit" or state == "Logic Settlement":
					_play_audio_cue("tuning_hit")
			"Queue":
				_play_audio_cue("unit_created")


func _sync_audio_from_battlefield_events() -> void:
	var events: Array = _session.battlefield_model.event_log
	while _last_battlefield_event_count < events.size():
		var event: Dictionary = events[_last_battlefield_event_count]
		_last_battlefield_event_count += 1
		match str(event.get("state", "")):
			"queue deployed":
				_play_audio_cue("deploy")
			"lane warning":
				_play_audio_cue("lane_danger")


func _reset_feel_runtime() -> void:
	_audio_events.clear()
	_audio_cue_counts.clear()
	_transition_beats.clear()
	_phase_status_mismatches.clear()
	_last_machine_event_count = 0
	_last_battlefield_event_count = 0


func _set_visible_phase(next_phase: String, next_step: String) -> void:
	_phase = next_phase
	_visible_step = next_step


func _battle_step_label(battle_number: int) -> String:
	if battle_number == 3:
		return "Battle 3 with counter"
	return "Battle %d" % battle_number


func _record_transition_beat(beat_id: String) -> void:
	if not _transition_beats.has(beat_id):
		_transition_beats.append(beat_id)


func _record_phase_status_check() -> void:
	var expected := _expected_step_for_phase()
	if _visible_step == expected:
		return
	var mismatch := "%s expected %s got %s" % [_phase, expected, _visible_step]
	if not _phase_status_mismatches.has(mismatch):
		_phase_status_mismatches.append(mismatch)


func _expected_step_for_phase() -> String:
	match _phase:
		"guardian":
			return "Guardian Select"
		"battle":
			return _battle_step_label(_battle_number)
		"first_reward":
			return "First Reward"
		"shop":
			return "Shop / Gold / Rest"
		"second_reward":
			return "Second Reward"
		"endpoint_prep":
			return "Endpoint Prep"
		"endpoint":
			return "Endpoint"
		"result":
			return "Result Page"
	return _visible_step


func _display_event_description(description: String) -> String:
	return description \
		.replace("按可玩短局节奏", "按本局节奏") \
		.replace("首版 Gold 来源，数值仍需实测。", "获得的 Gold 已计入本局。")


func _cue_node_suffix(cue_id: String) -> String:
	var suffix := ""
	for part in cue_id.split("_"):
		if part.is_empty():
			continue
		suffix += part.substr(0, 1).to_upper() + part.substr(1)
	return suffix


func _display_phase(phase: String) -> String:
	match phase:
		"guardian":
			return "守护者选择"
		"battle":
			return "战斗"
		"first_reward":
			return "第一次奖励"
		"shop":
			return "商店 / 休整"
		"second_reward":
			return "第二次奖励"
		"endpoint_prep":
			return "终点准备"
		"endpoint":
			return "终点"
		"result":
			return "结算页"
	return phase


func _display_step(step) -> String:
	match str(step):
		"Guardian Select":
			return "守护者选择"
		"Battle 1":
			return "第一战"
		"Battle 2":
			return "第二战"
		"Battle 3 with counter":
			return "第三战（反制）"
		"Battle 4":
			return "第四战"
		"Battle 5":
			return "第五战"
		"First Reward":
			return "第一奖励"
		"Shop / Gold / Rest":
			return "商店 / 金币 / 休整"
		"Second Reward":
			return "第二奖励"
		"Endpoint Prep":
			return "终点准备"
		"Endpoint":
			return "终点"
		"Result Page":
			return "结算页"
		"Battle 6":
			return "终点"
	return str(step)


func _display_axis(axis) -> String:
	match str(axis):
		"Launch":
			return "发射"
		"Tuning":
			return "调校"
		"Unit":
			return "单位"
	return str(axis)


func _display_lane(lane) -> String:
	match str(lane):
		"Left", "left":
			return "左路"
		"Mid", "mid":
			return "中路"
		"Right", "right":
			return "右路"
	return str(lane)


func _display_role(role) -> String:
	match str(role):
		"Patch":
			return "补洞"
		"Pivot":
			return "转轴"
		"Deepen":
			return "深化"
		"Anchor":
			return "锚点"
	return str(role)


func _display_result_key(key) -> String:
	match str(key):
		"chosen_guardian":
			return "选择的守护者"
		"main_axis":
			return "主轴"
		"most_impactful_reward":
			return "最有影响奖励"
		"key_battlefield_turn":
			return "关键战场回合"
		"weakest_link":
			return "最弱环节"
		"enemy_counter_impact":
			return "敌人反制影响"
		"next_run_suggestion":
			return "下一局建议"
		"key_rewards":
			return "关键奖励"
		"shop_rest_choice":
			return "商店 / 休整"
		"counter_target":
			return "反制目标"
		"deploy_lane_impact":
			return "Deploy Lane 影响"
		"endpoint_payoff_or_break_reason":
			return "终点收益 / 断裂"
		"next_run_watch_tag":
			return "下局观察标签"
	return str(key)


func _scaled_font(font_size: int) -> int:
	return int(round(float(font_size) * UI_SCALE))
