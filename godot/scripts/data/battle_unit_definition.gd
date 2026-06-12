class_name BattleUnitDefinition
extends Resource

const SIDE_PLAYER: String = "player"
const SIDE_ENEMY: String = "enemy"

var id: String = ""
var display_name: String = ""
var side: String = SIDE_PLAYER
var max_hp: int = 10
var attack_damage: int = 2
var attack_interval: float = 1.0
var attack_range: float = 3.0
var move_speed: float = 8.0
var lane_role: String = ""
var result_tag: String = ""

static func make(
	p_id: String,
	p_display_name: String,
	p_side: String,
	p_max_hp: int,
	p_attack_damage: int,
	p_attack_interval: float,
	p_attack_range: float,
	p_move_speed: float,
	p_lane_role: String,
	p_result_tag: String
) -> BattleUnitDefinition:
	var definition := BattleUnitDefinition.new()
	definition.id = p_id
	definition.display_name = p_display_name
	definition.side = p_side
	definition.max_hp = p_max_hp
	definition.attack_damage = p_attack_damage
	definition.attack_interval = p_attack_interval
	definition.attack_range = p_attack_range
	definition.move_speed = p_move_speed
	definition.lane_role = p_lane_role
	definition.result_tag = p_result_tag
	return definition

static func catalog() -> Dictionary:
	return {
		"hive_short_fang": BattleUnitDefinition.make("hive_short_fang", "短牙虫", SIDE_PLAYER, 10, 2, 1.0, 3.0, 10.0, "稳线", "Launch sustained flow"),
		"hive_shield_shell": BattleUnitDefinition.make("hive_shield_shell", "盾壳虫", SIDE_PLAYER, 18, 1, 1.2, 2.5, 7.0, "锚点", "Unit anchor slot"),
		"hive_acid_sac": BattleUnitDefinition.make("hive_acid_sac", "酸囊虫", SIDE_PLAYER, 8, 3, 1.4, 4.0, 8.0, "高价值命中", "Tuning high-value hit"),
		"hive_crush_shell_beast": BattleUnitDefinition.make("hive_crush_shell_beast", "碾壳兽", SIDE_PLAYER, 28, 5, 1.6, 3.5, 5.0, "翻线", "Unit batch release"),
		"enemy_grunt": BattleUnitDefinition.make("enemy_grunt", "敌方步虫", SIDE_ENEMY, 10, 2, 1.0, 3.0, 8.0, "基础推进", "enemy grunt"),
		"enemy_raider": BattleUnitDefinition.make("enemy_raider", "敌方突袭虫", SIDE_ENEMY, 7, 2, 0.8, 2.5, 13.0, "突袭", "lane leak watch"),
		"enemy_brute": BattleUnitDefinition.make("enemy_brute", "敌方重壳虫", SIDE_ENEMY, 24, 4, 1.5, 3.0, 5.0, "重压", "Guardian HP pressure"),
	}
