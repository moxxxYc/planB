class_name MvpDefinitionManifest
extends RefCounted

const REQUIRED_SCENES := [
	"res://scenes/run/mvp_shell.tscn",
]

const REQUIRED_SCRIPTS := [
	"res://scripts/run/mvp_shell.gd",
	"res://scripts/data/machine_component_definition.gd",
	"res://scripts/data/battle_lane_definition.gd",
	"res://scripts/data/unit_template_definition.gd",
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
]

const SESSION_STEPS := [
	{
		"id": "boot",
		"label": "MVP Shell Boot",
		"summary": "Project opened. No run state has been started.",
	},
	{
		"id": "guardian_choice",
		"label": "Guardian Choice Placeholder",
		"summary": "Choose between 巢脉母 and 酸冠母 before Battle 1. No UI flow implemented yet.",
	},
	{
		"id": "battle_shell",
		"label": "Battle Shell Placeholder",
		"summary": "Names Launch / Tuning / Unit, current Deploy Lane, and three lanes without combat simulation.",
	},
	{
		"id": "reward_shell",
		"label": "First Reward Placeholder",
		"summary": "Names Pool Pocket, Prime Charge, and Slot Primer as axis anchors.",
	},
	{
		"id": "shop_shell",
		"label": "Shop Placeholder",
		"summary": "Names Gold, one neutral modifier purchase cap, and rest as future session state.",
	},
	{
		"id": "counter_shell",
		"label": "Counter Placeholder",
		"summary": "Names Pool Polluter, Echo Breaker, and Stagger Punisher without applying effects.",
	},
	{
		"id": "endpoint_shell",
		"label": "Endpoint Placeholder",
		"summary": "Names Telegraphed Sweep and endpoint outcome as future battle shell state.",
	},
	{
		"id": "result_shell",
		"label": "Result Page Placeholder",
		"summary": "Names main axis, rewards, shop, Guardian, counters, Deploy Lane impact, and next watch tag.",
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
