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
