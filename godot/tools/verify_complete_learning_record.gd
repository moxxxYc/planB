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

const NON_EMPTY_STRING_KEYS: Array[String] = [
	"guardian.choice_id",
	"guardian.choice_read",
	"guardian.outcome",
	"reward1.choice_id",
	"reward1.axis",
	"reward1.component_operation",
	"reward1.battlefield_expectation",
	"reward1.battlefield_result",
	"shop1.purchase_id",
	"shop1.purchase_role",
	"rest.endpoint_relevance",
	"counter1.family",
	"counter1.target_component",
	"counter1.visible_effect",
	"counter1.response_link",
	"second_offer.current_axis",
	"second_offer.choice_id",
	"second_offer.choice_role",
	"endpoint.outcome",
	"endpoint.primary_axis_payoff",
	"endpoint.main_break_reason",
	"endpoint.next_run_watch_tag",
	"endpoint.deploy_lane_impact",
	"endpoint.guardian_hp",
]

const NON_EMPTY_ARRAY_KEYS: Array[String] = [
	"guardian.hp_pressure_events",
	"second_offer.candidates",
	"session.decision_windows",
]

const NON_NEGATIVE_NUMBER_KEYS: Array[String] = [
	"shop1.gold_before",
	"shop1.gold_after",
	"rest.total_purchases",
	"rest.total_gold_spent",
	"rest.total_hp_restored",
	"session.consecutive_no_explained_decision_battles",
]

const SPECIAL_SHAPE_KEYS: Array[String] = [
	"battle1.machine_chain_sample",
	"battle1.exposure_gate_snapshot",
	"battle1.deploy_lane_selection",
	"battle1.lane_danger_snapshot",
	"unit.visible_contribution_slots",
	"unit.key_queue_entries_by_slot",
	"unit.dominant_slot_share",
	"rest_windows",
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
	_verify_shape_rules_cover_required_keys()
	_verify_learning_field_shapes(record)

func _verify_learning_field_shapes(record: Dictionary) -> void:
	_verify_machine_chain_sample(record)
	_verify_exposure_gate_snapshot(record)
	_verify_non_empty_string_fields(record, NON_EMPTY_STRING_KEYS)
	_verify_non_empty_array_fields(record, NON_EMPTY_ARRAY_KEYS)
	_verify_non_negative_number_fields(record, NON_NEGATIVE_NUMBER_KEYS)
	_verify_non_empty_selection_field(record, "battle1.deploy_lane_selection")
	_verify_lane_danger_snapshot(record)
	_verify_visible_contribution_slots(record)
	_verify_key_queue_entries_by_slot(record)
	_verify_dominant_slot_share(record)
	_verify_non_empty_array_or_dictionary_field(record, "rest_windows")

func _verify_shape_rules_cover_required_keys() -> void:
	var covered: Dictionary = {}
	for key: String in NON_EMPTY_STRING_KEYS:
		covered[key] = true
	for key: String in NON_EMPTY_ARRAY_KEYS:
		covered[key] = true
	for key: String in NON_NEGATIVE_NUMBER_KEYS:
		covered[key] = true
	for key: String in SPECIAL_SHAPE_KEYS:
		covered[key] = true
	for key: String in REQUIRED_KEYS:
		if not covered.has(key):
			failures.append("Verifier internal error: %s has no typed learning-record validation rule." % key)

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

func _verify_non_empty_string_fields(record: Dictionary, keys: Array[String]) -> void:
	for key: String in keys:
		if not record.has(key):
			continue
		var value: Variant = record.get(key)
		if not (value is String) or String(value).strip_edges().is_empty():
			failures.append("%s must be a non-empty String; use an explicit none marker such as 无/none when no choice was made." % key)

func _verify_non_empty_selection_field(record: Dictionary, key: String) -> void:
	if not record.has(key):
		return
	var value: Variant = record.get(key)
	if value is String and not String(value).strip_edges().is_empty():
		return
	if value is Array and not (value as Array).is_empty():
		return
	if value is Dictionary and not (value as Dictionary).is_empty():
		return
	failures.append("%s must be a non-empty String, Array, or Dictionary." % key)

func _verify_non_empty_array_or_dictionary_field(record: Dictionary, key: String) -> void:
	if not record.has(key):
		return
	var value: Variant = record.get(key)
	if value is Array and not (value as Array).is_empty():
		return
	if value is Dictionary and not (value as Dictionary).is_empty():
		return
	failures.append("%s must be a non-empty Array or Dictionary." % key)

func _verify_non_empty_array_fields(record: Dictionary, keys: Array[String]) -> void:
	for key: String in keys:
		if not record.has(key):
			continue
		var value: Variant = record.get(key)
		if not (value is Array) or (value as Array).is_empty():
			failures.append("%s must be a non-empty Array." % key)

func _verify_non_negative_number_fields(record: Dictionary, keys: Array[String]) -> void:
	for key: String in keys:
		if not record.has(key):
			continue
		var value: Variant = record.get(key)
		if not (value is int or value is float):
			failures.append("%s must be a Number >= 0." % key)
			continue
		if float(value) < 0.0:
			failures.append("%s must be >= 0." % key)

func _verify_lane_danger_snapshot(record: Dictionary) -> void:
	if not record.has("battle1.lane_danger_snapshot"):
		return
	var value: Variant = record.get("battle1.lane_danger_snapshot")
	if not (value is Dictionary):
		failures.append("battle1.lane_danger_snapshot must be a non-empty Dictionary.")
		return
	var snapshot: Dictionary = value as Dictionary
	if snapshot.is_empty():
		failures.append("battle1.lane_danger_snapshot must be a non-empty Dictionary.")
		return
	for lane_key: Variant in snapshot.keys():
		var entry: Variant = snapshot.get(lane_key)
		var danger_value: Variant = entry
		if entry is Dictionary:
			var entry_dictionary: Dictionary = entry as Dictionary
			danger_value = entry_dictionary.get("danger", entry_dictionary.get("danger_level", entry_dictionary.get("level", null)))
		if not (danger_value is int or danger_value is float):
			failures.append("battle1.lane_danger_snapshot[%s] must expose numeric danger level 0-3." % String(lane_key))
			continue
		var danger: float = float(danger_value)
		if danger < 0.0 or danger > 3.0:
			failures.append("battle1.lane_danger_snapshot[%s] danger level must be in range 0-3." % String(lane_key))

func _verify_visible_contribution_slots(record: Dictionary) -> void:
	if not record.has("unit.visible_contribution_slots"):
		return
	var value: Variant = record.get("unit.visible_contribution_slots")
	if value is Dictionary:
		if (value as Dictionary).is_empty():
			failures.append("unit.visible_contribution_slots Dictionary must be non-empty.")
		return
	if not (value is Array):
		failures.append("unit.visible_contribution_slots must be a non-empty Array or Dictionary.")
		return
	var slots: Array = value as Array
	if slots.is_empty():
		failures.append("unit.visible_contribution_slots must be non-empty.")
		return
	for slot_variant: Variant in slots:
		if not (slot_variant is int or slot_variant is float):
			failures.append("unit.visible_contribution_slots entries must be numeric slot ids.")
			continue
		var slot_id: int = int(slot_variant)
		if slot_id < 1 or slot_id > 4:
			failures.append("unit.visible_contribution_slots slot ids must be in range 1-4.")

func _verify_key_queue_entries_by_slot(record: Dictionary) -> void:
	if not record.has("unit.key_queue_entries_by_slot"):
		return
	var value: Variant = record.get("unit.key_queue_entries_by_slot")
	if not (value is Dictionary):
		failures.append("unit.key_queue_entries_by_slot must be a non-empty Dictionary.")
		return
	var by_slot: Dictionary = value as Dictionary
	if by_slot.is_empty():
		failures.append("unit.key_queue_entries_by_slot must be a non-empty Dictionary.")
		return
	for slot_key: Variant in by_slot.keys():
		var entries_variant: Variant = by_slot.get(slot_key)
		if entries_variant is Array:
			if (entries_variant as Array).is_empty():
				failures.append("unit.key_queue_entries_by_slot[%s] must contain at least one queue entry." % String(slot_key))
		elif entries_variant is Dictionary:
			if (entries_variant as Dictionary).is_empty():
				failures.append("unit.key_queue_entries_by_slot[%s] must contain non-empty queue entry evidence." % String(slot_key))
		else:
			failures.append("unit.key_queue_entries_by_slot[%s] must be an Array or Dictionary." % String(slot_key))

func _verify_dominant_slot_share(record: Dictionary) -> void:
	if not record.has("unit.dominant_slot_share"):
		return
	var value: Variant = record.get("unit.dominant_slot_share")
	if value is Dictionary:
		var share_record: Dictionary = value as Dictionary
		if share_record.is_empty():
			failures.append("unit.dominant_slot_share Dictionary must be non-empty.")
			return
		if not _has_any_key(share_record, ["slot_id", "slot", "dominant_slot"]):
			failures.append("unit.dominant_slot_share Dictionary must include slot_id/slot/dominant_slot.")
		var share_variant: Variant = share_record.get("share", share_record.get("ratio", share_record.get("dominant_share", null)))
		if not (share_variant is int or share_variant is float):
			failures.append("unit.dominant_slot_share Dictionary must include numeric share/ratio.")
			return
		_verify_ratio(float(share_variant), "unit.dominant_slot_share.share")
		return
	if value is int or value is float:
		_verify_ratio(float(value), "unit.dominant_slot_share")
		return
	failures.append("unit.dominant_slot_share must be a Dictionary with slot/share evidence or numeric ratio.")

func _verify_ratio(value: float, label: String) -> void:
	if value < 0.0 or value > 1.0:
		failures.append("%s must be in range 0.0-1.0." % label)

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
