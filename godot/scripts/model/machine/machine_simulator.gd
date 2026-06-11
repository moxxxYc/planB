class_name MachineSimulator
extends RefCounted

const SLOT_REQUIREMENTS: Dictionary = {
	1: 3,
	2: 5,
	3: 8,
	4: 12,
}

var forge_progress: float = 0.0
var launcher_progress: float = 0.0
var pool: Array[Dictionary] = []
var slot_progress: Dictionary = {1: 0, 2: 0, 3: 0, 4: 0}
var queue: Array[Dictionary] = []
var event_log: Array[String] = []
var _step_index: int = 0

func advance_step(delta: float) -> void:
	forge_progress += delta
	launcher_progress += delta

	if forge_progress >= 2.2:
		forge_progress -= 2.2
		_add_pool_ball("clean")

	if launcher_progress >= 1.3 and not pool.is_empty():
		launcher_progress -= 1.3
		var ball: Dictionary = pool.pop_front()
		_route_ball(ball)

func has_queue_entry() -> bool:
	return not queue.is_empty()

func pop_queue_entry() -> Dictionary:
	if queue.is_empty():
		return {}
	return queue.pop_front()

func _add_pool_ball(kind: String) -> void:
	if pool.size() >= 5:
		event_log.append("Launch.Pool full rejected %s" % kind)
		return
	pool.append({"kind": kind, "value": 1})
	event_log.append("Launch.Forge added %s ball" % kind)

func _route_ball(ball: Dictionary) -> void:
	_step_index += 1
	var launch_result: String = _launch_result_for_step(_step_index)
	event_log.append(MachineResult.new("Launch", launch_result, 0, 0, {}).to_log_line())

	if launch_result == "Split":
		_add_pool_ball("clean")
		_add_pool_ball("clean")
		return

	if launch_result == "Recycle":
		_add_pool_ball("clean")
		return

	if launch_result == "Waste":
		event_log.append("Launch.Waste consumed ball")
		return

	var tuning_result: String = _tuning_result_for_step(_step_index)
	var value: int = int(ball.get("value", 1))
	if tuning_result == "Prime":
		value += 1

	var slot_id: int = _slot_for_step(_step_index)
	var added_entries: Array[Dictionary] = _apply_unit_hit(slot_id, value, tuning_result)
	event_log.append(MachineResult.new("Tuning", tuning_result, slot_id, value, {}).to_log_line())

	if tuning_result == "Echo":
		added_entries.append_array(_apply_unit_hit(slot_id, value, "EchoCopy"))

	for entry: Dictionary in added_entries:
		queue.append(entry)
		event_log.append(MachineResult.new("Unit", "QueueEntry", slot_id, value, entry).to_log_line())

func _apply_unit_hit(slot_id: int, value: int, source: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	slot_progress[slot_id] = int(slot_progress[slot_id]) + value
	var required: int = int(SLOT_REQUIREMENTS[slot_id])

	if int(slot_progress[slot_id]) >= required:
		slot_progress[slot_id] = int(slot_progress[slot_id]) - required
		entries.append({
			"unit_id": _unit_id_for_slot(slot_id),
			"slot_id": slot_id,
			"source": source,
			"count": 1,
		})

	return entries

func _launch_result_for_step(step: int) -> String:
	var pattern: Array[String] = ["Tuning", "Tuning", "Split", "Tuning", "Recycle", "Tuning", "Waste", "Tuning"]
	return pattern[(step - 1) % pattern.size()]

func _tuning_result_for_step(step: int) -> String:
	var pattern: Array[String] = ["Gate", "Prime", "Gate", "Echo", "Gate", "Surge"]
	return pattern[(step - 1) % pattern.size()]

func _slot_for_step(step: int) -> int:
	var pattern: Array[int] = [1, 1, 2, 1, 2, 3, 1, 4]
	return pattern[(step - 1) % pattern.size()]

func _unit_id_for_slot(slot_id: int) -> String:
	match slot_id:
		1:
			return "hive_short_fang"
		2:
			return "hive_shield_shell"
		3:
			return "hive_acid_sac"
		4:
			return "hive_crush_shell_beast"
		_:
			return "unknown_unit"
