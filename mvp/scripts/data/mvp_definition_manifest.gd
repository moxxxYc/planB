class_name MvpDefinitionManifest
extends RefCounted

const REQUIRED_SCENES := [
	"res://scenes/run/mvp_shell.tscn",
	"res://scenes/run/mvp_session_debug.tscn",
	"res://scenes/ball_machine/machine_causality_debug.tscn",
	"res://scenes/battlefield/battlefield_deploy_debug.tscn",
]

const REQUIRED_SCRIPTS := [
	"res://scripts/run/mvp_shell.gd",
	"res://scripts/run/mvp_session_model.gd",
	"res://scripts/run/mvp_session_debug.gd",
	"res://scripts/ball_machine/machine_causality_model.gd",
	"res://scripts/ball_machine/machine_causality_view.gd",
	"res://scripts/ball_machine/machine_causality_debug.gd",
	"res://scripts/battlefield/battlefield_deploy_model.gd",
	"res://scripts/battlefield/battlefield_deploy_view.gd",
	"res://scripts/battlefield/battlefield_deploy_debug.gd",
	"res://scripts/data/machine_component_definition.gd",
	"res://scripts/data/battle_lane_definition.gd",
	"res://scripts/data/unit_template_definition.gd",
	"res://scripts/data/enemy_unit_template_definition.gd",
	"res://scripts/data/guardian_definition.gd",
	"res://scripts/data/modifier_definition.gd",
	"res://scripts/data/counter_definition.gd",
	"res://scripts/data/result_field_definition.gd",
]

const REQUIRED_RESOURCE_PATHS := [
	"res://resources/machine/launch_forge.tres",
	"res://resources/machine/launch_pool.tres",
	"res://resources/machine/launch_launcher.tres",
	"res://resources/machine/tuning_gate.tres",
	"res://resources/machine/tuning_prime.tres",
	"res://resources/machine/tuning_echo.tres",
	"res://resources/machine/tuning_surge.tres",
	"res://resources/machine/unit_exposure_gate.tres",
	"res://resources/machine/unit_queue.tres",
	"res://resources/battlefield/lane_left.tres",
	"res://resources/battlefield/lane_mid.tres",
	"res://resources/battlefield/lane_right.tres",
	"res://resources/units/hive_short_fang.tres",
	"res://resources/units/hive_shield_shell.tres",
	"res://resources/units/hive_acid_sac.tres",
	"res://resources/units/hive_crush_shell_beast.tres",
	"res://resources/guardians/hive_vein_mother.tres",
	"res://resources/guardians/hive_acid_crown_mother.tres",
	"res://resources/economy/pool_pocket.tres",
	"res://resources/economy/front_recycle.tres",
	"res://resources/economy/junk_sieve.tres",
	"res://resources/economy/prime_charge.tres",
	"res://resources/economy/echo_latch.tres",
	"res://resources/economy/surge_buffer.tres",
	"res://resources/economy/queue_brace.tres",
	"res://resources/economy/muster_pair.tres",
	"res://resources/economy/slot_primer.tres",
	"res://resources/enemies/pool_polluter.tres",
	"res://resources/enemies/echo_breaker.tres",
	"res://resources/enemies/stagger_punisher.tres",
	"res://resources/enemies/enemy_grunt.tres",
	"res://resources/enemies/enemy_raider.tres",
	"res://resources/enemies/enemy_brute.tres",
	"res://resources/run/result_main_axis.tres",
	"res://resources/run/result_rewards.tres",
	"res://resources/run/result_shop.tres",
	"res://resources/run/result_guardian.tres",
	"res://resources/run/result_unit_contribution.tres",
	"res://resources/run/result_counter.tres",
	"res://resources/run/result_deploy_lane.tres",
	"res://resources/run/result_endpoint.tres",
	"res://resources/run/result_next_watch_tag.tres",
]

const REQUIRED_TERMS := [
	"Launch",
	"Tuning",
	"Unit",
	"Gate",
	"Prime",
	"Echo",
	"Surge",
	"Deploy Lane",
	"Left",
	"Mid",
	"Right",
	"短牙虫",
	"盾壳虫",
	"酸囊虫",
	"碾壳兽",
	"Enemy Grunt",
	"Enemy Raider",
	"Enemy Brute",
]

const SOURCE_DOCS := [
	"AGENTS.md",
	"README.md",
	"mvp/AGENTS.md",
	"mvp/docs/agent/README.md",
	"docs/gstack-artifacts/yang-mvp-handoff-20260608-164833.md",
	"docs/gdd.md",
	"docs/mvp-scope.md",
	"docs/machine-warehouses.md",
	"docs/battlefield-rules.md",
	"docs/enemy-rules.md",
	"docs/deploy-lane-ui.md",
	"docs/guardian-system.md",
	"docs/neutral-modifiers.md",
	"docs/mvp-learning-checkpoints.md",
	"docs/ball-machine-physical.md",
	"docs/DESIGN.md",
]

const SESSION_STEPS := [
	{
		"id": "boot",
		"label": "MVP 入口",
		"summary": "工程已打开，尚未开始本局状态。",
	},
	{
		"id": "guardian_choice",
		"label": "守护者选择",
		"summary": "在第一场战斗前选择巢脉母或酸冠母，选择后整局固定。",
	},
	{
		"id": "battle_1",
		"label": "第一场战斗",
		"summary": "M1 队列条目通过 M2 三路战场部署，并记录第一段机器因果样本。",
	},
	{
		"id": "first_reward",
		"label": "第一次奖励",
		"summary": "池袋、预充强化、槽位底火分别锚定发射仓、调校仓、单位仓。",
	},
	{
		"id": "shop_gold_rest",
		"label": "商店 / 金币 / 休整",
		"summary": "已实现第一版调试金币来源、一个中立修正购买上限和休整记录。",
	},
	{
		"id": "counter",
		"label": "反制战斗",
		"summary": "池污染者、复写破坏者、断档惩罚者都有预警、目标、效果和日志记录。",
	},
	{
		"id": "endpoint",
		"label": "终点战",
		"summary": "终点守护者使用预告横扫，并记录胜负结论。",
	},
	{
		"id": "result_page",
		"label": "结算页",
		"summary": "结算页字段来自 M3 本局真实数据和检查点记录。",
	},
]


static func count_required_resources_with_prefix(prefix: String) -> int:
	var count := 0
	for path in REQUIRED_RESOURCE_PATHS:
		if str(path).begins_with(prefix):
			count += 1
	return count


static func required_paths() -> Array:
	var paths: Array = []
	paths.append_array(REQUIRED_SCENES)
	paths.append_array(REQUIRED_SCRIPTS)
	paths.append_array(REQUIRED_RESOURCE_PATHS)
	return paths
