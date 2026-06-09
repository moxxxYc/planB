class_name MvpSessionModel
extends RefCounted

const MachineModelScript := preload("res://scripts/ball_machine/machine_causality_model.gd")
const BattlefieldModelScript := preload("res://scripts/battlefield/battlefield_deploy_model.gd")

const GUARDIAN_RESOURCES := {
	"hive.vein_mother": preload("res://resources/guardians/hive_vein_mother.tres"),
	"hive.acid_crown_mother": preload("res://resources/guardians/hive_acid_crown_mother.tres"),
}

const MODIFIER_RESOURCES := {
	"pool_pocket": preload("res://resources/economy/pool_pocket.tres"),
	"prime_charge": preload("res://resources/economy/prime_charge.tres"),
	"slot_primer": preload("res://resources/economy/slot_primer.tres"),
	"front_recycle": preload("res://resources/economy/front_recycle.tres"),
	"junk_sieve": preload("res://resources/economy/junk_sieve.tres"),
	"surge_buffer": preload("res://resources/economy/surge_buffer.tres"),
	"queue_brace": preload("res://resources/economy/queue_brace.tres"),
	"muster_pair": preload("res://resources/economy/muster_pair.tres"),
	"echo_latch": preload("res://resources/economy/echo_latch.tres"),
}

const COUNTER_RESOURCES := {
	"pool_polluter": preload("res://resources/enemies/pool_polluter.tres"),
	"echo_breaker": preload("res://resources/enemies/echo_breaker.tres"),
	"stagger_punisher": preload("res://resources/enemies/stagger_punisher.tres"),
}

const FLOW_STEPS := [
	"Guardian Select",
	"Battle 1",
	"First Reward",
	"Battle 2",
	"Shop / Gold / Rest",
	"Battle 3 with counter",
	"Battle 4",
	"Second Reward",
	"Battle 5",
	"Endpoint Prep",
	"Endpoint",
	"Result Page",
]

const GOLD_FAUCET_DEBUG := {
	1: 6,
	2: 6,
	3: 8,
	4: 0,
	5: 0,
	6: 0,
}

const REST_COST_DEBUG := 3
const REST_HEAL_DEBUG := 20
const PLAYER_GUARDIAN_MAX_HP := 100

var machine_model: RefCounted = MachineModelScript.new()
var battlefield_model: RefCounted = BattlefieldModelScript.new()

var flow_history: Array[String] = []
var event_log: Array[Dictionary] = []
var telemetry: Dictionary = {}
var result_page: Dictionary = {}
var current_step := "Guardian Select"
var gold := 0
var player_guardian_hp := PLAYER_GUARDIAN_MAX_HP
var chosen_guardian: Dictionary = {}
var main_axis := ""
var first_reward: Dictionary = {}
var second_reward: Dictionary = {}
var shop_purchase: Dictionary = {}
var rest_records: Array[Dictionary] = []
var counter_records: Array[Dictionary] = []
var key_queue_entries_by_slot: Dictionary = {}
var visible_contribution_slots: Dictionary = {}
var deploy_lane_records: Array[Dictionary] = []
var decision_windows: Array[String] = []


func _init() -> void:
	reset()


func reset() -> void:
	machine_model = MachineModelScript.new()
	battlefield_model = BattlefieldModelScript.new()
	flow_history.clear()
	event_log.clear()
	telemetry.clear()
	result_page.clear()
	current_step = "Guardian Select"
	gold = 0
	player_guardian_hp = PLAYER_GUARDIAN_MAX_HP
	chosen_guardian.clear()
	main_axis = ""
	first_reward.clear()
	second_reward.clear()
	shop_purchase.clear()
	rest_records.clear()
	counter_records.clear()
	key_queue_entries_by_slot.clear()
	visible_contribution_slots.clear()
	deploy_lane_records.clear()
	decision_windows.clear()


func start_new_run(guardian_id: String = "hive.vein_mother") -> Dictionary:
	reset()
	telemetry["gold_faucet.debug_first_pass"] = "6 / 6 / 8 / 0 / 0 / 0，调试首版水龙头，非最终平衡。"
	_enter_step("Guardian Select")
	return choose_guardian(guardian_id)


func choose_guardian(guardian_id: String) -> Dictionary:
	if not GUARDIAN_RESOURCES.has(guardian_id):
		guardian_id = "hive.vein_mother"

	var guardian: Resource = GUARDIAN_RESOURCES[guardian_id]
	chosen_guardian = _guardian_to_dict(guardian)
	main_axis = str(chosen_guardian.get("axis_lean", "Launch"))
	decision_windows.append("守护者")
	telemetry["guardian.choice_id"] = chosen_guardian["guardian_id"]
	telemetry["guardian.choice_read"] = "%s 倾向%s轴，战术为%s，战略目标为%s。" % [
		chosen_guardian["display_name"],
		_display_axis(chosen_guardian["axis_lean"]),
		chosen_guardian["tactical_skill"],
		_display_component(chosen_guardian["strategic_target"]),
	]
	_log(
		"guardian selected",
		"%s 已在第一战前选定。轴倾向：%s。" % [
			chosen_guardian["display_name"],
			_display_axis(chosen_guardian["axis_lean"]),
		],
		chosen_guardian
	)
	return chosen_guardian.duplicate(true)


func run_debug_win_session(guardian_id: String = "hive.vein_mother") -> Dictionary:
	start_new_run(guardian_id)
	run_battle(1)
	choose_first_reward(_default_first_reward_for_axis(main_axis))
	run_battle(2)
	run_first_shop()
	run_battle(3, _counter_for_axis(main_axis))
	run_battle(4)
	choose_second_reward()
	run_battle(5, _counter_for_axis(main_axis))
	run_endpoint_prep()
	run_endpoint(true)
	build_result_page()
	return get_run_summary()


func run_debug_loss_session(guardian_id: String = "hive.acid_crown_mother") -> Dictionary:
	start_new_run(guardian_id)
	run_battle(1)
	choose_first_reward(_default_first_reward_for_axis(main_axis))
	run_battle(2)
	run_first_shop()
	run_battle(3, _counter_for_axis(main_axis))
	run_battle(4)
	choose_second_reward()
	run_battle(5, _counter_for_axis(main_axis))
	run_endpoint_prep()
	run_endpoint(false)
	build_result_page()
	return get_run_summary()


func run_battle(battle_number: int, counter_id: String = "", lane_name_override: String = "") -> Dictionary:
	var step_label := "Battle %d" % battle_number
	if battle_number == 3:
		step_label = "Battle 3 with counter"
	_enter_step(step_label)

	battlefield_model.reset()
	var lane_name := _lane_for_battle(battle_number)
	if not lane_name_override.is_empty():
		lane_name = lane_name_override
	battlefield_model.select_lane(lane_name)

	var queue_entry: Dictionary = _generate_machine_queue_entry_for_battle(battle_number)
	battlefield_model.enqueue_machine_queue_entry(queue_entry)
	var deployed: Dictionary = battlefield_model.deploy_next_queue_entry()
	_record_deploy_lane_impact(battle_number, lane_name, deployed, queue_entry)

	if battle_number == 1:
		_record_battle1_checkpoint(queue_entry)

	var counter_record: Dictionary = {}
	if not counter_id.is_empty():
		counter_record = apply_counter(counter_id, battle_number)

	_spawn_battle_pressure(battle_number)
	for _step in range(6):
		battlefield_model.tick(0.25)

	var outcome := "player_win"
	battlefield_model.force_battle_result_for_debug(outcome)
	_apply_debug_battle_pressure(battle_number)
	_apply_gold_faucet(battle_number, outcome)
	_record_unit_contribution(queue_entry, lane_name, battle_number)

	if battle_number == 3 and not counter_record.is_empty():
		telemetry["counter1.family"] = counter_record["display_name"]
		telemetry["counter1.target_component"] = counter_record["target_component"]
		telemetry["counter1.visible_effect"] = counter_record["visible_effect"]
		telemetry["counter1.response_link"] = _counter_response_link(counter_record)

	_log(
		"battle resolved",
		"第 %d 战结算为%s。金币水龙头为调试首版，非最终平衡。" % [
			battle_number,
			_display_outcome(outcome),
		],
		{
			"battle_number": battle_number,
			"gold": gold,
			"counter": counter_record,
		}
	)
	return {
		"battle_number": battle_number,
		"outcome": outcome,
		"gold": gold,
		"queue_entry": queue_entry,
		"deploy_lane": lane_name,
		"counter": counter_record,
	}


func choose_first_reward(reward_id: String) -> Dictionary:
	_enter_step("First Reward")
	if not ["pool_pocket", "prime_charge", "slot_primer"].has(reward_id):
		reward_id = _default_first_reward_for_axis(main_axis)

	first_reward = _modifier_to_dict(MODIFIER_RESOURCES[reward_id])
	main_axis = first_reward["warehouse"]
	decision_windows.append("第一奖励")

	telemetry["reward1.choice_id"] = first_reward["display_name"]
	telemetry["reward1.axis"] = first_reward["warehouse"]
	telemetry["reward1.component_operation"] = "%s -> %s" % [
		first_reward["target_component"],
		first_reward["operation"],
	]
	telemetry["reward1.battlefield_expectation"] = first_reward["player_read"]
	telemetry["reward1.battlefield_result"] = "调试战斗中在%s看到了：%s" % [
		_display_lane(_lane_for_battle(2)),
		first_reward["player_read"],
	]

	_log(
		"first reward selected",
		"%s 被选择为%s轴锚点。" % [first_reward["display_name"], _display_axis(main_axis)],
		first_reward
	)
	return first_reward.duplicate(true)


func run_first_shop() -> Dictionary:
	return choose_shop_purchase("", true)


func get_shop_choices() -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	for modifier_id in _shop_inventory_for_axis(main_axis):
		var modifier := _modifier_to_dict(MODIFIER_RESOURCES[modifier_id])
		modifier["price"] = _price_for_modifier(modifier)
		choices.append(modifier)
	return choices


func choose_shop_purchase(purchase_id: String = "", buy_rest: bool = false) -> Dictionary:
	_enter_step("Shop / Gold / Rest")

	var inventory := _shop_inventory_for_axis(main_axis)
	var selected_purchase_id := purchase_id
	if not inventory.has(selected_purchase_id):
		selected_purchase_id = inventory[0]

	shop_purchase = _modifier_to_dict(MODIFIER_RESOURCES[selected_purchase_id])
	var gold_before := gold
	var neutral_cap_before := 0
	var neutral_cap_after := 1
	var price := _price_for_modifier(shop_purchase)
	gold = max(0, gold - price)
	decision_windows.append("第一次商店")

	var rest_record := {}
	if buy_rest:
		rest_record = _maybe_rest("first_shop")

	telemetry["shop1.gold_before"] = gold_before
	telemetry["shop1.purchase_id"] = shop_purchase["display_name"]
	telemetry["shop1.purchase_role"] = shop_purchase["role_tag"]
	telemetry["shop1.gold_after"] = gold
	telemetry["shop1.neutral_purchase_cap"] = "%d / 1 -> %d / 1" % [
		neutral_cap_before,
		neutral_cap_after,
	]
	telemetry["shop1.inventory"] = _modifier_names_from_ids(inventory)
	telemetry["rest_windows"] = rest_records.duplicate(true)

	_log(
		"shop purchase",
		"花费 %d 金币购买%s。中立修改购买上限已使用；休整是独立选择。" % [
			price,
			shop_purchase["display_name"],
		],
		{
			"gold_before": gold_before,
			"gold_after": gold,
			"purchase": shop_purchase,
			"rest": rest_record,
			"debug_first_pass_balance": true,
		}
	)
	return {
		"inventory": inventory,
		"purchase": shop_purchase,
		"rest": rest_record,
		"gold_before": gold_before,
		"gold_after": gold,
	}


func get_second_reward_choices() -> Array[Dictionary]:
	return _second_reward_candidates_for_axis(main_axis)


func get_counter_id_for_current_axis() -> String:
	return _counter_for_axis(main_axis)


func choose_second_reward(choice_id: String = "") -> Dictionary:
	_enter_step("Second Reward")
	var candidates := _second_reward_candidates_for_axis(main_axis)
	var selected_index := 0
	for index in range(candidates.size()):
		if str(candidates[index].get("modifier_id", "")) == choice_id:
			selected_index = index
			break
	var selected_choice_id: String = candidates[selected_index]["modifier_id"]
	second_reward = _modifier_to_dict(MODIFIER_RESOURCES[selected_choice_id])
	decision_windows.append("第二奖励")

	telemetry["second_offer.current_axis"] = main_axis
	telemetry["second_offer.candidates"] = candidates.duplicate(true)
	telemetry["second_offer.choice_id"] = second_reward["display_name"]
	telemetry["second_offer.choice_role"] = candidates[selected_index]["offer_role"]

	_log(
		"second reward selected",
		"%s 被选择为%s候选，当前轴为%s。" % [
			second_reward["display_name"],
			candidates[selected_index]["offer_role"],
			_display_axis(main_axis),
		],
		{"candidates": candidates, "choice": second_reward}
	)
	return second_reward.duplicate(true)


func run_endpoint_prep(buy_rest: bool = true) -> Dictionary:
	_enter_step("Endpoint Prep")
	var rest_record := {}
	if buy_rest:
		rest_record = _maybe_rest("endpoint_prep")
	decision_windows.append("终点准备")
	telemetry["session.decision_windows"] = decision_windows.duplicate(true)
	telemetry["session.consecutive_no_explained_decision_battles"] = 0
	_log(
		"endpoint prep",
		"终点准备已开启。没有第二次商店；只有生命和金币允许时才休整。",
		{"rest": rest_record, "gold": gold}
	)
	return {"rest": rest_record, "gold": gold}


func run_endpoint(player_wins: bool, lane_name_override: String = "Mid") -> Dictionary:
	_enter_step("Endpoint")
	battlefield_model.reset()
	var lane_name := "Mid"
	if not lane_name_override.is_empty():
		lane_name = lane_name_override
	battlefield_model.select_lane(lane_name)
	var queue_entry: Dictionary = _generate_machine_queue_entry_for_battle(6)
	battlefield_model.enqueue_machine_queue_entry(queue_entry)
	var deployed: Dictionary = battlefield_model.deploy_next_queue_entry()
	_record_deploy_lane_impact(6, lane_name, deployed, queue_entry)
	battlefield_model.set_public_warning(lane_name, 2)

	var endpoint_counter := apply_counter(_counter_for_axis(main_axis), 6)
	var endpoint_outcome := "win" if player_wins else "loss"
	var payoff := _endpoint_payoff_for_axis(main_axis, player_wins)
	var break_reason := "" if player_wins else _break_reason_for_counter(endpoint_counter)
	if player_wins:
		battlefield_model.force_battle_result_for_debug("player_win")
	else:
		battlefield_model.force_battle_result_for_debug("player_loss")
		player_guardian_hp = 0

	telemetry["endpoint.outcome"] = endpoint_outcome
	telemetry["endpoint.primary_axis_payoff"] = payoff
	telemetry["endpoint.main_break_reason"] = break_reason
	telemetry["endpoint.deploy_lane_impact"] = _summarize_deploy_lane_impact()
	telemetry["endpoint.guardian_hp"] = {
		"player_guardian_hp": player_guardian_hp,
		"endpoint_guardian_hp": 0 if player_wins else 48,
	}
	telemetry["endpoint.next_run_watch_tag"] = _next_watch_tag(endpoint_counter, player_wins)
	telemetry["guardian.outcome"] = {
		"reached_endpoint": true,
		"victory": player_wins,
		"ending_hp": player_guardian_hp,
	}

	_log(
		"endpoint resolved",
		"终点守护者触发了横扫预告。结果：%s。" % _display_endpoint_outcome(endpoint_outcome),
		{
			"outcome": endpoint_outcome,
			"payoff": payoff,
			"break_reason": break_reason,
			"counter": endpoint_counter,
		}
	)
	return {
		"outcome": endpoint_outcome,
		"primary_axis_payoff": payoff,
		"break_reason": break_reason,
		"counter": endpoint_counter,
	}


func begin_playable_battle(
	battle_number: int,
	lane_name: String,
	counter_id: String = ""
) -> Dictionary:
	var step_label := "Battle %d" % battle_number
	if battle_number == 3:
		step_label = "Battle 3 with counter"
	_enter_step(step_label)

	battlefield_model.reset()
	battlefield_model.set_player_guardian_template_id(str(chosen_guardian.get("guardian_id", "")))
	battlefield_model.select_lane(lane_name)
	machine_model.set_battle_time(float(_battle_time_anchor_for_battle(battle_number)))
	machine_model.set_auto_running(true)

	var counter_record := {}
	if not counter_id.is_empty():
		counter_record = apply_counter(counter_id, battle_number)
	_spawn_battle_pressure(battle_number)

	return {
		"battle_number": battle_number,
		"lane_name": lane_name,
		"counter": counter_record,
	}


func finish_playable_battle(
	battle_number: int,
	outcome: String,
	deployed_units: Array[Dictionary]
) -> Dictionary:
	machine_model.set_auto_running(false)

	var final_outcome := outcome
	if final_outcome != "player_loss":
		final_outcome = "player_win"

	if final_outcome == "player_win":
		battlefield_model.force_battle_result_for_debug("player_win")
	else:
		battlefield_model.force_battle_result_for_debug("player_loss")

	if battle_number == 1:
		var queue_entry := _first_queue_entry_from_deployed_units(deployed_units)
		if not queue_entry.is_empty():
			_record_battle1_checkpoint(queue_entry)

	_apply_debug_battle_pressure(battle_number)
	_apply_gold_faucet(battle_number, final_outcome)
	for deployed in deployed_units:
		_record_playable_deploy_lane_impact(battle_number, deployed)
		_record_unit_contribution_from_deployed_unit(battle_number, deployed)

	var counter_record: Dictionary = {}
	if not counter_records.is_empty():
		var latest_counter: Dictionary = counter_records[counter_records.size() - 1]
		if int(latest_counter.get("battle_number", -1)) == battle_number:
			counter_record = latest_counter

	if battle_number == 3 and not counter_record.is_empty():
		telemetry["counter1.family"] = counter_record["display_name"]
		telemetry["counter1.target_component"] = counter_record["target_component"]
		telemetry["counter1.visible_effect"] = counter_record["visible_effect"]
		telemetry["counter1.response_link"] = _counter_response_link(counter_record)

	_log(
		"battle resolved",
		"第 %d 战按可玩短局节奏结算为%s。金币水龙头为调试首版，非最终平衡。" % [
			battle_number,
			_display_outcome(final_outcome),
		],
		{
			"battle_number": battle_number,
			"outcome": final_outcome,
			"deployed_unit_count": deployed_units.size(),
			"gold": gold,
		}
	)
	return {
		"battle_number": battle_number,
		"outcome": final_outcome,
		"gold": gold,
		"deployed_unit_count": deployed_units.size(),
		"counter": counter_record,
	}


func begin_playable_endpoint(lane_name: String) -> Dictionary:
	_enter_step("Endpoint")
	battlefield_model.reset()
	battlefield_model.set_player_guardian_template_id(str(chosen_guardian.get("guardian_id", "")))
	battlefield_model.select_lane(lane_name)
	battlefield_model.set_public_warning(lane_name, 2)
	machine_model.set_battle_time(float(_battle_time_anchor_for_battle(6)))
	machine_model.set_auto_running(true)
	var endpoint_counter := apply_counter(_counter_for_axis(main_axis), 6)
	_log(
		"endpoint warning",
		"终点守护者横扫预警已经公开，玩家仍只能通过当前 Deploy Lane 影响未来队列落点。",
		{"lane_name": lane_name, "counter": endpoint_counter}
	)
	return {"lane_name": lane_name, "counter": endpoint_counter}


func finish_playable_endpoint(
	player_wins: bool,
	deployed_units: Array[Dictionary]
) -> Dictionary:
	machine_model.set_auto_running(false)

	for deployed in deployed_units:
		_record_playable_deploy_lane_impact(6, deployed)
		_record_unit_contribution_from_deployed_unit(6, deployed)

	var endpoint_counter := {}
	if not counter_records.is_empty():
		endpoint_counter = counter_records[counter_records.size() - 1]

	var endpoint_outcome := "win" if player_wins else "loss"
	var payoff := _endpoint_payoff_for_axis(main_axis, player_wins)
	var break_reason := "" if player_wins else _break_reason_for_counter(endpoint_counter)
	if player_wins:
		battlefield_model.force_battle_result_for_debug("player_win")
	else:
		battlefield_model.force_battle_result_for_debug("player_loss")
		player_guardian_hp = 0

	telemetry["endpoint.outcome"] = endpoint_outcome
	telemetry["endpoint.primary_axis_payoff"] = payoff
	telemetry["endpoint.main_break_reason"] = break_reason
	telemetry["endpoint.deploy_lane_impact"] = _summarize_deploy_lane_impact()
	telemetry["endpoint.guardian_hp"] = {
		"player_guardian_hp": player_guardian_hp,
		"endpoint_guardian_hp": 0 if player_wins else 48,
	}
	telemetry["endpoint.next_run_watch_tag"] = _next_watch_tag(endpoint_counter, player_wins)
	telemetry["guardian.outcome"] = {
		"reached_endpoint": true,
		"victory": player_wins,
		"ending_hp": player_guardian_hp,
	}

	_log(
		"endpoint resolved",
		"终点守护者横扫节奏结束。结果：%s。" % _display_endpoint_outcome(endpoint_outcome),
		{
			"outcome": endpoint_outcome,
			"payoff": payoff,
			"break_reason": break_reason,
			"counter": endpoint_counter,
			"deployed_unit_count": deployed_units.size(),
		}
	)
	return {
		"outcome": endpoint_outcome,
		"primary_axis_payoff": payoff,
		"break_reason": break_reason,
		"counter": endpoint_counter,
	}


func apply_counter(counter_id: String, battle_number: int = 3) -> Dictionary:
	if not COUNTER_RESOURCES.has(counter_id):
		counter_id = "pool_polluter"

	var counter: Resource = COUNTER_RESOURCES[counter_id]
	var record := _counter_to_record(counter, battle_number)
	counter_records.append(record)

	match counter_id:
		"pool_polluter":
			machine_model.force_settlement_state("Waste")
		"echo_breaker":
			machine_model.force_tuning_result("Echo")
			machine_model.force_settlement_state("Logic Settlement")
		"stagger_punisher":
			battlefield_model.set_public_warning("Right", 2)
			battlefield_model.spawn_enemy("Right", "Enemy Raider", 22.0)
			battlefield_model.spawn_enemy("Right", "Enemy Raider", 24.0)

	_log(
		"counter warning",
		"%s 对%s发出预警，随后施加可见效果：%s" % [
			record["display_name"],
			_display_component(record["target_component"]),
			record["visible_effect"],
		],
		record
	)
	return record.duplicate(true)


func run_counter_debug_cases() -> Array:
	var cases: Array = []
	for counter_id in ["pool_polluter", "echo_breaker", "stagger_punisher"]:
		var counter: Resource = COUNTER_RESOURCES[counter_id]
		var record := _counter_to_record(counter, 0)
		cases.append({
			"counter_id": counter_id,
			"warning": record["warning"],
			"target_component": record["target_component"],
			"visible_effect": record["visible_effect"],
			"log_record": record["log_record"],
		})
	return cases


func build_result_page() -> Dictionary:
	_enter_step("Result Page")
	var latest_counter := counter_records[counter_records.size() - 1] if not counter_records.is_empty() else {}
	var outcome := str(telemetry.get("endpoint.outcome", ""))
	var payoff_or_break := str(telemetry.get("endpoint.primary_axis_payoff", ""))
	if outcome == "loss":
		payoff_or_break = str(telemetry.get("endpoint.main_break_reason", ""))

	result_page = {
		"chosen_guardian": "%s (%s)" % [
			chosen_guardian.get("display_name", ""),
			_display_axis(chosen_guardian.get("axis_lean", "")),
		],
		"main_axis": _display_axis(main_axis),
		"key_rewards": "第一奖励：%s；第二奖励：%s" % [
			first_reward.get("display_name", ""),
			second_reward.get("display_name", ""),
		],
		"shop_rest_choice": _summarize_shop_and_rest(),
		"counter_target": "%s -> %s" % [
			latest_counter.get("display_name", ""),
			_display_component(latest_counter.get("target_component", "")),
		],
		"deploy_lane_impact": _summarize_deploy_lane_impact(),
		"endpoint_payoff_or_break_reason": payoff_or_break,
		"next_run_watch_tag": str(telemetry.get("endpoint.next_run_watch_tag", "")),
	}

	telemetry["unit.visible_contribution_slots"] = _visible_slot_ids()
	telemetry["unit.key_queue_entries_by_slot"] = key_queue_entries_by_slot.duplicate(true)
	telemetry["unit.dominant_slot_share"] = _dominant_slot_share()

	_log("result page", "结算页已由真实 M3 本局数据生成。", result_page)
	return result_page.duplicate(true)


func get_run_summary() -> Dictionary:
	return {
		"current_step": current_step,
		"flow_history": flow_history.duplicate(),
		"chosen_guardian": chosen_guardian.duplicate(true),
		"main_axis": main_axis,
		"gold": gold,
		"player_guardian_hp": player_guardian_hp,
		"first_reward": first_reward.duplicate(true),
		"second_reward": second_reward.duplicate(true),
		"shop_purchase": shop_purchase.duplicate(true),
		"rest_records": rest_records.duplicate(true),
		"counter_records": counter_records.duplicate(true),
		"deploy_lane_records": deploy_lane_records.duplicate(true),
		"telemetry": telemetry.duplicate(true),
		"result_page": result_page.duplicate(true),
		"event_log": event_log.duplicate(true),
	}


func get_available_guardians() -> Array[Dictionary]:
	var guardians: Array[Dictionary] = []
	for guardian_id in ["hive.vein_mother", "hive.acid_crown_mother"]:
		guardians.append(_guardian_to_dict(GUARDIAN_RESOURCES[guardian_id]))
	return guardians


func get_first_reward_choices() -> Array[Dictionary]:
	return [
		_modifier_to_dict(MODIFIER_RESOURCES["pool_pocket"]),
		_modifier_to_dict(MODIFIER_RESOURCES["prime_charge"]),
		_modifier_to_dict(MODIFIER_RESOURCES["slot_primer"]),
	]


func _battle_time_anchor_for_battle(battle_number: int) -> int:
	match battle_number:
		1:
			return 24
		2:
			return 30
		3:
			return 60
		4:
			return 72
		5:
			return 100
		_:
			return 110


func _first_queue_entry_from_deployed_units(deployed_units: Array[Dictionary]) -> Dictionary:
	if deployed_units.is_empty():
		return {}
	var deployed: Dictionary = deployed_units[0]
	return {
		"queue_entry_id": deployed.get("source_queue_entry_id", ""),
		"source_slot_id": deployed.get("source_slot_id", 0),
		"source_slot_label": "Slot %d" % int(deployed.get("source_slot_id", 0)),
		"tuning_result": deployed.get("tuning_result", ""),
		"trigger_chain": "%s Launch->Tuning->Unit->Queue" % deployed.get(
			"source_queue_entry_id",
			"playable"
		),
	}


func _record_playable_deploy_lane_impact(battle_number: int, deployed: Dictionary) -> void:
	var record := {
		"battle": battle_number,
		"selected_lane": deployed.get("lane_name", ""),
		"queue_entry_id": deployed.get("source_queue_entry_id", ""),
		"source_slot_id": deployed.get("source_slot_id", 0),
		"unit_id": deployed.get("unit_id", ""),
		"unit_name": deployed.get("display_name", ""),
		"impact": "玩家点击路线后，未来队列条目部署到当时选中的路线；已部署单位不被重新指派。",
	}
	deploy_lane_records.append(record)


func _record_unit_contribution_from_deployed_unit(
	battle_number: int,
	deployed: Dictionary
) -> void:
	var slot_id := int(deployed.get("source_slot_id", 0))
	if slot_id <= 0:
		return
	visible_contribution_slots[slot_id] = true
	if not key_queue_entries_by_slot.has(slot_id):
		key_queue_entries_by_slot[slot_id] = []
	var entries: Array = key_queue_entries_by_slot[slot_id]
	entries.append({
		"battle": battle_number,
		"queue_entry_id": deployed.get("source_queue_entry_id", ""),
		"lane": deployed.get("lane_name", ""),
		"result": _slot_result_read(slot_id),
	})
	key_queue_entries_by_slot[slot_id] = entries


func _generate_machine_queue_entry_for_battle(battle_number: int) -> Dictionary:
	var slot_id := 1
	var tuning := "Gate"
	match battle_number:
		1:
			slot_id = 1
			tuning = "Gate"
			machine_model.set_battle_time(24.0)
		2:
			slot_id = 2
			tuning = "Prime" if main_axis == "Tuning" else "Gate"
			machine_model.set_battle_time(30.0)
		3:
			slot_id = 1 if main_axis == "Launch" else 3
			tuning = "Echo" if main_axis == "Tuning" else "Gate"
			machine_model.set_battle_time(60.0)
		4:
			slot_id = 3
			tuning = "Prime"
			machine_model.set_battle_time(72.0)
		5:
			slot_id = 4 if main_axis == "Unit" else 2
			tuning = "Surge" if main_axis == "Unit" else "Prime"
			machine_model.set_battle_time(100.0)
		_:
			slot_id = 4 if main_axis == "Unit" else 3
			tuning = "Prime"
			machine_model.set_battle_time(110.0)

	var entry: Dictionary = machine_model.force_unit_slot_queue(slot_id, tuning)
	if entry.is_empty():
		entry = machine_model.force_unit_slot_queue(1, "Gate")
	return entry


func _record_battle1_checkpoint(queue_entry: Dictionary) -> void:
	telemetry["battle1.machine_chain_sample"] = {
		"queue_entry_id": queue_entry.get("queue_entry_id", ""),
		"source_slot": queue_entry.get("source_slot_label", ""),
		"tuning_result": queue_entry.get("tuning_result", ""),
		"trigger_chain": queue_entry.get("trigger_chain", ""),
		"recent_machine_events": machine_model.event_log.duplicate(true),
	}
	telemetry["battle1.exposure_gate_snapshot"] = machine_model.get_unit_slots()
	telemetry["battle1.deploy_lane_selection"] = {
		"selected_lane": battlefield_model.get_selected_lane_name(),
		"changed_lane": false,
	}
	telemetry["battle1.lane_danger_snapshot"] = {
		"Left": battlefield_model.get_lane_danger_tier("Left"),
		"Mid": battlefield_model.get_lane_danger_tier("Mid"),
		"Right": battlefield_model.get_lane_danger_tier("Right"),
	}


func _spawn_battle_pressure(battle_number: int) -> void:
	match battle_number:
		1:
			battlefield_model.spawn_enemy("Mid", "Enemy Grunt", 24.0)
		2:
			battlefield_model.set_public_warning("Left", 1)
			battlefield_model.spawn_enemy("Left", "Enemy Grunt", 28.0)
		3:
			battlefield_model.set_public_warning("Right", 2)
			battlefield_model.spawn_enemy("Right", "Enemy Raider", 18.0)
		4:
			battlefield_model.spawn_enemy("Mid", "Enemy Brute", 34.0)
		5:
			battlefield_model.set_public_warning("Left", 2)
			battlefield_model.spawn_enemy("Left", "Enemy Brute", 26.0)
		_:
			battlefield_model.set_public_warning("Mid", 2)
			battlefield_model.spawn_enemy("Mid", "Enemy Brute", 24.0)


func _apply_debug_battle_pressure(battle_number: int) -> void:
	match battle_number:
		2:
			player_guardian_hp = max(0, player_guardian_hp - 18)
		3:
			player_guardian_hp = max(0, player_guardian_hp - 16)
		5:
			player_guardian_hp = max(0, player_guardian_hp - 14)
		_:
			pass
	telemetry["guardian.hp_pressure_events"] = {
		"current_hp": player_guardian_hp,
		"rest_records": rest_records.duplicate(true),
	}


func _apply_gold_faucet(battle_number: int, outcome: String) -> void:
	if outcome != "player_win":
		return
	var awarded := int(GOLD_FAUCET_DEBUG.get(battle_number, 0))
	gold += awarded
	_log(
		"gold faucet",
		"第 %d 战获得 %d 金币。调试首版水龙头，非最终平衡。" % [
			battle_number,
			awarded,
		],
		{"gold": gold, "debug_first_pass_balance": true}
	)


func _maybe_rest(window_id: String) -> Dictionary:
	if player_guardian_hp >= PLAYER_GUARDIAN_MAX_HP:
		return {}
	if gold < REST_COST_DEBUG:
		return {}

	var before_hp := player_guardian_hp
	var before_gold := gold
	gold -= REST_COST_DEBUG
	player_guardian_hp = min(PLAYER_GUARDIAN_MAX_HP, player_guardian_hp + REST_HEAL_DEBUG)
	var record := {
		"window": window_id,
		"gold_spent": REST_COST_DEBUG,
		"hp_before": before_hp,
		"hp_after": player_guardian_hp,
		"hp_restored": player_guardian_hp - before_hp,
		"gold_before": before_gold,
		"gold_after": gold,
	}
	rest_records.append(record)
	return record


func _record_deploy_lane_impact(
	battle_number: int,
	lane_name: String,
	deployed: Dictionary,
	queue_entry: Dictionary
) -> void:
	var record := {
		"battle": battle_number,
		"selected_lane": lane_name,
		"queue_entry_id": queue_entry.get("queue_entry_id", ""),
		"source_slot_id": queue_entry.get("source_slot_id", 0),
		"unit_id": deployed.get("unit_id", ""),
		"unit_name": deployed.get("display_name", ""),
		"impact": "未来队列条目部署到选中路线；已部署单位不会被重新指派。",
	}
	deploy_lane_records.append(record)


func _record_unit_contribution(queue_entry: Dictionary, lane_name: String, battle_number: int) -> void:
	var slot_id := int(queue_entry.get("source_slot_id", 0))
	if slot_id <= 0:
		return
	visible_contribution_slots[slot_id] = true
	if not key_queue_entries_by_slot.has(slot_id):
		key_queue_entries_by_slot[slot_id] = []
	var entries: Array = key_queue_entries_by_slot[slot_id]
	entries.append({
		"battle": battle_number,
		"queue_entry_id": queue_entry.get("queue_entry_id", ""),
		"lane": lane_name,
		"result": _slot_result_read(slot_id),
	})
	key_queue_entries_by_slot[slot_id] = entries


func _slot_result_read(slot_id: int) -> String:
	match slot_id:
		1:
			return "低需求单位稳定补线。"
		2:
			return "盾壳虫吸收路线接触压力。"
		3:
			return "酸囊虫帮助打破僵持。"
		4:
			return "碾壳兽承担后段压力。"
	return "未知单位槽贡献。"


func _counter_to_record(counter: Resource, battle_number: int) -> Dictionary:
	var display_name := str(counter.get("display_name"))
	var target_component := str(counter.get("target_component"))
	var visible_effect := str(counter.get("visible_effect"))
	return {
		"counter_id": str(counter.get("counter_id")),
		"display_name": display_name,
		"battle_number": battle_number,
		"warning": "%s 对%s预警 %.1f 秒。" % [
			display_name,
			_display_component(target_component),
			float(counter.get("warning_seconds")),
		],
		"target_component": target_component,
		"visible_effect": visible_effect,
		"log_record": "UI / 日志记录：%s -> %s -> %s。" % [
			display_name,
			_display_component(target_component),
			visible_effect,
		],
	}


func _guardian_to_dict(guardian: Resource) -> Dictionary:
	return {
		"guardian_id": str(guardian.get("guardian_id")),
		"display_name": str(guardian.get("display_name")),
		"race": str(guardian.get("race")),
		"axis_lean": str(guardian.get("axis_lean")),
		"tactical_skill": str(guardian.get("tactical_skill")),
		"strategic_target": str(guardian.get("strategic_target")),
	}


func _modifier_to_dict(modifier: Resource) -> Dictionary:
	return {
		"modifier_id": str(modifier.get("modifier_id")),
		"display_name": str(modifier.get("display_name")),
		"source_pool": str(modifier.get("source_pool")),
		"warehouse": str(modifier.get("warehouse")),
		"target_component": str(modifier.get("target_component")),
		"operation": str(modifier.get("operation")),
		"role_tag": str(modifier.get("role_tag")),
		"player_read": str(modifier.get("player_read")),
	}


func _enter_step(step_label: String) -> void:
	current_step = step_label
	if not flow_history.has(step_label):
		flow_history.append(step_label)


func _log(state: String, description: String, data: Dictionary) -> void:
	event_log.append({
		"state": state,
		"description": description,
		"data": data.duplicate(true),
	})
	if event_log.size() > 96:
		event_log.pop_front()


func _lane_for_battle(battle_number: int) -> String:
	match battle_number:
		1:
			return "Mid"
		2:
			return "Left"
		3:
			return "Right"
		4:
			return "Mid"
		5:
			return "Left"
		_:
			return "Mid"


func _default_first_reward_for_axis(axis: String) -> String:
	match axis:
		"Tuning":
			return "prime_charge"
		"Unit":
			return "slot_primer"
		_:
			return "pool_pocket"


func _counter_for_axis(axis: String) -> String:
	match axis:
		"Tuning":
			return "echo_breaker"
		"Unit":
			return "stagger_punisher"
		_:
			return "pool_polluter"


func _shop_inventory_for_axis(axis: String) -> Array[String]:
	match axis:
		"Tuning":
			return ["surge_buffer", "prime_charge", "queue_brace"]
		"Unit":
			return ["queue_brace", "muster_pair", "front_recycle"]
		_:
			return ["junk_sieve", "front_recycle", "queue_brace"]


func _second_reward_candidates_for_axis(axis: String) -> Array[Dictionary]:
	match axis:
		"Tuning":
			return [
				_offer("echo_latch", "深化当前轴", "因为第一奖励已经落在调校仓。"),
				_offer("surge_buffer", "补洞", "因为反制会打断重复调校价值。"),
				_offer("queue_brace", "转轴", "因为队列空窗仍然是可见压力。"),
			]
		"Unit":
			return [
				_offer("muster_pair", "深化当前轴", "因为第一奖励已经落在单位仓。"),
				_offer("queue_brace", "补洞", "因为断档惩罚者攻击队列空窗。"),
				_offer("front_recycle", "转轴", "因为发射仓流量可以覆盖空窗。"),
			]
		_:
			return [
				_offer("front_recycle", "深化当前轴", "因为第一奖励已经落在发射仓。"),
				_offer("junk_sieve", "补洞", "因为池污染者攻击球池容量。"),
				_offer("queue_brace", "转轴", "因为队列空窗仍然是可见压力。"),
			]


func _offer(modifier_id: String, offer_role: String, reason: String) -> Dictionary:
	var modifier := _modifier_to_dict(MODIFIER_RESOURCES[modifier_id])
	modifier["offer_role"] = offer_role
	modifier["reason"] = reason
	return modifier


func _price_for_modifier(modifier: Dictionary) -> int:
	match str(modifier.get("role_tag", "")):
		"Patch":
			return 4
		"Pivot":
			return 5
		"Deepen":
			return 6
		_:
			match str(modifier.get("modifier_id", "")):
				"pool_pocket", "front_recycle", "muster_pair":
					return 5
				"prime_charge", "slot_primer", "echo_latch":
					return 6
	return 4


func _modifier_names_from_ids(ids: Array[String]) -> Array[String]:
	var names: Array[String] = []
	for id in ids:
		names.append(str(MODIFIER_RESOURCES[id].get("display_name")))
	return names


func _counter_response_link(counter_record: Dictionary) -> String:
	var target := str(counter_record.get("target_component", ""))
	if target.contains("Pool"):
		return "可用废料筛 / 池袋作为发射仓污染补洞。"
	if target.contains("Echo"):
		return "可用脉冲缓冲 / 预充强化作为调校仓补洞或转轴。"
	return "可用队列支架 / 槽预涂作为单位仓空窗补洞。"


func _endpoint_payoff_for_axis(axis: String, player_wins: bool) -> String:
	if not player_wins:
		return "主轴没有清楚转化为终点守护者伤害。"
	match axis:
		"Tuning":
			return "调校高价值命中顶住复写压力，打开终点伤害窗口。"
		"Unit":
			return "单位批量释放形成后段终点路线推进。"
		_:
			return "发射仓持续流量在横扫预告后仍维持队列压力。"


func _break_reason_for_counter(counter_record: Dictionary) -> String:
	var target := str(counter_record.get("target_component", ""))
	if target.contains("Pool"):
		return "球池污染在终点前打断了发射仓持续流量。"
	if target.contains("Echo"):
		return "复写 / 脉冲价值在终点收益前被打断。"
	return "队列空窗让断档压力打到守护者生命。"


func _next_watch_tag(counter_record: Dictionary, player_wins: bool) -> String:
	if player_wins:
		match main_axis:
			"Tuning":
				return "观察：调校高价值命中已确认"
			"Unit":
				return "观察：单位批量释放已确认"
			_:
				return "观察：发射仓持续流量已确认"

	var target := str(counter_record.get("target_component", ""))
	if target.contains("Pool"):
		return "观察：发射仓污染补洞"
	if target.contains("Echo"):
		return "观察：调校重复命中"
	return "观察：单位空窗补洞"


func _summarize_shop_and_rest() -> String:
	var rest_text := "未休整"
	if not rest_records.is_empty():
		var restored := 0
		var spent := 0
		for record in rest_records:
			restored += int(record.get("hp_restored", 0))
			spent += int(record.get("gold_spent", 0))
		rest_text = "休整 %d 次，花费 %d 金币恢复 %d 生命" % [
			rest_records.size(),
			spent,
			restored,
		]
	return "%s（%s），%s，剩余金币 %d" % [
		shop_purchase.get("display_name", ""),
		_display_role(shop_purchase.get("role_tag", "")),
		rest_text,
		gold,
	]


func _summarize_deploy_lane_impact() -> String:
	if deploy_lane_records.is_empty():
		return "未记录关键部署路线影响。"

	var first := deploy_lane_records[0]
	var last := deploy_lane_records[deploy_lane_records.size() - 1]
	return "第 %d 战把来自槽 %d 的%s送到%s；终点把%s送到%s。路线点击只影响未来部署。" % [
		int(first.get("battle", 0)),
		int(first.get("source_slot_id", 0)),
		first.get("unit_name", ""),
		_display_lane(first.get("selected_lane", "")),
		last.get("unit_name", ""),
		_display_lane(last.get("selected_lane", "")),
	]


func _visible_slot_ids() -> Array[int]:
	var slots: Array[int] = []
	for slot_id in visible_contribution_slots.keys():
		slots.append(int(slot_id))
	slots.sort()
	return slots


func _dominant_slot_share() -> Dictionary:
	var total := 0
	var best_slot := 0
	var best_count := 0
	for slot_id in key_queue_entries_by_slot.keys():
		var count := (key_queue_entries_by_slot[slot_id] as Array).size()
		total += count
		if count > best_count:
			best_count = count
			best_slot = int(slot_id)
	var share := 0.0
	if total > 0:
		share = float(best_count) / float(total)
	return {
		"slot_id": best_slot,
		"share": share,
		"debug_key_entry_count": total,
	}


func _display_axis(axis) -> String:
	match str(axis):
		"Launch":
			return "发射"
		"Tuning":
			return "调校"
		"Unit":
			return "单位"
	return str(axis)


func _display_lane(lane) -> String:
	match str(lane):
		"Left", "left":
			return "左路"
		"Mid", "mid":
			return "中路"
		"Right", "right":
			return "右路"
	return str(lane)


func _display_role(role) -> String:
	match str(role):
		"Anchor":
			return "锚点"
		"Patch":
			return "补洞"
		"Pivot":
			return "转轴"
		"Deepen":
			return "深化"
		"Rest":
			return "休整"
	return str(role)


func _display_outcome(outcome) -> String:
	match str(outcome):
		"player_win":
			return "玩家胜利"
		"player_loss":
			return "玩家失败"
		"win":
			return "胜利"
		"loss":
			return "失败"
	return str(outcome)


func _display_endpoint_outcome(outcome) -> String:
	return _display_outcome(outcome)


func _display_component(component) -> String:
	var text := str(component)
	if text.is_empty():
		return ""
	return text \
		.replace("Launch", "发射仓") \
		.replace("Tuning", "调校仓") \
		.replace("Unit", "单位仓") \
		.replace("Pool", "球池") \
		.replace("Junk", "废球") \
		.replace("Recycle", "回收") \
		.replace("Prime", "预充") \
		.replace("Echo", "复写") \
		.replace("Surge", "脉冲") \
		.replace("Queue", "队列") \
		.replace("Slot", "单位槽") \
		.replace("Gate", "闸门") \
		.replace("capacity", "容量") \
		.replace("pollution", "污染") \
		.replace("value_bonus", "价值加成") \
		.replace("repeat_value", "重复价值") \
		.replace("target_lock", "目标锁定") \
		.replace("charge_buffer", "充能缓冲") \
		.replace("progress_floor", "进度底线") \
		.replace("empty_gap_response", "空窗响应") \
		.replace("empty_gap", "空窗") \
		.replace("merge_window", "合并窗口") \
		.replace("fire_behavior", "发射行为") \
		.replace("return_position", "回流位置")
