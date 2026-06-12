class_name BattlefieldState
extends RefCounted

const LANES: Array[String] = ["Left", "Mid", "Right"]
const RESULT_RUNNING: String = "Running"
const RESULT_WIN: String = "Win"
const RESULT_LOSS: String = "Loss"
const PATH_LENGTH: float = 100.0
const PLAYER_GATE_POSITION: float = 10.0
const ENEMY_GATE_POSITION: float = 90.0
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
var sweep_warning_lane: String = ""
var sweep_warning_timer: float = 0.0
var sweep_cooldown: float = 0.0
var _entity_serial: int = 0
var _next_spawn_index: int = 0

func configure(p_battle_number: int, p_endpoint: bool = false, p_player_guardian_hp: int = 100, p_endpoint_guardian_hp: int = 0) -> void:
	battle_number = p_battle_number
	is_endpoint = p_endpoint or p_battle_number >= 6
	wave = BattleWaveDefinition.make_for_battle(6 if is_endpoint else p_battle_number)
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
	sweep_warning_lane = ""
	sweep_warning_timer = 0.0
	sweep_cooldown = 7.0
	_entity_serial = 0
	_next_spawn_index = 0

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
	_spawn_due_enemies()
	_advance_sweep(delta)
	for entity: BattleEntityState in entities:
		entity.advance_cooldown(delta)
		if entity.alive:
			_advance_entity(entity, delta)
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
	var target := _nearest_opposing_entity(entity)
	if target != null and absf(target.position - entity.position) <= entity.definition.attack_range:
		_attack_entity(entity, target)
		return
	if entity.side == BattleUnitDefinition.SIDE_PLAYER:
		_advance_player_entity(entity, delta)
	else:
		_advance_enemy_entity(entity, delta)

func _advance_player_entity(entity: BattleEntityState, delta: float) -> void:
	if int(enemy_gate_hp.get(entity.lane, 0)) > 0:
		if entity.position < ENEMY_GATE_POSITION:
			entity.position = minf(ENEMY_GATE_POSITION, entity.position + entity.definition.move_speed * delta)
		else:
			_attack_gate(entity, enemy_gate_hp, entity.lane, false)
		return
	if entity.position < PATH_LENGTH:
		entity.position = minf(PATH_LENGTH, entity.position + entity.definition.move_speed * delta)
	else:
		_attack_endpoint_guardian(entity)

func _advance_enemy_entity(entity: BattleEntityState, delta: float) -> void:
	if int(player_gate_hp.get(entity.lane, 0)) > 0:
		if entity.position > PLAYER_GATE_POSITION:
			entity.position = maxf(PLAYER_GATE_POSITION, entity.position - entity.definition.move_speed * delta)
		else:
			_attack_gate(entity, player_gate_hp, entity.lane, true)
		return
	if entity.position > 0.0:
		entity.position = maxf(0.0, entity.position - entity.definition.move_speed * delta)
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
	target.take_damage(entity.definition.attack_damage)
	entity.reset_attack_cooldown()

func _attack_gate(entity: BattleEntityState, gates: Dictionary, lane: String, is_player_gate: bool) -> void:
	if not entity.can_attack():
		return
	gates[lane] = maxi(0, int(gates.get(lane, 0)) - entity.definition.attack_damage)
	entity.reset_attack_cooldown()
	if is_player_gate and int(gates[lane]) == 0:
		telemetry.record_guardian_pressure("%s 路线门被突破，Guardian 受压" % _lane_name(lane))

func _attack_endpoint_guardian(entity: BattleEntityState) -> void:
	if not entity.can_attack():
		return
	endpoint_guardian_hp = maxi(0, endpoint_guardian_hp - entity.definition.attack_damage)
	entity.reset_attack_cooldown()

func _attack_player_guardian(entity: BattleEntityState) -> void:
	if not entity.can_attack():
		return
	player_guardian_hp = maxi(0, player_guardian_hp - entity.definition.attack_damage)
	telemetry.record_guardian_pressure("Enemy 从%s进入基地圈，Player Guardian HP %d" % [_lane_name(entity.lane), player_guardian_hp])
	entity.reset_attack_cooldown()

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
	for entity: BattleEntityState in entities:
		if entity.alive:
			continue
		if entity.side == BattleUnitDefinition.SIDE_ENEMY and entity.definition != null and entity.definition.id == "enemy_raider":
			enemy_raiders[entity.lane] = maxi(0, int(enemy_raiders.get(entity.lane, 0)) - 1)

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
		result_text = "%s 胜利：敌方 Guardian 被打穿，机器输出转成基地圈压力。" % _battle_label()
		return
	if player_guardian_hp <= 0:
		battle_result = RESULT_LOSS
		result_text = "%s 失败：左路长期没有 Queue 支援，Player Guardian HP 归零。" % _battle_label()
		telemetry.endpoint_main_break_reason = "Guardian HP 被打穿"
		telemetry.endpoint_next_run_watch_tag = "Guardian HP pressure"
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
