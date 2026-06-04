extends RefCounted

func test_battle_lab_runtime_advances_and_changes_visible_state() -> bool:
	var root = load("res://scenes/battle_lab.tscn").instantiate()
	if not root.has_method("get_motion_snapshot") or not root.has_method("advance_for_test"):
		root.free()
		push_error("BattleLab must expose runtime motion methods")
		return false

	var before: Dictionary = root.call("get_motion_snapshot")
	root.call("advance_for_test", 2.0)
	var after: Dictionary = root.call("get_motion_snapshot")
	root.free()

	if float(after.get("time_seconds", 0.0)) <= float(before.get("time_seconds", 0.0)):
		push_error("Battle time must advance: before=%s after=%s" % [before, after])
		return false
	if after.get("active_event_count", 0) <= before.get("active_event_count", 0):
		push_error("Active events must increase after runtime advances: before=%s after=%s" % [before, after])
		return false
	if after.get("launch_snapshot") == before.get("launch_snapshot"):
		push_error("Launch lane snapshot must change with runtime motion")
		return false
	if after.get("frontline_snapshot") == before.get("frontline_snapshot"):
		push_error("Frontline snapshot must change with runtime motion")
		return false
	return true

func test_lane_views_accept_runtime_state() -> bool:
	var root = load("res://scenes/battle_lab.tscn").instantiate()
	for name in ["LaunchLane", "TuningLane", "UnitLane", "FrontlineView"]:
		var view = root.find_child(name, true, false)
		if not view.has_method("set_runtime_state") or not view.has_method("get_motion_snapshot"):
			root.free()
			push_error("%s must accept runtime state and expose motion snapshot" % name)
			return false
	root.free()
	return true

func test_launch_lane_exposes_readable_firing_chain() -> bool:
	var root = load("res://scenes/battle_lab.tscn").instantiate()
	var launch = root.find_child("LaunchLane", true, false)
	if launch == null or not launch.has_method("get_readability_landmarks"):
		root.free()
		push_error("LaunchLane must expose readable firing-chain landmarks")
		return false

	var landmarks: Array = launch.call("get_readability_landmarks")
	root.free()
	for expected in ["Forge / 产球", "Pool / 球池", "Launcher / 发射器", "Fired Ball / 发出的球", "Route / 发球路线"]:
		if not landmarks.has(expected):
			push_error("LaunchLane missing landmark: %s in %s" % [expected, landmarks])
			return false
	return true

func test_all_lanes_expose_requirement_landmarks() -> bool:
	var root = load("res://scenes/battle_lab.tscn").instantiate()
	var expected_by_node := {
		"TuningLane": ["Prime / 预充", "Echo / 复写", "Surge / 脉冲", "Copy Afterimage / 复写残影"],
		"UnitLane": ["Unit Slots / 出兵槽", "Queue / 队列", "Squad Bracket / 小队框", "Deploy / 出兵"],
		"FrontlineView": ["Sustained Flow / 持续水位", "Repeated Heavy Hit / 重复重击", "Batch Push / 成组推进", "Pressure Line / 战线"],
	}
	for node_name in expected_by_node:
		var view = root.find_child(node_name, true, false)
		if view == null or not view.has_method("get_readability_landmarks"):
			root.free()
			push_error("%s must expose readability landmarks" % node_name)
			return false
		var landmarks: Array = view.call("get_readability_landmarks")
		for expected in expected_by_node[node_name]:
			if not landmarks.has(expected):
				root.free()
				push_error("%s missing landmark: %s in %s" % [node_name, expected, landmarks])
				return false
	root.free()
	return true

func test_counter_and_overdrive_are_component_local_in_runtime_snapshot() -> bool:
	var root = load("res://scenes/battle_lab.tscn").instantiate()
	root.call("advance_for_test", 31.0)
	var snapshot: Dictionary = root.call("get_motion_snapshot")
	root.call("press_overdrive_for_test")
	root.call("advance_for_test", 0.1)
	var overdrive_snapshot: Dictionary = root.call("get_motion_snapshot")
	root.free()

	if snapshot.get("active_counter_target", "") != "pool_slots":
		push_error("Launch counter must target Pool slots at warning time: %s" % snapshot)
		return false
	if snapshot.get("active_counter_state", "") != "warning":
		push_error("Counter state should be warning at 31s: %s" % snapshot)
		return false
	if overdrive_snapshot.get("overdrive_axis", "") != "launch":
		push_error("Clicked Overdrive must be attached to Launch during Launch Flood: %s" % overdrive_snapshot)
		return false
	if overdrive_snapshot.get("overdrive_component", "") != "return_arrows":
		push_error("Launch Overdrive must amplify return arrows: %s" % overdrive_snapshot)
		return false
	return true

func test_battle_lab_reaches_visible_result_screen_after_battle_end() -> bool:
	var root = load("res://scenes/battle_lab.tscn").instantiate()
	root.call("advance_for_test", 75.0)
	if not root.has_method("result_screen_is_visible") or not root.call("result_screen_is_visible"):
		root.free()
		push_error("BattleLab must show result screen after battle ends")
		return false
	if not root.has_method("result_screen_question_count") or root.call("result_screen_question_count") != 4:
		root.free()
		push_error("Result screen must expose four blind questions")
		return false
	if not root.has_method("result_screen_confidence_count") or root.call("result_screen_confidence_count") != 4:
		root.free()
		push_error("Result screen must expose four confidence controls")
		return false
	root.free()
	return true
