extends SceneTree

const RUN_SCENE_PATH: String = "res://scenes/run/mvp_run_session.tscn"

var failures: Array[String] = []

func _initialize() -> void:
	_verify_vein_mother_strategic_recycle()
	_verify_acid_crown_strategic_gate()
	_verify_vein_mother_tactical_tether()
	_verify_acid_crown_tactical_counterattack()
	_finish()

func _verify_vein_mother_strategic_recycle() -> void:
	var run: Node = _start_battle_for_guardian("hive_vein_mother")
	if run == null:
		return
	var battle: Node = _active_battle(run)
	if battle != null:
		var result: Dictionary = _call_required_dictionary(
			battle,
			"force_guardian_recycle_sequence_for_verifier",
			[6],
			"巢脉母 Recycle strategic verifier"
		)
		if not result.is_empty():
			_verify_vein_mother_strategic_record(result)
	_dispose_run(run)

func _verify_acid_crown_strategic_gate() -> void:
	var run: Node = _start_battle_for_guardian("hive_acid_crown_mother")
	if run == null:
		return
	var battle: Node = _active_battle(run)
	if battle != null:
		var result: Dictionary = _call_required_dictionary(
			battle,
			"force_guardian_gate_sequence_for_verifier",
			[6],
			"酸冠母 Gate strategic verifier"
		)
		if not result.is_empty():
			_verify_acid_crown_strategic_record(result)
	_dispose_run(run)

func _verify_vein_mother_tactical_tether() -> void:
	var run: Node = _start_battle_for_guardian("hive_vein_mother")
	if run == null:
		return
	var battle: Node = _active_battle(run)
	if battle != null:
		var result: Dictionary = _call_required_dictionary(
			battle,
			"force_guardian_tether_intruder_for_verifier",
			[],
			"巢脉牵缚 tactical verifier"
		)
		if not result.is_empty():
			_verify_vein_mother_tactical_record(result)
	_dispose_run(run)

func _verify_acid_crown_tactical_counterattack() -> void:
	var run: Node = _start_battle_for_guardian("hive_acid_crown_mother")
	if run == null:
		return
	var battle: Node = _active_battle(run)
	if battle != null:
		var result: Dictionary = _call_required_dictionary(
			battle,
			"force_guardian_acid_counterattack_for_verifier",
			[],
			"酸冠反喷 tactical verifier"
		)
		if not result.is_empty():
			_verify_acid_crown_tactical_record(result)
	_dispose_run(run)

func _call_required_dictionary(battle: Node, method_name: String, args: Array, label: String) -> Dictionary:
	if not battle.has_method(method_name):
		failures.append("Battle runtime missing helper: %s." % method_name)
		return {}
	var result_variant: Variant = battle.callv(method_name, args)
	if not (result_variant is Dictionary):
		failures.append("%s must return structured Dictionary evidence, not %s." % [label, type_string(typeof(result_variant))])
		return {}
	var result: Dictionary = result_variant as Dictionary
	if result.is_empty():
		failures.append("%s must return non-empty Dictionary evidence." % label)
	return result

func _verify_vein_mother_strategic_record(record: Dictionary) -> void:
	_expect_bool(record, "triggered", true, "巢脉母 Recycle strategic")
	_expect_int(record, "legal_recycle_count", 6, "巢脉母 Recycle strategic")
	_expect_int(record, "extra_clean_ball_count", 1, "巢脉母 Recycle strategic")
	_expect_pool_delta(record, "巢脉母 Recycle strategic")
	_expect_bool(record, "pity_reset", true, "巢脉母 Recycle strategic")
	_expect_bool(record, "reset_per_battle", true, "巢脉母 Recycle strategic")
	_expect_layer(record, ["Guardian.StrategicSkill", "strategic_machine"], "巢脉母 Recycle strategic")

func _verify_acid_crown_strategic_record(record: Dictionary) -> void:
	_expect_bool(record, "converted", true, "酸冠母 Gate strategic")
	_expect_int(record, "gate_count", 6, "酸冠母 Gate strategic")
	_expect_string(record, "original_result", "Gate", "酸冠母 Gate strategic")
	_expect_string(record, "final_result", "Prime", "酸冠母 Gate strategic")
	_expect_bool(record, "reset", true, "酸冠母 Gate strategic")
	_expect_bool(record, "reset_per_battle", true, "酸冠母 Gate strategic")
	_expect_no_cross_axis(record, "酸冠母 Gate strategic")
	_expect_layer(record, ["Guardian.StrategicSkill", "strategic_machine"], "酸冠母 Gate strategic")

func _verify_vein_mother_tactical_record(record: Dictionary) -> void:
	_expect_bool(record, "triggered", true, "巢脉牵缚 tactical")
	_expect_int(record, "damage", 4, "巢脉牵缚 tactical")
	_expect_float(record, "root_seconds", 0.5, 0.001, "巢脉牵缚 tactical")
	_expect_float(record, "slow_multiplier", 0.6, 0.05, "巢脉牵缚 tactical")
	_expect_float(record, "slow_seconds", 1.2, 0.001, "巢脉牵缚 tactical")
	_expect_any_non_empty_string(record, ["target_basis", "target_priority"], "巢脉牵缚 tactical")

func _verify_acid_crown_tactical_record(record: Dictionary) -> void:
	_expect_bool(record, "triggered", true, "酸冠反喷 tactical")
	_expect_bool(record, "real_hp_damage_consumed", true, "酸冠反喷 tactical")
	_expect_int(record, "attacker_damage", 4, "酸冠反喷 tactical")
	_expect_float(record, "splash_radius", 3.0, 0.001, "酸冠反喷 tactical")
	_expect_int(record, "max_nearby_targets", 2, "酸冠反喷 tactical")
	_expect_int(record, "nearby_damage", 1, "酸冠反喷 tactical")
	_expect_bool(record, "no_heal", true, "酸冠反喷 tactical")
	_expect_bool(record, "no_refund", true, "酸冠反喷 tactical")
	_expect_bool(record, "no_damage_prevention", true, "酸冠反喷 tactical")

func _expect_bool(record: Dictionary, key: String, expected: bool, label: String) -> void:
	if not record.has(key):
		failures.append("%s missing %s." % [label, key])
		return
	if bool(record.get(key, not expected)) != expected:
		failures.append("%s.%s expected %s." % [label, key, str(expected)])

func _expect_int(record: Dictionary, key: String, expected: int, label: String) -> void:
	if not record.has(key):
		failures.append("%s missing %s." % [label, key])
		return
	if int(record.get(key, -999999)) != expected:
		failures.append("%s.%s expected %d, got %d." % [label, key, expected, int(record.get(key, -999999))])

func _expect_float(record: Dictionary, key: String, expected: float, tolerance: float, label: String) -> void:
	if not record.has(key):
		failures.append("%s missing %s." % [label, key])
		return
	var actual: float = float(record.get(key, -999999.0))
	if absf(actual - expected) > tolerance:
		failures.append("%s.%s expected %.3f, got %.3f." % [label, key, expected, actual])

func _expect_string(record: Dictionary, key: String, expected: String, label: String) -> void:
	if not record.has(key):
		failures.append("%s missing %s." % [label, key])
		return
	var actual: String = String(record.get(key, ""))
	if actual != expected:
		failures.append("%s.%s expected %s, got %s." % [label, key, expected, actual])

func _expect_pool_delta(record: Dictionary, label: String) -> void:
	if record.has("pool_delta"):
		if int(record.get("pool_delta", 0)) != 1:
			failures.append("%s.pool_delta expected 1." % label)
		return
	if record.has("pool_count_before") and record.has("pool_count_after"):
		var before: int = int(record.get("pool_count_before", 0))
		var after: int = int(record.get("pool_count_after", 0))
		if after - before != 1:
			failures.append("%s pool_count_after - pool_count_before expected 1." % label)
		return
	failures.append("%s missing pool_delta or pool_count_before/after evidence." % label)

func _expect_no_cross_axis(record: Dictionary, label: String) -> void:
	if record.has("no_cross_axis"):
		if not bool(record.get("no_cross_axis", false)):
			failures.append("%s.no_cross_axis expected true." % label)
		return
	if record.has("cross_axis_counted"):
		if bool(record.get("cross_axis_counted", true)):
			failures.append("%s.cross_axis_counted expected false." % label)
		return
	if record.has("counted_only_gate"):
		if not bool(record.get("counted_only_gate", false)):
			failures.append("%s.counted_only_gate expected true." % label)
		return
	failures.append("%s missing no_cross_axis or equivalent evidence." % label)

func _expect_layer(record: Dictionary, expected_markers: Array[String], label: String) -> void:
	var layer_text: String = "%s %s %s" % [
		String(record.get("source", "")),
		String(record.get("contract_layer", "")),
		String(record.get("layer", "")),
	]
	for marker: String in expected_markers:
		if layer_text.contains(marker):
			return
	failures.append("%s missing Guardian contract layer evidence: %s." % [label, ", ".join(expected_markers)])

func _expect_any_non_empty_string(record: Dictionary, keys: Array[String], label: String) -> void:
	for key: String in keys:
		if record.has(key) and not String(record.get(key, "")).strip_edges().is_empty():
			return
	failures.append("%s missing non-empty evidence in one of: %s." % [label, ", ".join(keys)])

func _start_battle_for_guardian(guardian_id: String) -> Node:
	var scene: PackedScene = load(RUN_SCENE_PATH)
	if scene == null:
		failures.append("Run session scene missing: %s" % RUN_SCENE_PATH)
		return null
	var run: Node = scene.instantiate()
	if run == null:
		failures.append("Could not instantiate run session scene for %s." % guardian_id)
		return null
	root.add_child(run)
	if not _require_run_methods(run):
		_dispose_run(run)
		return null
	run.call("select_guardian", guardian_id)
	run.call("confirm_guardian")
	if String(run.call("get_current_node_id")) != "battle_1":
		failures.append("Guardian %s should route to Battle 1." % guardian_id)
		_dispose_run(run)
		return null
	return run

func _active_battle(run: Node) -> Node:
	var battle: Node = run.get("active_battle") as Node
	if battle == null:
		failures.append("Run scene must expose active_battle after Guardian confirmation.")
	return battle

func _require_run_methods(run: Node) -> bool:
	var has_all_methods: bool = true
	for method_name: String in [
		"select_guardian",
		"confirm_guardian",
		"get_current_node_id",
	]:
		if not run.has_method(method_name):
			failures.append("Run scene missing method: %s" % method_name)
			has_all_methods = false
	return has_all_methods

func _dispose_run(run: Node) -> void:
	if run == null:
		return
	root.remove_child(run)
	run.free()

func _finish() -> void:
	if failures.is_empty():
		print("verify_guardian_contract_behaviors: PASS")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
