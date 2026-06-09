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

	print("verify_playable_session.gd passed: player-facing MVP session reaches result page")
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

	var result: Dictionary = instance.run_minimal_player_session_for_verification()
	var flow: Array = result.get("flow_history", [])
	for expected_step in REQUIRED_FLOW:
		if not flow.has(expected_step):
			failures.append("Playable flow missing step: %s" % expected_step)

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
			failures.append("Playable result page missing field: %s" % field)

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

	instance.free()
