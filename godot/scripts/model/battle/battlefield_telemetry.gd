class_name BattlefieldTelemetry
extends RefCounted

var deploy_lane_changes: Array[String] = []
var deploy_lane_change_records: Array[Dictionary] = []
var deploy_events: Array[Dictionary] = []
var visible_contribution_slots: Array[int] = []
var key_queue_entries_by_slot: Dictionary = {}
var first_window_lane_danger_snapshot: Dictionary = {}
var guardian_hp_pressure_events: Array[String] = []
var endpoint_primary_axis_payoff: String = "未明显兑现"
var endpoint_main_break_reason: String = "未定"
var endpoint_next_run_watch_tag: String = "观察部署路线漏兵"
var endpoint_deploy_lane_impact: String = "未记录关键路线选择"
var guardian_break_recorded: bool = false

func record_lane_change(lane: String, battle_elapsed: float = -1.0) -> void:
	if deploy_lane_changes.is_empty() or deploy_lane_changes[deploy_lane_changes.size() - 1] != lane:
		deploy_lane_changes.append(lane)
		deploy_lane_change_records.append({
			"lane": lane,
			"time": maxf(0.0, battle_elapsed),
		})

func record_deploy(lane: String, queue_entry: Dictionary, battle_elapsed: float = 0.0) -> void:
	var slot_id: int = int(queue_entry.get("slot_id", 0))
	var unit_id: String = String(queue_entry.get("unit_id", "unknown"))
	var record: Dictionary = {
		"lane": lane,
		"unit_id": unit_id,
		"slot_id": slot_id,
		"count": int(queue_entry.get("count", 1)),
		"source": String(queue_entry.get("source", "")),
		"time": maxf(0.0, battle_elapsed),
		"result": "Queue 部署到%s，清理或压住该路线危险。" % _lane_name(lane),
	}
	deploy_events.append(record)
	if slot_id > 0 and not visible_contribution_slots.has(slot_id):
		visible_contribution_slots.append(slot_id)
	if slot_id > 0:
		var slot_key: String = "S%d" % slot_id
		if not key_queue_entries_by_slot.has(slot_key):
			key_queue_entries_by_slot[slot_key] = []
		var entries: Array = key_queue_entries_by_slot[slot_key] as Array
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
	endpoint_next_run_watch_tag = "观察守护者 HP 压力"

func record_lane_danger_snapshot(lane_danger: Dictionary, enemy_raiders: Dictionary, player_units: Dictionary, battle_elapsed: float) -> void:
	if battle_elapsed > 30.0:
		return
	for lane: String in ["Left", "Mid", "Right"]:
		var previous: Dictionary = first_window_lane_danger_snapshot.get(lane, {
			"danger": 0,
			"enemy_raiders": 0,
			"player_units": 0,
		}) as Dictionary
		first_window_lane_danger_snapshot[lane] = {
			"danger": maxi(int(previous.get("danger", 0)), int(lane_danger.get(lane, 0))),
			"enemy_raiders": maxi(int(previous.get("enemy_raiders", 0)), int(enemy_raiders.get(lane, 0))),
			"player_units": maxi(int(previous.get("player_units", 0)), int(player_units.get(lane, 0))),
		}

func record_axis_payoff(tag: String) -> void:
	if tag.is_empty():
		return
	endpoint_primary_axis_payoff = tag

func to_record() -> Dictionary:
	return {
		"battle1.deploy_lane_selection": deploy_lane_change_records.duplicate(true),
		"battle1.lane_danger_snapshot": first_window_lane_danger_snapshot.duplicate(true),
		"unit.visible_contribution_slots": _visible_contribution_slot_records(),
		"unit.key_queue_entries_by_slot": key_queue_entries_by_slot.duplicate(true),
		"unit.dominant_slot_share": _dominant_slot_share(),
		"guardian.hp_pressure_events": guardian_hp_pressure_events.duplicate(),
		"endpoint.primary_axis_payoff": endpoint_primary_axis_payoff,
		"endpoint.main_break_reason": endpoint_main_break_reason,
		"endpoint.next_run_watch_tag": endpoint_next_run_watch_tag,
		"endpoint.deploy_lane_impact": endpoint_deploy_lane_impact,
	}

func _visible_contribution_slot_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for slot_id: int in visible_contribution_slots:
		var entries: Array = key_queue_entries_by_slot.get("S%d" % slot_id, []) as Array
		records.append({
			"slot_id": slot_id,
			"unit_id": String((entries[0] as Dictionary).get("unit_id", "unknown")) if not entries.is_empty() else "unknown",
			"count": entries.size(),
			"visible_result": "该槽产生 Queue 条目并在路线压力中形成可见贡献。",
		})
	return records

func _dominant_slot_share() -> Dictionary:
	var total_entries: int = 0
	var best_slot_id: int = 1
	var best_count: int = 0
	for slot_key: Variant in key_queue_entries_by_slot.keys():
		var entries: Array = key_queue_entries_by_slot[slot_key] as Array
		var count: int = entries.size()
		total_entries += count
		if count > best_count:
			best_count = count
			best_slot_id = _slot_id_from_key(slot_key)
	if total_entries <= 0:
		return {}
	return {
		"slot_id": best_slot_id,
		"share": float(best_count) / float(total_entries),
	}

func _slot_id_from_key(slot_key: Variant) -> int:
	if slot_key is int or slot_key is float:
		return int(slot_key)
	var text: String = String(slot_key).strip_edges().to_upper()
	if text.begins_with("S"):
		return int(text.substr(1))
	return int(text)

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
