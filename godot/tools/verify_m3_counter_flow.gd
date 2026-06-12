extends SceneTree

const RUN_SCENE_PATH: String = "res://scenes/run/mvp_run_session.tscn"

func _initialize() -> void:
	var failed: bool = false
	var scene: PackedScene = load(RUN_SCENE_PATH)
	if scene == null:
		push_error("M3 run session scene missing: %s" % RUN_SCENE_PATH)
		quit(1)
		return

	failed = not _verify_pool_polluter_path(scene) or failed
	failed = not _verify_echo_breaker_path(scene) or failed
	failed = not _verify_stagger_punisher_path(scene) or failed
	failed = not _verify_untriggered_counter_does_not_fake_effect(scene) or failed
	failed = not _verify_stagger_mid_deployments_reset_gap(scene) or failed

	if failed:
		quit(1)
		return

	print("verify_m3_counter_flow: PASS")
	quit(0)

func _verify_pool_polluter_path(scene: PackedScene) -> bool:
	var run: Node = _start_shop_with_counter(scene, "pool_polluter", "pool_pocket")
	if run == null:
		return false

	var passed: bool = true
	if not _has_methods(run, [
		"get_counter_scout_text",
		"get_visible_shop_item_ids",
		"buy_shop_item",
		"confirm_shop_and_rest",
		"advance_active_battle_for_verifier",
		"get_active_counter_banner_text",
		"get_active_machine_log_text",
		"complete_current_battle_for_verifier",
		"get_result_record",
		"get_result_summary_text",
	]):
		_dispose(run)
		return false

	var scout_text: String = String(run.call("get_counter_scout_text"))
	if not scout_text.contains("Pool Polluter") or not scout_text.contains("Pool"):
		push_error("Pool Polluter scout should name the family and Pool target.")
		passed = false

	var shop_ids: Array = run.call("get_visible_shop_item_ids") as Array
	if not shop_ids.has("junk_sieve"):
		push_error("Pool Polluter should prioritize Junk Sieve in the first shop.")
		passed = false

	run.call("buy_shop_item", "junk_sieve")
	run.call("confirm_shop_and_rest")
	run.call("advance_active_battle_for_verifier", 5.0)

	var early_banner_text: String = String(run.call("get_active_counter_banner_text"))
	if not early_banner_text.contains("待命") or early_banner_text.contains("生效："):
		push_error("Pool Polluter should not warn or apply before the 25-40s first counter window.")
		passed = false

	run.call("advance_active_battle_for_verifier", 25.5)

	var banner_text: String = String(run.call("get_active_counter_banner_text"))
	if not banner_text.contains("Pool Polluter") or not banner_text.contains("预警") or not banner_text.contains("Junk"):
		push_error("Pool Polluter warning should be visible during Battle 3. banner=%s record=%s" % [
			banner_text,
			str(run.call("get_counter_record")),
		])
		passed = false

	run.call("advance_active_battle_for_verifier", 20.0)
	var machine_log: String = String(run.call("get_active_machine_log_text"))
	if not machine_log.contains("Junk 插入 Pool") or not machine_log.contains("Junk Sieve"):
		push_error("Pool Polluter should insert Junk and purchased Junk Sieve should respond visibly.")
		passed = false
	if String(_active_machine_visual_contract(run).get("counter_target_component", "")) != "Pool":
		push_error("Pool Polluter should pass Pool target to machine board visuals.")
		passed = false

	run.call("complete_current_battle_for_verifier", "Loss")
	var record: Dictionary = run.call("get_result_record") as Dictionary
	if String(record.get("counter1.family", "")) != "pool_polluter":
		push_error("Result record should store counter1.family=pool_polluter.")
		passed = false
	if String(record.get("counter1.response_link", "")) != "Junk Sieve":
		push_error("Result record should link Pool Polluter to purchased Junk Sieve.")
		passed = false
	var result_text: String = String(run.call("get_result_summary_text"))
	if not result_text.contains("Pool Polluter") or not result_text.contains("Junk Sieve"):
		push_error("Result screen should summarize Pool Polluter and Junk Sieve response.")
		passed = false

	_dispose(run)
	return passed

func _verify_untriggered_counter_does_not_fake_effect(scene: PackedScene) -> bool:
	var run: Node = _start_shop_with_counter(scene, "stagger_punisher", "slot_primer")
	if run == null:
		return false

	var passed: bool = true
	run.call("confirm_shop_and_rest")
	run.call("complete_current_battle_for_verifier", "Loss")

	var record: Dictionary = run.call("get_result_record") as Dictionary
	if String(record.get("counter1.visible_effect", "")) != "":
		push_error("Untriggered counter should not record a fake visible effect.")
		passed = false

	var result_text: String = String(run.call("get_result_summary_text"))
	if result_text.contains("Raider 因 Queue 空档出现") or not result_text.contains("未触发"):
		push_error("Result screen should show untriggered counter as 未触发, not as Raider effect.")
		passed = false

	_dispose(run)
	return passed

func _verify_stagger_mid_deployments_reset_gap(scene: PackedScene) -> bool:
	var run: Node = _start_shop_with_counter(scene, "stagger_punisher", "slot_primer")
	if run == null:
		return false

	var passed: bool = true
	run.call("confirm_shop_and_rest")
	var battle: Node = run.get("active_battle") as Node
	if battle == null:
		push_error("Stagger regression test needs active Battle 3 node.")
		_dispose(run)
		return false

	battle.call("select_deploy_lane", "Mid")
	run.call("advance_active_battle_for_verifier", 3.2)
	for _i: int in range(4):
		if not _inject_verifier_queue_entry(run):
			passed = false
			break
		run.call("advance_active_battle_for_verifier", 0.6)
		run.call("advance_active_battle_for_verifier", 1.0)

	var lane_text: String = String(run.call("get_lane_button_text", "Left"))
	if lane_text.contains("突袭") or lane_text.contains("危险 2"):
		push_error("Stagger should not punish sustained Queue deployments just because they went Mid.")
		passed = false

	var counter_record: Dictionary = run.call("get_counter_record") as Dictionary
	if String(counter_record.get("visible_effect", "")).contains("Raider"):
		push_error("Stagger should not record Raider effect while Mid deployments keep resetting Queue gap.")
		passed = false

	_dispose(run)
	return passed

func _verify_echo_breaker_path(scene: PackedScene) -> bool:
	var run: Node = _start_shop_with_counter(scene, "echo_breaker", "prime_charge")
	if run == null:
		return false

	var passed: bool = true
	var shop_ids: Array = run.call("get_visible_shop_item_ids") as Array
	if not shop_ids.has("surge_buffer"):
		push_error("Echo Breaker should prioritize Surge Buffer in the first shop.")
		passed = false

	run.call("confirm_shop_and_rest")
	run.call("advance_active_battle_for_verifier", 24.0)
	var early_machine_log: String = String(run.call("get_active_machine_log_text"))
	if early_machine_log.contains("Echo Breaker 已锁定 Echo 槽") or early_machine_log.contains("Echo 复制降级为 Gate"):
		push_error("Echo Breaker should not apply before the first counter warning window.")
		passed = false

	run.call("advance_active_battle_for_verifier", 20.0)
	var machine_log: String = String(run.call("get_active_machine_log_text"))
	if not machine_log.contains("Echo Breaker") or not machine_log.contains("Echo 复制降级为 Gate"):
		push_error("Echo Breaker should visibly downgrade one Echo copy. record=%s log=%s" % [
			str(run.call("get_counter_record")),
			machine_log,
		])
		passed = false
	if String(_active_machine_visual_contract(run).get("counter_target_component", "")) != "Echo / Surge 价值":
		push_error("Echo Breaker should pass Echo target to machine board visuals.")
		passed = false

	var counter_record: Dictionary = run.call("get_counter_record") as Dictionary
	if String(counter_record.get("target_component", "")) != "Echo / Surge 价值":
		push_error("Echo Breaker counter record should target Echo / Surge value.")
		passed = false

	_dispose(run)
	return passed

func _verify_stagger_punisher_path(scene: PackedScene) -> bool:
	var run: Node = _start_shop_with_counter(scene, "stagger_punisher", "slot_primer")
	if run == null:
		return false

	var passed: bool = true
	var shop_ids: Array = run.call("get_visible_shop_item_ids") as Array
	if not shop_ids.has("queue_brace"):
		push_error("Stagger Punisher should prioritize Queue Brace in the first shop.")
		passed = false

	run.call("confirm_shop_and_rest")
	if not _block_verifier_queue_output(run):
		_dispose(run)
		return false
	run.call("advance_active_battle_for_verifier", 12.0)
	var early_lane_text: String = String(run.call("get_lane_button_text", "Left"))
	if early_lane_text.contains("突袭") or early_lane_text.contains("危险 2"):
		push_error("Stagger Punisher should not raise danger before the first counter window.")
		passed = false

	run.call("advance_active_battle_for_verifier", 30.0)
	var banner_text: String = String(run.call("get_active_counter_banner_text"))
	var lane_text: String = String(run.call("get_lane_button_text", "Left"))
	if not banner_text.contains("Stagger Punisher") or not banner_text.contains("队列空档"):
		push_error("Stagger Punisher should show queue-gap warning.")
		passed = false
	if not lane_text.contains("突袭") or not lane_text.contains("危险 2"):
		push_error("Stagger Punisher should raise visible lane danger.")
		passed = false

	var counter_record: Dictionary = run.call("get_counter_record") as Dictionary
	if String(counter_record.get("visible_effect", "")) != "Raider 因 Queue 空档出现":
		push_error("Stagger result should record Raider queue-gap effect.")
		passed = false
	if String(_active_machine_visual_contract(run).get("counter_target_component", "")) != "Queue 空档":
		push_error("Stagger Punisher should pass Queue target to machine board visuals.")
		passed = false

	_dispose(run)
	return passed

func _start_shop_with_counter(scene: PackedScene, counter_id: String, reward_id: String) -> Node:
	var run: Node = scene.instantiate()
	if run == null:
		push_error("Could not instantiate M3 run session scene.")
		return null
	root.add_child(run)

	if not _has_methods(run, [
		"select_guardian",
		"confirm_guardian",
		"set_next_counter_for_verifier",
		"complete_current_battle_for_verifier",
		"choose_reward_one",
	]):
		_dispose(run)
		return null

	run.call("select_guardian", "hive_vein_mother")
	run.call("confirm_guardian")
	run.call("set_next_counter_for_verifier", counter_id)
	run.call("complete_current_battle_for_verifier", "Win")
	run.call("choose_reward_one", reward_id)
	run.call("complete_current_battle_for_verifier", "Win")

	if String(run.call("get_current_node_id")) != "shop_1":
		push_error("M3 setup should reach first shop.")
		_dispose(run)
		return null

	return run

func _has_methods(node: Node, methods: Array[String]) -> bool:
	for method_name: String in methods:
		if not node.has_method(method_name):
			push_error("M3 run scene missing method: %s" % method_name)
			return false
	return true

func _active_machine_visual_contract(run: Node) -> Dictionary:
	var battle: Node = run.get("active_battle") as Node
	if battle == null or not battle.has_method("get_machine_visual_contract"):
		return {}
	return (battle.call("get_machine_visual_contract") as Dictionary).duplicate(true)

func _inject_verifier_queue_entry(run: Node) -> bool:
	var battle: Node = run.get("active_battle") as Node
	if battle == null:
		push_error("No active battle for verifier queue injection.")
		return false
	var machine: Object = battle.get("machine") as Object
	if machine == null:
		push_error("No machine simulator for verifier queue injection.")
		return false
	var queue: Array = machine.get("queue") as Array
	queue.append({
		"unit_id": "hive_short_fang",
		"slot_id": 1,
		"source": "Verifier",
		"count": 1,
	})
	machine.set("queue", queue)
	return true

func _block_verifier_queue_output(run: Node) -> bool:
	var battle: Node = run.get("active_battle") as Node
	if battle == null:
		push_error("No active battle for verifier queue blocking.")
		return false
	var machine: Object = battle.get("machine") as Object
	if machine == null:
		push_error("No machine simulator for verifier queue blocking.")
		return false
	machine.set("pool_capacity", 0)
	machine.set("queue", [])
	return true

func _dispose(run: Node) -> void:
	if run == null:
		return
	root.remove_child(run)
	run.free()
