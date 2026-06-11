extends SceneTree

const ALLOWED_TUNING_RESULTS: Array[String] = ["Gate", "Prime", "Echo", "Surge"]
const MIN_MACHINE_BOARD_HEIGHT: float = 560.0
const MIN_SUPPLY_STRIP_HEIGHT: float = 140.0
const MIN_POOL_BALL_RADIUS: float = 14.0
const MIN_ACTIVE_BALL_RADIUS: float = 12.0

func _initialize() -> void:
	var failed := false

	var machine := MachineSimulator.new()
	var deploy := DeployLaneModel.new()
	var lanes := BattleLaneState.new()
	var deployed_entries: Array[Dictionary] = []
	var deployed_lanes: Array[String] = []
	var deployed_event_ranges: Array[Dictionary] = []

	deploy.select_lane("Right")
	for i: int in range(12):
		var event_start_index: int = machine.event_log.size()
		machine.advance_step(0.5)
		var event_end_index: int = machine.event_log.size()
		while machine.has_queue_entry():
			var entry: Dictionary = machine.pop_queue_entry()
			var lane: String = deploy.current_lane
			lanes.apply_player_deploy(lane, entry)
			deployed_entries.append(entry)
			deployed_lanes.append(lane)
			deployed_event_ranges.append({
				"start": event_start_index,
				"end": event_end_index,
			})

	if deploy.current_lane != "Right":
		push_error("Deploy lane did not remain Right.")
		failed = true

	if lanes.get_player_units("Right") <= 0:
		push_error("Expected at least one player unit on Right lane.")
		failed = true

	if lanes.get_player_units("Left") != 0 or lanes.get_player_units("Mid") != 0:
		push_error("Expected no player units on non-selected lanes.")
		failed = true

	if deployed_entries.is_empty():
		push_error("Expected at least one queue entry to be deployed.")
		failed = true

	var has_queue_entry_event := false
	for log_line: String in machine.event_log:
		if log_line.contains("Unit:QueueEntry"):
			has_queue_entry_event = true
			break

	if not has_queue_entry_event:
		push_error("Expected machine event log to include Unit:QueueEntry causality.")
		failed = true

	var has_identified_deployed_entry := false
	var has_ordered_right_deployment := false
	for entry_index: int in range(deployed_entries.size()):
		var entry: Dictionary = deployed_entries[entry_index]
		var unit_id := String(entry.get("unit_id", ""))
		if entry.has("slot_id") and not unit_id.is_empty():
			has_identified_deployed_entry = true
			var deployed_lane: String = deployed_lanes[entry_index]
			var event_range: Dictionary = deployed_event_ranges[entry_index]
			var event_start_index: int = int(event_range["start"])
			var event_end_index: int = int(event_range["end"])
			if (
				deployed_lane == "Right"
				and _has_ordered_machine_chain(machine.event_log, event_start_index, event_end_index)
				and _has_deploy_log_for_unit(lanes.deploy_log, "Right", unit_id)
			):
				has_ordered_right_deployment = true
				break

		if has_ordered_right_deployment:
			break

	if not has_identified_deployed_entry:
		push_error("Expected deployed queue entry to include slot_id and unit_id.")
		failed = true

	if not has_ordered_right_deployment:
		push_error("Expected ordered Launch:Tuning -> Tuning -> Unit:QueueEntry chain to deploy on Right lane.")
		failed = true

	if not _verify_battle_scene():
		failed = true
	if not _verify_battle_result_paths():
		failed = true

	if failed:
		quit(1)
		return

	print("verify_m1_machine_to_lane: PASS")
	quit(0)

func _has_ordered_machine_chain(event_log: Array[String], start_index: int, end_index: int) -> bool:
	var found_launch_tuning := false
	var found_tuning_result := false

	for index: int in range(start_index, end_index):
		var log_line: String = event_log[index]

		if not found_launch_tuning:
			if log_line.begins_with("Launch:Tuning"):
				found_launch_tuning = true
			continue

		if not found_tuning_result:
			if _is_allowed_tuning_log(log_line):
				found_tuning_result = true
			continue

		if log_line.begins_with("Unit:QueueEntry"):
			return true

	return false

func _is_allowed_tuning_log(log_line: String) -> bool:
	for tuning_result: String in ALLOWED_TUNING_RESULTS:
		if log_line.begins_with("Tuning:%s " % tuning_result):
			return true
	return false

func _has_deploy_log_for_unit(deploy_log: Array[String], lane: String, unit_id: String) -> bool:
	for deploy_line: String in deploy_log:
		if deploy_line.begins_with("%s:%s " % [lane, unit_id]):
			return true
	return false

func _verify_battle_scene() -> bool:
	var passed := true
	var battle_scene: PackedScene = load("res://scenes/run/battle_one_vertical.tscn")
	if battle_scene == null:
		push_error("Could not load Battle 1 vertical scene.")
		return false

	var instance: Node = battle_scene.instantiate()
	if instance == null:
		push_error("Could not instantiate Battle 1 vertical scene.")
		return false

	root.add_child(instance)

	if not instance.has_method("get_selected_lane"):
		push_error("Battle scene does not expose selected lane state.")
		passed = false
	elif String(instance.call("get_selected_lane")) != "Mid":
		push_error("Battle scene should default to Mid deploy lane.")
		passed = false

	if not _verify_scene_route_text(instance, "Mid"):
		passed = false
	if not _verify_machine_visual_contract(instance):
		passed = false
	if not _verify_player_facing_machine_log(instance):
		passed = false

	if not instance.has_method("select_deploy_lane"):
		push_error("Battle scene does not expose direct deploy lane selection.")
		passed = false
	else:
		instance.call("select_deploy_lane", "Left")
		if String(instance.call("get_selected_lane")) != "Left":
			push_error("Battle scene did not select Left lane through direct lane selection.")
			passed = false

	if not instance.has_method("get_lane_button_text"):
		push_error("Battle scene does not expose lane button text for UI verification.")
		passed = false
	else:
		var left_button_text: String = String(instance.call("get_lane_button_text", "Left"))
		if not left_button_text.contains("选中路线") or not left_button_text.contains("左路出兵口"):
			push_error("Left lane button did not show selected text after lane selection.")
			passed = false

	if not _verify_scene_route_text(instance, "Left"):
		passed = false

	if (
		not instance.has_method("advance_simulation")
		or not instance.has_method("get_lane_units")
		or not instance.has_method("get_queue_count")
		or not instance.has_method("get_machine_event_count")
	):
		push_error("Battle scene does not expose simulation advancement and lane counts.")
		passed = false
	else:
		var left_units_before_deploy: int = int(instance.call("get_lane_units", "Left"))
		var saw_left_transfer_feedback := _verify_bridge_transfer_feedback_after_next_deploy(
			instance,
			"Left",
			left_units_before_deploy
		)
		if int(instance.call("get_lane_units", "Left")) <= 0:
			push_error("Expected Battle scene simulation to deploy at least one unit to selected Left lane.")
			passed = false
		if not saw_left_transfer_feedback:
			passed = false

		var left_units_before_switch: int = int(instance.call("get_lane_units", "Left"))
		var right_units_before_switch: int = int(instance.call("get_lane_units", "Right"))
		var queue_before_switch: int = int(instance.call("get_queue_count"))
		var machine_events_before_switch: int = int(instance.call("get_machine_event_count"))

		instance.call("select_deploy_lane", "Right")
		if String(instance.call("get_selected_lane")) != "Right":
			push_error("Battle scene did not select Right lane through direct lane selection.")
			passed = false
		var right_button_text: String = String(instance.call("get_lane_button_text", "Right"))
		if not right_button_text.contains("选中路线") or not right_button_text.contains("右路出兵口"):
			push_error("Right lane button did not show selected text after lane selection.")
			passed = false
		if not _verify_scene_route_text(instance, "Right"):
			passed = false
		if int(instance.call("get_lane_units", "Left")) != left_units_before_switch:
			push_error("Switching deploy lane should not rewrite already deployed Left units.")
			passed = false
		if int(instance.call("get_lane_units", "Right")) != right_units_before_switch:
			push_error("Switching deploy lane should not immediately create Right units.")
			passed = false
		if int(instance.call("get_queue_count")) != queue_before_switch:
			push_error("Switching deploy lane should not change machine queue count.")
			passed = false
		if int(instance.call("get_machine_event_count")) != machine_events_before_switch:
			push_error("Switching deploy lane should not advance machine production.")
			passed = false

		for i: int in range(32):
			instance.call("advance_simulation", 0.5)
		if int(instance.call("get_lane_units", "Right")) <= right_units_before_switch:
			push_error("Expected later Battle scene simulation to deploy units to newly selected Right lane.")
			passed = false
		if int(instance.call("get_lane_units", "Left")) != left_units_before_switch:
			push_error("After switching to Right, later deploys should not keep adding to Left lane.")
			passed = false

	root.remove_child(instance)
	instance.free()
	return passed

func _verify_battle_result_paths() -> bool:
	var passed := true

	var win_instance := _instantiate_battle_scene()
	if win_instance == null:
		return false
	root.add_child(win_instance)
	win_instance.call("select_deploy_lane", "Left")
	if not _advance_until_battle_result(win_instance, "Win", 80):
		push_error("Battle 1 should expose a victory path when the pressured lane receives Queue units.")
		passed = false
	var win_text := String(win_instance.call("get_battle_result_text")) if win_instance.has_method("get_battle_result_text") else ""
	if not win_text.contains("胜利") or not win_text.contains("左路"):
		push_error("Battle 1 victory text should explain the pressured lane result: %s" % win_text)
		passed = false
	root.remove_child(win_instance)
	win_instance.free()

	var loss_instance := _instantiate_battle_scene()
	if loss_instance == null:
		return false
	root.add_child(loss_instance)
	loss_instance.call("select_deploy_lane", "Right")
	if not _advance_until_battle_result(loss_instance, "Loss", 80):
		push_error("Battle 1 should expose a loss path when the pressured lane receives no Queue units.")
		passed = false
	var loss_text := String(loss_instance.call("get_battle_result_text")) if loss_instance.has_method("get_battle_result_text") else ""
	if not loss_text.contains("失败") or not loss_text.contains("左路"):
		push_error("Battle 1 loss text should explain the missed pressured lane: %s" % loss_text)
		passed = false
	root.remove_child(loss_instance)
	loss_instance.free()

	return passed

func _instantiate_battle_scene() -> Node:
	var battle_scene: PackedScene = load("res://scenes/run/battle_one_vertical.tscn")
	if battle_scene == null:
		push_error("Could not load Battle 1 vertical scene for result-path verification.")
		return null
	var instance: Node = battle_scene.instantiate()
	if instance == null:
		push_error("Could not instantiate Battle 1 vertical scene for result-path verification.")
		return null
	if not instance.has_method("get_battle_result") or not instance.has_method("get_battle_result_text"):
		push_error("Battle scene does not expose Battle 1 result state.")
		instance.free()
		return null
	return instance

func _advance_until_battle_result(instance: Node, expected_result: String, max_steps: int) -> bool:
	for i: int in range(max_steps):
		instance.call("advance_simulation", 0.5)
		if String(instance.call("get_battle_result")) != "Running":
			return String(instance.call("get_battle_result")) == expected_result
	return false

func _verify_player_facing_machine_log(instance: Node) -> bool:
	if not instance.has_method("get_machine_readable_log_text"):
		push_error("Battle scene does not expose player-facing machine log text.")
		return false

	for i: int in range(12):
		instance.call("advance_simulation", 0.5)

	var log_text: String = String(instance.call("get_machine_readable_log_text"))
	if log_text.is_empty():
		push_error("Player-facing machine log text should not be empty after simulation advances.")
		return false

	var forbidden_tokens: Array[String] = ["slot=", "value=", "entry=", "{", "}", "\"unit_id\""]
	for token: String in forbidden_tokens:
		if log_text.contains(token):
			push_error("Player-facing machine log leaks debug token '%s': %s" % [token, log_text])
			return false

	return true

func _verify_bridge_transfer_feedback_after_next_deploy(instance: Node, lane: String, units_before: int) -> bool:
	if not instance.has_method("get_bridge_transfer_text"):
		push_error("Battle scene does not expose Queue Bridge transfer feedback text.")
		return false

	var transfer_text := ""
	for i: int in range(24):
		instance.call("advance_simulation", 0.5)
		if int(instance.call("get_lane_units", lane)) > units_before:
			transfer_text = String(instance.call("get_bridge_transfer_text"))
			break

	var lane_name := _lane_name(lane)
	if transfer_text.is_empty():
		push_error("Queue Bridge should show a visible transfer confirmation after deployment.")
		return false
	if not transfer_text.contains(lane_name) or not transfer_text.contains("出兵口"):
		push_error("Queue Bridge transfer feedback should name the target spawn port: %s" % transfer_text)
		return false

	for i: int in range(4):
		instance.call("advance_simulation", 0.5)

	var expired_transfer_text: String = String(instance.call("get_bridge_transfer_text"))
	if not expired_transfer_text.is_empty():
		push_error("Queue Bridge transfer feedback should clear after a short dwell: %s" % expired_transfer_text)
		return false

	return true

func _verify_machine_visual_contract(instance: Node) -> bool:
	var passed := true

	if not instance.has_method("get_machine_visual_contract"):
		push_error("Battle scene does not expose machine visual contract.")
		return false

	var visual_contract: Dictionary = instance.call("get_machine_visual_contract")
	if int(visual_contract.get("board_count", 0)) != 3:
		push_error("Machine view must expose three visible boards: Launch / Tuning / Unit.")
		passed = false
	if int(visual_contract.get("pool_slot_count", 0)) != 5:
		push_error("Machine view must expose five visible Pool slots.")
		passed = false
	if int(visual_contract.get("unit_slot_count", 0)) != 4:
		push_error("Machine view must expose four visible Unit slots.")
		passed = false
	if int(visual_contract.get("queue_preview_count", 0)) < 3:
		push_error("Machine view must expose at least three Queue preview slots.")
		passed = false
	if not bool(visual_contract.get("has_active_ball", false)):
		push_error("Machine view must expose an active ball marker.")
		passed = false
	if float(visual_contract.get("machine_board_min_height", 0.0)) < MIN_MACHINE_BOARD_HEIGHT:
		push_error("Machine view must reserve enough height for readable ball-machine boards.")
		passed = false
	if float(visual_contract.get("supply_strip_height", 0.0)) < MIN_SUPPLY_STRIP_HEIGHT:
		push_error("Machine view must reserve a readable Forge / Pool / Launcher supply chamber.")
		passed = false
	if float(visual_contract.get("pool_ball_radius", 0.0)) < MIN_POOL_BALL_RADIUS:
		push_error("Pool balls are too small to satisfy the M1 readability gate.")
		passed = false
	if float(visual_contract.get("active_ball_radius", 0.0)) < MIN_ACTIVE_BALL_RADIUS:
		push_error("Active ball marker is too small to satisfy the M1 readability gate.")
		passed = false

	return passed

func _verify_scene_route_text(instance: Node, lane: String) -> bool:
	var passed := true

	if not instance.has_method("get_bridge_lane_text"):
		push_error("Battle scene does not expose Queue Bridge lane text.")
		return false
	if not instance.has_method("get_bridge_route_text"):
		push_error("Battle scene does not expose Queue Bridge route text.")
		return false
	if not instance.has_method("get_spawn_port_text"):
		push_error("Battle scene does not expose spawn-port text.")
		return false

	var lane_text: String = String(instance.call("get_bridge_lane_text"))
	var route_text: String = String(instance.call("get_bridge_route_text"))
	var spawn_port_text: String = String(instance.call("get_spawn_port_text"))
	var lane_name: String = _lane_name(lane)

	if not lane_text.contains(lane_name):
		push_error("Queue Bridge lane label did not reflect selected %s lane." % lane)
		passed = false
	if not route_text.contains("Queue Bridge -> %s出兵口" % lane_name):
		push_error("Queue Bridge route did not point to %s spawn port." % lane)
		passed = false
	if not spawn_port_text.contains("%s玩家侧出兵口" % lane_name):
		push_error("Spawn-port connector did not point to %s player-side spawn port." % lane)
		passed = false

	return passed

func _lane_name(lane: String) -> String:
	match lane:
		"Left":
			return "左路"
		"Mid":
			return "中路"
		"Right":
			return "右路"
		_:
			return lane
