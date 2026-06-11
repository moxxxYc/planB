class_name BattlefieldDeployModel
extends RefCounted

const HIVE_UNIT_RESOURCES := {
	1: preload("res://resources/units/hive_short_fang.tres"),
	2: preload("res://resources/units/hive_shield_shell.tres"),
	3: preload("res://resources/units/hive_acid_sac.tres"),
	4: preload("res://resources/units/hive_crush_shell_beast.tres"),
}

const ENEMY_UNIT_RESOURCES := {
	"Enemy Grunt": preload("res://resources/enemies/enemy_grunt.tres"),
	"Enemy Raider": preload("res://resources/enemies/enemy_raider.tres"),
	"Enemy Brute": preload("res://resources/enemies/enemy_brute.tres"),
}

const LANE_IDS := [&"left", &"mid", &"right"]
const LANE_NAMES := {
	&"left": "Left",
	&"mid": "Mid",
	&"right": "Right",
}

const PLAYER_SIDE := "player"
const ENEMY_SIDE := "enemy"

const PLAYER_GATE_POS := 8.0
const ENEMY_GATE_POS := 92.0
const PLAYER_SPAWN_POS := 0.0
const ENEMY_SPAWN_POS := 100.0
const PLAYER_GUARDIAN_MAX_HP := 100
const ENEMY_GUARDIAN_MAX_HP := 120
const LANE_GATE_MAX_HP := 60
const BASE_DEPLOY_INTERVAL_SECONDS := 0.5
const EVENT_LOG_LIMIT := 48

var selected_lane_id: StringName = &"mid"
var battle_time_seconds: float = 0.0
var battle_state := "running"
var player_guardian_hp := PLAYER_GUARDIAN_MAX_HP
var enemy_guardian_hp := ENEMY_GUARDIAN_MAX_HP
var player_guardian_template_id := "hive.vein_mother"
var lanes: Dictionary = {}
var deploy_queue: Array[Dictionary] = []
var units: Array[Dictionary] = []
var deployed_units_history: Array[Dictionary] = []
var event_log: Array[Dictionary] = []

var _deploy_timer_seconds: float = 0.0
var _unit_index := 0
var _seen_lane_states := {}


func _init() -> void:
	reset()


func reset() -> void:
	selected_lane_id = &"mid"
	battle_time_seconds = 0.0
	battle_state = "running"
	player_guardian_hp = PLAYER_GUARDIAN_MAX_HP
	enemy_guardian_hp = ENEMY_GUARDIAN_MAX_HP
	player_guardian_template_id = "hive.vein_mother"
	deploy_queue.clear()
	units.clear()
	deployed_units_history.clear()
	event_log.clear()
	_deploy_timer_seconds = 0.0
	_unit_index = 0
	_seen_lane_states.clear()
	lanes.clear()

	for lane_id in LANE_IDS:
		lanes[lane_id] = {
			"lane_id": lane_id,
			"lane_name": LANE_NAMES[lane_id],
			"player_gate_hp": LANE_GATE_MAX_HP,
			"enemy_gate_hp": LANE_GATE_MAX_HP,
			"player_gate_broken": false,
			"enemy_gate_broken": false,
			"public_warning_tier": 0,
			"danger_tier": 0,
			"state": "idle",
		}

	_record_event("battle reset", "战场已准备，默认部署路线为中路。", {})


func select_lane(lane) -> bool:
	var lane_id := _normalize_lane_id(lane)
	if lane_id == &"":
		return false
	selected_lane_id = lane_id
	_record_event(
		"lane selected",
		"部署路线已切换到%s。" % _display_lane(lane_id),
		{"lane_name": LANE_NAMES[lane_id]}
	)
	_update_lane_states_and_danger()
	return true


func get_selected_lane_name() -> String:
	return LANE_NAMES[selected_lane_id]


func set_player_guardian_template_id(template_id: String) -> void:
	if template_id == "hive.acid_crown_mother":
		player_guardian_template_id = template_id
	else:
		player_guardian_template_id = "hive.vein_mother"


func enqueue_machine_queue_entry(queue_entry: Dictionary) -> bool:
	if not queue_entry.has("queue_entry_id") or not queue_entry.has("source_slot_id"):
		return false
	if not str(queue_entry.get("trigger_chain", "")).contains("Launch->Tuning->Unit"):
		return false

	var entry := queue_entry.duplicate(true)
	entry["queued_at_seconds"] = battle_time_seconds
	deploy_queue.append(entry)
	_record_event(
		"queue entry added",
		"队首 %s 现在预览部署到%s。" % [
			entry.get("queue_entry_id", ""),
			_display_lane(selected_lane_id),
		],
		{
			"queue_entry_id": entry.get("queue_entry_id", ""),
			"deploy_lane_name": get_selected_lane_name(),
		}
	)
	return true


func get_queue_preview() -> Array:
	var preview: Array = []
	for entry in deploy_queue.slice(0, min(3, deploy_queue.size())):
		var preview_entry: Dictionary = entry.duplicate(true)
		preview_entry["deploy_lane_id"] = selected_lane_id
		preview_entry["deploy_lane_name"] = get_selected_lane_name()
		preview.append(preview_entry)
	return preview


func deploy_next_queue_entry() -> Dictionary:
	if deploy_queue.is_empty() or battle_state != "running":
		return {}

	var entry: Dictionary = deploy_queue.pop_front()
	var lane_id := selected_lane_id
	var unit := _spawn_player_unit_from_queue(entry, lane_id)
	deployed_units_history.append(unit.duplicate(true))
	_record_event(
		"queue deployed",
		"队列条目 %s 已部署到%s。" % [
			entry.get("queue_entry_id", ""),
			_display_lane(lane_id),
		],
		{
			"queue_entry_id": entry.get("queue_entry_id", ""),
			"lane_name": LANE_NAMES[lane_id],
			"unit_id": unit.get("unit_id", ""),
		}
	)
	_update_lane_states_and_danger()
	return unit.duplicate(true)


func get_deployed_units_history() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for unit in deployed_units_history:
		results.append(unit.duplicate(true))
	return results


func spawn_enemy(lane, enemy_name := "Enemy Grunt", path_pos := ENEMY_SPAWN_POS) -> Dictionary:
	var lane_id := _normalize_lane_id(lane)
	if lane_id == &"":
		return {}
	if not ENEMY_UNIT_RESOURCES.has(enemy_name):
		return {}

	var unit := _make_unit_from_resource(
		ENEMY_SIDE,
		lane_id,
		ENEMY_UNIT_RESOURCES[enemy_name],
		clamp(path_pos, PLAYER_SPAWN_POS, ENEMY_SPAWN_POS),
		{}
	)
	units.append(unit)
	_record_event(
		"enemy spawned",
		"%s 在%s %.1f 位置出现。" % [
			unit.get("display_name", enemy_name),
			_display_lane(lane_id),
			unit.get("path_pos", path_pos),
		],
		unit
	)
	_update_lane_states_and_danger()
	return unit.duplicate(true)


func tick(delta: float) -> void:
	if battle_state != "running":
		return

	var step: float = max(0.0, delta)
	battle_time_seconds += step
	_deploy_timer_seconds = max(0.0, _deploy_timer_seconds - step)
	if not deploy_queue.is_empty() and _deploy_timer_seconds <= 0.0:
		var next_entry: Dictionary = deploy_queue[0]
		deploy_next_queue_entry()
		_deploy_timer_seconds = float(
			next_entry.get("deploy_delay_seconds", BASE_DEPLOY_INTERVAL_SECONDS)
		)

	for index in range(units.size()):
		_tick_unit(index, step)

	_remove_dead_units()
	_update_lane_states_and_danger()


func get_units_for_lane(lane, side := "") -> Array:
	var lane_id := _normalize_lane_id(lane)
	var results: Array = []
	for unit in units:
		if unit.get("lane_id", &"") != lane_id:
			continue
		if not side.is_empty() and unit.get("side", "") != side:
			continue
		if int(unit.get("hp", 0)) <= 0:
			continue
		results.append(unit.duplicate(true))
	return results


func get_lane_state(lane) -> String:
	_update_lane_states_and_danger()
	var lane_id := _normalize_lane_id(lane)
	if lane_id == &"":
		return ""
	return str(lanes[lane_id].get("state", "idle"))


func get_lane_danger_tier(lane) -> int:
	_update_lane_states_and_danger()
	var lane_id := _normalize_lane_id(lane)
	if lane_id == &"":
		return 0
	return int(lanes[lane_id].get("danger_tier", 0))


func set_public_warning(lane, tier: int) -> bool:
	var lane_id := _normalize_lane_id(lane)
	if lane_id == &"":
		return false
	var lane_data: Dictionary = lanes[lane_id]
	lane_data["public_warning_tier"] = clamp(tier, 0, 3)
	lanes[lane_id] = lane_data
	_record_event(
		"lane warning",
		"%s公开预警提升到 %d 级。" % [
			_display_lane(lane_id),
			lane_data["public_warning_tier"],
		],
		{
			"lane_name": LANE_NAMES[lane_id],
			"tier": lane_data["public_warning_tier"],
		}
	)
	_update_lane_states_and_danger()
	return true


func get_battle_state() -> String:
	return battle_state


func get_recent_event_states() -> Array[String]:
	var states: Array[String] = []
	for event in event_log:
		states.append(str(event.get("state", "")))
	return states


func get_state_snapshot() -> Dictionary:
	_update_lane_states_and_danger()
	return {
		"battle_time_seconds": battle_time_seconds,
		"battle_state": battle_state,
		"selected_lane_name": get_selected_lane_name(),
		"queue_preview": get_queue_preview(),
		"lanes": lanes.duplicate(true),
		"units": units.duplicate(true),
		"player_guardian_hp": player_guardian_hp,
		"player_guardian_max_hp": PLAYER_GUARDIAN_MAX_HP,
		"player_guardian_template_id": player_guardian_template_id,
		"enemy_guardian_hp": enemy_guardian_hp,
		"enemy_guardian_max_hp": ENEMY_GUARDIAN_MAX_HP,
		"event_log": event_log.duplicate(true),
	}


func create_lane_state_sample(lane, state: String) -> bool:
	var lane_id := _normalize_lane_id(lane)
	if lane_id == &"":
		return false

	match state:
		"pushing":
			_spawn_player_sample_unit(lane_id, 54.0)
		"stalled":
			_spawn_player_sample_unit(lane_id, 48.0)
			spawn_enemy(LANE_NAMES[lane_id], "Enemy Grunt", 50.0)
		"leaking":
			spawn_enemy(LANE_NAMES[lane_id], "Enemy Raider", 18.0)
		"gate broken":
			var lane_data: Dictionary = lanes[lane_id]
			lane_data["player_gate_hp"] = 0
			lane_data["player_gate_broken"] = true
			lanes[lane_id] = lane_data
			_record_event("gate broken", "%s玩家侧路闸被击破。" % _display_lane(lane_id), {})
		"invading":
			var lane_data: Dictionary = lanes[lane_id]
			lane_data["player_gate_hp"] = 0
			lane_data["player_gate_broken"] = true
			lanes[lane_id] = lane_data
			spawn_enemy(LANE_NAMES[lane_id], "Enemy Raider", 6.0)
		_:
			return false

	_seen_lane_states[state] = true
	_update_lane_states_and_danger()
	return true


func has_seen_lane_state(state: String) -> bool:
	return _seen_lane_states.has(state)


func resolve_battle_result(next_state: String) -> bool:
	match next_state:
		"player_win":
			battle_state = "player_win"
			enemy_guardian_hp = 0
		"player_loss":
			battle_state = "player_loss"
			player_guardian_hp = 0
		_:
			return false
	_record_event("battle resolved", "战斗已结算：%s。" % _display_battle_state(battle_state), {})
	return true


func _spawn_player_unit_from_queue(entry: Dictionary, lane_id: StringName) -> Dictionary:
	var slot_id := int(entry.get("source_slot_id", 1))
	if not HIVE_UNIT_RESOURCES.has(slot_id):
		slot_id = 1

	var unit := _make_unit_from_resource(
		PLAYER_SIDE,
		lane_id,
		HIVE_UNIT_RESOURCES[slot_id],
		PLAYER_SPAWN_POS,
		entry
	)
	units.append(unit)
	return unit


func _spawn_player_sample_unit(lane_id: StringName, path_pos: float) -> Dictionary:
	var unit := _make_unit_from_resource(
		PLAYER_SIDE,
		lane_id,
		HIVE_UNIT_RESOURCES[2],
		clamp(path_pos, PLAYER_SPAWN_POS, ENEMY_SPAWN_POS),
		{"queue_entry_id": "sample", "source_slot_id": 2}
	)
	units.append(unit)
	_record_event(
		"unit spawned",
		"蜂巢单位已放置到%s %.1f 位置。" % [_display_lane(lane_id), path_pos],
		unit
	)
	return unit


func _make_unit_from_resource(
	side: String,
	lane_id: StringName,
	template: Resource,
	path_pos: float,
	source_entry: Dictionary
) -> Dictionary:
	_unit_index += 1
	var max_hp := int(template.get("hp"))
	var template_id_value = template.get("unit_id")
	if template_id_value == null or str(template_id_value).is_empty():
		template_id_value = template.get("enemy_id")
	return {
		"unit_id": "%s-%03d" % [side, _unit_index],
		"side": side,
		"lane_id": lane_id,
		"lane_name": LANE_NAMES[lane_id],
		"path_pos": path_pos,
		"display_name": str(template.get("display_name")),
		"template_id": str(template_id_value),
		"hp": max_hp,
		"max_hp": max_hp,
		"attack_damage": int(template.get("attack_damage")),
		"attack_interval": float(template.get("attack_interval")),
		"attack_range": float(template.get("attack_range")),
		"move_speed": float(template.get("move_speed")),
		"attack_cooldown": 0.0,
		"state": "marching",
		"source_queue_entry_id": str(source_entry.get("queue_entry_id", "")),
		"source_slot_id": int(source_entry.get("source_slot_id", 0)),
		"tuning_result": str(source_entry.get("tuning_result", "")),
	}


func _tick_unit(index: int, delta: float) -> void:
	if index < 0 or index >= units.size():
		return

	var unit: Dictionary = units[index]
	if int(unit.get("hp", 0)) <= 0:
		return

	var target_index := _find_unit_target_index(index)
	if target_index != -1:
		_attack_unit_target(index, target_index, delta)
		return

	if _attack_lane_object_if_reached(index, delta):
		return

	_march_unit(index, delta)


func _find_unit_target_index(index: int) -> int:
	var unit: Dictionary = units[index]
	var lane_id: StringName = unit.get("lane_id", &"")
	var side: String = unit.get("side", "")
	var best_index := -1
	var best_distance := INF

	for target_index in range(units.size()):
		if target_index == index:
			continue
		var target: Dictionary = units[target_index]
		if int(target.get("hp", 0)) <= 0:
			continue
		if target.get("lane_id", &"") != lane_id:
			continue
		if target.get("side", "") == side:
			continue
		var distance: float = abs(
			float(unit.get("path_pos", 0.0)) - float(target.get("path_pos", 0.0))
		)
		if distance <= float(unit.get("attack_range", 0.0)) and distance < best_distance:
			best_distance = distance
			best_index = target_index

	return best_index


func _attack_unit_target(index: int, target_index: int, delta: float) -> void:
	var unit: Dictionary = units[index]
	unit["state"] = "unit attacking"
	unit["attack_cooldown"] = float(unit.get("attack_cooldown", 0.0)) - delta
	if float(unit["attack_cooldown"]) <= 0.0:
		_damage_unit(target_index, int(unit.get("attack_damage", 0)), str(unit.get("unit_id", "")))
		unit["attack_cooldown"] = float(unit.get("attack_interval", 1.0))
		_record_event(
			"unit attacking",
			"%s 在%s攻击敌对单位。" % [
				unit.get("display_name", ""),
				_display_lane(unit.get("lane_name", "")),
			],
			{"unit_id": unit.get("unit_id", "")}
		)
	units[index] = unit


func _attack_lane_object_if_reached(index: int, delta: float) -> bool:
	var unit: Dictionary = units[index]
	var lane_id: StringName = unit.get("lane_id", &"")
	var lane_data: Dictionary = lanes[lane_id]
	var side: String = unit.get("side", "")
	var path_pos := float(unit.get("path_pos", 0.0))
	var attack_range := float(unit.get("attack_range", 0.0))

	if side == PLAYER_SIDE:
		if not bool(lane_data.get("enemy_gate_broken", false)):
			if path_pos >= ENEMY_GATE_POS - attack_range:
				unit["path_pos"] = ENEMY_GATE_POS
				units[index] = unit
				_attack_gate(index, ENEMY_SIDE, delta)
				return true
		elif path_pos >= ENEMY_GATE_POS + 4.0:
			_attack_guardian(index, ENEMY_SIDE, delta)
			return true
	else:
		if not bool(lane_data.get("player_gate_broken", false)):
			if path_pos <= PLAYER_GATE_POS + attack_range:
				unit["path_pos"] = PLAYER_GATE_POS
				units[index] = unit
				_attack_gate(index, PLAYER_SIDE, delta)
				return true
		elif path_pos <= PLAYER_GATE_POS - 4.0:
			_attack_guardian(index, PLAYER_SIDE, delta)
			return true

	return false


func _attack_gate(index: int, target_side: String, delta: float) -> void:
	var unit: Dictionary = units[index]
	unit["state"] = "attacking gate"
	unit["attack_cooldown"] = float(unit.get("attack_cooldown", 0.0)) - delta
	if float(unit["attack_cooldown"]) > 0.0:
		units[index] = unit
		return

	var lane_id: StringName = unit.get("lane_id", &"")
	var lane_data: Dictionary = lanes[lane_id]
	var hp_key := "player_gate_hp" if target_side == PLAYER_SIDE else "enemy_gate_hp"
	var broken_key := "player_gate_broken" if target_side == PLAYER_SIDE else "enemy_gate_broken"
	lane_data[hp_key] = max(0, int(lane_data.get(hp_key, 0)) - int(unit.get("attack_damage", 0)))
	if int(lane_data[hp_key]) <= 0 and not bool(lane_data.get(broken_key, false)):
		lane_data[broken_key] = true
		_record_event(
			"gate broken",
			"%s%s路闸被击破。" % [
				_display_lane(lane_id),
				_display_side(target_side),
			],
			{"lane_name": LANE_NAMES[lane_id], "target_side": target_side}
		)
	else:
		_record_event(
			"gate damaged",
			"%s 伤害了%s%s路闸。" % [
				unit.get("display_name", ""),
				_display_lane(lane_id),
				_display_side(target_side),
			],
			{"lane_name": LANE_NAMES[lane_id], "target_side": target_side}
		)
	lanes[lane_id] = lane_data
	unit["attack_cooldown"] = float(unit.get("attack_interval", 1.0))
	units[index] = unit


func _attack_guardian(index: int, target_side: String, delta: float) -> void:
	var unit: Dictionary = units[index]
	unit["state"] = "attacking guardian"
	unit["attack_cooldown"] = float(unit.get("attack_cooldown", 0.0)) - delta
	if float(unit["attack_cooldown"]) > 0.0:
		units[index] = unit
		return

	var damage := int(unit.get("attack_damage", 0))
	if target_side == PLAYER_SIDE:
		player_guardian_hp = max(0, player_guardian_hp - damage)
		if player_guardian_hp == 0:
			battle_state = "player_loss"
	else:
		enemy_guardian_hp = max(0, enemy_guardian_hp - damage)
		if enemy_guardian_hp == 0:
			battle_state = "player_win"

	_record_event(
		"guardian damaged",
		"%s 攻击了%s守护者。" % [unit.get("display_name", ""), _display_side(target_side)],
		{"target_side": target_side, "battle_state": battle_state}
	)
	unit["attack_cooldown"] = float(unit.get("attack_interval", 1.0))
	units[index] = unit


func _march_unit(index: int, delta: float) -> void:
	var unit: Dictionary = units[index]
	unit["state"] = "marching"
	var side: String = unit.get("side", "")
	var lane_id: StringName = unit.get("lane_id", &"")
	var lane_data: Dictionary = lanes[lane_id]
	var move_delta := float(unit.get("move_speed", 0.0)) * delta
	var path_pos := float(unit.get("path_pos", 0.0))

	if side == PLAYER_SIDE:
		var max_pos := ENEMY_SPAWN_POS if bool(lane_data.get("enemy_gate_broken", false)) else ENEMY_GATE_POS
		unit["path_pos"] = min(float(max_pos), path_pos + move_delta)
	else:
		var min_pos := PLAYER_SPAWN_POS if bool(lane_data.get("player_gate_broken", false)) else PLAYER_GATE_POS
		unit["path_pos"] = max(float(min_pos), path_pos - move_delta)

	units[index] = unit


func _damage_unit(target_index: int, amount: int, source_id: String) -> void:
	if target_index < 0 or target_index >= units.size():
		return
	var target: Dictionary = units[target_index]
	if int(target.get("hp", 0)) <= 0:
		return
	target["hp"] = max(0, int(target.get("hp", 0)) - max(0, amount))
	if int(target["hp"]) == 0:
		target["state"] = "dead"
		_record_event(
			"unit died",
			"%s 在%s阵亡。" % [
				target.get("display_name", ""),
				_display_lane(target.get("lane_name", "")),
			],
			{
				"unit_id": target.get("unit_id", ""),
				"source_id": source_id,
			}
		)
	units[target_index] = target


func _remove_dead_units() -> void:
	for index in range(units.size() - 1, -1, -1):
		var unit: Dictionary = units[index]
		if int(unit.get("hp", 0)) <= 0:
			units.remove_at(index)


func _update_lane_states_and_danger() -> void:
	for lane_id in LANE_IDS:
		var lane_data: Dictionary = lanes[lane_id]
		var state := _derive_lane_state(lane_id, lane_data)
		var danger_tier := _derive_lane_danger_tier(lane_id, lane_data)
		lane_data["state"] = state
		lane_data["danger_tier"] = danger_tier
		lanes[lane_id] = lane_data
		if state != "idle":
			_seen_lane_states[state] = true


func _derive_lane_state(lane_id: StringName, lane_data: Dictionary) -> String:
	if _has_enemy_in_player_base(lane_id) or _has_player_in_enemy_base(lane_id):
		return "invading"
	if bool(lane_data.get("player_gate_broken", false)) or bool(lane_data.get("enemy_gate_broken", false)):
		return "gate broken"
	if _has_enemy_near_player_gate(lane_id):
		return "leaking"
	if _has_fighting_units(lane_id):
		return "stalled"
	if not get_units_for_lane(LANE_NAMES[lane_id], PLAYER_SIDE).is_empty():
		return "pushing"
	return "idle"


func _derive_lane_danger_tier(lane_id: StringName, lane_data: Dictionary) -> int:
	var tier := int(lane_data.get("public_warning_tier", 0))
	if bool(lane_data.get("player_gate_broken", false)) or _has_enemy_in_player_base(lane_id):
		return 3
	if _has_enemy_at_or_past_player_gate(lane_id):
		return 3
	if _has_enemy_near_player_gate(lane_id):
		tier = max(tier, 2)
	elif not get_units_for_lane(LANE_NAMES[lane_id], ENEMY_SIDE).is_empty():
		tier = max(tier, 1)
	return clamp(tier, 0, 3)


func _has_fighting_units(lane_id: StringName) -> bool:
	var has_player_fighter := false
	var has_enemy_fighter := false
	for unit in units:
		if unit.get("lane_id", &"") != lane_id:
			continue
		if str(unit.get("state", "")) != "unit attacking":
			continue
		if unit.get("side", "") == PLAYER_SIDE:
			has_player_fighter = true
		else:
			has_enemy_fighter = true
	return has_player_fighter and has_enemy_fighter


func _has_enemy_near_player_gate(lane_id: StringName) -> bool:
	for unit in units:
		if unit.get("lane_id", &"") == lane_id and unit.get("side", "") == ENEMY_SIDE:
			if float(unit.get("path_pos", 100.0)) <= 20.0:
				return true
	return false


func _has_enemy_at_or_past_player_gate(lane_id: StringName) -> bool:
	for unit in units:
		if unit.get("lane_id", &"") == lane_id and unit.get("side", "") == ENEMY_SIDE:
			if float(unit.get("path_pos", 100.0)) <= PLAYER_GATE_POS:
				return true
	return false


func _has_enemy_in_player_base(lane_id: StringName) -> bool:
	for unit in units:
		if unit.get("lane_id", &"") == lane_id and unit.get("side", "") == ENEMY_SIDE:
			if float(unit.get("path_pos", 100.0)) < PLAYER_GATE_POS:
				return true
	return false


func _has_player_in_enemy_base(lane_id: StringName) -> bool:
	for unit in units:
		if unit.get("lane_id", &"") == lane_id and unit.get("side", "") == PLAYER_SIDE:
			if float(unit.get("path_pos", 0.0)) > ENEMY_GATE_POS:
				return true
	return false


func _record_event(state: String, description: String, data: Dictionary) -> Dictionary:
	var event := {
		"time": battle_time_seconds,
		"state": state,
		"description": description,
		"data": data.duplicate(true),
	}
	event_log.append(event)
	if event_log.size() > EVENT_LOG_LIMIT:
		event_log.pop_front()
	return event


func _normalize_lane_id(lane) -> StringName:
	var text := str(lane).strip_edges().to_lower()
	match text:
		"left", "lane_left", "left lane", "左路", "左":
			return &"left"
		"mid", "middle", "lane_mid", "mid lane", "中路", "中":
			return &"mid"
		"right", "lane_right", "right lane", "右路", "右":
			return &"right"
	return &""


func _display_lane(lane) -> String:
	var lane_id := _normalize_lane_id(lane)
	match lane_id:
		&"left":
			return "左路"
		&"mid":
			return "中路"
		&"right":
			return "右路"
	return str(lane)


func _display_side(side: String) -> String:
	match side:
		PLAYER_SIDE:
			return "玩家侧"
		ENEMY_SIDE:
			return "敌方侧"
	return side


func _display_battle_state(state: String) -> String:
	match state:
		"running":
			return "进行中"
		"player_win":
			return "玩家胜利"
		"player_loss":
			return "玩家失败"
	return state
