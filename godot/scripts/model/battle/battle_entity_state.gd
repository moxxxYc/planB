class_name BattleEntityState
extends RefCounted

var entity_id: String = ""
var definition: BattleUnitDefinition = null
var lane: String = "Mid"
var side: String = BattleUnitDefinition.SIDE_PLAYER
var hp: int = 1
var position: float = 0.0
var attack_cooldown: float = 0.0
var alive: bool = true
var entered_from: String = ""

static func make(p_entity_id: String, p_definition: BattleUnitDefinition, p_lane: String, p_position: float) -> BattleEntityState:
	var entity := BattleEntityState.new()
	entity.entity_id = p_entity_id
	entity.definition = p_definition
	entity.lane = p_lane
	entity.side = p_definition.side if p_definition != null else BattleUnitDefinition.SIDE_PLAYER
	entity.hp = p_definition.max_hp if p_definition != null else 1
	entity.position = p_position
	entity.entered_from = p_lane
	return entity

func take_damage(amount: int) -> void:
	if not alive:
		return
	hp = maxi(0, hp - amount)
	alive = hp > 0

func advance_cooldown(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)

func can_attack() -> bool:
	return alive and attack_cooldown <= 0.0

func reset_attack_cooldown() -> void:
	if definition == null:
		attack_cooldown = 1.0
	else:
		attack_cooldown = definition.attack_interval

func snapshot() -> Dictionary:
	return {
		"id": entity_id,
		"unit_id": definition.id if definition != null else "",
		"display_name": definition.display_name if definition != null else "",
		"side": side,
		"lane": lane,
		"hp": hp,
		"position": position,
		"alive": alive,
	}
