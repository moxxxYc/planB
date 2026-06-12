extends SceneTree

const RUN_SCENE_PATH: String = "res://scenes/run/mvp_run_session.tscn"

const REQUIRED_KEYS: Array[String] = [
	"guardian.choice_id",
	"guardian.choice_read",
	"guardian.outcome",
	"guardian.hp_pressure_events",
	"battle1.machine_chain_sample",
	"battle1.exposure_gate_snapshot",
	"battle1.deploy_lane_selection",
	"battle1.lane_danger_snapshot",
	"unit.visible_contribution_slots",
	"unit.key_queue_entries_by_slot",
	"unit.dominant_slot_share",
	"reward1.choice_id",
	"reward1.axis",
	"reward1.component_operation",
	"reward1.battlefield_expectation",
	"reward1.battlefield_result",
	"shop1.gold_before",
	"shop1.purchase_id",
	"shop1.purchase_role",
	"shop1.gold_after",
	"rest_windows",
	"rest.total_purchases",
	"rest.total_gold_spent",
	"rest.total_hp_restored",
	"rest.endpoint_relevance",
	"counter1.family",
	"counter1.target_component",
	"counter1.visible_effect",
	"counter1.response_link",
	"second_offer.current_axis",
	"second_offer.candidates",
	"second_offer.choice_id",
	"second_offer.choice_role",
	"endpoint.outcome",
	"endpoint.primary_axis_payoff",
	"endpoint.main_break_reason",
	"endpoint.next_run_watch_tag",
	"endpoint.deploy_lane_impact",
	"endpoint.guardian_hp",
	"session.decision_windows",
	"session.consecutive_no_explained_decision_battles",
]

var failures: Array[String] = []

func _initialize() -> void:
	var scene: PackedScene = load(RUN_SCENE_PATH)
	if scene == null:
		failures.append("Run session scene missing: %s" % RUN_SCENE_PATH)
		_finish()
		return

	var run: Node = scene.instantiate()
	if run == null:
		failures.append("Could not instantiate run session scene.")
		_finish()
		return

	root.add_child(run)
	if _require_methods(run):
		_drive_full_run_to_final_result(run)
		_verify_required_learning_keys(run)
	root.remove_child(run)
	run.free()
	_finish()

func _drive_full_run_to_final_result(run: Node) -> void:
	run.call("select_guardian", "hive_acid_crown_mother")
	run.call("confirm_guardian")
	if not _expect_node(run, "battle_1"):
		return
	run.call("complete_current_battle_for_verifier", "Win")
	if not _expect_node(run, "reward_1"):
		return
	run.call("choose_reward_one", "slot_primer")
	if not _expect_node(run, "battle_2"):
		return
	run.call("complete_current_battle_for_verifier", "Win")
	if not _expect_node(run, "shop_1"):
		return
	run.call("buy_shop_item", "queue_brace")
	run.call("confirm_shop_and_rest")
	if not _expect_node(run, "battle_3"):
		return
	run.call("complete_current_battle_for_verifier", "Win")
	if not _expect_node(run, "rest_after_battle_3"):
		return
	run.call("confirm_shop_and_rest")
	if not _expect_node(run, "battle_4"):
		return
	run.call("complete_current_battle_for_verifier", "Win")
	if not _expect_node(run, "reward_2"):
		return
	run.call("choose_second_reward", "muster_pair")
	if not _expect_node(run, "battle_5"):
		return
	run.call("complete_current_battle_for_verifier", "Win")
	if not _expect_node(run, "endpoint_prep"):
		return
	run.call("confirm_endpoint_prep")
	if not _expect_node(run, "endpoint"):
		return
	run.call("complete_current_battle_for_verifier", "Win")
	_expect_node(run, "final_result")

func _verify_required_learning_keys(run: Node) -> void:
	if String(run.call("get_current_node_id")) != "final_result":
		failures.append("Complete learning record verifier must drive the run to Final Result.")
		return
	var record_variant: Variant = run.call("get_result_record")
	if not (record_variant is Dictionary):
		failures.append("get_result_record() must return a Dictionary at Final Result.")
		return
	var record: Dictionary = record_variant as Dictionary
	for key: String in REQUIRED_KEYS:
		if not record.has(key):
			failures.append("Final Result learning record missing required field: %s" % key)

func _expect_node(run: Node, expected: String) -> bool:
	var actual: String = String(run.call("get_current_node_id"))
	if actual != expected:
		failures.append("Expected run node %s, got %s." % [expected, actual])
		return false
	return true

func _require_methods(run: Node) -> bool:
	var has_all_methods: bool = true
	for method_name: String in [
		"select_guardian",
		"confirm_guardian",
		"complete_current_battle_for_verifier",
		"choose_reward_one",
		"buy_shop_item",
		"confirm_shop_and_rest",
		"choose_second_reward",
		"confirm_endpoint_prep",
		"get_current_node_id",
		"get_result_record",
	]:
		if not run.has_method(method_name):
			failures.append("Run scene missing method: %s" % method_name)
			has_all_methods = false
	return has_all_methods

func _finish() -> void:
	if failures.is_empty():
		print("verify_complete_learning_record: PASS")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
