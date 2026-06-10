extends SceneTree

const MODEL_PATH := "res://scripts/run/mvp_session_model.gd"
const DEBUG_PATH := "res://scripts/run/mvp_session_debug.gd"
const SCENE_PATH := "res://scenes/run/mvp_session_debug.tscn"

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

const REQUIRED_RESULT_FIELDS := [
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
]

const REQUIRED_TELEMETRY_FIELDS := [
	"guardian.choice_id",
	"guardian.outcome",
	"battle1.machine_chain_sample",
	"battle1.deploy_lane_selection",
	"phase2.battle_1.readability",
	"phase2.queue_to_lane_bridge",
	"phase2.first_reward_commitment",
	"phase2.next_battle_causality",
	"phase2.result_machine_cause_recap",
	"reward1.choice_id",
	"reward1.axis",
	"shop1.gold_before",
	"shop1.purchase_id",
	"counter1.family",
	"counter1.target_component",
	"counter1.visible_effect",
	"second_offer.current_axis",
	"second_offer.candidates",
	"endpoint.outcome",
	"endpoint.primary_axis_payoff",
	"endpoint.deploy_lane_impact",
	"endpoint.next_run_watch_tag",
]


func _init() -> void:
	var failures: Array[String] = []

	_check_paths(failures)
	if failures.is_empty():
		_check_model_full_run(failures)
		_check_debug_scene(failures)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	print("verify_mvp_session.gd passed: M3 complete session reaches real result telemetry")
	quit(0)


func _check_paths(failures: Array[String]) -> void:
	for path in [MODEL_PATH, DEBUG_PATH, SCENE_PATH]:
		if not ResourceLoader.exists(path):
			failures.append("Missing M3 resource path: %s" % path)


func _check_model_full_run(failures: Array[String]) -> void:
	var script := ResourceLoader.load(MODEL_PATH)
	if script == null:
		failures.append("Could not load M3 session model script")
		return

	var model = script.new()
	if model == null:
		failures.append("Could not instantiate M3 session model")
		return

	if not model.has_method("run_debug_win_session"):
		failures.append("M3 model missing run_debug_win_session()")
		return

	var result: Dictionary = model.run_debug_win_session("hive.vein_mother")
	if result.is_empty():
		failures.append("M3 debug win session returned empty result")
		return

	_check_flow(result, failures)
	_check_result_fields(result, failures)
	_check_telemetry_fields(result, failures)
	_check_phase2_readability_fields(result, failures)
	_check_counter_coverage(model, failures)


func _check_flow(result: Dictionary, failures: Array[String]) -> void:
	var flow: Array = result.get("flow_history", [])
	for expected_step in REQUIRED_FLOW:
		if not flow.has(expected_step):
			failures.append("M3 flow missing step: %s" % expected_step)


func _check_result_fields(result: Dictionary, failures: Array[String]) -> void:
	var result_page: Dictionary = result.get("result_page", {})
	for field in REQUIRED_RESULT_FIELDS:
		if not result_page.has(field):
			failures.append("M3 result page missing field: %s" % field)
		elif str(result_page[field]).is_empty():
			failures.append("M3 result page field is empty: %s" % field)


func _check_telemetry_fields(result: Dictionary, failures: Array[String]) -> void:
	var telemetry: Dictionary = result.get("telemetry", {})
	for field in REQUIRED_TELEMETRY_FIELDS:
		if not telemetry.has(field):
			failures.append("M3 telemetry missing checkpoint field: %s" % field)
		elif str(telemetry[field]).is_empty():
			failures.append("M3 telemetry checkpoint field is empty: %s" % field)


func _check_phase2_readability_fields(result: Dictionary, failures: Array[String]) -> void:
	var first_reward_commitment: Dictionary = result.get("first_reward_commitment", {})
	for field in ["axis", "machine_component", "queue_effect", "next_battle_watch"]:
		if str(first_reward_commitment.get(field, "")).is_empty():
			failures.append("Phase2 first reward commitment missing field: %s" % field)

	var next_battle_causality: Dictionary = result.get("next_battle_causality", {})
	for field in ["committed_axis", "queue_effect_changed", "next_watch_target", "observed_battlefield_signal"]:
		if str(next_battle_causality.get(field, "")).is_empty():
			failures.append("Phase2 next battle causality missing field: %s" % field)

	var queue_to_lane_bridge: Dictionary = result.get("queue_to_lane_bridge", {})
	for field in ["queue_head", "current_deploy_lane", "predicted_deploy_lane", "already_deployed_rule"]:
		if str(queue_to_lane_bridge.get(field, "")).is_empty():
			failures.append("Phase2 queue-to-lane bridge missing field: %s" % field)

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
			failures.append("Phase2 result recap missing field: %s" % field)


func _check_counter_coverage(model, failures: Array[String]) -> void:
	if not model.has_method("run_counter_debug_cases"):
		failures.append("M3 model missing run_counter_debug_cases()")
		return

	var cases: Array = model.run_counter_debug_cases()
	var seen := {}
	for counter_case in cases:
		var counter_id := str(counter_case.get("counter_id", ""))
		seen[counter_id] = true
		for field in ["warning", "target_component", "visible_effect", "log_record"]:
			if str(counter_case.get(field, "")).is_empty():
				failures.append("Counter %s missing %s" % [counter_id, field])

	for counter_id in ["pool_polluter", "echo_breaker", "stagger_punisher"]:
		if not seen.has(counter_id):
			failures.append("M3 counter debug coverage missing %s" % counter_id)


func _check_debug_scene(failures: Array[String]) -> void:
	var packed := ResourceLoader.load(SCENE_PATH)
	if not packed is PackedScene:
		failures.append("M3 debug scene did not load as PackedScene")
		return

	var instance := (packed as PackedScene).instantiate()
	if instance == null:
		failures.append("M3 debug scene could not instantiate")
		return

	if not instance.has_method("verify_scene_build"):
		failures.append("M3 debug scene missing verify_scene_build()")
	elif not instance.verify_scene_build():
		failures.append("M3 debug scene UI build failed")

	if not instance.has_method("run_full_debug_session_for_verification"):
		failures.append("M3 debug scene missing run_full_debug_session_for_verification()")
	else:
		var result: Dictionary = instance.run_full_debug_session_for_verification()
		if result.get("result_page", {}).is_empty():
			failures.append("M3 debug scene did not reach result page")

	instance.free()
