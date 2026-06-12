class_name RunSessionModel
extends RefCounted

const NODE_GUARDIAN_CONTRACT: String = "guardian_contract"
const NODE_BATTLE_1: String = "battle_1"
const NODE_REWARD_1: String = "reward_1"
const NODE_BATTLE_2: String = "battle_2"
const NODE_SHOP_1: String = "shop_1"
const NODE_BATTLE_3: String = "battle_3"
const NODE_REST_AFTER_BATTLE_3: String = "rest_after_battle_3"
const NODE_RESULT_ROUTING: String = "result_routing"
const RESULT_WIN: String = "Win"
const RESULT_LOSS: String = "Loss"

var current_node_id: String = NODE_GUARDIAN_CONTRACT
var selected_guardian_id: String = ""
var reward_one_id: String = ""
var shop_purchase_id: String = ""
var gold: int = 0
var guardian_max_hp: int = 100
var guardian_hp: int = 100
var first_shop_rest_count: int = 0
var battle_three_rest_count: int = 0
var last_battle: String = ""
var last_battle_result: String = ""
var planned_counter_id: String = ""
var counter_record: Dictionary = {}
var result_record: Dictionary = {}

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
	if not [NODE_BATTLE_1, NODE_BATTLE_2, NODE_BATTLE_3].has(current_node_id):
		push_error("Current node is not a battle: %s" % current_node_id)
		return

	if battle_result != RESULT_WIN:
		if battle_result != RESULT_LOSS:
			push_error("Unsupported battle result: %s" % battle_result)
			return

	last_battle = current_node_id
	last_battle_result = battle_result

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

func choose_reward_one(reward_id: String) -> void:
	if current_node_id != NODE_REWARD_1:
		push_error("Reward 1 can only be chosen at Reward 1.")
		return

	reward_one_id = reward_id
	current_node_id = NODE_BATTLE_2

func set_planned_counter(counter_id: String) -> void:
	planned_counter_id = counter_id

func set_counter_record(record: Dictionary) -> void:
	counter_record = record.duplicate(true)

func buy_shop_item(modifier_id: String, cost: int) -> bool:
	if current_node_id != NODE_SHOP_1:
		push_error("Shop item can only be bought at First Shop.")
		return false

	if not shop_purchase_id.is_empty():
		return false

	if gold < cost:
		return false

	shop_purchase_id = modifier_id
	gold -= cost
	return true

func damage_guardian(amount: int) -> void:
	guardian_hp = maxi(0, guardian_hp - amount)

func can_buy_rest() -> bool:
	return gold >= 3 and guardian_hp < guardian_max_hp and _rest_limit_remaining() > 0

func buy_rest() -> bool:
	if not can_buy_rest():
		return false

	gold -= 3
	guardian_hp = mini(guardian_max_hp, guardian_hp + 20)

	match current_node_id:
		NODE_SHOP_1:
			first_shop_rest_count += 1
		NODE_REST_AFTER_BATTLE_3:
			battle_three_rest_count += 1

	return true

func confirm_shop_and_rest() -> void:
	if current_node_id != NODE_SHOP_1:
		push_error("First Shop / Rest can only route to Battle 3 from First Shop.")
		return

	current_node_id = NODE_BATTLE_3

func confirm_battle_three_rest() -> void:
	if current_node_id != NODE_REST_AFTER_BATTLE_3:
		push_error("Battle 3 Rest can only route to result after Battle 3.")
		return

	_route_to_result()

func get_rest_count() -> int:
	match current_node_id:
		NODE_SHOP_1:
			return first_shop_rest_count
		NODE_REST_AFTER_BATTLE_3:
			return battle_three_rest_count
		_:
			return 0

func _rest_limit_remaining() -> int:
	match current_node_id:
		NODE_SHOP_1:
			return maxi(0, 1 - first_shop_rest_count)
		NODE_REST_AFTER_BATTLE_3:
			return maxi(0, 1 - battle_three_rest_count)
		_:
			return 0

func _route_to_result() -> void:
	current_node_id = NODE_RESULT_ROUTING
	result_record = {
		"guardian_id": selected_guardian_id,
		"reward1_id": reward_one_id,
		"shop1_purchase_id": shop_purchase_id,
		"gold": gold,
		"rest_first_shop": first_shop_rest_count,
		"rest_battle_three": battle_three_rest_count,
		"last_battle": last_battle,
		"battle_result": last_battle_result,
	}
	for key: String in counter_record.keys():
		result_record["counter1.%s" % key] = counter_record[key]
