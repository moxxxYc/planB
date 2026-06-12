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

	var banner_text: String = String(run.call("get_active_counter_banner_text"))
	if not banner_text.contains("Pool Polluter") or not banner_text.contains("预警") or not banner_text.contains("Junk"):
		push_error("Pool Polluter warning should be visible during Battle 3.")
		passed = false

	run.call("advance_active_battle_for_verifier", 20.0)
	var machine_log: String = String(run.call("get_active_machine_log_text"))
	if not machine_log.contains("Junk 插入 Pool") or not machine_log.contains("Junk Sieve"):
		push_error("Pool Polluter should insert Junk and purchased Junk Sieve should respond visibly.")
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
	var machine_log: String = String(run.call("get_active_machine_log_text"))
	if not machine_log.contains("Echo Breaker") or not machine_log.contains("Echo 复制降级为 Gate"):
		push_error("Echo Breaker should visibly downgrade one Echo copy.")
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
	run.call("advance_active_battle_for_verifier", 12.0)
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

func _dispose(run: Node) -> void:
	if run == null:
		return
	root.remove_child(run)
	run.free()
