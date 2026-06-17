class_name RunSessionModel
extends RefCounted

const RunLearningRecordScript := preload("res://scripts/model/run/run_learning_record.gd")

const NODE_GUARDIAN_CONTRACT: String = "guardian_contract"
const NODE_BATTLE_1: String = "battle_1"
const NODE_REWARD_1: String = "reward_1"
const NODE_BATTLE_2: String = "battle_2"
const NODE_SHOP_1: String = "shop_1"
const NODE_BATTLE_3: String = "battle_3"
const NODE_REST_AFTER_BATTLE_3: String = "rest_after_battle_3"
const NODE_BATTLE_4: String = "battle_4"
const NODE_REWARD_2: String = "reward_2"
const NODE_BATTLE_5: String = "battle_5"
const NODE_ENDPOINT_PREP: String = "endpoint_prep"
const NODE_ENDPOINT: String = "endpoint"
const NODE_FINAL_RESULT: String = "final_result"
const NODE_RESULT_ROUTING: String = "result_routing"
const RESULT_WIN: String = "Win"
const RESULT_LOSS: String = "Loss"

var current_node_id: String = NODE_GUARDIAN_CONTRACT
var selected_guardian_id: String = ""
var reward_one_id: String = ""
var reward_one_payload: Dictionary = {}
var shop_purchase_id: String = ""
var shop_gold_before: int = -1
var shop_gold_after: int = -1
var second_reward_id: String = ""
var second_offer_current_axis: String = ""
var second_offer_candidates: Array[Dictionary] = []
var second_offer_choice_role: String = ""
var gold: int = 0
var guardian_max_hp: int = 100
var guardian_hp: int = 100
var endpoint_guardian_max_hp: int = 180
var endpoint_guardian_hp: int = 180
var first_shop_rest_count: int = 0
var battle_three_rest_count: int = 0
var endpoint_prep_rest_count: int = 0
var rest_total_hp_restored: int = 0
var rest_window_records: Array[Dictionary] = []
var last_battle: String = ""
var last_battle_result: String = ""
var planned_counter_id: String = ""
var counter_record: Dictionary = {}
var counter_two_record: Dictionary = {}
var battle_records: Dictionary = {}
var result_record: Dictionary = {}
var endpoint_reached: bool = false
var guardian_hp_pressure_events: Array[String] = []

func has_run_node(node_id: String) -> bool:
	return [
		NODE_GUARDIAN_CONTRACT,
		NODE_BATTLE_1,
		NODE_REWARD_1,
		NODE_BATTLE_2,
		NODE_SHOP_1,
		NODE_BATTLE_3,
		NODE_REST_AFTER_BATTLE_3,
		NODE_BATTLE_4,
		NODE_REWARD_2,
		NODE_BATTLE_5,
		NODE_ENDPOINT_PREP,
		NODE_ENDPOINT,
		NODE_FINAL_RESULT,
		NODE_RESULT_ROUTING,
	].has(node_id)

func select_guardian(guardian_id: String) -> void:
	if current_node_id != NODE_GUARDIAN_CONTRACT:
		push_error("Guardian can only be selected at Guardian Contract.")
		return
	selected_guardian_id = guardian_id

func confirm_guardian() -> void:
	if current_node_id != NODE_GUARDIAN_CONTRACT:
		push_error("Guardian can only be confirmed at Guardian Contract.")
		return
	if selected_guardian_id.is_empty():
		push_error("Cannot confirm an empty Guardian selection.")
		return
	current_node_id = NODE_BATTLE_1

func complete_battle(battle_result: String) -> void:
	if not _battle_nodes().has(current_node_id):
		push_error("Current node is not a battle: %s" % current_node_id)
		return
	if battle_result != RESULT_WIN and battle_result != RESULT_LOSS:
		push_error("Unsupported battle result: %s" % battle_result)
		return

	last_battle = current_node_id
	last_battle_result = battle_result

	if current_node_id == NODE_ENDPOINT:
		endpoint_reached = true
		_route_to_final_result()
		return

	if battle_result == RESULT_LOSS:
		_route_to_result()
		return

	match last_battle:
		NODE_BATTLE_1:
			gold += 6
			current_node_id = NODE_REWARD_1
		NODE_BATTLE_2:
			gold += 6
			current_node_id = NODE_SHOP_1
		NODE_BATTLE_3:
			gold += 8
			current_node_id = NODE_REST_AFTER_BATTLE_3
		NODE_BATTLE_4:
			current_node_id = NODE_REWARD_2
		NODE_BATTLE_5:
			current_node_id = NODE_ENDPOINT_PREP

func choose_reward_one(reward_id: String) -> void:
	var payload: Dictionary = {"slot_id": 1} if reward_id == "slot_primer" else {}
	choose_reward_one_with_payload(reward_id, payload)

func choose_reward_one_with_payload(reward_id: String, payload: Dictionary) -> void:
	if current_node_id != NODE_REWARD_1:
		push_error("Reward 1 can only be chosen at Reward 1.")
		return
	reward_one_id = reward_id
	reward_one_payload = payload.duplicate(true)
	current_node_id = NODE_BATTLE_2

func set_planned_counter(counter_id: String) -> void:
	planned_counter_id = counter_id

func set_counter_record(record: Dictionary) -> void:
	counter_record = record.duplicate(true)

func set_counter_two_record(record: Dictionary) -> void:
	counter_two_record = record.duplicate(true)

func set_battle_record(battle_id: String, record: Dictionary) -> void:
	if battle_id.is_empty():
		return
	battle_records[battle_id] = record.duplicate(true)
	_append_guardian_pressure_events(record.get("guardian.hp_pressure_events", []))
	if battle_id == NODE_ENDPOINT and record.has("endpoint.guardian_hp"):
		endpoint_guardian_hp = _extract_endpoint_hp(String(record.get("endpoint.guardian_hp", "")), endpoint_guardian_hp)

func buy_shop_item(modifier_id: String, cost: int) -> bool:
	if current_node_id != NODE_SHOP_1:
		push_error("Shop item can only be bought at First Shop.")
		return false
	if not shop_purchase_id.is_empty():
		return false
	if gold < cost:
		return false
	shop_gold_before = gold
	shop_purchase_id = modifier_id
	gold -= cost
	shop_gold_after = gold
	return true

func damage_guardian(amount: int) -> void:
	var before: int = guardian_hp
	guardian_hp = maxi(0, guardian_hp - amount)
	if before > guardian_hp:
		_record_guardian_pressure_event("守护者受伤：HP %d -> %d" % [before, guardian_hp])

func can_buy_rest() -> bool:
	return gold >= 3 and guardian_hp < guardian_max_hp and _rest_limit_remaining() > 0

func buy_rest() -> bool:
	if not can_buy_rest():
		return false
	var window_id: String = current_node_id
	var before_gold: int = gold
	gold -= 3
	var before_hp: int = guardian_hp
	guardian_hp = mini(guardian_max_hp, guardian_hp + 20)
	var restored_hp: int = guardian_hp - before_hp
	rest_total_hp_restored += restored_hp
	_record_rest_window(window_id, before_gold, gold, before_hp, guardian_hp, restored_hp)
	_record_guardian_pressure_event("休整：花费 3 Gold，恢复 %d HP，守护者 HP %d -> %d" % [restored_hp, before_hp, guardian_hp])
	match current_node_id:
		NODE_SHOP_1:
			first_shop_rest_count += 1
		NODE_REST_AFTER_BATTLE_3:
			battle_three_rest_count += 1
		NODE_ENDPOINT_PREP:
			endpoint_prep_rest_count += 1
	return true

func confirm_shop_and_rest() -> void:
	if current_node_id != NODE_SHOP_1:
		push_error("First Shop / Rest can only route to Battle 3 from First Shop.")
		return
	current_node_id = NODE_BATTLE_3

func confirm_battle_three_rest() -> void:
	if current_node_id != NODE_REST_AFTER_BATTLE_3:
		push_error("Battle 3 Rest can only route to Battle 4 from Battle 3 Rest.")
		return
	current_node_id = NODE_BATTLE_4

func confirm_endpoint_prep() -> void:
	if current_node_id != NODE_ENDPOINT_PREP:
		push_error("Endpoint Prep can only route to Endpoint from Endpoint Prep.")
		return
	current_node_id = NODE_ENDPOINT

func set_second_offer(current_axis: String, candidates: Array[Dictionary]) -> void:
	second_offer_current_axis = current_axis
	second_offer_candidates = candidates.duplicate(true)

func choose_second_reward(choice_id: String, choice_role: String) -> void:
	if current_node_id != NODE_REWARD_2:
		push_error("Second Reward can only be chosen at Reward 2.")
		return
	second_reward_id = choice_id
	second_offer_choice_role = choice_role
	current_node_id = NODE_BATTLE_5

func get_rest_count() -> int:
	match current_node_id:
		NODE_SHOP_1:
			return first_shop_rest_count
		NODE_REST_AFTER_BATTLE_3:
			return battle_three_rest_count
		NODE_ENDPOINT_PREP:
			return endpoint_prep_rest_count
		_:
			return 0

func get_endpoint_prep_rest_limit_remaining() -> int:
	if current_node_id != NODE_ENDPOINT_PREP:
		return 0
	return maxi(0, 2 - endpoint_prep_rest_count)

func build_final_result_record() -> Dictionary:
	result_record = _base_result_record()
	result_record["guardian.choice_id"] = selected_guardian_id
	result_record["guardian.choice_read"] = _guardian_choice_read()
	result_record["guardian.outcome"] = _guardian_outcome()
	result_record["guardian.hp_pressure_events"] = guardian_hp_pressure_events.duplicate()
	result_record["reward1.choice_id"] = reward_one_id
	result_record["reward1.payload"] = reward_one_payload.duplicate(true)
	if reward_one_id == "slot_primer":
		result_record["slot_primer.selected_slot"] = int(reward_one_payload.get("slot_id", 0))
	result_record["reward1.axis"] = _axis_for_reward_one()
	result_record["reward1.component_operation"] = _operation_for_reward_one()
	result_record["reward1.battlefield_expectation"] = _battlefield_expectation_for_reward_one()
	result_record["reward1.battlefield_result"] = _battlefield_result_for_reward_one()
	result_record["shop1.gold_before"] = maxi(0, shop_gold_before)
	result_record["shop1.purchase_id"] = shop_purchase_id
	result_record["shop1.purchase_role"] = _role_for_shop_purchase()
	result_record["shop1.gold_after"] = maxi(0, shop_gold_after)
	result_record["rest.windows_used"] = _rest_windows_used()
	result_record["rest.total_purchases"] = first_shop_rest_count + battle_three_rest_count + endpoint_prep_rest_count
	result_record["rest.gold_spent"] = 3 * int(result_record["rest.total_purchases"])
	result_record["rest.total_gold_spent"] = int(result_record["rest.gold_spent"])
	result_record["rest.total_hp_restored"] = rest_total_hp_restored
	result_record["rest.endpoint_relevance"] = _rest_endpoint_relevance()
	result_record["rest.opportunity_cost"] = _rest_opportunity_cost()
	result_record["session.decision_windows"] = _decision_windows()
	_merge_counter_records()
	_merge_battle_records()
	_ensure_endpoint_fields()
	result_record = RunLearningRecordScript.build(self, result_record)
	return result_record.duplicate(true)

func _record_guardian_pressure_event(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	guardian_hp_pressure_events.append(text)

func _record_rest_window(window_id: String, gold_before: int, gold_after: int, hp_before: int, hp_after: int, hp_restored: int) -> void:
	rest_window_records.append({
		"id": _rest_window_record_id(window_id),
		"name": _rest_window_record_name(window_id),
		"appeared": true,
		"purchased": true,
		"gold_before": gold_before,
		"gold_after": gold_after,
		"gold_spent": gold_before - gold_after,
		"hp_before": hp_before,
		"hp_after": hp_after,
		"hp_restored": hp_restored,
		"guardian_hp": "%d -> %d" % [hp_before, hp_after],
	})

func _rest_window_record_id(window_id: String) -> String:
	match window_id:
		NODE_SHOP_1:
			return "first_shop"
		NODE_REST_AFTER_BATTLE_3:
			return "after_battle_3"
		NODE_ENDPOINT_PREP:
			return "endpoint_prep"
		_:
			return window_id

func _rest_window_record_name(window_id: String) -> String:
	match window_id:
		NODE_SHOP_1:
			return "第一次商店休整"
		NODE_REST_AFTER_BATTLE_3:
			return "战斗 3 后休整"
		NODE_ENDPOINT_PREP:
			return "Endpoint 前整备"
		_:
			return "未知休整"

func _append_guardian_pressure_events(events_variant: Variant) -> void:
	if not (events_variant is Array):
		return
	var events: Array = events_variant as Array
	for event_variant: Variant in events:
		_record_guardian_pressure_event(String(event_variant))

func _guardian_choice_read() -> String:
	match selected_guardian_id:
		"hive_vein_mother":
			return "Launch 契约：巢脉回流 / 守家牵缚"
		"hive_acid_crown_mother":
			return "Tuning 契约：Gate 转 Prime / 受击反喷"
		_:
			return "未选择"

func _battle_nodes() -> Array[String]:
	return [NODE_BATTLE_1, NODE_BATTLE_2, NODE_BATTLE_3, NODE_BATTLE_4, NODE_BATTLE_5, NODE_ENDPOINT]

func _rest_limit_remaining() -> int:
	match current_node_id:
		NODE_SHOP_1:
			return maxi(0, 1 - first_shop_rest_count)
		NODE_REST_AFTER_BATTLE_3:
			return maxi(0, 1 - battle_three_rest_count)
		NODE_ENDPOINT_PREP:
			return maxi(0, 2 - endpoint_prep_rest_count)
		_:
			return 0

func _route_to_result() -> void:
	current_node_id = NODE_RESULT_ROUTING
	build_final_result_record()

func _route_to_final_result() -> void:
	current_node_id = NODE_FINAL_RESULT
	build_final_result_record()

func _base_result_record() -> Dictionary:
	var record: Dictionary = {
		"guardian_id": selected_guardian_id,
		"reward1_id": reward_one_id,
		"reward1_payload": reward_one_payload.duplicate(true),
		"shop1_purchase_id": shop_purchase_id,
		"gold": gold,
		"rest_first_shop": first_shop_rest_count,
		"rest_battle_three": battle_three_rest_count,
		"rest_endpoint_prep": endpoint_prep_rest_count,
		"last_battle": last_battle,
		"battle_result": last_battle_result,
	}
	if not second_offer_current_axis.is_empty():
		record["second_offer.current_axis"] = second_offer_current_axis
		record["second_offer.candidates"] = second_offer_candidates.duplicate(true)
	if not second_reward_id.is_empty():
		record["second_offer.choice_id"] = second_reward_id
		record["second_offer.choice_role"] = second_offer_choice_role
	return record

func _merge_counter_records() -> void:
	for key: String in counter_record.keys():
		result_record["counter1.%s" % key] = counter_record[key]
	for key: String in counter_two_record.keys():
		result_record["counter2.%s" % key] = counter_two_record[key]

func _merge_battle_records() -> void:
	for battle_id: String in battle_records.keys():
		var record: Dictionary = battle_records[battle_id] as Dictionary
		for key: String in record.keys():
			if battle_id != NODE_ENDPOINT and ["endpoint.outcome", "endpoint.guardian_hp"].has(key):
				continue
			if not result_record.has(key):
				result_record[key] = record[key]

func _ensure_endpoint_fields() -> void:
	var endpoint_outcome := "胜利" if last_battle_result == RESULT_WIN and last_battle == NODE_ENDPOINT else ("失败" if last_battle == NODE_ENDPOINT else "未到达")
	var recorded_endpoint_outcome: String = String(result_record.get("endpoint.outcome", ""))
	if recorded_endpoint_outcome.is_empty() or recorded_endpoint_outcome == "进行中":
		result_record["endpoint.outcome"] = endpoint_outcome
	else:
		result_record["endpoint.outcome"] = recorded_endpoint_outcome
	result_record["endpoint.primary_axis_payoff"] = result_record.get("endpoint.primary_axis_payoff", _default_axis_payoff())
	result_record["endpoint.main_break_reason"] = result_record.get("endpoint.main_break_reason", _main_break_reason())
	result_record["endpoint.next_run_watch_tag"] = result_record.get("endpoint.next_run_watch_tag", _next_run_watch_tag())
	result_record["endpoint.deploy_lane_impact"] = result_record.get("endpoint.deploy_lane_impact", "Queue 只改变部署落点，关键路线改变会记录在战场遥测。")
	result_record["endpoint.guardian_hp"] = result_record.get("endpoint.guardian_hp", "玩家 %d / %d，终点 %d / %d" % [
		guardian_hp,
		guardian_max_hp,
		endpoint_guardian_hp,
		endpoint_guardian_max_hp,
	])
	result_record["guardian.hp_pressure_events"] = result_record.get("guardian.hp_pressure_events", [])
	result_record["battle1.machine_chain_sample"] = result_record.get("battle1.machine_chain_sample", "Pool 入槽 -> fired ball -> Tuning 命中 -> Unit progress -> Queue entry")
	result_record["unit.visible_contribution_slots"] = result_record.get("unit.visible_contribution_slots", [])
	result_record["unit.key_queue_entries_by_slot"] = result_record.get("unit.key_queue_entries_by_slot", {})

func _guardian_outcome() -> String:
	if last_battle == NODE_ENDPOINT and last_battle_result == RESULT_WIN:
		return "到达 Endpoint 并胜利，结束 HP %d / %d" % [guardian_hp, guardian_max_hp]
	if endpoint_reached:
		return "到达 Endpoint 但失败，结束 HP %d / %d" % [guardian_hp, guardian_max_hp]
	return "未到达 Endpoint，结束 HP %d / %d" % [guardian_hp, guardian_max_hp]

func _axis_for_reward_one() -> String:
	match reward_one_id:
		"pool_pocket":
			return "Launch"
		"prime_charge":
			return "Tuning"
		"slot_primer":
			return "Unit"
		_:
			return "未选择"

func _operation_for_reward_one() -> String:
	match reward_one_id:
		"pool_pocket":
			return "Pool capacity +1"
		"prime_charge":
			return "Prime hit value +1 -> +2"
		"slot_primer":
			return "Unit S%d progress floor = 1" % clampi(int(reward_one_payload.get("slot_id", 1)), 1, 4)
		_:
			return "无"

func _battlefield_expectation_for_reward_one() -> String:
	match reward_one_id:
		"pool_pocket":
			return "Launch sustained flow"
		"prime_charge":
			return "Tuning high-value hit"
		"slot_primer":
			return "Unit anchor slot"
		_:
			return "未明显兑现"

func _battlefield_result_for_reward_one() -> String:
	if reward_one_id.is_empty():
		return "未明显兑现"
	var evidence: String = _first_reward_runtime_evidence()
	if evidence.is_empty():
		return "未明显兑现"
	return "%s：%s" % [_battlefield_expectation_for_reward_one(), evidence]

func _first_reward_runtime_evidence() -> String:
	for battle_id: String in [NODE_BATTLE_2, NODE_BATTLE_3, NODE_BATTLE_4, NODE_BATTLE_5, NODE_ENDPOINT]:
		if not battle_records.has(battle_id):
			continue
		var record: Dictionary = battle_records[battle_id] as Dictionary
		var queue_evidence: String = _queue_evidence_from_battle_record(battle_id, record)
		if not queue_evidence.is_empty():
			return queue_evidence
		var payoff: String = String(record.get("endpoint.primary_axis_payoff", ""))
		if not payoff.is_empty() and payoff != "未明显兑现":
			return "%s 记录到 %s" % [_battle_label(battle_id), payoff]
	return ""

func _queue_evidence_from_battle_record(battle_id: String, record: Dictionary) -> String:
	var entries_by_slot: Dictionary = record.get("unit.key_queue_entries_by_slot", {}) as Dictionary
	for slot_key: Variant in entries_by_slot.keys():
		var entries: Array = entries_by_slot[slot_key] as Array
		if entries.is_empty():
			continue
		var entry: Dictionary = entries[0] as Dictionary
		var lane: String = String(entry.get("lane", "Mid"))
		var time_text: String = "%.1fs" % float(entry.get("time", 0.0))
		return "%s，%s 于 %s 投到%s" % [
			_battle_label(battle_id),
			String(slot_key),
			time_text,
			_lane_label(lane),
		]
	return ""

func _battle_label(battle_id: String) -> String:
	match battle_id:
		NODE_BATTLE_2:
			return "战斗 2"
		NODE_BATTLE_3:
			return "战斗 3"
		NODE_BATTLE_4:
			return "战斗 4"
		NODE_BATTLE_5:
			return "战斗 5"
		NODE_ENDPOINT:
			return "Endpoint"
		_:
			return battle_id

func _lane_label(lane: String) -> String:
	match lane:
		"Left":
			return "左路"
		"Mid":
			return "中路"
		"Right":
			return "右路"
		_:
			return lane

func _role_for_shop_purchase() -> String:
	match shop_purchase_id:
		"junk_sieve", "surge_buffer", "queue_brace":
			return "Patch"
		"front_recycle", "muster_pair":
			return "Pivot"
		_:
			return "无"

func _rest_windows_used() -> Array[String]:
	var windows: Array[String] = []
	if first_shop_rest_count > 0:
		windows.append("第一次商店")
	if battle_three_rest_count > 0:
		windows.append("战斗 3 后")
	if endpoint_prep_rest_count > 0:
		windows.append("Endpoint 前整备")
	return windows

func _rest_endpoint_relevance() -> String:
	if endpoint_prep_rest_count <= 0:
		return "none"
	if last_battle == NODE_ENDPOINT and last_battle_result == RESULT_WIN:
		return "changed_endpoint_margin"
	if last_battle == NODE_ENDPOINT and last_battle_result == RESULT_LOSS:
		return "insufficient"
	return "helped_survive_to_endpoint"

func _rest_opportunity_cost() -> String:
	var total_rest_purchases: int = first_shop_rest_count + battle_three_rest_count + endpoint_prep_rest_count
	if total_rest_purchases <= 0:
		return "无"
	var total_spent: int = total_rest_purchases * 3
	var roles := PackedStringArray()
	for role: String in _rest_opportunity_roles():
		if not roles.has(role):
			roles.append(role)
	if roles.is_empty():
		roles.append("后续整备余量")
	return "休整花费 %d Gold；机会成本：%s" % [total_spent, " / ".join(roles)]

func _rest_opportunity_roles() -> Array[String]:
	var roles: Array[String] = []
	var first_shop_pool: Dictionary = {
		"front_recycle": "转向",
		"junk_sieve": "补洞",
		"surge_buffer": "补洞",
		"queue_brace": "补洞",
		"muster_pair": "转向",
	}
	if first_shop_rest_count > 0:
		for item_id: String in first_shop_pool.keys():
			if item_id == shop_purchase_id:
				continue
			roles.append(String(first_shop_pool[item_id]))
	if battle_three_rest_count > 0 or endpoint_prep_rest_count > 0:
		roles.append("补洞")
		roles.append("转向")
		roles.append("深化")
	return roles

func _decision_windows() -> Array[String]:
	var windows: Array[String] = ["Guardian", "第一次奖励", "第一次商店", "战斗 3 后休整", "第二次奖励"]
	if endpoint_prep_rest_count >= 0:
		windows.append("Endpoint 前整备")
	windows.append("关键 Deploy Lane 改变")
	return windows

func _default_axis_payoff() -> String:
	if second_reward_id == "echo_latch":
		return "Tuning repeated hit"
	return _battlefield_result_for_reward_one()

func _main_break_reason() -> String:
	if last_battle_result == RESULT_WIN:
		return "未断裂"
	if guardian_hp <= 0:
		return "守护者 HP 被打穿"
	if planned_counter_id == "pool_polluter":
		return "Pool 卡住"
	if planned_counter_id == "echo_breaker":
		return "Echo / Surge 价值被打断"
	if planned_counter_id == "stagger_punisher":
		return "Queue 空档"
	return "未定"

func _next_run_watch_tag() -> String:
	match _main_break_reason():
		"Pool 卡住":
			return "观察 Launch 污染补洞"
		"Echo / Surge 价值被打断":
			return "观察 Tuning 重复命中"
		"Queue 空档":
			return "观察 Unit 队列空档"
		"守护者 HP 被打穿":
			return "观察守护者 HP 压力"
		_:
			return "观察部署路线漏兵"

func _extract_endpoint_hp(text: String, fallback: int) -> int:
	var marker := "终点 "
	var index := text.find(marker)
	if index == -1:
		return fallback
	index += marker.length()
	var slash := text.find(" /", index)
	if slash == -1:
		return fallback
	return int(text.substr(index, slash - index))
