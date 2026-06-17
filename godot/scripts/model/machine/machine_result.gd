class_name MachineResult
extends RefCounted

var source: String = ""
var result: String = ""
var unit_slot_id: int = 0
var unit_value: int = 0
var queue_entry: Dictionary = {}

func _init(
	p_source: String = "",
	p_result: String = "",
	p_unit_slot_id: int = 0,
	p_unit_value: int = 0,
	p_queue_entry: Dictionary = {}
) -> void:
	source = p_source
	result = p_result
	unit_slot_id = p_unit_slot_id
	unit_value = p_unit_value
	queue_entry = p_queue_entry

func to_log_line() -> String:
	if queue_entry.is_empty():
		return "%s:%s slot=%d value=%d" % [source, result, unit_slot_id, unit_value]
	return "%s:%s slot=%d value=%d entry=%s" % [source, result, unit_slot_id, unit_value, str(queue_entry)]
