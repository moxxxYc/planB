extends SceneTree

const RUN_SCENE_PATH: String = "res://scenes/run/mvp_run_session.tscn"

var failures: Array[String] = []

func _initialize() -> void:
	var scene: PackedScene = load(RUN_SCENE_PATH)
	if scene == null:
		failures.append("Run session scene missing.")
		_finish()
		return
	var run: Node = scene.instantiate()
	root.add_child(run)
	_verify_full_flow(run)
	root.remove_child(run)
	run.free()
	_finish()

func _verify_full_flow(run: Node) -> void:
	for method_name: String in [
		"select_guardian",
		"confirm_guardian",
		"complete_current_battle_for_verifier",
		"choose_reward_one",
		"confirm_shop_and_rest",
		"choose_second_reward",
		"confirm_endpoint_prep",
		"get_current_node_id",
		"get_result_record",
		"get_result_summary_text",
	]:
		if not run.has_method(method_name):
			failures.append("Run scene missing method: %s" % method_name)
			return

	var session: RunSessionModel = run.get("session") as RunSessionModel
	for node_id: String in ["battle_5", "endpoint_prep", "endpoint", "final_result"]:
		if session == null or not session.has_run_node(node_id):
			failures.append("RunSessionModel missing node: %s" % node_id)

	run.call("select_guardian", "hive_vein_mother")
	run.call("confirm_guardian")
	_expect_node(run, "battle_1")
	run.call("complete_current_battle_for_verifier", "Win")
	_expect_node(run, "reward_1")
	run.call("choose_reward_one", "prime_charge")
	_expect_node(run, "battle_2")
	run.call("complete_current_battle_for_verifier", "Win")
	_expect_node(run, "shop_1")
	run.call("confirm_shop_and_rest")
	_expect_node(run, "battle_3")
	run.call("complete_current_battle_for_verifier", "Win")
	_expect_node(run, "rest_after_battle_3")
	run.call("confirm_shop_and_rest")
	_expect_node(run, "battle_4")
	var gold_before_battle_four: int = int(run.call("get_gold")) if run.has_method("get_gold") else -1
	run.call("complete_current_battle_for_verifier", "Win")
	_expect_node(run, "reward_2")
	var gold_after_battle_four: int = int(run.call("get_gold")) if run.has_method("get_gold") else -2
	if gold_before_battle_four != gold_after_battle_four:
		failures.append("Battle 4 should grant 0 Gold.")
	run.call("choose_second_reward", "echo_latch")
	_expect_node(run, "battle_5")
	var marker_text: String = String(run.call("get_battle_modifier_marker_text")) if run.has_method("get_battle_modifier_marker_text") else ""
	if not marker_text.contains("Echo 锁存"):
		failures.append("Second Reward should be applied to Battle 5 machine markers.")
	run.call("complete_current_battle_for_verifier", "Win")
	_expect_node(run, "endpoint_prep")
	run.call("confirm_endpoint_prep")
	_expect_node(run, "endpoint")
	run.call("complete_current_battle_for_verifier", "Win")
	_expect_node(run, "final_result")

	var record: Dictionary = run.call("get_result_record") as Dictionary
	for key: String in [
		"endpoint.outcome",
		"endpoint.primary_axis_payoff",
		"endpoint.main_break_reason",
		"endpoint.next_run_watch_tag",
		"endpoint.deploy_lane_impact",
		"endpoint.guardian_hp",
	]:
		if not record.has(key):
			failures.append("Final result missing required field: %s" % key)
	var summary: String = String(run.call("get_result_summary_text"))
	if not summary.contains("下一局观察") or not summary.contains("终点战结论"):
		failures.append("Final Result screen should show endpoint conclusion and next-run watch text.")

func _expect_node(run: Node, expected: String) -> void:
	var actual: String = String(run.call("get_current_node_id"))
	if actual != expected:
		failures.append("Expected node %s, got %s." % [expected, actual])

func _finish() -> void:
	if failures.is_empty():
		print("verify_full_handoff_flow: PASS")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
