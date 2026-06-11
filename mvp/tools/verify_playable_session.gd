extends SceneTree

const SCENE_PATH := "res://scenes/run/mvp_playable_session.tscn"
const SESSION_MODEL_PATH := "res://scripts/run/mvp_session_model.gd"

const REQUIRED_FLOW := [
	"Guardian Select",
	"Battle 1",
	"First Reward",
	"Battle 2",
	"Shop / Gold / Rest",
	"Battle 3 with counter",
	"Battle 4",
	"Second Reward",
	"Battle 5",
	"Endpoint Prep",
	"Endpoint",
	"Result Page",
]

const REQUIRED_AUDIO_CUES := [
	"launch",
	"tuning_hit",
	"unit_created",
	"deploy",
	"lane_danger",
	"victory",
	"reward_picked",
	"result",
]

const REQUIRED_TRANSITION_BEATS := [
	"battle_1_to_first_reward",
	"battle_2_to_shop",
	"battle_4_to_second_reward",
	"battle_5_to_endpoint_prep",
	"endpoint_to_result",
]

const FORBIDDEN_PLAYER_TEXT := [
	"debug",
	"DEBUG",
	"开发入口",
	"调试入口",
	"调试",
	"harness",
	"验证",
	"可读性",
	"流程",
	"事件",
	"结算页会在 Endpoint 后显示",
	"选择 Player Guardian",
	"点击右侧战场路线",
	"球半径",
	"钉子半径",
	"重置尺寸",
	"ACTIVE BALL",
]


func _init() -> void:
	_run_checks.call_deferred()


func _run_checks() -> void:
	var failures: Array[String] = []

	await _check_scene_loads(failures)
	if failures.is_empty():
		_check_running_battle_is_not_forced_to_win(failures)
		await _check_playable_path_reaches_result(failures)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		await process_frame
		quit(1)
		return

	print("verify_playable_session.gd passed: formal playable Win/Loss paths verified")
	await process_frame
	quit(0)


func _check_scene_loads(failures: Array[String]) -> void:
	var instance := await _instantiate_playable(failures)
	if instance == null:
		return

	instance.call("_ensure_built")
	if not _has_required_runtime_children(instance):
		failures.append("Playable session scene is missing required player-facing UI regions")
	if _contains_scroll_container(instance):
		failures.append("Playable layout still uses scroll containers in the default window")
	_check_no_forbidden_player_text(instance, "initial playable screen", failures)
	_check_player_facing_contract_text(instance, failures)
	_check_guardian_contract_is_standalone(instance, failures)
	await _check_battle_screen_contract(instance, failures)
	_check_post_battle_pages_are_primary(instance, failures)
	await _free_test_instance(instance)


func _check_running_battle_is_not_forced_to_win(failures: Array[String]) -> void:
	var script := ResourceLoader.load(SESSION_MODEL_PATH)
	if script == null:
		failures.append("Could not load playable session model script")
		return

	var model = script.new()
	if model == null:
		failures.append("Could not instantiate playable session model")
		return

	var deployed_units: Array[Dictionary] = []
	var result: Dictionary = model.finish_playable_battle(1, "running", deployed_units)
	if not result.is_empty():
		failures.append("Running playable battle should not produce a completed battle result")
	if str(model.battlefield_model.get_battle_state()) != "running":
		failures.append("Running playable battle was forced into a terminal battle state")


func _check_playable_path_reaches_result(failures: Array[String]) -> void:
	var win_instance := await _instantiate_playable(failures)
	if win_instance == null:
		return

	_check_terminal_battle_completes_immediately(win_instance, failures)
	await _free_test_instance(win_instance)

	win_instance = await _instantiate_playable(failures)
	if win_instance == null:
		return
	var result: Dictionary = _run_player_session(win_instance, true, failures)
	_check_result_reaches_page("win", result, failures)
	_check_player_choice_telemetry(result, failures)
	_check_completed_playable_contract(win_instance, failures)
	_check_no_forbidden_player_text(win_instance, "completed win screen", failures)
	await _free_test_instance(win_instance)

	var loss_instance := await _instantiate_playable(failures)
	if loss_instance == null:
		return
	var loss_result: Dictionary = _run_player_session(loss_instance, false, failures)
	_check_result_reaches_page("loss", loss_result, failures)
	_check_completed_playable_contract(loss_instance, failures)
	_check_no_forbidden_player_text(loss_instance, "completed loss screen", failures)
	await _free_test_instance(loss_instance)


func _check_terminal_battle_completes_immediately(instance: Node, failures: Array[String]) -> void:
	instance.call("_ensure_built")
	instance.call("_on_guardian_choice", "hive.vein_mother")
	instance.call("_advance_battle", 0.25)

	var session: RefCounted = instance.get("_session")
	session.battlefield_model.resolve_battle_result("player_win")
	instance.call("_advance_battle", 0.01)

	if bool(instance.get("_battle_running")):
		failures.append("Terminal battle state did not end playable battle immediately")
	if str(instance.get("_visible_step")) != "First Reward":
		failures.append("Terminal Battle 1 did not advance to First Reward immediately")
	var elapsed := float(instance.get("_battle_elapsed"))
	if elapsed >= 1.0:
		failures.append("Terminal battle waited for duration gate before completing")


func _run_player_session(
	instance: Node,
	player_wins_endpoint: bool,
	failures: Array[String]
) -> Dictionary:
	instance.call("_ensure_built")
	instance.call("_on_guardian_choice", "hive.vein_mother")
	_run_current_battle(instance, true, failures)

	var session: RefCounted = instance.get("_session")
	var first_reward_id := _first_id(session.get_first_reward_choices(), "modifier_id")
	instance.call("_on_first_reward_choice", first_reward_id)
	_run_current_battle(instance, true, failures)

	var shop_id := _first_id(session.get_shop_choices(), "modifier_id")
	instance.call("_on_shop_purchase_choice", shop_id)
	instance.call("_on_rest_choice", true)
	_run_current_battle(instance, true, failures)
	_run_current_battle(instance, true, failures)

	var second_reward_id := _first_id(session.get_second_reward_choices(), "modifier_id")
	instance.call("_on_second_reward_choice", second_reward_id)
	_run_current_battle(instance, true, failures)

	instance.call("_on_endpoint_rest_choice", true)
	_run_current_battle(instance, player_wins_endpoint, failures)

	return session.get_run_summary()


func _run_current_battle(
	instance: Node,
	player_wins: bool,
	failures: Array[String]
) -> void:
	var session: RefCounted = instance.get("_session")
	var target_state := "player_win" if player_wins else "player_loss"
	for _index in range(240):
		if not bool(instance.get("_battle_running")):
			return
		instance.call("_advance_battle", 0.25)
		if bool(instance.get("_battle_running")):
			session.battlefield_model.resolve_battle_result(target_state)
			instance.call("_advance_battle", 0.01)

	failures.append("Playable battle did not reach terminal state from formal battlefield result")


func _check_completed_playable_contract(instance: Node, failures: Array[String]) -> void:
	var audio_counts: Dictionary = instance.get("_audio_cue_counts")
	for cue_id in REQUIRED_AUDIO_CUES:
		if int(audio_counts.get(cue_id, 0)) <= 0:
			failures.append("Playable session missing audio cue: %s" % cue_id)

	var transition_beats: Array = instance.get("_transition_beats")
	for beat_id in REQUIRED_TRANSITION_BEATS:
		if not transition_beats.has(beat_id):
			failures.append("Playable session missing transition beat: %s" % beat_id)

	var phase_mismatches: Array = instance.get("_phase_status_mismatches")
	if not phase_mismatches.is_empty():
		failures.append("Playable session phase/status mismatches: %s" % str(phase_mismatches))


func _check_player_choice_telemetry(result: Dictionary, failures: Array[String]) -> void:
	var telemetry: Dictionary = result.get("telemetry", {})
	if str(telemetry.get("playable.guardian_choice_source", "")) != "player":
		failures.append("Guardian choice was not recorded as player-facing")
	if str(telemetry.get("playable.first_reward_choice_source", "")) != "player":
		failures.append("First reward was not recorded as player-facing")
	if str(telemetry.get("playable.shop_choice_source", "")) != "player":
		failures.append("Shop choice was not recorded as player-facing")
	if str(telemetry.get("playable.rest_choice_source", "")) != "player":
		failures.append("Rest choice was not recorded as player-facing")
	if str(telemetry.get("playable.second_reward_choice_source", "")) != "player":
		failures.append("Second reward was not recorded as player-facing")


func _check_result_reaches_page(
	expected_outcome: String,
	result: Dictionary,
	failures: Array[String]
) -> void:
	var flow: Array = result.get("flow_history", [])
	for expected_step in REQUIRED_FLOW:
		if not flow.has(expected_step):
			failures.append("Playable %s flow missing step: %s" % [expected_outcome, expected_step])

	var result_page: Dictionary = result.get("result_page", {})
	for field in [
		"chosen_guardian",
		"main_axis",
		"key_rewards",
		"shop_rest_choice",
		"counter_target",
		"deploy_lane_impact",
		"endpoint_payoff_or_break_reason",
		"next_run_watch_tag",
	]:
		if str(result_page.get(field, "")).is_empty():
			failures.append("Playable %s result page missing field: %s" % [
				expected_outcome,
				field,
			])

	var telemetry: Dictionary = result.get("telemetry", {})
	if str(telemetry.get("endpoint.outcome", "")) != expected_outcome:
		failures.append("Playable result outcome was not %s" % expected_outcome)

	_check_phase2_playable_readability(expected_outcome, result, failures)


func _check_phase2_playable_readability(
	expected_outcome: String,
	result: Dictionary,
	failures: Array[String]
) -> void:
	var battle_records: Dictionary = result.get("battle_readability_records", {})
	if not battle_records.has("battle_1"):
		failures.append("Playable %s missing Battle 1 readability record" % expected_outcome)
	else:
		var battle1: Dictionary = battle_records["battle_1"]
		for field in ["machine_component", "queue_effect", "queue_head", "selected_deploy_lane", "battlefield_outcome"]:
			if str(battle1.get(field, "")).is_empty():
				failures.append("Playable %s Battle 1 readability missing %s" % [expected_outcome, field])

	var first_reward_commitment: Dictionary = result.get("first_reward_commitment", {})
	for field in ["axis", "machine_component", "queue_effect", "next_battle_watch"]:
		if str(first_reward_commitment.get(field, "")).is_empty():
			failures.append("Playable %s first reward commitment missing %s" % [expected_outcome, field])

	var next_battle_causality: Dictionary = result.get("next_battle_causality", {})
	for field in ["committed_axis", "queue_effect_changed", "next_watch_target", "observed_battlefield_signal"]:
		if str(next_battle_causality.get(field, "")).is_empty():
			failures.append("Playable %s next-battle causality missing %s" % [expected_outcome, field])

	var queue_to_lane_bridge: Dictionary = result.get("queue_to_lane_bridge", {})
	for field in ["queue_head", "current_deploy_lane", "predicted_deploy_lane", "already_deployed_rule"]:
		if str(queue_to_lane_bridge.get(field, "")).is_empty():
			failures.append("Playable %s queue-to-lane bridge missing %s" % [expected_outcome, field])

	var result_recap: Dictionary = result.get("result_machine_cause_recap", {})
	for field in [
		"main_axis",
		"most_impactful_reward",
		"key_battlefield_turn",
		"weakest_link",
		"enemy_counter_impact",
		"next_run_suggestion",
	]:
		if str(result_recap.get(field, "")).is_empty():
			failures.append("Playable %s result recap missing %s" % [expected_outcome, field])


func _instantiate_playable(failures: Array[String]) -> Node:
	if not ResourceLoader.exists(SCENE_PATH):
		failures.append("Missing playable session scene: %s" % SCENE_PATH)
		return null

	var packed := ResourceLoader.load(SCENE_PATH)
	if not packed is PackedScene:
		failures.append("Playable session scene did not load as PackedScene")
		return null

	var instance := (packed as PackedScene).instantiate()
	if instance == null:
		failures.append("Playable session scene could not instantiate")
	else:
		root.add_child(instance)
		await process_frame
	return instance


func _free_test_instance(instance: Node) -> void:
	if instance == null or not is_instance_valid(instance):
		return
	var parent := instance.get_parent()
	if parent != null:
		parent.remove_child(instance)
	instance.free()
	await process_frame


func _has_required_runtime_children(node: Node) -> bool:
	for property_name in [
		"_phase_label",
		"_status_label",
		"_choice_panel",
		"_battle_page",
		"_simulation_speed_bar",
		"_post_battle_page",
		"_post_battle_list",
		"_machine_view",
		"_bridge_panel",
		"_battlefield_view",
		"_result_list",
	]:
		if node.get(property_name) == null:
			return false
	return true


func _check_player_facing_contract_text(node: Node, failures: Array[String]) -> void:
	var texts: Array[String] = []
	_collect_visible_text(node, texts)
	var joined := "\n".join(texts)
	for required_text in [
		"选择守护者契约",
		"选择本局机器偏向与基地兜底方式",
		"签订契约，开始 Battle 1",
	]:
		if not joined.contains(required_text):
			failures.append("Guardian Contract missing player-facing text: %s" % required_text)


func _check_guardian_contract_is_standalone(instance: Node, failures: Array[String]) -> void:
	var contract_page = instance.get("_contract_page")
	var run_page = instance.get("_run_page")
	if contract_page == null:
		failures.append("Guardian Contract page container is missing")
	elif contract_page is CanvasItem and not (contract_page as CanvasItem).visible:
		failures.append("Guardian Contract page is not visible before contract choice")
	if run_page == null:
		failures.append("Battle run page container is missing")
	elif run_page is CanvasItem and (run_page as CanvasItem).visible:
		failures.append("Battle run page is visible before Guardian Contract is signed")

	var texts: Array[String] = []
	_collect_visible_text(instance, texts)
	var joined := "\n".join(texts)
	for battle_text in [
		"Queue / Deploy Bridge",
		"当前出兵口",
		"部署路线",
		"战斗结果会在战斗结束后显示",
	]:
		if joined.contains(battle_text):
			failures.append("Guardian Contract screen leaks Battle Screen text: %s" % battle_text)


func _check_battle_screen_contract(instance: Node, failures: Array[String]) -> void:
	instance.call("_on_guardian_choice", "hive.vein_mother")
	await process_frame
	var contract_page = instance.get("_contract_page")
	var run_page = instance.get("_run_page")
	if contract_page is CanvasItem and (contract_page as CanvasItem).visible:
		failures.append("Guardian Contract page remains visible after contract choice")
	if run_page is CanvasItem and not (run_page as CanvasItem).visible:
		failures.append("Battle run page is not visible after Guardian Contract is signed")
	var bridge_panel = instance.get("_bridge_panel")
	if bridge_panel == null:
		failures.append("Battle Screen missing Queue / Deploy Bridge panel")
	var bridge_connector = instance.get("_bridge_connector_overlay")
	if bridge_connector == null:
		failures.append("Battle Screen missing Bridge-to-spawn connector overlay")
	var action_panel = instance.get("_action_panel")
	if action_panel is CanvasItem and (action_panel as CanvasItem).visible:
		failures.append("Battle Screen still exposes a fourth action/instruction panel")
	var result_panel = instance.get("_result_panel")
	if result_panel is CanvasItem and (result_panel as CanvasItem).visible:
		failures.append("Battle Screen still exposes the result strip before battle result")
	if _contains_slider(instance):
		failures.append("Player-facing flow exposes development sliders")
	_check_simulation_speed_control(instance, failures)
	var battlefield_view = instance.get("_battlefield_view")
	if battlefield_view == null:
		failures.append("Battle Screen missing battlefield view")
		return

	var snapshot: Dictionary = battlefield_view.call("get_player_facing_contract_snapshot")
	if str(snapshot.get("selected_spawn_port", "")) != "Mid":
		failures.append("Battle Screen does not expose Mid as selected spawn port")
	if str(snapshot.get("bridge_target", "")) != "Mid":
		failures.append("Queue Bridge does not target selected Mid spawn port")
	if not bool(snapshot.get("guardian_separate_from_spawn_ports", false)):
		failures.append("Guardian is not separated from spawn ports by a base buffer")
	if int(snapshot.get("spawn_port_count", 0)) != 3:
		failures.append("Battle Screen must expose exactly 3 player-side spawn ports")

	if bridge_connector != null and bridge_connector.has_method("get_contract_snapshot"):
		var connector_snapshot: Dictionary = bridge_connector.call("get_contract_snapshot")
		if str(connector_snapshot.get("selected_lane", "")) != "Mid":
			failures.append("Bridge connector does not start on selected Mid lane")
		if not bool(connector_snapshot.get("source_is_bridge_panel", false)):
			failures.append("Bridge connector source is not the Bridge panel")
		if not bool(connector_snapshot.get("target_is_battlefield_spawn_port", false)):
			failures.append("Bridge connector target is not a battlefield spawn port")
		if not bool(connector_snapshot.get("crosses_from_bridge_to_battlefield", false)):
			failures.append("Bridge connector does not cross from Bridge panel to battlefield")

	instance.call("_on_lane_clicked", "Right")
	await process_frame
	if bridge_connector != null and bridge_connector.has_method("get_contract_snapshot"):
		var right_connector_snapshot: Dictionary = bridge_connector.call("get_contract_snapshot")
		if str(right_connector_snapshot.get("selected_lane", "")) != "Right":
			failures.append("Bridge connector target does not update after lane click")


func _check_simulation_speed_control(instance: Node, failures: Array[String]) -> void:
	var speed_bar = instance.get("_simulation_speed_bar")
	if speed_bar == null:
		failures.append("Battle Screen missing global simulation speed control")
	var speed_buttons: Dictionary = instance.get("_simulation_speed_buttons")
	for speed_text in ["0.5x", "1x", "2x", "4x"]:
		var texts: Array[String] = []
		_collect_visible_text(instance, texts)
		if not "\n".join(texts).contains(speed_text):
			failures.append("Global simulation speed control missing option: %s" % speed_text)
	if abs(float(instance.get("_simulation_speed_multiplier")) - 1.0) > 0.001:
		failures.append("Global simulation speed should default to 1x")

	var button_1x := speed_buttons.get(1.0) as Button
	if button_1x == null or not button_1x.button_pressed:
		failures.append("Global simulation speed 1x button is not selected by default")

	var before_elapsed := float(instance.get("_battle_elapsed"))
	var session: RefCounted = instance.get("_session")
	var before_machine_time := float(session.machine_model.battle_time_seconds)
	instance.call("_set_simulation_speed_multiplier", 0.5)
	instance.call("_advance_battle", 0.1)
	var half_speed_delta := float(instance.get("_battle_elapsed")) - before_elapsed
	var half_machine_delta := float(session.machine_model.battle_time_seconds) - before_machine_time
	if abs(half_speed_delta - 0.13) > 0.03:
		failures.append("0.5x speed did not halve battle timeline step")
	if abs(half_machine_delta - half_speed_delta) > 0.03:
		failures.append("0.5x speed did not apply to ball machine simulation")

	before_elapsed = float(instance.get("_battle_elapsed"))
	before_machine_time = float(session.machine_model.battle_time_seconds)
	instance.call("_set_simulation_speed_multiplier", 4.0)
	instance.call("_advance_battle", 0.1)
	var four_speed_delta := float(instance.get("_battle_elapsed")) - before_elapsed
	var four_machine_delta := float(session.machine_model.battle_time_seconds) - before_machine_time
	if abs(four_speed_delta - 1.04) > 0.05:
		failures.append("4x speed did not quadruple battle timeline step")
	if abs(four_machine_delta - four_speed_delta) > 0.05:
		failures.append("4x speed did not apply to ball machine simulation")

	var button_4x := speed_buttons.get(4.0) as Button
	if button_4x == null or not button_4x.button_pressed:
		failures.append("Global simulation speed 4x button does not reflect selected speed")


func _check_post_battle_pages_are_primary(instance: Node, failures: Array[String]) -> void:
	instance.call("_show_first_reward_choices")
	_check_primary_post_battle_page(
		instance,
		"First Reward",
		["第一次奖励", "战斗胜利"],
		failures
	)

	instance.call("_show_shop_choices")
	_check_primary_post_battle_page(
		instance,
		"Shop / Gold / Rest",
		["商店 / 休整", "Gold"],
		failures
	)

	var session: RefCounted = instance.get("_session")
	var shop_id := _first_id(session.get_shop_choices(), "modifier_id")
	instance.call("_on_shop_purchase_choice", shop_id)
	_check_primary_post_battle_page(
		instance,
		"Rest",
		["休整", "恢复 20"],
		failures
	)

	session.build_result_page()
	instance.call("_show_result_page")
	_check_primary_post_battle_page(
		instance,
		"Result Page",
		["本局结算", "下一局观察"],
		failures
	)


func _check_primary_post_battle_page(
	instance: Node,
	page_label: String,
	required_texts: Array[String],
	failures: Array[String]
) -> void:
	var post_battle_page = instance.get("_post_battle_page")
	if post_battle_page == null:
		failures.append("%s missing post-battle page container" % page_label)
	elif post_battle_page is CanvasItem and not (post_battle_page as CanvasItem).visible:
		failures.append("%s is not shown as the primary post-battle page" % page_label)

	var battle_page = instance.get("_battle_page")
	if battle_page is CanvasItem and (battle_page as CanvasItem).visible:
		failures.append("%s still shows the Battle Screen beside the post-battle decision" % page_label)

	var action_panel = instance.get("_action_panel")
	if action_panel is CanvasItem and (action_panel as CanvasItem).visible:
		failures.append("%s still uses the obsolete left action panel" % page_label)

	var texts: Array[String] = []
	_collect_visible_text(instance, texts)
	var joined := "\n".join(texts)
	for required in required_texts:
		if not joined.contains(required):
			failures.append("%s missing primary page text: %s" % [page_label, required])
	for battle_text in ["Queue Bridge", "当前出兵口"]:
		if joined.contains(battle_text):
			failures.append("%s leaks Battle Screen text while post-battle page is active: %s" % [
				page_label,
				battle_text,
			])


func _contains_scroll_container(node: Node) -> bool:
	if node is ScrollContainer:
		return true
	for child in node.get_children():
		if child is Node and _contains_scroll_container(child):
			return true
	return false


func _contains_slider(node: Node) -> bool:
	if node is Slider:
		return true
	if node.name == "SizeControls":
		return true
	for child in node.get_children():
		if child is Node and _contains_slider(child):
			return true
	return false


func _check_no_forbidden_player_text(node: Node, label: String, failures: Array[String]) -> void:
	var texts: Array[String] = []
	_collect_visible_text(node, texts)
	var joined := "\n".join(texts)
	for forbidden in FORBIDDEN_PLAYER_TEXT:
		if joined.contains(forbidden):
			failures.append("%s exposes forbidden text: %s" % [label, forbidden])


func _collect_visible_text(node: Node, texts: Array[String]) -> void:
	if node is CanvasItem and not (node as CanvasItem).visible:
		return
	if node is Label:
		texts.append(str((node as Label).text))
	elif node is Button:
		texts.append(str((node as Button).text))
	for child in node.get_children():
		if child is Node:
			_collect_visible_text(child, texts)


func _first_id(items: Array, key: String) -> String:
	if items.is_empty():
		return ""
	return str((items[0] as Dictionary).get(key, ""))
