extends SceneTree

const BATTLE_SCENE_PATH: String = "res://scenes/run/battle_one_vertical.tscn"

var failures: Array[String] = []

func _initialize() -> void:
	_run_verification.call_deferred()

func _run_verification() -> void:
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
		"get_machine_visual_contract",
		"get_active_machine_log_text",
	]):
		await _wait_for_runtime_physics_queue_chain(battle)
		_verify_runtime_physics_contract(battle)
	root.remove_child(battle)
	battle.free()
	_finish()

func _wait_for_runtime_physics_queue_chain(battle: Node) -> void:
	for _frame: int in range(2400):
		await physics_frame
		var contract_variant: Variant = battle.call("get_machine_visual_contract")
		if not (contract_variant is Dictionary):
			continue
		var visual_contract: Dictionary = contract_variant as Dictionary
		if int(visual_contract.get("physics_queue_chain_count", 0)) > 0:
			return

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
		failures.append("Battle runtime must report at least one queue-producing MachinePhysicsResult chain with source=physics. %s" % _runtime_failure_summary(battle, visual_contract, chains))
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
		failures.append("last_physics_queue_chain must include source=physics and Unit/Queue entry evidence. %s" % _runtime_failure_summary(battle, visual_contract, []))

func _runtime_failure_summary(battle: Node, visual_contract: Dictionary, chains: Array) -> String:
	var last_result: Variant = visual_contract.get("last_physics_result", {})
	var log_text: String = String(battle.call("get_active_machine_log_text")) if battle.has_method("get_active_machine_log_text") else ""
	var log_lines: PackedStringArray = log_text.split("\n", false)
	var tail := PackedStringArray()
	var start_index: int = maxi(0, log_lines.size() - 6)
	for index: int in range(start_index, log_lines.size()):
		tail.append(log_lines[index])
	return "landing_count=%d queue_chain_count=%d chains=%d physics_ticks=%d last_result=%s log_tail=%s rects=%s catchers=%s" % [
		int(visual_contract.get("physics_landing_count", 0)),
		int(visual_contract.get("physics_queue_chain_count", 0)),
		chains.size(),
		int(visual_contract.get("physics_tick_count", 0)),
		str(last_result),
		"%s ball_snapshot=%s" % [" | ".join(tail), str(visual_contract.get("ball_stage_snapshot", {}))],
		str(visual_contract.get("stage_rects", {})),
		str(visual_contract.get("stage_bottom_catchers", {})),
	]

func _is_physics_queue_chain(chain: Dictionary) -> bool:
	if not _chain_has_result(chain, "Launch"):
		return false
	if not _chain_has_result(chain, "Tuning"):
		return false
	if not _chain_has_result(chain, "Unit"):
		return false
	if not _chain_has_payload_keys(chain, ["kind", "value", "tags", "tuning_mark", "source_pass"]):
		return false
	if _chain_has_forced_redirect(chain) and not _chain_forced_redirect_is_readable(chain):
		return false
	for queue_entry_variant: Variant in _chain_queue_entries(chain):
		if not (queue_entry_variant is Dictionary):
			continue
		var queue_entry: Dictionary = queue_entry_variant as Dictionary
		if not _is_structured_queue_entry(queue_entry):
			continue
		for result_variant: Variant in _chain_unit_physics_results(chain):
			var unit_result: Dictionary = result_variant as Dictionary
			if _queue_entry_is_tied_to_unit_result(queue_entry, unit_result):
				return true
	return false

func _chain_has_result(chain: Dictionary, component: String) -> bool:
	for result_variant: Variant in _chain_results(chain):
		if not (result_variant is Dictionary):
			continue
		var result: Dictionary = result_variant as Dictionary
		if String(result.get("component", "")) == component:
			return true
	return false

func _chain_has_payload_keys(chain: Dictionary, keys: Array[String]) -> bool:
	var payload_variant: Variant = chain.get("pool", {})
	if not (payload_variant is Dictionary):
		return false
	var payload: Dictionary = payload_variant as Dictionary
	for key: String in keys:
		if not payload.has(key):
			return false
	return true

func _chain_has_forced_redirect(chain: Dictionary) -> bool:
	for result_variant: Variant in _chain_results(chain):
		if not (result_variant is Dictionary):
			continue
		var result: Dictionary = result_variant as Dictionary
		if String(result.get("feedback_state", "")) == "Forced Redirect":
			return true
	return false

func _chain_forced_redirect_is_readable(chain: Dictionary) -> bool:
	for result_variant: Variant in _chain_results(chain):
		if not (result_variant is Dictionary):
			continue
		var result: Dictionary = result_variant as Dictionary
		if String(result.get("feedback_state", "")) != "Forced Redirect":
			continue
		if String(result.get("forced_by", "")).strip_edges().is_empty():
			return false
		if String(result.get("natural_result_id", "")).strip_edges().is_empty():
			return false
	return true

func _is_structured_queue_entry(queue_entry: Dictionary) -> bool:
	if queue_entry.is_empty():
		return false
	if String(queue_entry.get("unit_id", "")).strip_edges().is_empty():
		return false
	if int(queue_entry.get("slot_id", 0)) <= 0:
		return false
	if not _queue_entry_has_physics_source_or_chain_id(queue_entry):
		return false
	return true

func _queue_entry_has_physics_source_or_chain_id(queue_entry: Dictionary) -> bool:
	if String(queue_entry.get("source", "")).contains("physics"):
		return true
	if not String(queue_entry.get("chain_id", "")).strip_edges().is_empty():
		return true
	var source_tags_variant: Variant = queue_entry.get("source_tags", [])
	if source_tags_variant is Array:
		for tag_variant: Variant in source_tags_variant:
			if String(tag_variant).contains("physics"):
				return true
	return false

func _chain_unit_physics_results(chain: Dictionary) -> Array:
	var results: Array = []
	for key: String in ["unit_physics_result", "physics_result", "last_physics_result", "machine_physics_result"]:
		var result_variant: Variant = chain.get(key, {})
		if result_variant is Dictionary and _is_unit_physics_result(result_variant as Dictionary):
			results.append(result_variant)
	var physics_results_variant: Variant = chain.get("physics_results", [])
	if physics_results_variant is Array:
		for result_variant: Variant in physics_results_variant:
			if result_variant is Dictionary and _is_unit_physics_result(result_variant as Dictionary):
				results.append(result_variant)
	for result_variant: Variant in _chain_results(chain):
		if result_variant is Dictionary and _is_unit_physics_result(result_variant as Dictionary):
			results.append(result_variant)
	return results

func _is_unit_physics_result(result: Dictionary) -> bool:
	var component: String = String(result.get("component", result.get("source_component", "")))
	if component != "Unit":
		return false
	if String(result.get("source", "")) != "physics":
		return false
	if int(result.get("slot_id", 0)) <= 0:
		return false
	return true

func _chain_queue_entries(chain: Dictionary) -> Array:
	var entries: Array = []
	var queue_entry_variant: Variant = chain.get("queue_entry", {})
	if queue_entry_variant is Dictionary:
		entries.append(queue_entry_variant)
	var queue_entries_variant: Variant = chain.get("queue_entries", [])
	if queue_entries_variant is Array:
		for entry_variant: Variant in queue_entries_variant:
			if entry_variant is Dictionary:
				entries.append(entry_variant)
	for result_variant: Variant in _chain_results(chain):
		if result_variant is Dictionary:
			var result: Dictionary = result_variant as Dictionary
			var nested_entry_variant: Variant = result.get("queue_entry", {})
			if nested_entry_variant is Dictionary:
				entries.append(nested_entry_variant)
	return entries

func _queue_entry_is_tied_to_unit_result(queue_entry: Dictionary, unit_result: Dictionary) -> bool:
	var entry_chain_id: String = String(queue_entry.get("chain_id", "")).strip_edges()
	var result_chain_id: String = String(unit_result.get("chain_id", "")).strip_edges()
	if not entry_chain_id.is_empty() and entry_chain_id == result_chain_id:
		return true
	if int(queue_entry.get("slot_id", 0)) != int(unit_result.get("slot_id", -1)):
		return false
	if String(queue_entry.get("source", "")).contains("physics"):
		return true
	var source_tags_variant: Variant = queue_entry.get("source_tags", [])
	if source_tags_variant is Array:
		for tag_variant: Variant in source_tags_variant:
			if String(tag_variant).contains("physics"):
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
