class_name BattlefieldState
extends RefCounted

const LANES: Array[String] = ["Left", "Mid", "Right"]
const RESULT_RUNNING: String = "Running"
const RESULT_WIN: String = "Win"
const RESULT_LOSS: String = "Loss"
const PATH_LENGTH: float = 100.0
const PLAYER_GATE_POSITION: float = 10.0
const ENEMY_GATE_POSITION: float = 90.0
const PLAYER_GUARDIAN_POSITION: float = 0.0
const PLAYER_BASE_CIRCLE_RADIUS: float = 6.0
const PLAYER_GUARDIAN_ATTACK_DAMAGE: int = 5
const PLAYER_GUARDIAN_ATTACK_INTERVAL: float = 1.5
const VEIN_TETHER_DAMAGE: int = 4
const VEIN_TETHER_ROOT_SECONDS: float = 0.5
const VEIN_TETHER_SLOW_SECONDS: float = 1.2
const VEIN_TETHER_SLOW_MULTIPLIER: float = 0.6
const ACID_COUNTER_ATTACKER_DAMAGE: int = 4
const ACID_COUNTER_SPLASH_RADIUS: float = 3.0
const ACID_COUNTER_SPLASH_DAMAGE: int = 1
const ACID_COUNTER_MAX_NEARBY_TARGETS: int = 2
const BASE_GATE_HP: int = 60
const PRESSURED_LANE: String = "Left"

var unit_defs: Dictionary = BattleUnitDefinition.catalog()
var wave: BattleWaveDefinition = BattleWaveDefinition.make_for_battle(1)
var telemetry: BattlefieldTelemetry = BattlefieldTelemetry.new()
var entities: Array[BattleEntityState] = []
var player_units: Dictionary = {"Left": 0, "Mid": 0, "Right": 0}
var lane_danger_level: Dictionary = {"Left": 0, "Mid": 0, "Right": 0}
var enemy_raiders: Dictionary = {"Left": 0, "Mid": 0, "Right": 0}
var player_gate_hp: Dictionary = {"Left": BASE_GATE_HP, "Mid": BASE_GATE_HP, "Right": BASE_GATE_HP}
var enemy_gate_hp: Dictionary = {"Left": BASE_GATE_HP, "Mid": BASE_GATE_HP, "Right": BASE_GATE_HP}
var counter_events: Array[String] = []
var deploy_log: Array[String] = []
var battle_elapsed: float = 0.0
var battle_result: String = RESULT_RUNNING
var result_text: String = "战斗进行中：读取 Queue、路线门和守护者压力。"
var battle_number: int = 1
var is_endpoint: bool = false
var player_guardian_max_hp: int = 100
var player_guardian_hp: int = 100
var endpoint_guardian_max_hp: int = 120
var endpoint_guardian_hp: int = 120
var player_guardian_attack_cooldown: float = 0.0
var guardian_contract: RefCounted = null
var _last_guardian_damage_before: int = 0
var sweep_warning_lane: String = ""
var sweep_warning_timer: float = 0.0
var sweep_cooldown: float = 0.0
var _entity_serial: int = 0
var _next_spawn_index: int = 0

func configure(p_battle_number: int, p_endpoint: bool = false, p_player_guardian_hp: int = 100, p_endpoint_guardian_hp: int = 0) -> void:
	battle_number = p_battle_number
	is_endpoint = p_endpoint or p_battle_number >= 6
	wave = BattleWaveDefinition.make_for_battle(6 if is_endpoint else p_battle_number)
	telemetry = BattlefieldTelemetry.new()
	player_guardian_hp = clampi(p_player_guardian_hp, 0, player_guardian_max_hp)
	endpoint_guardian_max_hp = wave.enemy_guardian_hp
	endpoint_guardian_hp = p_endpoint_guardian_hp if p_endpoint_guardian_hp > 0 else endpoint_guardian_max_hp
	entities.clear()
	player_units = {"Left": 0, "Mid": 0, "Right": 0}
	lane_danger_level = {"Left": 0, "Mid": 0, "Right": 0}
	enemy_raiders = {"Left": 0, "Mid": 0, "Right": 0}
	player_gate_hp = {"Left": BASE_GATE_HP, "Mid": BASE_GATE_HP, "Right": BASE_GATE_HP}
	enemy_gate_hp = {"Left": BASE_GATE_HP, "Mid": BASE_GATE_HP, "Right": BASE_GATE_HP}
	counter_events.clear()
	deploy_log.clear()
	battle_elapsed = 0.0
	battle_result = RESULT_RUNNING
	result_text = "战斗进行中：左路轻压，Queue 需要落到受压路线。"
	player_guardian_attack_cooldown = 0.0
	sweep_warning_lane = ""
	sweep_warning_timer = 0.0
	sweep_cooldown = 7.0
	_entity_serial = 0
	_next_spawn_index = 0

func set_guardian_contract(p_guardian_contract: RefCounted) -> void:
	if p_guardian_contract == null:
		guardian_contract = null
		return
	for method_name: String in [
		"advance",
		"on_base_zone_intruder",
		"on_player_guardian_damaged",
	]:
		if not p_guardian_contract.has_method(method_name):
			return
	guardian_contract = p_guardian_contract

func deploy_player_queue_entry(lane: String, queue_entry: Dictionary) -> void:
	if not LANES.has(lane):
		push_error("Invalid battle lane: %s" % lane)
		return
	var count: int = int(queue_entry.get("count", 1))
	var unit_id: String = String(queue_entry.get("unit_id", "hive_short_fang"))
	for _i: int in range(count):
		_spawn_unit(unit_id, lane, BattleUnitDefinition.SIDE_PLAYER)
	player_units[lane] = int(player_units.get(lane, 0)) + count
	deploy_log.append("%s:%s x%d" % [lane, unit_id, count])
	telemetry.record_deploy(lane, queue_entry)
	clear_lane_danger(lane, "Queue 已恢复部署")
	_update_battle_result()

func apply_player_deploy(lane: String, queue_entry: Dictionary) -> void:
	deploy_player_queue_entry(lane, queue_entry)

func advance(delta: float) -> void:
	if battle_result != RESULT_RUNNING:
		return
	battle_elapsed += delta
	if guardian_contract != null:
		guardian_contract.call("advance", delta)
	player_guardian_attack_cooldown = maxf(0.0, player_guardian_attack_cooldown - delta)
	_spawn_due_enemies()
	_advance_sweep(delta)
	for entity: BattleEntityState in entities:
		entity.advance_cooldown(delta)
		if entity.alive:
			_advance_entity(entity, delta)
	_check_guardian_tactical_intruders()
	_advance_player_guardian()
	_cleanup_dead()
	_update_pressure_loss()
	_update_battle_result()

func advance_battle(delta: float) -> void:
	advance(delta)

func get_player_units(lane: String) -> int:
	return int(player_units.get(lane, 0))

func set_lane_danger(lane: String, level: int, reason: String) -> void:
	if not LANES.has(lane):
		return
	lane_danger_level[lane] = clampi(level, 0, 3)
	counter_events.append("%s 危险 %d：%s" % [lane, int(lane_danger_level[lane]), reason])

func clear_lane_danger(lane: String, reason: String) -> void:
	if not LANES.has(lane):
		return
	if get_enemy_raiders(lane) > 0:
		return
	if int(lane_danger_level.get(lane, 0)) <= 0:
		return
	lane_danger_level[lane] = 0
	counter_events.append("%s 危险解除：%s" % [lane, reason])

func spawn_enemy_raiders(lane: String, count: int, reason: String) -> void:
	if not LANES.has(lane):
		return
	for _i: int in range(count):
		_spawn_unit("enemy_raider", lane, BattleUnitDefinition.SIDE_ENEMY)
	enemy_raiders[lane] = int(enemy_raiders.get(lane, 0)) + count
	lane_danger_level[lane] = maxi(int(lane_danger_level.get(lane, 0)), 2)
	counter_events.append("%s 突袭：Enemy Raider x%d，%s" % [lane, count, reason])

func spawn_base_intruder_for_verifier(
	unit_id: String = "enemy_raider",
	lane: String = "Left",
	position: float = 0.0
) -> BattleEntityState:
	if not LANES.has(lane):
		lane = "Left"
	var definition: BattleUnitDefinition = unit_defs.get(unit_id, null) as BattleUnitDefinition
	if definition == null:
		definition = unit_defs["enemy_raider"] as BattleUnitDefinition
	_entity_serial += 1
	var entity := BattleEntityState.make("%s_verifier_%d" % [unit_id, _entity_serial], definition, lane, position)
	entities.append(entity)
	return entity

func damage_player_guardian_for_verifier(attacker: BattleEntityState, amount: int) -> Dictionary:
	if attacker == null:
		return {}
	return _damage_player_guardian(attacker, amount)

func get_lane_danger_level(lane: String) -> int:
	return int(lane_danger_level.get(lane, 0))

func get_enemy_raiders(lane: String) -> int:
	return int(enemy_raiders.get(lane, 0))

func get_battle_result() -> String:
	return battle_result

func get_result_text() -> String:
	return result_text

func get_player_guardian_hp() -> int:
	return player_guardian_hp

func get_endpoint_guardian_hp() -> int:
	return endpoint_guardian_hp

func get_lane_snapshot(lane: String) -> Dictionary:
	var lane_entities: Array[Dictionary] = []
	for entity: BattleEntityState in entities:
		if entity.alive and entity.lane == lane:
			lane_entities.append(entity.snapshot())
	return {
		"lane": lane,
		"player_units": get_player_units(lane),
		"danger": get_lane_danger_level(lane),
		"enemy_raiders": get_enemy_raiders(lane),
		"player_gate_hp": int(player_gate_hp.get(lane, 0)),
		"enemy_gate_hp": int(enemy_gate_hp.get(lane, 0)),
		"entities": lane_entities,
		"sweep_warning": sweep_warning_lane == lane and sweep_warning_timer > 0.0,
	}

func get_telemetry_record() -> Dictionary:
	var record: Dictionary = telemetry.to_record()
	record["endpoint.outcome"] = _result_display()
	record["endpoint.guardian_hp"] = "玩家 %d / %d，终点 %d / %d" % [
		player_guardian_hp,
		player_guardian_max_hp,
		endpoint_guardian_hp,
		endpoint_guardian_max_hp,
	]
	record["battle.elapsed"] = battle_elapsed
	return record

func _spawn_due_enemies() -> void:
	while _next_spawn_index < wave.enemy_spawns.size():
		var spawn: Dictionary = wave.enemy_spawns[_next_spawn_index]
		if battle_elapsed < float(spawn.get("time", 0.0)):
			return
		var lane: String = String(spawn.get("lane", "Left"))
		var unit_id: String = String(spawn.get("unit_id", "enemy_grunt"))
		var count: int = int(spawn.get("count", 1))
		for _i: int in range(count):
			_spawn_unit(unit_id, lane, BattleUnitDefinition.SIDE_ENEMY)
		if unit_id == "enemy_raider":
			enemy_raiders[lane] = int(enemy_raiders.get(lane, 0)) + count
		lane_danger_level[lane] = maxi(int(lane_danger_level.get(lane, 0)), 1 if unit_id == "enemy_grunt" else 2)
		_next_spawn_index += 1

func _spawn_unit(unit_id: String, lane: String, side: String) -> void:
	var definition: BattleUnitDefinition = unit_defs.get(unit_id, null) as BattleUnitDefinition
	if definition == null:
		definition = unit_defs["hive_short_fang"] as BattleUnitDefinition
	var position := 0.0 if side == BattleUnitDefinition.SIDE_PLAYER else PATH_LENGTH
	_entity_serial += 1
	entities.append(BattleEntityState.make("%s_%d" % [unit_id, _entity_serial], definition, lane, position))
	if side == BattleUnitDefinition.SIDE_PLAYER:
		telemetry.record_axis_payoff(definition.result_tag)

func _advance_entity(entity: BattleEntityState, delta: float) -> void:
	if entity.root_timer > 0.0:
		return
	var target := _nearest_opposing_entity(entity)
	if target != null and absf(target.position - entity.position) <= entity.definition.attack_range:
		_attack_entity(entity, target)
		return
	if entity.side == BattleUnitDefinition.SIDE_PLAYER:
		_advance_player_entity(entity, delta)
	else:
		_advance_enemy_entity(entity, delta)

func _advance_player_entity(entity: BattleEntityState, delta: float) -> void:
	var move_delta: float = entity.definition.move_speed * entity.movement_multiplier() * delta
	if int(enemy_gate_hp.get(entity.lane, 0)) > 0:
		if entity.position < ENEMY_GATE_POSITION:
			entity.position = minf(ENEMY_GATE_POSITION, entity.position + move_delta)
		else:
			_attack_gate(entity, enemy_gate_hp, entity.lane, false)
		return
	if entity.position < PATH_LENGTH:
		entity.position = minf(PATH_LENGTH, entity.position + move_delta)
	else:
		_attack_endpoint_guardian(entity)

func _advance_enemy_entity(entity: BattleEntityState, delta: float) -> void:
	var move_delta: float = entity.definition.move_speed * entity.movement_multiplier() * delta
	if int(player_gate_hp.get(entity.lane, 0)) > 0:
		if entity.position > PLAYER_GATE_POSITION:
			entity.position = maxf(PLAYER_GATE_POSITION, entity.position - move_delta)
		else:
			_attack_gate(entity, player_gate_hp, entity.lane, true)
		return
	if entity.position > 0.0:
		entity.position = maxf(0.0, entity.position - move_delta)
	else:
		_attack_player_guardian(entity)

func _nearest_opposing_entity(entity: BattleEntityState) -> BattleEntityState:
	var nearest: BattleEntityState = null
	var nearest_distance := INF
	for other: BattleEntityState in entities:
		if other == entity or not other.alive or other.lane != entity.lane or other.side == entity.side:
			continue
		var distance := absf(other.position - entity.position)
		if distance < nearest_distance:
			nearest = other
			nearest_distance = distance
	return nearest

func _attack_entity(entity: BattleEntityState, target: BattleEntityState) -> void:
	if not entity.can_attack():
		return
	match entity.definition.attack_profile:
		"acid_projectile":
			_apply_acid_projectile_attack(entity, target)
		"lane_sweep":
			_apply_lane_sweep_attack(entity, target)
		_:
			target.take_damage(entity.definition.attack_damage)
	entity.reset_attack_cooldown()

func _apply_acid_projectile_attack(entity: BattleEntityState, target: BattleEntityState) -> void:
	target.take_damage(entity.definition.attack_damage)
	var splash_targets: Array[BattleEntityState] = _nearby_opposing_entities(
		entity,
		target.position,
		entity.definition.splash_radius,
		entity.definition.max_splash_targets,
		target
	)
	for splash_target: BattleEntityState in splash_targets:
		splash_target.take_damage(1)

func _apply_lane_sweep_attack(entity: BattleEntityState, target: BattleEntityState) -> void:
	var sweep_targets: Array[BattleEntityState] = _nearby_opposing_entities(
		entity,
		target.position,
		entity.definition.sweep_radius,
		entity.definition.max_sweep_targets
	)
	for sweep_target: BattleEntityState in sweep_targets:
		sweep_target.take_damage(entity.definition.attack_damage)

func _nearby_opposing_entities(
	entity: BattleEntityState,
	center_position: float,
	radius: float,
	max_count: int,
	excluded: BattleEntityState = null
) -> Array[BattleEntityState]:
	if max_count <= 0:
		return []
	var candidates: Array[BattleEntityState] = []
	for other: BattleEntityState in entities:
		if other == excluded or not other.alive or other.lane != entity.lane or other.side == entity.side:
			continue
		if absf(other.position - center_position) <= radius:
			candidates.append(other)
	candidates.sort_custom(func(a: BattleEntityState, b: BattleEntityState) -> bool:
		var distance_a: float = absf(a.position - center_position)
		var distance_b: float = absf(b.position - center_position)
		if is_equal_approx(distance_a, distance_b):
			return a.hp < b.hp
		return distance_a < distance_b
	)
	var limited: Array[BattleEntityState] = []
	for other: BattleEntityState in candidates:
		limited.append(other)
		if limited.size() >= max_count:
			break
	return limited

func _attack_gate(entity: BattleEntityState, gates: Dictionary, lane: String, is_player_gate: bool) -> void:
	if not entity.can_attack():
		return
	gates[lane] = maxi(0, int(gates.get(lane, 0)) - entity.definition.attack_damage)
	entity.reset_attack_cooldown()
	if is_player_gate and int(gates[lane]) == 0:
		telemetry.record_guardian_pressure("%s 路线门被突破，守护者受压" % _lane_name(lane))

func _attack_endpoint_guardian(entity: BattleEntityState) -> void:
	if not entity.can_attack():
		return
	endpoint_guardian_hp = maxi(0, endpoint_guardian_hp - entity.definition.attack_damage)
	entity.reset_attack_cooldown()

func _attack_player_guardian(entity: BattleEntityState) -> void:
	if not entity.can_attack():
		return
	_damage_player_guardian(entity, entity.definition.attack_damage)
	entity.reset_attack_cooldown()

func closest_player_base_intruder(center_position: float = PLAYER_GUARDIAN_POSITION) -> BattleEntityState:
	var target: BattleEntityState = null
	var target_distance := INF
	var target_hp := INF
	for entity: BattleEntityState in entities:
		if not _is_player_base_intruder(entity):
			continue
		var distance: float = absf(entity.position - center_position)
		if distance < target_distance or (is_equal_approx(distance, target_distance) and float(entity.hp) < target_hp):
			target = entity
			target_distance = distance
			target_hp = float(entity.hp)
	return target

func apply_vein_tether(target: BattleEntityState) -> Dictionary:
	if target == null or not target.alive:
		return {}
	var hp_before: int = target.hp
	target.take_damage(VEIN_TETHER_DAMAGE)
	target.apply_root(VEIN_TETHER_ROOT_SECONDS)
	target.apply_slow(VEIN_TETHER_SLOW_MULTIPLIER, VEIN_TETHER_SLOW_SECONDS)
	var record: Dictionary = {
		"triggered": true,
		"damage": VEIN_TETHER_DAMAGE,
		"target_id": target.entity_id,
		"target_hp_before": hp_before,
		"target_hp_after": target.hp,
		"root_seconds": VEIN_TETHER_ROOT_SECONDS,
		"slow_multiplier": VEIN_TETHER_SLOW_MULTIPLIER,
		"slow_seconds": VEIN_TETHER_SLOW_SECONDS,
		"target_basis": "closest_to_player_guardian_then_lowest_hp",
		"battle_event_log": ["巢脉牵缚：拖住最接近守护者的入侵者"],
		"visible_feedback": "巢脉牵缚",
	}
	telemetry.record_guardian_pressure("巢脉牵缚：%s 受 4 点伤害并被短暂牵制" % _unit_display_name(target))
	return record

func apply_acid_counterattack(attacker: BattleEntityState) -> Dictionary:
	if attacker == null or not attacker.alive:
		return {}
	var attacker_hp_before: int = attacker.hp
	attacker.take_damage(ACID_COUNTER_ATTACKER_DAMAGE)
	var nearby_records: Array[Dictionary] = []
	for target: BattleEntityState in _nearby_player_base_intruders(attacker, ACID_COUNTER_MAX_NEARBY_TARGETS):
		if target == attacker:
			continue
		var hp_before: int = target.hp
		target.take_damage(ACID_COUNTER_SPLASH_DAMAGE)
		nearby_records.append({
			"target_id": target.entity_id,
			"hp_before": hp_before,
			"hp_after": target.hp,
			"damage": ACID_COUNTER_SPLASH_DAMAGE,
		})
	var record: Dictionary = {
		"triggered": true,
		"real_hp_damage_consumed": true,
		"guardian_hp_before": _last_guardian_damage_before,
		"guardian_hp_after": player_guardian_hp,
		"attacker_id": attacker.entity_id,
		"attacker_hp_before": attacker_hp_before,
		"attacker_hp_after": attacker.hp,
		"attacker_damage": ACID_COUNTER_ATTACKER_DAMAGE,
		"splash_radius": ACID_COUNTER_SPLASH_RADIUS,
		"max_nearby_targets": ACID_COUNTER_MAX_NEARBY_TARGETS,
		"nearby_damage": ACID_COUNTER_SPLASH_DAMAGE,
		"nearby_targets": nearby_records,
		"no_heal": true,
		"no_refund": true,
		"no_damage_prevention": true,
		"battle_event_log": ["酸冠反喷：守护者受击后向入侵者反喷酸液"],
		"visible_feedback": "酸冠反喷",
	}
	telemetry.record_guardian_pressure("酸冠反喷：守护者受击后反击 %s" % _unit_display_name(attacker))
	return record

func record_guardian_contract_event(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	telemetry.record_guardian_pressure(text)

func _damage_player_guardian(attacker: BattleEntityState, amount: int) -> Dictionary:
	var hp_before: int = player_guardian_hp
	var damage: int = maxi(0, amount)
	player_guardian_hp = maxi(0, player_guardian_hp - damage)
	_last_guardian_damage_before = hp_before
	telemetry.record_guardian_pressure("敌人从%s进入基地圈，玩家守护者 HP %d" % [_lane_name(attacker.lane), player_guardian_hp])
	if player_guardian_hp <= 0:
		telemetry.record_guardian_break("玩家守护者 HP 被打穿")
	if guardian_contract != null and hp_before > player_guardian_hp:
		guardian_contract.call("on_player_guardian_damaged", attacker, self)
	return {
		"guardian_hp_before": hp_before,
		"guardian_hp_after": player_guardian_hp,
		"damage": hp_before - player_guardian_hp,
	}

func _advance_player_guardian() -> void:
	if player_guardian_attack_cooldown > 0.0:
		return
	var target: BattleEntityState = closest_player_base_intruder()
	if target == null:
		return
	var hp_before: int = target.hp
	target.take_damage(PLAYER_GUARDIAN_ATTACK_DAMAGE)
	player_guardian_attack_cooldown = PLAYER_GUARDIAN_ATTACK_INTERVAL
	telemetry.record_guardian_pressure("守护者基础攻击：%s HP %d -> %d" % [_unit_display_name(target), hp_before, target.hp])

func _check_guardian_tactical_intruders() -> void:
	if guardian_contract == null:
		return
	var target: BattleEntityState = closest_player_base_intruder()
	if target != null:
		guardian_contract.call("on_base_zone_intruder", target, self)

func _is_player_base_intruder(entity: BattleEntityState) -> bool:
	return (
		entity != null
		and entity.alive
		and entity.side == BattleUnitDefinition.SIDE_ENEMY
		and entity.position <= PLAYER_BASE_CIRCLE_RADIUS
	)

func _nearby_player_base_intruders(center: BattleEntityState, max_count: int) -> Array[BattleEntityState]:
	var candidates: Array[BattleEntityState] = []
	for entity: BattleEntityState in entities:
		if not _is_player_base_intruder(entity):
			continue
		if absf(entity.position - center.position) <= ACID_COUNTER_SPLASH_RADIUS:
			candidates.append(entity)
	candidates.sort_custom(func(a: BattleEntityState, b: BattleEntityState) -> bool:
		var distance_a: float = absf(a.position - center.position)
		var distance_b: float = absf(b.position - center.position)
		if is_equal_approx(distance_a, distance_b):
			return a.hp < b.hp
		return distance_a < distance_b
	)
	var limited: Array[BattleEntityState] = []
	for entity: BattleEntityState in candidates:
		if entity == center:
			continue
		limited.append(entity)
		if limited.size() >= max_count:
			break
	return limited

func _advance_sweep(delta: float) -> void:
	if not wave.sweep_enabled:
		return
	if sweep_warning_timer > 0.0:
		sweep_warning_timer = maxf(0.0, sweep_warning_timer - delta)
		if sweep_warning_timer <= 0.0:
			_apply_sweep_damage()
		return
	sweep_cooldown = maxf(0.0, sweep_cooldown - delta)
	if sweep_cooldown <= 0.0:
		sweep_warning_lane = _most_populated_player_lane()
		sweep_warning_timer = 1.8
		counter_events.append("%s 终点扫击预警" % _lane_name(sweep_warning_lane))
		sweep_cooldown = 9.0

func _apply_sweep_damage() -> void:
	for entity: BattleEntityState in entities:
		if entity.alive and entity.side == BattleUnitDefinition.SIDE_PLAYER and entity.lane == sweep_warning_lane:
			entity.take_damage(8)
			entity.position = maxf(0.0, entity.position - 8.0)
	counter_events.append("%s 终点扫击命中" % _lane_name(sweep_warning_lane))
	sweep_warning_lane = ""

func _most_populated_player_lane() -> String:
	var best_lane := "Mid"
	var best_count := -1
	for lane: String in LANES:
		var count := 0
		for entity: BattleEntityState in entities:
			if entity.alive and entity.side == BattleUnitDefinition.SIDE_PLAYER and entity.lane == lane:
				count += 1
		if count > best_count:
			best_lane = lane
			best_count = count
	return best_lane

func _cleanup_dead() -> void:
	var live_entities: Array[BattleEntityState] = []
	var live_raiders: Dictionary = {"Left": 0, "Mid": 0, "Right": 0}
	for entity: BattleEntityState in entities:
		if not entity.alive:
			continue
		live_entities.append(entity)
		if entity.side == BattleUnitDefinition.SIDE_ENEMY and entity.definition != null and entity.definition.id == "enemy_raider":
			live_raiders[entity.lane] = int(live_raiders.get(entity.lane, 0)) + 1
	entities = live_entities
	enemy_raiders = live_raiders

func _update_pressure_loss() -> void:
	if is_endpoint:
		return
	if battle_elapsed >= wave.pressure_limit_seconds and get_player_units(PRESSURED_LANE) <= 0:
		player_guardian_hp = 0

func _update_battle_result() -> void:
	if battle_result != RESULT_RUNNING:
		return
	if endpoint_guardian_hp <= 0:
		battle_result = RESULT_WIN
		result_text = "%s 胜利：敌方守护者被打穿，机器输出转成基地圈压力。" % _battle_label()
		return
	if player_guardian_hp <= 0:
		battle_result = RESULT_LOSS
		result_text = "%s 失败：左路长期没有 Queue 支援，玩家守护者 HP 归零。" % _battle_label()
		telemetry.record_guardian_break("玩家守护者 HP 归零")
		return
	if not is_endpoint and battle_elapsed >= wave.pressure_limit_seconds and _has_player_pressure():
		battle_result = RESULT_WIN
		result_text = "%s 胜利：Queue 成功支援左路，受压路线守住。" % _battle_label()

func _has_player_pressure() -> bool:
	for lane: String in LANES:
		if get_player_units(lane) > 0:
			return true
	return false

func _result_display() -> String:
	match battle_result:
		RESULT_WIN:
			return "胜利"
		RESULT_LOSS:
			return "失败"
		_:
			return "进行中"

func _battle_label() -> String:
	return "终点战" if is_endpoint else "战斗 %d" % battle_number

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

func _unit_display_name(entity: BattleEntityState) -> String:
	if entity == null or entity.definition == null:
		return "未知入侵者"
	return entity.definition.display_name
