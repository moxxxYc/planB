extends SceneTree

const BATTLE_SCENE_PATH: String = "res://scenes/run/battle_one_vertical.tscn"

var failures: Array[String] = []

func _initialize() -> void:
	var scene: PackedScene = load(BATTLE_SCENE_PATH)
	if scene == null:
		failures.append("Battle 1 vertical scene missing: %s" % BATTLE_SCENE_PATH)
		_finish()
		return

	var battle: Node = scene.instantiate()
	if battle == null:
		failures.append("Could not instantiate Battle 1 vertical scene.")
		_finish()
		return

	root.add_child(battle)
	if _require_methods(battle, [
		"advance_for_verifier",
		"get_machine_visual_contract",
		"get_active_machine_log_text",
	]):
		battle.call("advance_for_verifier", 8.0)
		_verify_runtime_physics_contract(battle)
	root.remove_child(battle)
	battle.free()
	_finish()

func _verify_runtime_physics_contract(battle: Node) -> void:
	var contract_variant: Variant = battle.call("get_machine_visual_contract")
	if not (contract_variant is Dictionary):
		failures.append("get_machine_visual_contract() must return a Dictionary.")
		return

	var visual_contract: Dictionary = contract_variant as Dictionary
	if not bool(visual_contract.get("runtime_physics_drives_results", false)):
		failures.append("Runtime machine results must be driven by visible physics landings.")
	if int(visual_contract.get("physics_landing_count", 0)) <= 0:
		failures.append("Battle runtime must observe at least one physics landing.")

	var log_text: String = String(battle.call("get_active_machine_log_text"))
	if not log_text.contains("物理落点"):
		failures.append("Machine log must expose physical landing causality in Chinese.")

func _require_methods(node: Node, methods: Array[String]) -> bool:
	var has_all_methods: bool = true
	for method_name: String in methods:
		if not node.has_method(method_name):
			failures.append("Battle 1 runtime missing method: %s" % method_name)
			has_all_methods = false
	return has_all_methods

func _finish() -> void:
	if failures.is_empty():
		print("verify_physics_machine_integration: PASS")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
