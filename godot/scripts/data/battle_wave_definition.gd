class_name BattleWaveDefinition
extends Resource

var battle_number: int = 1
var is_endpoint: bool = false
var enemy_spawns: Array[Dictionary] = []
var counter_intensity: int = 0
var sweep_enabled: bool = false
var enemy_guardian_hp: int = 120
var pressure_limit_seconds: float = 34.0

static func make_for_battle(p_battle_number: int) -> BattleWaveDefinition:
	var definition := BattleWaveDefinition.new()
	definition.battle_number = p_battle_number
	definition.is_endpoint = p_battle_number >= 6
	definition.sweep_enabled = definition.is_endpoint
	definition.enemy_guardian_hp = 180 if definition.is_endpoint else 120
	definition.counter_intensity = 2 if p_battle_number == 5 else (1 if p_battle_number == 3 or definition.is_endpoint else 0)
	definition.pressure_limit_seconds = 48.0 if definition.is_endpoint else (42.0 if p_battle_number >= 5 else 34.0)
	definition.enemy_spawns = _spawns_for_battle(p_battle_number)
	return definition

static func _spawns_for_battle(p_battle_number: int) -> Array[Dictionary]:
	match p_battle_number:
		1:
			return [
				{"time": 4.0, "lane": "Left", "unit_id": "enemy_grunt", "count": 1},
				{"time": 14.0, "lane": "Left", "unit_id": "enemy_grunt", "count": 1},
			]
		2:
			return [
				{"time": 3.0, "lane": "Left", "unit_id": "enemy_grunt", "count": 1},
				{"time": 10.0, "lane": "Mid", "unit_id": "enemy_grunt", "count": 1},
			]
		3:
			return [
				{"time": 3.0, "lane": "Left", "unit_id": "enemy_grunt", "count": 1},
				{"time": 11.0, "lane": "Left", "unit_id": "enemy_grunt", "count": 1},
				{"time": 18.0, "lane": "Mid", "unit_id": "enemy_grunt", "count": 1},
			]
		4:
			return [
				{"time": 3.0, "lane": "Left", "unit_id": "enemy_grunt", "count": 1},
				{"time": 8.0, "lane": "Mid", "unit_id": "enemy_grunt", "count": 1},
				{"time": 16.0, "lane": "Right", "unit_id": "enemy_raider", "count": 1},
			]
		5:
			return [
				{"time": 2.0, "lane": "Left", "unit_id": "enemy_raider", "count": 1},
				{"time": 7.0, "lane": "Mid", "unit_id": "enemy_brute", "count": 1},
				{"time": 16.0, "lane": "Right", "unit_id": "enemy_raider", "count": 1},
				{"time": 24.0, "lane": "Left", "unit_id": "enemy_brute", "count": 1},
			]
		_:
			return [
				{"time": 2.0, "lane": "Left", "unit_id": "enemy_brute", "count": 1},
				{"time": 9.0, "lane": "Mid", "unit_id": "enemy_raider", "count": 2},
				{"time": 18.0, "lane": "Right", "unit_id": "enemy_brute", "count": 1},
				{"time": 32.0, "lane": "Left", "unit_id": "enemy_raider", "count": 2},
			]
