class_name MachineSimulator
extends RefCounted

const SLOT_REQUIREMENTS: Dictionary = {
	1: 3,
	2: 5,
	3: 8,
	4: 12,
}
const QUEUE_BRACE_MISS_THRESHOLD: int = 3
const QUEUE_BRACE_COMPENSATION_VALUE: int = 1

var forge_progress: float = 0.0
var launcher_progress: float = 0.0
var pool_capacity: int = 5
var prime_value_bonus: int = 1
var surge_buffer_charge: int = 0
var queue_brace_gap_count: int = 0
var pool: Array[Dictionary] = []
var slot_progress: Dictionary = {1: 0, 2: 0, 3: 0, 4: 0}
var slot_progress_floor: Dictionary = {}
var queue: Array[Dictionary] = []
var event_log: Array[String] = []
var front_recycle_enabled: bool = false
var surge_buffer_enabled: bool = false
var queue_brace_enabled: bool = false
var active_modifier_ids: Array[String] = []
var active_modifier_markers: Array[String] = []
var _step_index: int = 0

func apply_modifier(modifier_id: String, payload: Dictionary = {}) -> void:
	var slot_id: int = int(payload.get("slot_id", 1))
	var active_key: String = _modifier_active_key(modifier_id, slot_id)
	if active_key.is_empty():
		return
	if active_modifier_ids.has(active_key):
		return

	var effect_marker: String = ""
	match modifier_id:
		"pool_pocket":
			pool_capacity = mini(pool_capacity + 1, 6)
			effect_marker = "pool_capacity=%d" % pool_capacity
		"prime_charge":
			prime_value_bonus = 2
			effect_marker = "prime_value_bonus=%d" % prime_value_bonus
		"slot_primer":
			slot_progress_floor[slot_id] = 1
			slot_progress[slot_id] = maxi(int(slot_progress.get(slot_id, 0)), 1)
			effect_marker = "slot_id=%d floor=1" % slot_id
		"front_recycle":
			front_recycle_enabled = true
			effect_marker = "front_recycle_enabled=true front_insert=true"
		"surge_buffer":
			surge_buffer_enabled = true
			effect_marker = "surge_buffer_enabled=true max=1"
		"queue_brace":
			queue_brace_enabled = true
			effect_marker = "queue_brace_enabled=true threshold=%d S1+1" % QUEUE_BRACE_MISS_THRESHOLD
		_:
			push_error("Unknown machine modifier: %s" % modifier_id)
			return

	active_modifier_ids.append(active_key)
	active_modifier_markers.append("%s (%s, %s)" % [
		_modifier_display_name(modifier_id),
		_modifier_axis(modifier_id),
		effect_marker,
	])
	event_log.append("Modifier:%s axis=%s key=%s id=%s %s" % [
		_modifier_display_name(modifier_id),
		_modifier_axis(modifier_id),
		active_key,
		modifier_id,
		effect_marker,
	])

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
	if pool.size() >= pool_capacity:
		event_log.append("Launch.Pool full rejected %s" % kind)
		return
	pool.append({"kind": kind, "value": 1})
	event_log.append("Launch.Forge added %s ball" % kind)

func _add_pool_ball_front(kind: String, source: String) -> void:
	if pool.size() >= pool_capacity:
		event_log.append("Modifier:%s front recycle rejected %s ball pool full" % [source, kind])
		return
	pool.push_front({"kind": kind, "value": 1})
	event_log.append("Modifier:%s returned %s ball to Pool front" % [source, kind])

func _route_ball(ball: Dictionary) -> void:
	_step_index += 1
	var launch_result: String = _launch_result_for_step(_step_index)
	event_log.append(MachineResult.new("Launch", launch_result, 0, 0, {}).to_log_line())

	if launch_result == "Split":
		_add_pool_ball("clean")
		_add_pool_ball("clean")
		_finalize_queue_output([], 0, 0)
		return

	if launch_result == "Recycle":
		if front_recycle_enabled:
			_add_pool_ball_front("clean", "Front Recycle")
		else:
			_add_pool_ball("clean")
		_finalize_queue_output([], 0, 0)
		return

	if launch_result == "Waste":
		event_log.append("Launch.Waste consumed ball")
		_finalize_queue_output([], 0, 0)
		return

	var tuning_result: String = _tuning_result_for_step(_step_index)
	var value: int = int(ball.get("value", 1))
	if tuning_result == "Prime":
		value += prime_value_bonus
	if surge_buffer_enabled and surge_buffer_charge > 0:
		surge_buffer_charge = 0
		value += 1
		event_log.append("Modifier:Surge Buffer consumed buffer value+1 on %s" % tuning_result)

	var slot_id: int = _slot_for_step(_step_index)
	var added_entries: Array[Dictionary] = _apply_unit_hit(slot_id, value, tuning_result)
	event_log.append(MachineResult.new("Tuning", tuning_result, slot_id, value, {}).to_log_line())

	if tuning_result == "Echo":
		added_entries.append_array(_apply_unit_hit(slot_id, value, "EchoCopy"))

	if surge_buffer_enabled and tuning_result == "Surge" and added_entries.is_empty():
		surge_buffer_charge = mini(1, surge_buffer_charge + 1)
		event_log.append("Modifier:Surge Buffer stored buffer=1 after Surge no Queue")

	_finalize_queue_output(added_entries, slot_id, value)

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

	var floor_value: int = int(slot_progress_floor.get(slot_id, 0))
	slot_progress[slot_id] = maxi(int(slot_progress[slot_id]), floor_value)

	return entries

func _finalize_queue_output(added_entries: Array[Dictionary], natural_slot_id: int, natural_value: int) -> void:
	var output_entries: Array[Dictionary] = added_entries.duplicate(true)
	if output_entries.is_empty():
		_maybe_apply_queue_brace(output_entries)
	else:
		queue_brace_gap_count = 0

	for entry: Dictionary in output_entries:
		queue.append(entry)
		var entry_slot_id: int = int(entry.get("slot_id", natural_slot_id))
		var entry_value: int = QUEUE_BRACE_COMPENSATION_VALUE if String(entry.get("source", "")) == "QueueBrace" else natural_value
		event_log.append(MachineResult.new("Unit", "QueueEntry", entry_slot_id, entry_value, entry).to_log_line())

func _maybe_apply_queue_brace(output_entries: Array[Dictionary]) -> void:
	if not queue_brace_enabled:
		return

	queue_brace_gap_count += 1
	if queue_brace_gap_count < QUEUE_BRACE_MISS_THRESHOLD:
		return

	queue_brace_gap_count = 0
	var brace_entries: Array[Dictionary] = _apply_unit_hit(1, QUEUE_BRACE_COMPENSATION_VALUE, "QueueBrace")
	event_log.append("Modifier:Queue Brace S1 +1 after %d no-Queue routes" % QUEUE_BRACE_MISS_THRESHOLD)
	output_entries.append_array(brace_entries)

func get_modifier_marker_text() -> String:
	if active_modifier_markers.is_empty():
		return "本局机器修正：无"

	var marker_text := PackedStringArray()
	for marker: String in active_modifier_markers:
		marker_text.append(marker)
	return "本局机器修正：%s" % ", ".join(marker_text)

func get_pool_capacity() -> int:
	return pool_capacity

func _modifier_display_name(modifier_id: String) -> String:
	match modifier_id:
		"pool_pocket":
			return "Pool Pocket"
		"prime_charge":
			return "Prime Charge"
		"slot_primer":
			return "Slot Primer"
		"front_recycle":
			return "Front Recycle"
		"surge_buffer":
			return "Surge Buffer"
		"queue_brace":
			return "Queue Brace"
		_:
			return modifier_id

func _modifier_axis(modifier_id: String) -> String:
	match modifier_id:
		"pool_pocket", "front_recycle":
			return "Launch"
		"prime_charge", "surge_buffer":
			return "Tuning"
		"slot_primer", "queue_brace":
			return "Unit"
		_:
			return "Unknown"

func _modifier_active_key(modifier_id: String, slot_id: int) -> String:
	match modifier_id:
		"slot_primer":
			if not SLOT_REQUIREMENTS.has(slot_id):
				push_error("Unknown Slot Primer slot_id: %d" % slot_id)
				return ""
			return "%s:%d" % [modifier_id, slot_id]
		"pool_pocket", "prime_charge", "front_recycle", "surge_buffer", "queue_brace":
			return modifier_id
		_:
			push_error("Unknown machine modifier: %s" % modifier_id)
			return ""

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
