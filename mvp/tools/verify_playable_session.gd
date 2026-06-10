extends SceneTree

const SCENE_PATH := "res://scenes/run/mvp_playable_session.tscn"

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


func _init() -> void:
	var failures: Array[String] = []

	_check_scene_loads(failures)
	if failures.is_empty():
		_check_playable_path_reaches_result(failures)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	print("verify_playable_session.gd passed: feel fixes, Win/Loss result pages verified")
	quit(0)


func _check_scene_loads(failures: Array[String]) -> void:
	if not ResourceLoader.exists(SCENE_PATH):
		failures.append("Missing playable session scene: %s" % SCENE_PATH)
		return

	var packed := ResourceLoader.load(SCENE_PATH)
	if not packed is PackedScene:
		failures.append("Playable session scene did not load as PackedScene")
		return

	var instance := (packed as PackedScene).instantiate()
	if instance == null:
		failures.append("Playable session scene could not instantiate")
		return

	if not instance.has_method("verify_scene_build"):
		failures.append("Playable session scene missing verify_scene_build()")
	elif not instance.verify_scene_build():
		failures.append("Playable session UI build failed")

	instance.free()


func _check_playable_path_reaches_result(failures: Array[String]) -> void:
	var packed := ResourceLoader.load(SCENE_PATH)
	var instance := (packed as PackedScene).instantiate()

	if not instance.has_method("run_minimal_player_session_for_verification"):
		failures.append("Playable session missing run_minimal_player_session_for_verification()")
		instance.free()
		return
	if not instance.has_method("run_loss_player_session_for_verification"):
		failures.append("Playable session missing run_loss_player_session_for_verification()")
		instance.free()
		return
	if not instance.has_method("get_playable_feel_summary"):
		failures.append("Playable session missing get_playable_feel_summary()")
		instance.free()
		return

	_check_initial_feel_contract(instance, failures)

	var result: Dictionary = instance.run_minimal_player_session_for_verification()
	_check_result_reaches_page("win", result, failures)
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

	_check_completed_feel_contract(instance, failures)

	instance.free()

	var loss_instance := (packed as PackedScene).instantiate()
	var loss_result: Dictionary = loss_instance.run_loss_player_session_for_verification()
	_check_result_reaches_page("loss", loss_result, failures)
	loss_instance.free()


func _check_initial_feel_contract(instance: Node, failures: Array[String]) -> void:
	var summary: Dictionary = instance.get_playable_feel_summary()
	if bool(summary.get("uses_scroll_containers", true)):
		failures.append("Playable layout still uses scroll containers in the default window")
	if bool(summary.get("has_visible_debug_framing", true)):
		failures.append("Playable screen still exposes debug framing text")
	if int(summary.get("default_viewport_width", 0)) != 1600:
		failures.append("Playable feel summary did not report the default 1600px viewport")
	if int(summary.get("default_viewport_height", 0)) != 900:
		failures.append("Playable feel summary did not report the default 900px viewport")


func _check_completed_feel_contract(instance: Node, failures: Array[String]) -> void:
	var summary: Dictionary = instance.get_playable_feel_summary()
	var audio_counts: Dictionary = summary.get("audio_cue_counts", {})
	for cue_id in REQUIRED_AUDIO_CUES:
		if int(audio_counts.get(cue_id, 0)) <= 0:
			failures.append("Playable session missing audio cue: %s" % cue_id)

	var transition_beats: Array = summary.get("transition_beats", [])
	for beat_id in REQUIRED_TRANSITION_BEATS:
		if not transition_beats.has(beat_id):
			failures.append("Playable session missing transition beat: %s" % beat_id)

	var phase_mismatches: Array = summary.get("phase_status_mismatches", [])
	if not phase_mismatches.is_empty():
		failures.append("Playable session phase/status mismatches: %s" % str(phase_mismatches))

	if bool(summary.get("has_visible_debug_framing", true)):
		failures.append("Playable screen exposes debug framing after full session")


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
