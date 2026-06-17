extends SceneTree

const EXPOSURE_STATE_PATH: String = "res://scripts/model/machine/machine_slot_exposure_state.gd"
const MACHINE_SIMULATOR_PATH: String = "res://scripts/model/machine/machine_simulator.gd"
const PHYSICS_BOARD_PATH: String = "res://scripts/ui/machine_physics_board_view.gd"
const RUN_SCENE_PATH: String = "res://scenes/run/mvp_run_session.tscn"

var failures: Array[String] = []

func _initialize() -> void:
	_verify_exposure_state_model()
	_verify_exposure_state_assignment_contract()
	_verify_exposure_gate_visual_contract()
	_verify_blocked_bounce_escape_contract()
	_verify_simulator_blocked_guard_terminates_chain()
	_verify_battle_one_learning_record()
	_finish()

func _verify_exposure_state_model() -> void:
	if not ResourceLoader.exists(EXPOSURE_STATE_PATH):
		failures.append("MachineSlotExposureState missing at %s." % EXPOSURE_STATE_PATH)
		return

	var exposure_script: Script = load(EXPOSURE_STATE_PATH) as Script
	if exposure_script == null:
		failures.append("MachineSlotExposureState script failed to load.")
		return

	var exposure: Object = exposure_script.new() as Object
	if exposure == null:
		failures.append("MachineSlotExposureState failed to instantiate.")
		return
	if not _require_object_methods(exposure, [
		"is_slot_fully_exposed",
		"is_slot_open_for_progress",
	]):
		return

	if not bool(exposure.call("is_slot_fully_exposed", 1, 0.0)):
		failures.append("Slot 1 must be fully exposed at battle start.")
	if bool(exposure.call("is_slot_open_for_progress", 2, 11.9)):
		failures.append("Slot 2 must not accept progress before 12s exposure start.")
	if not bool(exposure.call("is_slot_fully_exposed", 2, 24.0)):
		failures.append("Slot 2 must be fully exposed by 24s.")
	if bool(exposure.call("is_slot_open_for_progress", 4, 71.9)):
		failures.append("Slot 4 must not accept progress before 72s exposure start.")

func _verify_exposure_state_assignment_contract() -> void:
	var machine_script: Script = load(MACHINE_SIMULATOR_PATH) as Script
	if machine_script == null:
		failures.append("MachineSimulator script failed to load.")
		return
	var machine: Object = machine_script.new() as Object
	if machine == null:
		failures.append("MachineSimulator failed to instantiate.")
		return
	if not _require_object_methods(machine, [
		"get_exposure_state",
		"set_exposure_state",
	]):
		return
	var original_state: Variant = machine.call("get_exposure_state")
	machine.call("set_exposure_state", RefCounted.new())
	if machine.call("get_exposure_state") != original_state:
		failures.append("MachineSimulator.set_exposure_state() must reject objects without the exposure-state contract.")

	var board_script: Script = load(PHYSICS_BOARD_PATH) as Script
	if board_script == null:
		failures.append("MachinePhysicsBoardView script failed to load.")
		return
	var board: Node = board_script.new() as Node
	if board == null:
		failures.append("MachinePhysicsBoardView failed to instantiate.")
		return
	if not _require_node_methods(board, ["set_exposure_state"]):
		board.free()
		return
	if not board.has_method("_has_exposure_state_contract"):
		failures.append("MachinePhysicsBoardView must expose an internal exposure-state contract validator.")
	else:
		if bool(board.call("_has_exposure_state_contract", RefCounted.new())):
			failures.append("MachinePhysicsBoardView must reject exposure states without required methods.")
	board.free()

func _verify_exposure_gate_visual_contract() -> void:
	var board_script: Script = load(PHYSICS_BOARD_PATH) as Script
	if board_script == null:
		failures.append("MachinePhysicsBoardView script failed to load for visual contract.")
		return
	var board: Node = board_script.new() as Node
	if board == null:
		failures.append("MachinePhysicsBoardView failed to instantiate for visual contract.")
		return
	root.add_child(board)
	board.call("set_battle_elapsed", 9.0)
	var contract: Dictionary = board.call("get_runtime_contract") as Dictionary
	var bin_visuals: Dictionary = contract.get("bin_visuals", {}) as Dictionary
	for bin_key: String in [
		"Launch:Tuning",
		"Launch:Split",
		"Launch:Recycle",
		"Launch:Waste",
		"Tuning:Gate",
		"Tuning:Prime",
		"Tuning:Echo",
		"Tuning:Surge",
		"Unit:S1",
		"Unit:S2",
		"Unit:S3",
		"Unit:S4",
	]:
		var bin_visual: Dictionary = bin_visuals.get(bin_key, {}) as Dictionary
		if String(bin_visual.get("visual_role", "")) != "landing_rail":
			failures.append("%s must draw as a landing rail, not a solid bin plate." % bin_key)
		if float(bin_visual.get("visual_height", 999.0)) >= 12.0:
			failures.append("%s landing rail must be visibly thinner than the slot label row." % bin_key)
	var visuals: Dictionary = contract.get("unit_gate_visuals", {}) as Dictionary
	var slot_one: Dictionary = visuals.get(1, {}) as Dictionary
	if bool(slot_one.get("blocker_visible", true)):
		failures.append("S1 must not draw a blocker plate at 9s; it starts fully exposed.")
	if String(slot_one.get("bin_visual_role", "")) != "landing_rail":
		failures.append("Open Unit slots must draw as landing rails, not solid blocker plates.")
	if float(slot_one.get("bin_visual_height", 999.0)) >= 12.0:
		failures.append("Open Unit slot landing rail must be visibly thinner than a closed blocker.")
	for slot_id: int in range(2, 5):
		var slot_visual: Dictionary = visuals.get(slot_id, {}) as Dictionary
		if not bool(slot_visual.get("blocker_visible", false)):
			failures.append("S%d must still draw a blocker plate at 9s." % slot_id)
		if int(slot_visual.get("blocker_z_index", 0)) <= 0:
			failures.append("S%d blocker plate must render above Unit bin rails." % slot_id)
		if float(slot_visual.get("closed_width", 0.0)) <= 0.0:
			failures.append("S%d blocker plate must report positive closed width at 9s." % slot_id)
		if float(slot_visual.get("blocker_visual_height", 999.0)) >= 12.0:
			failures.append("S%d blocker visual must be a thin gate strip, not a solid plate covering slot content." % slot_id)
		if float(slot_visual.get("blocker_collision_height", 0.0)) <= float(slot_visual.get("blocker_visual_height", 0.0)):
			failures.append("S%d blocker collision may stay large, but visual height must be thinner than collision height." % slot_id)
	root.remove_child(board)
	board.free()

func _verify_blocked_bounce_escape_contract() -> void:
	var board_script: Script = load(PHYSICS_BOARD_PATH) as Script
	if board_script == null:
		failures.append("MachinePhysicsBoardView script failed to load.")
		return
	var board: Node = board_script.new() as Node
	if board == null:
		failures.append("MachinePhysicsBoardView failed to instantiate.")
		return
	root.add_child(board)
	board.call("set_battle_elapsed", 13.0)
	if not board.has_method("_open_unit_slot_for_bounce"):
		failures.append("MachinePhysicsBoardView missing blocked-bounce retarget helper.")
	else:
		var target_slot_id: int = int(board.call("_open_unit_slot_for_bounce", 2, 13.0))
		if target_slot_id == 2:
			failures.append("Narrowly exposed S2 must not retarget a blocked bounce back into S2.")
	if not board.has_method("_max_blocked_bounce_count"):
		failures.append("MachinePhysicsBoardView must expose a per-ball blocked-bounce cap.")
	else:
		if int(board.call("_max_blocked_bounce_count")) <= 0:
			failures.append("MachinePhysicsBoardView blocked-bounce cap must be positive.")
	root.remove_child(board)
	board.free()

func _verify_simulator_blocked_guard_terminates_chain() -> void:
	var machine_script: Script = load(MACHINE_SIMULATOR_PATH) as Script
	if machine_script == null:
		failures.append("MachineSimulator script failed to load.")
		return
	var machine: Object = machine_script.new() as Object
	if machine == null:
		failures.append("MachineSimulator failed to instantiate.")
		return
	if not _require_object_methods(machine, [
		"apply_physics_result",
		"get_machine_chain_sample",
	]):
		return
	machine.call("set_battle_elapsed", 0.0)
	machine.call("apply_physics_result", MachinePhysicsResult.make("Tuning", "Gate", 0, 1, "clean", "physics", "blocked_guard_chain", 0.0))
	machine.call("apply_physics_result", MachinePhysicsResult.make("Unit", "UnitHit", 2, 0, "clean", "physics", "blocked_guard_chain", 0.0))
	var chain_sample: Dictionary = machine.call("get_machine_chain_sample") as Dictionary
	var chain_text: String = JSON.stringify(chain_sample)
	if not chain_text.contains("ExposureBlocked"):
		failures.append("Simulator blocked Unit guard must record terminal ExposureBlocked telemetry.")
	var pending_variant: Variant = machine.get("_pending_physics_chains")
	if pending_variant is Dictionary and (pending_variant as Dictionary).has("blocked_guard_chain"):
		failures.append("Simulator blocked Unit guard must erase the pending physics chain.")

func _verify_battle_one_learning_record() -> void:
	var scene: PackedScene = load(RUN_SCENE_PATH)
	if scene == null:
		failures.append("Run session scene missing: %s" % RUN_SCENE_PATH)
		return

	var run: Node = scene.instantiate()
	if run == null:
		failures.append("Could not instantiate run session scene.")
		return

	root.add_child(run)
	if _require_node_methods(run, [
		"select_guardian",
		"confirm_guardian",
		"advance_active_battle_for_verifier",
		"complete_current_battle_for_verifier",
		"choose_reward_one",
		"confirm_shop_and_rest",
		"choose_second_reward",
		"confirm_endpoint_prep",
		"get_current_node_id",
		"get_result_record",
	]):
		_drive_full_run_to_final_result(run)
		var record_variant: Variant = run.call("get_result_record")
		if not (record_variant is Dictionary):
			failures.append("get_result_record() must return a Dictionary.")
		else:
			var record: Dictionary = record_variant as Dictionary
			if not record.has("battle1.exposure_gate_snapshot"):
				failures.append("Final result record must include battle1.exposure_gate_snapshot.")
	root.remove_child(run)
	run.free()

func _drive_full_run_to_final_result(run: Node) -> void:
	run.call("select_guardian", "hive_vein_mother")
	run.call("confirm_guardian")
	if not _expect_node(run, "battle_1"):
		return
	run.call("advance_active_battle_for_verifier", 30.0)
	run.call("complete_current_battle_for_verifier", "Win")
	if not _expect_node(run, "reward_1"):
		return
	run.call("choose_reward_one", "prime_charge")
	if not _expect_node(run, "battle_2"):
		return
	run.call("complete_current_battle_for_verifier", "Win")
	if not _expect_node(run, "shop_1"):
		return
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
	run.call("choose_second_reward", "echo_latch")
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

func _expect_node(run: Node, expected: String) -> bool:
	var actual: String = String(run.call("get_current_node_id"))
	if actual != expected:
		failures.append("Expected run node %s, got %s." % [expected, actual])
		return false
	return true

func _require_object_methods(object: Object, methods: Array[String]) -> bool:
	var has_all_methods: bool = true
	for method_name: String in methods:
		if not object.has_method(method_name):
			failures.append("MachineSlotExposureState missing method: %s" % method_name)
			has_all_methods = false
	return has_all_methods

func _require_node_methods(node: Node, methods: Array[String]) -> bool:
	var has_all_methods: bool = true
	for method_name: String in methods:
		if not node.has_method(method_name):
			failures.append("Run scene missing method: %s" % method_name)
			has_all_methods = false
	return has_all_methods

func _finish() -> void:
	if failures.is_empty():
		print("verify_exposure_gate: PASS")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
