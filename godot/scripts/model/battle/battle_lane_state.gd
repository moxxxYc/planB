class_name BattleLaneState
extends RefCounted

const LANES: Array[String] = ["Left", "Mid", "Right"]
const RESULT_RUNNING: String = "Running"
const RESULT_WIN: String = "Win"
const RESULT_LOSS: String = "Loss"
const PRESSURED_LANE: String = "Left"
const PRESSURED_LANE_REQUIRED_UNITS: int = 1
const PRESSURE_LIMIT_SECONDS: float = 28.0

var player_units: Dictionary = {"Left": 0, "Mid": 0, "Right": 0}
var deploy_log: Array[String] = []
var battle_elapsed: float = 0.0
var battle_result: String = RESULT_RUNNING
var result_text: String = "战斗进行中：左路轻压，Queue 需要落到受压路线。"

func apply_player_deploy(lane: String, queue_entry: Dictionary) -> void:
	if not LANES.has(lane):
		push_error("Invalid battle lane: %s" % lane)
		return

	var count: int = int(queue_entry.get("count", 1))
	player_units[lane] = int(player_units.get(lane, 0)) + count
	deploy_log.append("%s:%s x%d" % [lane, String(queue_entry.get("unit_id", "unknown_unit")), count])
	_update_battle_result()

func advance_battle(delta: float) -> void:
	if battle_result != RESULT_RUNNING:
		return

	battle_elapsed += delta
	_update_battle_result()

func get_player_units(lane: String) -> int:
	if not LANES.has(lane):
		push_error("Invalid battle lane: %s" % lane)
		return 0

	return int(player_units.get(lane, 0))

func get_battle_result() -> String:
	return battle_result

func get_result_text() -> String:
	return result_text

func _update_battle_result() -> void:
	if battle_result != RESULT_RUNNING:
		return

	if get_player_units(PRESSURED_LANE) >= PRESSURED_LANE_REQUIRED_UNITS:
		battle_result = RESULT_WIN
		result_text = "战斗 1 胜利：Queue 成功支援左路，受压路线守住。"
		return

	if battle_elapsed >= PRESSURE_LIMIT_SECONDS:
		battle_result = RESULT_LOSS
		result_text = "战斗 1 失败：左路长期没有 Queue 支援，受压路线被突破。"
