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

	_verify_physics_queue_chain(battle, visual_contract)

func _verify_physics_queue_chain(battle: Node, visual_contract: Dictionary) -> void:
	if battle.has_method("get_machine_physics_queue_chains_for_verifier"):
		var chains_variant: Variant = battle.call("get_machine_physics_queue_chains_for_verifier")
		if not (chains_variant is Array):
			failures.append("get_machine_physics_queue_chains_for_verifier() must return an Array.")
			return
		var chains: Array = chains_variant as Array
		for chain_variant: Variant in chains:
			if chain_variant is Dictionary and _is_physics_queue_chain(chain_variant as Dictionary):
				return
		failures.append("Battle runtime must report at least one queue-producing MachinePhysicsResult chain with source=physics.")
		return

	var has_contract_count: bool = visual_contract.has("physics_queue_chain_count")
	var has_contract_chain: bool = visual_contract.has("last_physics_queue_chain")
	if not has_contract_count and not has_contract_chain:
		failures.append(
			"Battle runtime must expose physics queue chain telemetry via get_machine_physics_queue_chains_for_verifier() or physics_queue_chain_count + last_physics_queue_chain."
		)
		return
	if int(visual_contract.get("physics_queue_chain_count", 0)) <= 0:
		failures.append("Machine visual contract must report physics_queue_chain_count > 0.")

	var chain_variant: Variant = visual_contract.get("last_physics_queue_chain", {})
	if not (chain_variant is Dictionary):
		failures.append("Machine visual contract last_physics_queue_chain must be a Dictionary.")
		return
	var chain: Dictionary = chain_variant as Dictionary
	if not _is_physics_queue_chain(chain):
		failures.append("last_physics_queue_chain must include source=physics and Unit/Queue entry evidence.")

func _is_physics_queue_chain(chain: Dictionary) -> bool:
	return _chain_has_physics_source(chain) and _chain_has_queue_entry(chain)

func _chain_has_physics_source(chain: Dictionary) -> bool:
	if String(chain.get("source", "")) == "physics":
		return true
	for key: String in ["physics_result", "last_physics_result", "machine_physics_result"]:
		var result_variant: Variant = chain.get(key, {})
		if result_variant is Dictionary and String((result_variant as Dictionary).get("source", "")) == "physics":
			return true
	for result_variant: Variant in _chain_results(chain):
		if result_variant is Dictionary and String((result_variant as Dictionary).get("source", "")) == "physics":
			return true
	return false

func _chain_has_queue_entry(chain: Dictionary) -> bool:
	var queue_entry_variant: Variant = chain.get("queue_entry", {})
	if queue_entry_variant is Dictionary and not (queue_entry_variant as Dictionary).is_empty():
		return true
	var queue_entries_variant: Variant = chain.get("queue_entries", [])
	if queue_entries_variant is Array and not (queue_entries_variant as Array).is_empty():
		return true
	if not String(chain.get("unit_id", "")).is_empty():
		return true
	if not String(chain.get("queue_unit_id", "")).is_empty():
		return true
	for result_variant: Variant in _chain_results(chain):
		if result_variant is Dictionary:
			var result: Dictionary = result_variant as Dictionary
			var component: String = String(result.get("component", result.get("source_component", "")))
			var result_id: String = String(result.get("result_id", result.get("result", "")))
			if component == "Unit" and (result_id == "QueueEntry" or result.has("queue_entry")):
				return true
	return false

func _chain_results(chain: Dictionary) -> Array:
	var results_variant: Variant = chain.get("results", [])
	if results_variant is Array:
		return results_variant as Array
	var chain_variant: Variant = chain.get("chain", [])
	if chain_variant is Array:
		return chain_variant as Array
	return []

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
