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
	_drive_to_final_result(run)
	_verify_record(run)
	_verify_visible_text(run)
	root.remove_child(run)
	run.free()
	_finish()

func _drive_to_final_result(run: Node) -> void:
	run.call("select_guardian", "hive_acid_crown_mother")
	run.call("confirm_guardian")
	run.call("complete_current_battle_for_verifier", "Win")
	run.call("choose_reward_one", "slot_primer")
	run.call("complete_current_battle_for_verifier", "Win")
	run.call("confirm_shop_and_rest")
	run.call("complete_current_battle_for_verifier", "Win")
	run.call("confirm_shop_and_rest")
	run.call("complete_current_battle_for_verifier", "Win")
	run.call("choose_second_reward", "muster_pair")
	run.call("complete_current_battle_for_verifier", "Win")
	run.call("confirm_endpoint_prep")
	run.call("complete_current_battle_for_verifier", "Loss")

func _verify_record(run: Node) -> void:
	var record: Dictionary = run.call("get_result_record") as Dictionary
	for key: String in [
		"guardian.choice_id",
		"guardian.outcome",
		"guardian.hp_pressure_events",
		"battle1.machine_chain_sample",
		"battle1.deploy_lane_selection",
		"unit.visible_contribution_slots",
		"unit.key_queue_entries_by_slot",
		"reward1.choice_id",
		"reward1.axis",
		"reward1.component_operation",
		"reward1.battlefield_result",
		"shop1.purchase_id",
		"shop1.purchase_role",
		"counter1.family",
		"counter1.target_component",
		"counter1.visible_effect",
		"counter1.response_link",
		"second_offer.current_axis",
		"second_offer.candidates",
		"second_offer.choice_id",
		"second_offer.choice_role",
		"counter2.family",
		"endpoint.outcome",
		"endpoint.primary_axis_payoff",
		"endpoint.main_break_reason",
		"endpoint.next_run_watch_tag",
		"endpoint.deploy_lane_impact",
		"endpoint.guardian_hp",
		"rest.opportunity_cost",
		"session.decision_windows",
	]:
		if not record.has(key):
			failures.append("Final result missing learning field: %s" % key)

func _verify_visible_text(run: Node) -> void:
	var summary: String = String(run.call("get_result_summary_text"))
	for text: String in ["最终结果", "主要机器轴", "关键选择", "敌方反制", "部署路线影响", "守护者压力", "终点战结论", "休整机会成本", "下一局观察"]:
		if not _tree_contains_text(run, text) and not summary.contains(text):
			failures.append("Final Result missing visible Chinese label: %s" % text)
	for forbidden: String in [
		"M4 到此结束",
		"M5",
		"M6",
		"DEBUG",
		"后续里程碑",
		"lane leak watch",
		"queue gap",
		"Pool Pocket",
		"Prime Charge",
		"Slot Primer",
		"Front Recycle",
		"Surge Buffer",
		"Queue Brace",
		"Junk Sieve",
		"Muster Pair",
		"Echo Latch",
		"Pool Polluter",
		"Echo Breaker",
		"Stagger Punisher",
		"Raider",
		"Guardian ",
	]:
		if _tree_contains_text(run, forbidden) or summary.contains(forbidden):
			failures.append("Final Result contains implementation-state text: %s" % forbidden)

func _tree_contains_text(node: Node, needle: String) -> bool:
	if node is Label and String((node as Label).text).contains(needle):
		return true
	if node is Button and String((node as Button).text).contains(needle):
		return true
	for child: Node in node.get_children():
		if _tree_contains_text(child, needle):
			return true
	return false

func _finish() -> void:
	if failures.is_empty():
		print("verify_endpoint_result_fields: PASS")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
