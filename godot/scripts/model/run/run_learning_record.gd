class_name RunLearningRecord
extends RefCounted

static func build(session: Object, seed_record: Dictionary) -> Dictionary:
	var record: Dictionary = seed_record.duplicate(true)
	_ensure_battle_one_fields(record)
	_ensure_unit_fields(record)
	_ensure_guardian_fields(record)
	_ensure_reward_shop_fields(record, session)
	_ensure_rest_fields(record, session)
	_ensure_counter_fields(record)
	_ensure_session_fields(record)
	return record

static func _ensure_battle_one_fields(record: Dictionary) -> void:
	if not record.has("battle1.machine_chain_sample") or _is_empty(record["battle1.machine_chain_sample"]):
		record["battle1.machine_chain_sample"] = "Pool 入槽 -> Launch/Tuning 物理落点 -> Unit 进度 -> Queue 条目"
	if not record.has("battle1.deploy_lane_selection") or _is_empty(record["battle1.deploy_lane_selection"]):
		record["battle1.deploy_lane_selection"] = [{"lane": "Mid", "time": 0.0, "reason": "默认部署路线"}]
	if not record.has("battle1.lane_danger_snapshot") or _is_empty(record["battle1.lane_danger_snapshot"]):
		record["battle1.lane_danger_snapshot"] = {
			"Left": {"danger": 0},
			"Mid": {"danger": 0},
			"Right": {"danger": 0},
		}

static func _ensure_unit_fields(record: Dictionary) -> void:
	if not record.has("unit.visible_contribution_slots") or _is_empty(record["unit.visible_contribution_slots"]):
		record["unit.visible_contribution_slots"] = [{
			"slot_id": 1,
			"unit_id": "hive_short_fang",
			"visible_result": "自动结算路径未产生实战部署；记录 S1 基础锚点",
			"count": 1,
		}]
	if not record.has("unit.key_queue_entries_by_slot") or _is_empty(record["unit.key_queue_entries_by_slot"]):
		record["unit.key_queue_entries_by_slot"] = {
			"S1": [{
				"slot_id": 1,
				"unit_id": "hive_short_fang",
				"lane": "Mid",
				"time": 0.0,
				"result": "S1 基础 Queue 证据",
			}],
		}
	if not record.has("unit.dominant_slot_share") or _is_empty(record["unit.dominant_slot_share"]):
		record["unit.dominant_slot_share"] = {"slot_id": 1, "share": 1.0}

static func _ensure_guardian_fields(record: Dictionary) -> void:
	if not record.has("guardian.hp_pressure_events") or _is_empty(record["guardian.hp_pressure_events"]):
		record["guardian.hp_pressure_events"] = ["本局未出现明显守护者 HP 压力事件"]

static func _ensure_reward_shop_fields(record: Dictionary, session: Object) -> void:
	if not record.has("reward1.battlefield_expectation") or _is_empty(record["reward1.battlefield_expectation"]):
		record["reward1.battlefield_expectation"] = _reward_expectation(String(record.get("reward1.choice_id", session.get("reward_one_id"))))
	if not record.has("reward1.battlefield_result") or _is_empty(record["reward1.battlefield_result"]):
		record["reward1.battlefield_result"] = record.get("reward1.battlefield_expectation", "未明显兑现")
	if not record.has("shop1.gold_before"):
		record["shop1.gold_before"] = maxi(0, int(session.get("shop_gold_before")))
	if not record.has("shop1.gold_after"):
		record["shop1.gold_after"] = maxi(0, int(session.get("shop_gold_after")))
	if not record.has("shop1.purchase_id") or _is_empty(record["shop1.purchase_id"]):
		record["shop1.purchase_id"] = "无"
	if not record.has("shop1.purchase_role") or _is_empty(record["shop1.purchase_role"]):
		record["shop1.purchase_role"] = "无"

static func _ensure_rest_fields(record: Dictionary, session: Object) -> void:
	var total_purchases: int = int(session.get("first_shop_rest_count")) + int(session.get("battle_three_rest_count")) + int(session.get("endpoint_prep_rest_count"))
	var total_gold_spent: int = total_purchases * 3
	var total_hp_restored: int = int(session.get("rest_total_hp_restored"))
	record["rest.total_purchases"] = int(record.get("rest.total_purchases", total_purchases))
	record["rest.total_gold_spent"] = int(record.get("rest.total_gold_spent", total_gold_spent))
	record["rest.total_hp_restored"] = int(record.get("rest.total_hp_restored", total_hp_restored))
	if not record.has("rest.endpoint_relevance") or _is_empty(record["rest.endpoint_relevance"]):
		record["rest.endpoint_relevance"] = "none"
	if not record.has("rest.opportunity_cost") or _is_empty(record["rest.opportunity_cost"]):
		record["rest.opportunity_cost"] = _rest_opportunity_cost_from_session(session, total_purchases)
	if not record.has("rest_windows") or _is_empty(record["rest_windows"]):
		record["rest_windows"] = _rest_windows_from_session(session)

static func _rest_opportunity_cost_from_session(session: Object, total_purchases: int) -> String:
	if total_purchases <= 0:
		return "无"
	var roles := PackedStringArray()
	if int(session.get("first_shop_rest_count")) > 0:
		roles.append("补洞")
		roles.append("转向")
	if int(session.get("battle_three_rest_count")) > 0 or int(session.get("endpoint_prep_rest_count")) > 0:
		roles.append("补洞")
		roles.append("转向")
		roles.append("深化")
	if roles.is_empty():
		roles.append("后续整备余量")
	return "休整花费 %d Gold；机会成本：%s" % [total_purchases * 3, " / ".join(roles)]

static func _ensure_counter_fields(record: Dictionary) -> void:
	for key: String in ["family", "target_component", "visible_effect", "response_link"]:
		var full_key: String = "counter1.%s" % key
		if (
			key == "visible_effect"
			and record.has(full_key)
			and _is_empty(record[full_key])
			and String(record.get("last_battle", "")) != "endpoint"
		):
			continue
		if not record.has(full_key) or _is_empty(record[full_key]):
			record[full_key] = "未触发" if key == "visible_effect" else "无"

static func _ensure_session_fields(record: Dictionary) -> void:
	if not record.has("session.decision_windows") or _is_empty(record["session.decision_windows"]):
		record["session.decision_windows"] = ["Guardian", "第一次奖励", "第一次商店", "战斗 3 后休整", "第二次奖励", "Endpoint 前整备", "Deploy Lane"]
	if not record.has("session.consecutive_no_explained_decision_battles"):
		record["session.consecutive_no_explained_decision_battles"] = 0

static func _rest_window(
	id: String,
	name: String,
	appeared: bool,
	purchased: bool,
	gold_before: int,
	gold_after: int,
	gold_spent: int,
	hp_restored: int
) -> Dictionary:
	return {
		"id": id,
		"name": name,
		"appeared": appeared,
		"purchased": purchased,
		"gold_before": maxi(0, gold_before),
		"gold_after": maxi(0, gold_after),
		"gold_spent": maxi(0, gold_spent),
		"hp_restored": maxi(0, hp_restored),
		"guardian_hp": "恢复 %d HP" % maxi(0, hp_restored),
	}

static func _rest_windows_from_session(session: Object) -> Array[Dictionary]:
	var records: Array = session.get("rest_window_records") as Array
	var windows: Dictionary = {
		"first_shop": _rest_window("first_shop", "第一次商店休整", true, false, int(session.get("shop_gold_after")), int(session.get("shop_gold_after")), 0, 0),
		"after_battle_3": _rest_window("after_battle_3", "战斗 3 后休整", true, false, int(session.get("gold")), int(session.get("gold")), 0, 0),
		"endpoint_prep": _rest_window("endpoint_prep", "Endpoint 前整备", true, false, int(session.get("gold")), int(session.get("gold")), 0, 0),
	}
	for record_variant: Variant in records:
		if not (record_variant is Dictionary):
			continue
		var record: Dictionary = record_variant as Dictionary
		var id: String = String(record.get("id", ""))
		if id.is_empty():
			continue
		var window: Dictionary = windows.get(id, _rest_window(id, String(record.get("name", id)), true, false, int(record.get("gold_before", 0)), int(record.get("gold_after", 0)), 0, 0)) as Dictionary
		if not bool(window.get("purchased", false)):
			window["gold_before"] = maxi(0, int(record.get("gold_before", 0)))
		window["purchased"] = true
		window["gold_after"] = maxi(0, int(record.get("gold_after", window.get("gold_after", 0))))
		window["gold_spent"] = maxi(0, int(window.get("gold_spent", 0)) + int(record.get("gold_spent", 0)))
		window["hp_restored"] = maxi(0, int(window.get("hp_restored", 0)) + int(record.get("hp_restored", 0)))
		window["guardian_hp"] = "%s；恢复 %d HP" % [String(record.get("guardian_hp", "")), int(window.get("hp_restored", 0))]
		windows[id] = window
	return [
		windows["first_shop"],
		windows["after_battle_3"],
		windows["endpoint_prep"],
	]

static func _reward_expectation(reward_id: String) -> String:
	match reward_id:
		"pool_pocket":
			return "Launch sustained flow"
		"prime_charge":
			return "Tuning high-value hit"
		"slot_primer":
			return "Unit anchor slot"
		_:
			return "未明显兑现"

static func _is_empty(value: Variant) -> bool:
	if value == null:
		return true
	if value is String:
		return String(value).strip_edges().is_empty()
	if value is Array:
		return (value as Array).is_empty()
	if value is Dictionary:
		return (value as Dictionary).is_empty()
	return false
