extends SceneTree

const RUN_SCENE_PATH: String = "res://scenes/run/mvp_run_session.tscn"

func _initialize() -> void:
	var failed: bool = false
	var scene: PackedScene = load(RUN_SCENE_PATH)
	if scene == null:
		push_error("M2 run session scene missing: %s" % RUN_SCENE_PATH)
		quit(1)
		return

	var run: Node = scene.instantiate()
	if run == null:
		push_error("Could not instantiate M2 run session scene.")
		quit(1)
		return

	root.add_child(run)

	failed = not _verify_guardian_contract(run) or failed
	failed = not _verify_reward_one_and_battle_two(run) or failed
	failed = not _verify_shop_rest_and_battle_three(run) or failed
	failed = not _verify_result_routing(run) or failed
	failed = not _verify_shop_modifier_machine_behaviors() or failed

	root.remove_child(run)
	run.free()

	failed = not _verify_supplemental_m2_paths(scene) or failed

	if failed:
		quit(1)
		return

	print("verify_m2_run_flow: PASS")
	quit(0)

func _verify_guardian_contract(run: Node) -> bool:
	if not _has_methods(run, [
		"get_current_node_id",
		"get_guardian_card_text",
		"select_guardian",
		"confirm_guardian",
		"get_selected_guardian_id",
	]):
		return false

	if String(run.call("get_current_node_id")) != "guardian_contract":
		push_error("M2 run should start at Guardian Contract.")
		return false

	var vein_text: String = String(run.call("get_guardian_card_text", "hive_vein_mother"))
	if not vein_text.contains("巢脉母") or not vein_text.contains("Launch") or not vein_text.contains("契约"):
		push_error("巢脉母 card must show name, Launch tendency, and contract framing.")
		return false

	var acid_text: String = String(run.call("get_guardian_card_text", "hive_acid_crown_mother"))
	if not acid_text.contains("酸冠母") or not acid_text.contains("Tuning") or not acid_text.contains("契约"):
		push_error("酸冠母 card must show name, Tuning tendency, and contract framing.")
		return false

	run.call("select_guardian", "hive_vein_mother")
	run.call("confirm_guardian")

	if String(run.call("get_selected_guardian_id")) != "hive_vein_mother":
		push_error("Guardian selection did not persist into the run model.")
		return false

	if String(run.call("get_current_node_id")) != "battle_1":
		push_error("Guardian confirmation should route to Battle 1.")
		return false

	return true

func _verify_reward_one_and_battle_two(run: Node) -> bool:
	if not _has_methods(run, [
		"complete_current_battle_for_verifier",
		"get_gold",
		"get_reward_card_text",
		"choose_reward_one",
		"get_reward_one_id",
		"get_battle_modifier_marker_text",
	]):
		return false

	run.call("complete_current_battle_for_verifier", "Win")
	if String(run.call("get_current_node_id")) != "reward_1":
		push_error("Battle 1 win should route to Reward 1.")
		return false
	if int(run.call("get_gold")) != 6:
		push_error("Battle 1 win should add 6 Gold.")
		return false

	var reward_text: String = String(run.call("get_reward_card_text", "prime_charge"))
	if not reward_text.contains("Tuning") or not reward_text.contains("Prime") or not reward_text.contains("数值 +1 提升到 +2"):
		push_error("Prime Charge card must show axis, component, and operation.")
		return false
	if _text_has_internal_path(reward_text):
		push_error("Reward 1 card must not expose internal component paths.")
		return false
	if reward_text.contains("Reward"):
		push_error("Reward 1 card should localize player-facing role labels.")
		return false
	if (
		not _node_tree_text_contains(run, "Pool 扩容袋")
		or not _node_tree_text_contains(run, "Prime 充能")
		or not _node_tree_text_contains(run, "S1 打底")
	):
		push_error("Reward 1 screen must visibly render all three reward cards.")
		return false

	run.call("choose_reward_one", "prime_charge")
	if String(run.call("get_reward_one_id")) != "prime_charge":
		push_error("Reward 1 choice did not persist.")
		return false
	if String(run.call("get_current_node_id")) != "battle_2":
		push_error("Reward 1 choice should route to Battle 2.")
		return false

	var marker_text: String = String(run.call("get_battle_modifier_marker_text"))
	if not marker_text.contains("Prime 充能") or not marker_text.contains("Tuning"):
		push_error("Battle 2 should expose the selected Reward 1 machine marker.")
		return false

	return true

func _verify_shop_rest_and_battle_three(run: Node) -> bool:
	if not _has_methods(run, [
		"get_shop_card_text",
		"buy_shop_item",
		"get_shop_purchase_id",
		"damage_guardian_for_verifier",
		"can_buy_rest",
		"buy_rest",
		"get_guardian_hp",
		"get_guardian_max_hp",
		"get_rest_count",
		"confirm_shop_and_rest",
	]):
		return false

	run.call("complete_current_battle_for_verifier", "Win")
	if String(run.call("get_current_node_id")) != "shop_1":
		push_error("Battle 2 win should route to First Shop / Rest.")
		return false
	if int(run.call("get_gold")) != 12:
		push_error("Battle 2 win should bring Gold to 12 after two wins.")
		return false

	var shop_text: String = String(run.call("get_shop_card_text", "surge_buffer"))
	if not shop_text.contains("4 Gold") or not shop_text.contains("补洞") or not shop_text.contains("Tuning") or not shop_text.contains("Surge"):
		push_error("Shop card must show price, role, and machine component.")
		return false
	if shop_text.contains("Patch") or shop_text.contains("+1 buffer") or _text_has_internal_path(shop_text):
		push_error("Shop card should localize player-facing role and operation text.")
		return false
	if (
		not _node_tree_text_contains(run, "前置回流")
		or not _node_tree_text_contains(run, "Surge 缓冲")
		or not _node_tree_text_contains(run, "Queue 支撑")
	):
		push_error("First Shop screen must visibly render all three shop cards.")
		return false

	run.call("buy_shop_item", "surge_buffer")
	if String(run.call("get_shop_purchase_id")) != "surge_buffer":
		push_error("Shop purchase did not persist.")
		return false
	if not _node_tree_text_contains(run, "已购买"):
		push_error("First Shop screen must visibly mark the purchased shop item.")
		return false
	if int(run.call("get_gold")) != 8:
		push_error("Surge Buffer should cost 4 Gold from 12.")
		return false

	run.call("buy_shop_item", "queue_brace")
	if String(run.call("get_shop_purchase_id")) != "surge_buffer":
		push_error("First Shop should allow only one neutral machine modifier.")
		return false

	if bool(run.call("can_buy_rest")):
		push_error("Rest should not be available while Guardian HP is full.")
		return false

	run.call("damage_guardian_for_verifier", 30)
	if not bool(run.call("can_buy_rest")):
		push_error("Rest should become available after Guardian HP damage.")
		return false
	var hp_before: int = int(run.call("get_guardian_hp"))
	run.call("buy_rest")
	if int(run.call("get_gold")) != 5:
		push_error("Rest should cost 3 Gold.")
		return false
	var expected_hp_after_rest: int = mini(int(run.call("get_guardian_max_hp")), hp_before + 20)
	if int(run.call("get_guardian_hp")) != expected_hp_after_rest:
		push_error("Rest should restore 20 current HP without exceeding max HP.")
		return false
	if int(run.call("get_rest_count")) != 1:
		push_error("First Shop rest count should be 1 after buying rest.")
		return false

	run.call("confirm_shop_and_rest")
	if String(run.call("get_current_node_id")) != "battle_3":
		push_error("Leaving First Shop should route to Battle 3.")
		return false
	var battle_three_marker_text: String = String(run.call("get_battle_modifier_marker_text"))
	if (
		not battle_three_marker_text.contains("Surge 缓冲")
		or not battle_three_marker_text.contains("Tuning")
		or not battle_three_marker_text.contains("surge_buffer_enabled=true")
	):
		push_error("Battle 3 should expose the purchased Shop 1 machine marker: %s" % battle_three_marker_text)
		return false

	return true

func _verify_result_routing(run: Node) -> bool:
	if not _has_methods(run, [
		"get_result_summary_text",
		"get_result_record",
	]):
		return false

	run.call("complete_current_battle_for_verifier", "Loss")
	if String(run.call("get_current_node_id")) != "result_routing":
		push_error("Battle 3 loss should route to Result Routing.")
		return false

	var result_text: String = String(run.call("get_result_summary_text"))
	if not result_text.contains("巢脉母") or not result_text.contains("Prime 充能") or not result_text.contains("Surge 缓冲"):
		push_error("Result Routing must summarize Guardian, Reward 1, and Shop 1.")
		return false
	if result_text.contains("battle_3") or result_text.contains("Loss"):
		push_error("Result Routing should localize battle and result display text.")
		return false

	var record: Dictionary = run.call("get_result_record")
	if String(record.get("last_battle", "")) != "battle_3":
		push_error("Result record should include last_battle=battle_3.")
		return false
	if String(record.get("battle_result", "")) != "Loss":
		push_error("Result record should include battle_result=Loss.")
		return false

	return true

func _verify_supplemental_m2_paths(scene: PackedScene) -> bool:
	var passed: bool = true

	if not _verify_guardian_can_confirm(scene, "hive_acid_crown_mother"):
		passed = false
	if not _verify_reward_option_machine_marker(scene, "pool_pocket", "pool_capacity=6"):
		passed = false
	if not _verify_reward_option_machine_marker(scene, "prime_charge", "prime_value_bonus=2"):
		passed = false
	if not _verify_reward_option_machine_marker(scene, "slot_primer", "slot_id=1 floor=1"):
		passed = false
	if not _verify_battle_three_win_rest_route(scene):
		passed = false

	return passed

func _verify_guardian_can_confirm(scene: PackedScene, guardian_id: String) -> bool:
	var run: Node = _instantiate_run(scene)
	if run == null:
		return false

	run.call("select_guardian", guardian_id)
	run.call("confirm_guardian")

	var passed: bool = true
	if String(run.call("get_selected_guardian_id")) != guardian_id:
		push_error("Guardian selection did not persist for %s." % guardian_id)
		passed = false
	if String(run.call("get_current_node_id")) != "battle_1":
		push_error("Guardian %s should route to Battle 1 after confirmation." % guardian_id)
		passed = false

	_dispose_run(run)
	return passed

func _verify_reward_option_machine_marker(scene: PackedScene, reward_id: String, marker_needle: String) -> bool:
	var run: Node = _instantiate_run(scene)
	if run == null:
		return false

	run.call("select_guardian", "hive_vein_mother")
	run.call("confirm_guardian")
	run.call("complete_current_battle_for_verifier", "Win")
	run.call("choose_reward_one", reward_id)

	var passed: bool = true
	var marker_text: String = String(run.call("get_battle_modifier_marker_text"))
	if String(run.call("get_current_node_id")) != "battle_2":
		push_error("Reward %s should route to Battle 2." % reward_id)
		passed = false
	if not marker_text.contains(marker_needle):
		push_error("Reward %s should expose machine marker %s, got: %s" % [
			reward_id,
			marker_needle,
			marker_text,
		])
		passed = false

	_dispose_run(run)
	return passed

func _verify_battle_three_win_rest_route(scene: PackedScene) -> bool:
	var run: Node = _instantiate_run(scene)
	if run == null:
		return false

	run.call("select_guardian", "hive_vein_mother")
	run.call("confirm_guardian")
	run.call("complete_current_battle_for_verifier", "Win")
	run.call("choose_reward_one", "prime_charge")
	run.call("complete_current_battle_for_verifier", "Win")
	run.call("confirm_shop_and_rest")
	run.call("complete_current_battle_for_verifier", "Win")

	var passed: bool = true
	if String(run.call("get_current_node_id")) != "rest_after_battle_3":
		push_error("Battle 3 win should route to Battle 3 Rest.")
		passed = false
	if int(run.call("get_gold")) != 20:
		push_error("Battle 3 win should add +8 Gold after two prior wins.")
		passed = false

	run.call("damage_guardian_for_verifier", 30)
	if not bool(run.call("can_buy_rest")):
		push_error("Battle 3 Rest should become available after Guardian HP damage.")
		passed = false
	var hp_before: int = int(run.call("get_guardian_hp"))
	run.call("buy_rest")
	if int(run.call("get_gold")) != 17:
		push_error("Battle 3 Rest should cost 3 Gold.")
		passed = false
	var expected_hp_after_rest: int = mini(int(run.call("get_guardian_max_hp")), hp_before + 20)
	if int(run.call("get_guardian_hp")) != expected_hp_after_rest:
		push_error("Battle 3 Rest should restore 20 current HP without exceeding max HP.")
		passed = false
	if int(run.call("get_rest_count")) != 1:
		push_error("Battle 3 Rest count should be 1 after buying rest.")
		passed = false

	_dispose_run(run)
	return passed

func _verify_shop_modifier_machine_behaviors() -> bool:
	var passed: bool = true

	if not _verify_front_recycle_behavior():
		passed = false
	if not _verify_surge_buffer_behavior():
		passed = false
	if not _verify_queue_brace_behavior():
		passed = false

	return passed

func _verify_front_recycle_behavior() -> bool:
	var machine: MachineSimulator = MachineSimulator.new()
	machine.apply_modifier("front_recycle")
	machine.pool_capacity = 2
	machine.pool = [
		{"kind": "old_front", "value": 1},
		{"kind": "old_tail", "value": 1},
	]
	machine._step_index = 4
	machine.advance_step(1.3)

	if machine.pool.size() != 2:
		push_error("Front Recycle should respect pool capacity and preserve one returned ball.")
		return false
	if String(machine.pool[0].get("kind", "")) != "clean":
		push_error("Front Recycle should return the clean ball to Pool front.")
		return false
	if not _event_log_contains(machine.event_log, "Front Recycle returned clean ball to Pool front"):
		push_error("Front Recycle should write a readable machine event.")
		return false
	return true

func _verify_surge_buffer_behavior() -> bool:
	var machine: MachineSimulator = MachineSimulator.new()
	machine.apply_modifier("surge_buffer")

	machine.apply_physics_result(MachinePhysicsResult.make("Tuning", "Surge", 2, 1, "clean", "verifier"))
	if not bool(machine.surge_buffer_charge_by_slot.get(2, false)):
		push_error("Surge Buffer should store one slot-local buffer after Surge produces no Queue entry.")
		return false
	if not _event_log_contains(machine.event_log, "Surge Buffer stored S2 charge=1"):
		push_error("Surge Buffer should log buffer storage.")
		return false

	machine.apply_physics_result(MachinePhysicsResult.make("Tuning", "Gate", 1, 3, "clean", "verifier"))
	if not bool(machine.surge_buffer_charge_by_slot.get(2, false)):
		push_error("Surge Buffer charge should not be consumed by another slot.")
		return false

	machine.apply_physics_result(MachinePhysicsResult.make("Tuning", "Gate", 2, 5, "clean", "verifier"))
	if bool(machine.surge_buffer_charge_by_slot.get(2, false)):
		push_error("Surge Buffer should consume buffer on the charged slot's next queue entry.")
		return false
	var entry: Dictionary = machine.queue[machine.queue.size() - 1] as Dictionary
	if absf(float(entry.get("deploy_delay", -1.0)) - 0.25) > 0.001:
		push_error("Surge Buffer should attach deploy_delay=0.25 to the charged slot's next queue entry.")
		return false
	if not _event_log_contains(machine.event_log, "Surge Buffer S2 charge consumed"):
		push_error("Surge Buffer should log buffer consumption.")
		return false

	return true

func _verify_queue_brace_behavior() -> bool:
	var machine: MachineSimulator = MachineSimulator.new()
	machine.apply_modifier("queue_brace")
	var exposure := MachineSlotExposureState.new()
	machine.slot_progress = {1: 2, 2: 0, 3: 0, 4: 0}

	machine.record_empty_deploy_gap(3.0, 30.0, exposure)

	if int(machine.slot_progress.get(2, 0)) != 1:
		push_error("Queue Brace should compensate long no-Queue gaps on the lowest-progress exposed slot.")
		return false
	if int(machine.slot_progress.get(1, 0)) != 2:
		push_error("Queue Brace should not hard-code compensation to S1.")
		return false
	if not _event_log_contains(machine.event_log, "Queue Brace S2 +1"):
		push_error("Queue Brace should log selected-slot compensation.")
		return false

	return true

func _event_log_contains(event_log: Array[String], needle: String) -> bool:
	for log_line: String in event_log:
		if log_line.contains(needle):
			return true
	return false

func _node_tree_text_contains(node: Node, needle: String) -> bool:
	if node is Label and (node as Label).text.contains(needle):
		return true
	if node is Button and (node as Button).text.contains(needle):
		return true
	for child: Node in node.get_children():
		if _node_tree_text_contains(child, needle):
			return true
	return false

func _text_has_internal_path(text: String) -> bool:
	for internal_path: String in [
		"Launch.Pool",
		"Launch.Recycle",
		"Tuning.Prime",
		"Tuning.Surge",
		"Tuning.Echo",
		"Unit.S1",
		"Unit.Queue",
	]:
		if text.contains(internal_path):
			return true
	return false

func _instantiate_run(scene: PackedScene) -> Node:
	var run: Node = scene.instantiate()
	if run == null:
		push_error("Could not instantiate M2 run session scene.")
		return null
	root.add_child(run)
	return run

func _dispose_run(run: Node) -> void:
	if run == null:
		return
	root.remove_child(run)
	run.free()

func _has_methods(node: Node, methods: Array[String]) -> bool:
	for method_name: String in methods:
		if not node.has_method(method_name):
			push_error("M2 run scene missing method: %s" % method_name)
			return false
	return true
