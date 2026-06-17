class_name DeployLaneModel
extends RefCounted

const LANES: Array[String] = ["Left", "Mid", "Right"]

var current_lane: String = "Mid"
var change_log: Array[String] = ["Mid"]

func select_lane(lane: String) -> void:
	if not LANES.has(lane):
		push_error("Invalid deploy lane: %s" % lane)
		return
	current_lane = lane
	change_log.append(lane)
