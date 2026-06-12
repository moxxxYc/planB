class_name BattleEntityState
extends RefCounted

var entity_id: String = ""
var definition: BattleUnitDefinition = null
var lane: String = "Mid"
var side: String = BattleUnitDefinition.SIDE_PLAYER
var hp: int = 1
var position: float = 0.0
var attack_cooldown: float = 0.0
var root_timer: float = 0.0
var slow_timer: float = 0.0
var slow_multiplier: float = 1.0
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
	root_timer = maxf(0.0, root_timer - delta)
	slow_timer = maxf(0.0, slow_timer - delta)
	if slow_timer <= 0.0:
		slow_multiplier = 1.0

func can_attack() -> bool:
	return alive and attack_cooldown <= 0.0 and root_timer <= 0.0

func reset_attack_cooldown() -> void:
	if definition == null:
		attack_cooldown = 1.0
	else:
		attack_cooldown = definition.attack_interval

func apply_root(seconds: float) -> void:
	root_timer = maxf(root_timer, seconds)

func apply_slow(multiplier: float, seconds: float) -> void:
	slow_multiplier = clampf(multiplier, 0.0, 1.0)
	slow_timer = maxf(slow_timer, seconds)

func movement_multiplier() -> float:
	if root_timer > 0.0:
		return 0.0
	if slow_timer > 0.0:
		return slow_multiplier
	return 1.0

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
		"root_timer": root_timer,
		"slow_timer": slow_timer,
		"slow_multiplier": slow_multiplier,
	}
