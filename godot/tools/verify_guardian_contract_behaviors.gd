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
		if not battle.has_method("force_guardian_recycle_sequence_for_verifier"):
			failures.append("Battle runtime missing helper: force_guardian_recycle_sequence_for_verifier(count).")
		elif not bool(battle.call("force_guardian_recycle_sequence_for_verifier", 6)):
			failures.append("巢脉母 must trigger hidden pity on the 6th legal Recycle.")
	_dispose_run(run)

func _verify_acid_crown_strategic_gate() -> void:
	var run: Node = _start_battle_for_guardian("hive_acid_crown_mother")
	if run == null:
		return
	var battle: Node = _active_battle(run)
	if battle != null:
		if not battle.has_method("force_guardian_gate_sequence_for_verifier"):
			failures.append("Battle runtime missing helper: force_guardian_gate_sequence_for_verifier(count).")
		elif not bool(battle.call("force_guardian_gate_sequence_for_verifier", 6)):
			failures.append("酸冠母 must convert the 6th Gate miss path into Prime.")
	_dispose_run(run)

func _verify_vein_mother_tactical_tether() -> void:
	var run: Node = _start_battle_for_guardian("hive_vein_mother")
	if run == null:
		return
	var battle: Node = _active_battle(run)
	if battle != null:
		_verify_tactical_helper(
			battle,
			"force_guardian_tether_intruder_for_verifier",
			"巢脉牵缚"
		)
	_dispose_run(run)

func _verify_acid_crown_tactical_counterattack() -> void:
	var run: Node = _start_battle_for_guardian("hive_acid_crown_mother")
	if run == null:
		return
	var battle: Node = _active_battle(run)
	if battle != null:
		_verify_tactical_helper(
			battle,
			"force_guardian_acid_counterattack_for_verifier",
			"酸冠反喷"
		)
	_dispose_run(run)

func _verify_tactical_helper(battle: Node, method_name: String, required_text: String) -> void:
	if not battle.has_method(method_name):
		failures.append("Battle runtime missing helper: %s()." % method_name)
		return
	var result: Variant = battle.call(method_name)
	if result is bool and not bool(result):
		failures.append("%s helper returned false." % required_text)
		return
	var result_text: String = _variant_to_text(result)
	if not result_text.contains(required_text):
		failures.append("%s helper must return visible/log text containing %s." % [method_name, required_text])

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

func _variant_to_text(value: Variant) -> String:
	if value is Dictionary or value is Array:
		return JSON.stringify(value)
	return String(value)

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
