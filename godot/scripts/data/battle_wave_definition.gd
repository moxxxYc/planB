class_name BattleWaveDefinition
extends Resource

var battle_number: int = 1
var is_endpoint: bool = false
var enemy_spawns: Array[Dictionary] = []
var counter_intensity: int = 0
var sweep_enabled: bool = false
var enemy_guardian_hp: int = 120
var target_duration_min_seconds: float = 90.0
var target_duration_max_seconds: float = 110.0
var pressure_limit_seconds: float = 90.0

static func make_for_battle(p_battle_number: int) -> BattleWaveDefinition:
	var definition := BattleWaveDefinition.new()
	definition.battle_number = p_battle_number
	definition.is_endpoint = p_battle_number >= 6
	definition.sweep_enabled = definition.is_endpoint
	definition.enemy_guardian_hp = 180 if definition.is_endpoint else 120
	definition.counter_intensity = 2 if p_battle_number == 5 else (1 if p_battle_number == 3 or definition.is_endpoint else 0)
	var duration: Vector2 = _duration_for_battle(p_battle_number)
	definition.target_duration_min_seconds = duration.x
	definition.target_duration_max_seconds = duration.y
	definition.pressure_limit_seconds = definition.target_duration_min_seconds
	definition.enemy_spawns = _spawns_for_battle(p_battle_number)
	return definition

static func _duration_for_battle(p_battle_number: int) -> Vector2:
	match p_battle_number:
		1:
			return Vector2(90.0, 110.0)
		2:
			return Vector2(100.0, 125.0)
		3:
			return Vector2(115.0, 140.0)
		4:
			return Vector2(105.0, 130.0)
		5:
			return Vector2(125.0, 150.0)
		_:
			return Vector2(165.0, 195.0)

static func _spawns_for_battle(p_battle_number: int) -> Array[Dictionary]:
	match p_battle_number:
		1:
			return [
				{"time": 10.0, "lane": "Left", "unit_id": "enemy_grunt", "count": 1},
				{"time": 34.0, "lane": "Left", "unit_id": "enemy_grunt", "count": 1},
				{"time": 68.0, "lane": "Left", "unit_id": "enemy_grunt", "count": 1},
			]
		2:
			return [
				{"time": 9.0, "lane": "Left", "unit_id": "enemy_grunt", "count": 1},
				{"time": 28.0, "lane": "Mid", "unit_id": "enemy_grunt", "count": 1},
				{"time": 62.0, "lane": "Left", "unit_id": "enemy_grunt", "count": 1},
				{"time": 86.0, "lane": "Mid", "unit_id": "enemy_raider", "count": 1},
			]
		3:
			return [
				{"time": 8.0, "lane": "Left", "unit_id": "enemy_grunt", "count": 1},
				{"time": 32.0, "lane": "Left", "unit_id": "enemy_grunt", "count": 1},
				{"time": 54.0, "lane": "Mid", "unit_id": "enemy_raider", "count": 1},
				{"time": 88.0, "lane": "Left", "unit_id": "enemy_brute", "count": 1},
			]
		4:
			return [
				{"time": 9.0, "lane": "Left", "unit_id": "enemy_grunt", "count": 1},
				{"time": 30.0, "lane": "Mid", "unit_id": "enemy_grunt", "count": 1},
				{"time": 66.0, "lane": "Right", "unit_id": "enemy_raider", "count": 1},
				{"time": 92.0, "lane": "Left", "unit_id": "enemy_grunt", "count": 2},
			]
		5:
			return [
				{"time": 8.0, "lane": "Left", "unit_id": "enemy_raider", "count": 1},
				{"time": 35.0, "lane": "Mid", "unit_id": "enemy_brute", "count": 1},
				{"time": 70.0, "lane": "Right", "unit_id": "enemy_raider", "count": 1},
				{"time": 104.0, "lane": "Left", "unit_id": "enemy_brute", "count": 1},
				{"time": 128.0, "lane": "Mid", "unit_id": "enemy_raider", "count": 2},
			]
		_:
			return [
				{"time": 10.0, "lane": "Left", "unit_id": "enemy_brute", "count": 1},
				{"time": 42.0, "lane": "Mid", "unit_id": "enemy_raider", "count": 2},
				{"time": 86.0, "lane": "Right", "unit_id": "enemy_brute", "count": 1},
				{"time": 124.0, "lane": "Left", "unit_id": "enemy_raider", "count": 2},
				{"time": 158.0, "lane": "Mid", "unit_id": "enemy_brute", "count": 1},
			]
