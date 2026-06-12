extends SceneTree

const RUN_SCENE_PATH: String = "res://scenes/run/mvp_run_session.tscn"

func _initialize() -> void:
	var failed: bool = false
	var scene: PackedScene = load(RUN_SCENE_PATH)
	if scene == null:
		push_error("M4 run session scene missing: %s" % RUN_SCENE_PATH)
		quit(1)
		return

	failed = not _verify_second_reward_for_axis(scene, "pool_pocket", "Launch", "front_recycle", "junk_sieve") or failed
	failed = not _verify_second_reward_for_axis(scene, "prime_charge", "Tuning", "echo_latch", "surge_buffer") or failed
	failed = not _verify_second_reward_for_axis(scene, "slot_primer", "Unit", "muster_pair", "queue_brace") or failed
	failed = not _verify_battle_four_loss_routes_to_result(scene) or failed
	failed = not _verify_no_battle_four_gold(scene) or failed

	if failed:
		quit(1)
		return

	print("verify_m4_second_reward_flow: PASS")
	quit(0)

func _verify_second_reward_for_axis(
	scene: PackedScene,
	reward_one_id: String,
	expected_axis: String,
	expected_deepen_id: String,
	expected_patch_or_pivot_id: String
) -> bool:
	var run: Node = _start_second_reward(scene, reward_one_id)
	if run == null:
		return false

	var passed: bool = true
	if String(run.call("get_current_node_id")) != "reward_2":
		push_error("Battle 4 win should route to reward_2.")
		passed = false

	if String(run.call("get_second_reward_current_axis")) != expected_axis:
		push_error("Second Reward current axis should be %s." % expected_axis)
		passed = false

	var candidate_ids: Array = run.call("get_second_reward_candidate_ids") as Array
	if not candidate_ids.has(expected_deepen_id):
		push_error("Second Reward should include deepen candidate %s." % expected_deepen_id)
		passed = false
	if not candidate_ids.has(expected_patch_or_pivot_id):
		push_error("Second Reward should include patch/pivot candidate %s." % expected_patch_or_pivot_id)
		passed = false
	for candidate_id_variant: Variant in candidate_ids:
		var candidate_id: String = String(candidate_id_variant)
		var candidate_card: String = String(run.call("get_second_reward_card_text", candidate_id))
		if candidate_card.contains("Gold"):
			push_error("Second Reward candidate should be free and should not display Gold: %s" % candidate_id)
			passed = false

	var deepen_card: String = String(run.call("get_second_reward_card_text", expected_deepen_id))
	if not deepen_card.contains("深化当前主轴"):
		push_error("Deepen candidate should display Chinese deepen role label.")
		passed = false
	if expected_deepen_id == "echo_latch" and not deepen_card.contains("Tuning 深化"):
		push_error("Echo Latch should display Tuning deepen as Chinese player-facing text in Second Reward.")
		passed = false

	run.call("choose_second_reward", expected_deepen_id)
	if String(run.call("get_current_node_id")) != "battle_5":
		push_error("Second Reward choice should route to Battle 5.")
		passed = false
	var marker_text: String = String(run.call("get_battle_modifier_marker_text"))
	if not marker_text.contains(_modifier_display_name(expected_deepen_id)):
		push_error("Battle 5 should expose selected Second Reward marker.")
		passed = false
	run.call("complete_current_battle_for_verifier", "Win")
	if String(run.call("get_current_node_id")) != "endpoint_prep":
		push_error("Battle 5 win should route to Endpoint Prep.")
		passed = false

	_dispose(run)
	return passed

func _modifier_display_name(modifier_id: String) -> String:
	match modifier_id:
		"front_recycle":
			return "Front Recycle"
		"junk_sieve":
			return "Junk Sieve"
		"surge_buffer":
			return "Surge Buffer"
		"queue_brace":
			return "Queue Brace"
		"muster_pair":
			return "Muster Pair"
		"echo_latch":
			return "Echo Latch"
		_:
			return modifier_id

func _verify_battle_four_loss_routes_to_result(scene: PackedScene) -> bool:
	var run: Node = _start_battle_four(scene, "prime_charge")
	if run == null:
		return false

	run.call("complete_current_battle_for_verifier", "Loss")
	var passed: bool = true
	if String(run.call("get_current_node_id")) != "result_routing":
		push_error("Battle 4 loss should route to result.")
		passed = false
	var record: Dictionary = run.call("get_result_record") as Dictionary
	if String(record.get("last_battle", "")) != "battle_4":
		push_error("Battle 4 loss result should record last_battle=battle_4.")
		passed = false
	if record.has("second_offer.choice_id"):
		push_error("Battle 4 loss should not record second reward choice.")
		passed = false

	_dispose(run)
	return passed

func _verify_no_battle_four_gold(scene: PackedScene) -> bool:
	var run: Node = _start_battle_four(scene, "pool_pocket")
	if run == null:
		return false

	var gold_before: int = int(run.call("get_gold"))
	run.call("complete_current_battle_for_verifier", "Win")
	var gold_after: int = int(run.call("get_gold"))
	var passed: bool = true
	if gold_after != gold_before:
		push_error("Battle 4 should not grant Gold.")
		passed = false

	_dispose(run)
	return passed

func _start_second_reward(scene: PackedScene, reward_one_id: String) -> Node:
	var run: Node = _start_battle_four(scene, reward_one_id)
	if run == null:
		return null
	run.call("complete_current_battle_for_verifier", "Win")
	return run

func _start_battle_four(scene: PackedScene, reward_one_id: String) -> Node:
	var run: Node = scene.instantiate()
	if run == null:
		push_error("Could not instantiate M4 run session scene.")
		return null
	root.add_child(run)

	var required_methods: Array[String] = [
		"select_guardian",
		"confirm_guardian",
		"set_next_counter_for_verifier",
		"complete_current_battle_for_verifier",
		"choose_reward_one",
		"confirm_shop_and_rest",
	]
	for method_name: String in required_methods:
		if not run.has_method(method_name):
			push_error("M4 run scene missing method: %s" % method_name)
			_dispose(run)
			return null

	run.call("select_guardian", "hive_vein_mother")
	run.call("confirm_guardian")
	run.call("set_next_counter_for_verifier", _counter_for_reward(reward_one_id))
	run.call("complete_current_battle_for_verifier", "Win")
	run.call("choose_reward_one", reward_one_id)
	run.call("complete_current_battle_for_verifier", "Win")
	run.call("confirm_shop_and_rest")
	run.call("complete_current_battle_for_verifier", "Win")
	if String(run.call("get_current_node_id")) == "rest_after_battle_3":
		run.call("confirm_shop_and_rest")

	if String(run.call("get_current_node_id")) != "battle_4":
		push_error("M4 setup should reach battle_4, got %s." % String(run.call("get_current_node_id")))
		_dispose(run)
		return null
	return run

func _counter_for_reward(reward_one_id: String) -> String:
	match reward_one_id:
		"pool_pocket":
			return "pool_polluter"
		"slot_primer":
			return "stagger_punisher"
		_:
			return "echo_breaker"

func _dispose(run: Node) -> void:
	if run == null:
		return
	root.remove_child(run)
	run.free()
