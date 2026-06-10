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
]


func _init() -> void:
	var failures: Array[String] = []

	_check_scene_loads(failures)
	if failures.is_empty():
		_check_running_battle_is_not_forced_to_win(failures)
		_check_playable_path_reaches_result(failures)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	print("verify_playable_session.gd passed: formal playable Win/Loss paths verified")
	quit(0)


func _check_scene_loads(failures: Array[String]) -> void:
	var instance := _instantiate_playable(failures)
	if instance == null:
		return

	instance.call("_ensure_built")
	if not _has_required_runtime_children(instance):
		failures.append("Playable session scene is missing required player-facing UI regions")
	if _contains_scroll_container(instance):
		failures.append("Playable layout still uses scroll containers in the default window")
	_check_no_forbidden_player_text(instance, "initial playable screen", failures)
	instance.free()


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
	var win_instance := _instantiate_playable(failures)
	if win_instance == null:
		return

	_check_terminal_battle_completes_immediately(win_instance, failures)
	win_instance.free()

	win_instance = _instantiate_playable(failures)
	if win_instance == null:
		return
	var result: Dictionary = _run_player_session(win_instance, true, failures)
	_check_result_reaches_page("win", result, failures)
	_check_player_choice_telemetry(result, failures)
	_check_completed_playable_contract(win_instance, failures)
	_check_no_forbidden_player_text(win_instance, "completed win screen", failures)
	win_instance.free()

	var loss_instance := _instantiate_playable(failures)
	if loss_instance == null:
		return
	var loss_result: Dictionary = _run_player_session(loss_instance, false, failures)
	_check_result_reaches_page("loss", loss_result, failures)
	_check_completed_playable_contract(loss_instance, failures)
	_check_no_forbidden_player_text(loss_instance, "completed loss screen", failures)
	loss_instance.free()


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
	return instance


func _has_required_runtime_children(root: Node) -> bool:
	for property_name in [
		"_phase_label",
		"_status_label",
		"_choice_panel",
		"_machine_view",
		"_battlefield_view",
		"_result_list",
	]:
		if root.get(property_name) == null:
			return false
	return true


func _contains_scroll_container(root: Node) -> bool:
	if root is ScrollContainer:
		return true
	for child in root.get_children():
		if child is Node and _contains_scroll_container(child):
			return true
	return false


func _check_no_forbidden_player_text(root: Node, label: String, failures: Array[String]) -> void:
	var texts: Array[String] = []
	_collect_visible_text(root, texts)
	var joined := "\n".join(texts)
	for forbidden in FORBIDDEN_PLAYER_TEXT:
		if joined.contains(forbidden):
			failures.append("%s exposes forbidden text: %s" % [label, forbidden])


func _collect_visible_text(root: Node, texts: Array[String]) -> void:
	if root is CanvasItem and not (root as CanvasItem).visible:
		return
	if root is Label:
		texts.append(str((root as Label).text))
	elif root is Button:
		texts.append(str((root as Button).text))
	for child in root.get_children():
		if child is Node:
			_collect_visible_text(child, texts)


func _first_id(items: Array, key: String) -> String:
	if items.is_empty():
		return ""
	return str((items[0] as Dictionary).get(key, ""))
