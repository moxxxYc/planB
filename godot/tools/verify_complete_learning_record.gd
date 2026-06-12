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
	_verify_learning_field_shapes(record)

func _verify_learning_field_shapes(record: Dictionary) -> void:
	_verify_machine_chain_sample(record)
	_verify_exposure_gate_snapshot(record)
	_verify_non_empty_dictionary_field(record, "unit.key_queue_entries_by_slot")
	_verify_non_empty_array_or_dictionary_field(record, "rest_windows")
	_verify_non_empty_field(record, "endpoint.outcome")
	_verify_non_empty_field(record, "endpoint.guardian_hp")
	_verify_non_empty_field(record, "endpoint.next_run_watch_tag")
	_verify_non_empty_array_field(record, "second_offer.candidates")
	_verify_non_empty_array_field(record, "session.decision_windows")

func _verify_machine_chain_sample(record: Dictionary) -> void:
	if not record.has("battle1.machine_chain_sample"):
		return
	var value: Variant = record.get("battle1.machine_chain_sample")
	if value is String:
		var text: String = String(value)
		if not _text_has_all(text, ["Pool", "Tuning", "Unit", "Queue"]):
			failures.append("battle1.machine_chain_sample string must contain Pool/Tuning/Unit/Queue.")
		return
	if value is Dictionary:
		var chain: Dictionary = value as Dictionary
		if chain.is_empty():
			failures.append("battle1.machine_chain_sample Dictionary must be non-empty.")
			return
		if not (
			_has_any_key(chain, ["pool", "pool_entry", "Pool"])
			and _has_any_key(chain, ["tuning", "tuning_result", "Tuning"])
			and _has_any_key(chain, ["unit", "unit_slot", "Unit"])
			and _has_any_key(chain, ["queue", "queue_entry", "Queue"])
		) and not _text_has_all(JSON.stringify(chain), ["Pool", "Tuning", "Unit", "Queue"]):
			failures.append("battle1.machine_chain_sample Dictionary must structure Pool/Tuning/Unit/Queue evidence.")
		return
	if value is Array:
		var chain_array: Array = value as Array
		if chain_array.is_empty() or not _text_has_all(JSON.stringify(chain_array), ["Pool", "Tuning", "Unit", "Queue"]):
			failures.append("battle1.machine_chain_sample Array must be non-empty and include Pool/Tuning/Unit/Queue evidence.")
		return
	failures.append("battle1.machine_chain_sample must be a structured Dictionary/Array or descriptive String.")

func _verify_exposure_gate_snapshot(record: Dictionary) -> void:
	if not record.has("battle1.exposure_gate_snapshot"):
		return
	var value: Variant = record.get("battle1.exposure_gate_snapshot")
	if not (value is Dictionary):
		failures.append("battle1.exposure_gate_snapshot must be a Dictionary.")
		return
	var snapshot: Dictionary = value as Dictionary
	if snapshot.is_empty():
		failures.append("battle1.exposure_gate_snapshot must be non-empty.")
		return
	for required_time: float in [0.0, 12.0, 24.0, 30.0]:
		if not _has_snapshot_time(snapshot, required_time):
			failures.append("battle1.exposure_gate_snapshot missing required time t_%.0f." % required_time)

func _has_snapshot_time(snapshot: Dictionary, required_time: float) -> bool:
	for key: String in [
		"t_%d" % int(required_time),
		str(int(required_time)),
		"%.1f" % required_time,
		"time_%d" % int(required_time),
	]:
		if snapshot.has(key):
			return true
	var snapshots_variant: Variant = snapshot.get("snapshots", [])
	if snapshots_variant is Array:
		for entry_variant: Variant in snapshots_variant:
			if entry_variant is Dictionary:
				var entry: Dictionary = entry_variant as Dictionary
				var time_value: float = float(entry.get("time", entry.get("battle_elapsed", -999.0)))
				if absf(time_value - required_time) <= 0.05:
					return true
	return false

func _verify_non_empty_dictionary_field(record: Dictionary, key: String) -> void:
	if not record.has(key):
		return
	var value: Variant = record.get(key)
	if not (value is Dictionary) or (value as Dictionary).is_empty():
		failures.append("%s must be a non-empty Dictionary." % key)

func _verify_non_empty_array_or_dictionary_field(record: Dictionary, key: String) -> void:
	if not record.has(key):
		return
	var value: Variant = record.get(key)
	if value is Array and not (value as Array).is_empty():
		return
	if value is Dictionary and not (value as Dictionary).is_empty():
		return
	failures.append("%s must be a non-empty Array or Dictionary." % key)

func _verify_non_empty_array_field(record: Dictionary, key: String) -> void:
	if not record.has(key):
		return
	var value: Variant = record.get(key)
	if not (value is Array) or (value as Array).is_empty():
		failures.append("%s must be a non-empty Array." % key)

func _verify_non_empty_field(record: Dictionary, key: String) -> void:
	if not record.has(key):
		return
	var value: Variant = record.get(key)
	if value == null:
		failures.append("%s must be non-empty." % key)
	elif value is String and String(value).strip_edges().is_empty():
		failures.append("%s must be non-empty." % key)
	elif value is Array and (value as Array).is_empty():
		failures.append("%s must be non-empty." % key)
	elif value is Dictionary and (value as Dictionary).is_empty():
		failures.append("%s must be non-empty." % key)

func _has_any_key(record: Dictionary, keys: Array[String]) -> bool:
	for key: String in keys:
		if record.has(key):
			return true
	return false

func _text_has_all(text: String, needles: Array[String]) -> bool:
	for needle: String in needles:
		if not text.contains(needle):
			return false
	return true

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
