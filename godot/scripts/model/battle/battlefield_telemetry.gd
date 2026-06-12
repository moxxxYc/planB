class_name BattlefieldTelemetry
extends RefCounted

var deploy_lane_changes: Array[String] = []
var deploy_events: Array[Dictionary] = []
var visible_contribution_slots: Array[int] = []
var key_queue_entries_by_slot: Dictionary = {}
var guardian_hp_pressure_events: Array[String] = []
var endpoint_primary_axis_payoff: String = "未明显兑现"
var endpoint_main_break_reason: String = "未定"
var endpoint_next_run_watch_tag: String = "lane leak watch"
var endpoint_deploy_lane_impact: String = "未记录关键路线选择"
var guardian_break_recorded: bool = false

func record_lane_change(lane: String) -> void:
	if deploy_lane_changes.is_empty() or deploy_lane_changes[deploy_lane_changes.size() - 1] != lane:
		deploy_lane_changes.append(lane)

func record_deploy(lane: String, queue_entry: Dictionary) -> void:
	var slot_id: int = int(queue_entry.get("slot_id", 0))
	var unit_id: String = String(queue_entry.get("unit_id", "unknown"))
	var record: Dictionary = {
		"lane": lane,
		"unit_id": unit_id,
		"slot_id": slot_id,
		"count": int(queue_entry.get("count", 1)),
		"source": String(queue_entry.get("source", "")),
	}
	deploy_events.append(record)
	if slot_id > 0 and not visible_contribution_slots.has(slot_id):
		visible_contribution_slots.append(slot_id)
	if slot_id > 0 and not key_queue_entries_by_slot.has(slot_id):
		key_queue_entries_by_slot[slot_id] = []
	if slot_id > 0:
		var entries: Array = key_queue_entries_by_slot[slot_id] as Array
		if entries.size() < 3:
			entries.append(record)
	if lane == "Left":
		endpoint_deploy_lane_impact = "关键 Queue 条目投到左路受压线，避免路线漏兵。"
	elif endpoint_deploy_lane_impact == "未记录关键路线选择":
		endpoint_deploy_lane_impact = "Queue 投到%s，路线选择改变了后续落点。" % _lane_name(lane)

func record_guardian_pressure(text: String) -> void:
	guardian_hp_pressure_events.append(text)

func record_guardian_break(text: String) -> void:
	if guardian_break_recorded:
		return
	guardian_break_recorded = true
	record_guardian_pressure(text)
	endpoint_main_break_reason = "守护者 HP 被打穿"
	endpoint_next_run_watch_tag = "Guardian HP pressure"

func record_axis_payoff(tag: String) -> void:
	if tag.is_empty():
		return
	endpoint_primary_axis_payoff = tag

func to_record() -> Dictionary:
	return {
		"battle1.deploy_lane_selection": ", ".join(deploy_lane_changes),
		"unit.visible_contribution_slots": visible_contribution_slots.duplicate(),
		"unit.key_queue_entries_by_slot": key_queue_entries_by_slot.duplicate(true),
		"guardian.hp_pressure_events": guardian_hp_pressure_events.duplicate(),
		"endpoint.primary_axis_payoff": endpoint_primary_axis_payoff,
		"endpoint.main_break_reason": endpoint_main_break_reason,
		"endpoint.next_run_watch_tag": endpoint_next_run_watch_tag,
		"endpoint.deploy_lane_impact": endpoint_deploy_lane_impact,
	}

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
