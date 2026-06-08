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
	telemetry["gold_faucet.debug_first_pass"] = "6 / 6 / 8 / 0 / 0 / 0, debug first-pass, not final balance"
	_enter_step("Guardian Select")
	return choose_guardian(guardian_id)


func choose_guardian(guardian_id: String) -> Dictionary:
	if not GUARDIAN_RESOURCES.has(guardian_id):
		guardian_id = "hive.vein_mother"

	var guardian: Resource = GUARDIAN_RESOURCES[guardian_id]
	chosen_guardian = _guardian_to_dict(guardian)
	main_axis = str(chosen_guardian.get("axis_lean", "Launch"))
	decision_windows.append("Guardian")
	telemetry["guardian.choice_id"] = chosen_guardian["guardian_id"]
	telemetry["guardian.choice_read"] = "%s leans %s with %s and %s." % [
		chosen_guardian["display_name"],
		chosen_guardian["axis_lean"],
		chosen_guardian["tactical_skill"],
		chosen_guardian["strategic_target"],
	]
	_log(
		"guardian selected",
		"%s selected before Battle 1. Axis lean: %s." % [
			chosen_guardian["display_name"],
			chosen_guardian["axis_lean"],
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


func run_battle(battle_number: int, counter_id: String = "") -> Dictionary:
	var step_label := "Battle %d" % battle_number
	if battle_number == 3:
		step_label = "Battle 3 with counter"
	_enter_step(step_label)

	battlefield_model.reset()
	var lane_name := _lane_for_battle(battle_number)
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
		"Battle %d resolved as %s. Debug Gold faucet is first-pass, not final balance." % [
			battle_number,
			outcome,
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
	decision_windows.append("First Reward")

	telemetry["reward1.choice_id"] = first_reward["display_name"]
	telemetry["reward1.axis"] = first_reward["warehouse"]
	telemetry["reward1.component_operation"] = "%s -> %s" % [
		first_reward["target_component"],
		first_reward["operation"],
	]
	telemetry["reward1.battlefield_expectation"] = first_reward["player_read"]
	telemetry["reward1.battlefield_result"] = "%s seen on %s during debug battles." % [
		first_reward["player_read"],
		_lane_for_battle(2),
	]

	_log(
		"first reward selected",
		"%s selected as %s axis anchor." % [first_reward["display_name"], main_axis],
		first_reward
	)
	return first_reward.duplicate(true)


func run_first_shop() -> Dictionary:
	_enter_step("Shop / Gold / Rest")

	var inventory := _shop_inventory_for_axis(main_axis)
	var purchase_id: String = inventory[0]
	shop_purchase = _modifier_to_dict(MODIFIER_RESOURCES[purchase_id])
	var gold_before := gold
	var neutral_cap_before := 0
	var neutral_cap_after := 1
	var price := _price_for_modifier(shop_purchase)
	gold = max(0, gold - price)
	decision_windows.append("First Shop")

	var rest_record := _maybe_rest("first_shop")

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
		"Bought %s for %d Gold. Neutral modifier cap used. Rest is a separate choice." % [
			shop_purchase["display_name"],
			price,
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


func choose_second_reward() -> Dictionary:
	_enter_step("Second Reward")
	var candidates := _second_reward_candidates_for_axis(main_axis)
	var choice_id: String = candidates[0]["modifier_id"]
	second_reward = _modifier_to_dict(MODIFIER_RESOURCES[choice_id])
	decision_windows.append("Second Reward")

	telemetry["second_offer.current_axis"] = main_axis
	telemetry["second_offer.candidates"] = candidates.duplicate(true)
	telemetry["second_offer.choice_id"] = second_reward["display_name"]
	telemetry["second_offer.choice_role"] = candidates[0]["offer_role"]

	_log(
		"second reward selected",
		"%s selected as %s for current axis %s." % [
			second_reward["display_name"],
			candidates[0]["offer_role"],
			main_axis,
		],
		{"candidates": candidates, "choice": second_reward}
	)
	return second_reward.duplicate(true)


func run_endpoint_prep() -> Dictionary:
	_enter_step("Endpoint Prep")
	var rest_record := _maybe_rest("endpoint_prep")
	decision_windows.append("Endpoint Prep")
	telemetry["session.decision_windows"] = decision_windows.duplicate(true)
	telemetry["session.consecutive_no_explained_decision_battles"] = 0
	_log(
		"endpoint prep",
		"Endpoint prep opened. No second shop; Rest only if HP and Gold allow.",
		{"rest": rest_record, "gold": gold}
	)
	return {"rest": rest_record, "gold": gold}


func run_endpoint(player_wins: bool) -> Dictionary:
	_enter_step("Endpoint")
	battlefield_model.reset()
	battlefield_model.select_lane("Mid")
	var queue_entry: Dictionary = _generate_machine_queue_entry_for_battle(6)
	battlefield_model.enqueue_machine_queue_entry(queue_entry)
	var deployed: Dictionary = battlefield_model.deploy_next_queue_entry()
	_record_deploy_lane_impact(6, "Mid", deployed, queue_entry)
	battlefield_model.set_public_warning("Mid", 2)

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
		"Endpoint Guardian used Telegraphed Sweep warning. Outcome: %s." % endpoint_outcome,
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
		"%s warned against %s, then applied visible effect: %s" % [
			record["display_name"],
			record["target_component"],
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
			chosen_guardian.get("axis_lean", ""),
		],
		"main_axis": main_axis,
		"key_rewards": "First: %s; Second: %s" % [
			first_reward.get("display_name", ""),
			second_reward.get("display_name", ""),
		],
		"shop_rest_choice": _summarize_shop_and_rest(),
		"counter_target": "%s -> %s" % [
			latest_counter.get("display_name", ""),
			latest_counter.get("target_component", ""),
		],
		"deploy_lane_impact": _summarize_deploy_lane_impact(),
		"endpoint_payoff_or_break_reason": payoff_or_break,
		"next_run_watch_tag": str(telemetry.get("endpoint.next_run_watch_tag", "")),
	}

	telemetry["unit.visible_contribution_slots"] = _visible_slot_ids()
	telemetry["unit.key_queue_entries_by_slot"] = key_queue_entries_by_slot.duplicate(true)
	telemetry["unit.dominant_slot_share"] = _dominant_slot_share()

	_log("result page", "Result page built from real M3 run data.", result_page)
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
		"Battle %d awarded %d Gold. Debug first-pass faucet, not final balance." % [
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
		"impact": "future queue entry deployed to selected lane; existing units were not retargeted",
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
			return "steady low-demand line refill"
		2:
			return "shield pressure absorbed lane contact"
		3:
			return "acid sac helped break a stall"
		4:
			return "crush shell beast anchored late pressure"
	return "unknown slot contribution"


func _counter_to_record(counter: Resource, battle_number: int) -> Dictionary:
	var display_name := str(counter.get("display_name"))
	var target_component := str(counter.get("target_component"))
	var visible_effect := str(counter.get("visible_effect"))
	return {
		"counter_id": str(counter.get("counter_id")),
		"display_name": display_name,
		"battle_number": battle_number,
		"warning": "%s warning for %.1fs at %s." % [
			display_name,
			float(counter.get("warning_seconds")),
			target_component,
		],
		"target_component": target_component,
		"visible_effect": visible_effect,
		"log_record": "UI/log records %s -> %s -> %s." % [
			display_name,
			target_component,
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
				_offer("echo_latch", "Deepen current axis", "Because your first reward is Tuning."),
				_offer("surge_buffer", "Patch", "Because counters can break repeated Tuning value."),
				_offer("queue_brace", "Pivot", "Because queue gaps remain visible pressure."),
			]
		"Unit":
			return [
				_offer("muster_pair", "Deepen current axis", "Because your first reward is Unit."),
				_offer("queue_brace", "Patch", "Because Stagger Punisher attacks queue gaps."),
				_offer("front_recycle", "Pivot", "Because Launch flow can cover empty windows."),
			]
		_:
			return [
				_offer("front_recycle", "Deepen current axis", "Because your first reward is Launch."),
				_offer("junk_sieve", "Patch", "Because Pool Polluter attacks Pool capacity."),
				_offer("queue_brace", "Pivot", "Because queue gaps remain visible pressure."),
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
		return "Junk Sieve / Pool Pocket available as Launch pollution patch."
	if target.contains("Echo"):
		return "Surge Buffer / Prime Charge available as Tuning patch or pivot."
	return "Queue Brace / Slot Primer available as Unit gap patch."


func _endpoint_payoff_for_axis(axis: String, player_wins: bool) -> String:
	if not player_wins:
		return "main axis did not clearly convert into Endpoint base-circle output"
	match axis:
		"Tuning":
			return "Tuning high-value hit survived Echo pressure and opened Endpoint damage window"
		"Unit":
			return "Unit batch release produced a late Endpoint lane push"
		_:
			return "Launch sustained flow kept queue pressure through Telegraphed Sweep"


func _break_reason_for_counter(counter_record: Dictionary) -> String:
	var target := str(counter_record.get("target_component", ""))
	if target.contains("Pool"):
		return "Pool pollution broke Launch sustained flow before Endpoint"
	if target.contains("Echo"):
		return "Echo / Surge value was interrupted before Endpoint payoff"
	return "queue gap let Stagger pressure reach Guardian HP"


func _next_watch_tag(counter_record: Dictionary, player_wins: bool) -> String:
	if player_wins:
		match main_axis:
			"Tuning":
				return "Tuning high-value hit confirmed"
			"Unit":
				return "Unit batch release confirmed"
			_:
				return "Launch sustained flow confirmed"

	var target := str(counter_record.get("target_component", ""))
	if target.contains("Pool"):
		return "Launch pollution patch"
	if target.contains("Echo"):
		return "Tuning repeated hit"
	return "Unit gap patch"


func _summarize_shop_and_rest() -> String:
	var rest_text := "no Rest"
	if not rest_records.is_empty():
		var restored := 0
		var spent := 0
		for record in rest_records:
			restored += int(record.get("hp_restored", 0))
			spent += int(record.get("gold_spent", 0))
		rest_text = "Rest x%d, %d HP restored for %d Gold" % [
			rest_records.size(),
			restored,
			spent,
		]
	return "%s (%s), %s, Gold left %d" % [
		shop_purchase.get("display_name", ""),
		shop_purchase.get("role_tag", ""),
		rest_text,
		gold,
	]


func _summarize_deploy_lane_impact() -> String:
	if deploy_lane_records.is_empty():
		return "No key Deploy Lane impact recorded."

	var first := deploy_lane_records[0]
	var last := deploy_lane_records[deploy_lane_records.size() - 1]
	return "Battle %d sent %s from S%d to %s; Endpoint sent %s to %s. Lane clicks affected future deployments only." % [
		int(first.get("battle", 0)),
		first.get("unit_name", ""),
		int(first.get("source_slot_id", 0)),
		first.get("selected_lane", ""),
		last.get("unit_name", ""),
		last.get("selected_lane", ""),
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
