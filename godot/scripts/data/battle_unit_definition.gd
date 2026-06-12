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
var attack_profile: String = "single_melee"
var projectile_speed: float = 0.0
var splash_radius: float = 0.0
var max_splash_targets: int = 0
var sweep_radius: float = 0.0
var max_sweep_targets: int = 0
var can_hit_cross_lane: bool = false
var acid_dot_enabled: bool = false
var acid_pool_enabled: bool = false
var has_taunt: bool = false
var has_aura: bool = false
var has_hidden_behavior: bool = false

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
	p_result_tag: String,
	p_attack_profile: String = "single_melee",
	p_projectile_speed: float = 0.0,
	p_splash_radius: float = 0.0,
	p_max_splash_targets: int = 0,
	p_sweep_radius: float = 0.0,
	p_max_sweep_targets: int = 0
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
	definition.attack_profile = p_attack_profile
	definition.projectile_speed = p_projectile_speed
	definition.splash_radius = p_splash_radius
	definition.max_splash_targets = p_max_splash_targets
	definition.sweep_radius = p_sweep_radius
	definition.max_sweep_targets = p_max_sweep_targets
	return definition

static func catalog() -> Dictionary:
	return {
		"hive_short_fang": BattleUnitDefinition.make("hive_short_fang", "短牙虫", SIDE_PLAYER, 6, 1, 0.7, 1.5, 10.0, "稳线", "Launch sustained flow"),
		"hive_shield_shell": BattleUnitDefinition.make("hive_shield_shell", "盾壳虫", SIDE_PLAYER, 18, 2, 1.4, 1.5, 6.0, "锚点", "Unit anchor slot"),
		"hive_acid_sac": BattleUnitDefinition.make("hive_acid_sac", "酸囊虫", SIDE_PLAYER, 8, 3, 1.8, 7.0, 7.0, "高价值命中", "Tuning high-value hit", "acid_projectile", 14.0, 2.5, 2),
		"hive_crush_shell_beast": BattleUnitDefinition.make("hive_crush_shell_beast", "碾壳兽", SIDE_PLAYER, 26, 6, 2.6, 2.0, 5.0, "翻线", "Unit batch release", "lane_sweep", 0.0, 0.0, 0, 3.5, 3),
		"enemy_grunt": BattleUnitDefinition.make("enemy_grunt", "敌方步虫", SIDE_ENEMY, 10, 2, 1.0, 3.0, 7.0, "基础推进", "enemy grunt"),
		"enemy_raider": BattleUnitDefinition.make("enemy_raider", "敌方突袭虫", SIDE_ENEMY, 7, 1, 0.7, 2.5, 10.0, "突袭", "lane leak watch"),
		"enemy_brute": BattleUnitDefinition.make("enemy_brute", "敌方重壳虫", SIDE_ENEMY, 24, 4, 1.4, 3.0, 5.0, "重压", "Guardian HP pressure"),
	}
