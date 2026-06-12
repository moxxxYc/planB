extends SceneTree

const EXPOSURE_STATE_PATH: String = "res://scripts/model/machine/machine_slot_exposure_state.gd"
const RUN_SCENE_PATH: String = "res://scenes/run/mvp_run_session.tscn"

var failures: Array[String] = []

func _initialize() -> void:
	_verify_exposure_state_model()
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
