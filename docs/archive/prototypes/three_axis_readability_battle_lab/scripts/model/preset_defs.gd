extends RefCounted

const AxisIds = preload("res://scripts/model/axis_ids.gd")

const LAUNCH_FLOOD := "launch_flood"
const TUNING_ECHO := "tuning_echo"
const UNIT_QUEUE_BURST := "unit_queue_burst"

const POOL_POLLUTER := "pool_polluter"
const ECHO_BREAKER := "echo_breaker"
const STAGGER_PUNISHER := "stagger_punisher"

const SUSTAINED_FLOW := "sustained_flow"
const REPEATED_HEAVY_HIT := "repeated_heavy_hit"
const BATCH_CHARGE_RELEASE := "batch_charge_release"

const BATTLE_DURATION_SECONDS := 75.0

const PRESETS := {
	LAUNCH_FLOOD: {
		"id": LAUNCH_FLOOD,
		"label": "Launch Flood",
		"primary_axis_id": AxisIds.LAUNCH,
		"counter_id": POOL_POLLUTER,
		"frontline_signature": SUSTAINED_FLOW,
		"overdrive_label": "Launch Overdrive",
		"battle_duration_seconds": BATTLE_DURATION_SECONDS,
	},
	TUNING_ECHO: {
		"id": TUNING_ECHO,
		"label": "Tuning Echo",
		"primary_axis_id": AxisIds.TUNING,
		"counter_id": ECHO_BREAKER,
		"frontline_signature": REPEATED_HEAVY_HIT,
		"overdrive_label": "Tuning Overdrive",
		"battle_duration_seconds": BATTLE_DURATION_SECONDS,
	},
	UNIT_QUEUE_BURST: {
		"id": UNIT_QUEUE_BURST,
		"label": "Unit Queue Burst",
		"primary_axis_id": AxisIds.UNIT,
		"counter_id": STAGGER_PUNISHER,
		"frontline_signature": BATCH_CHARGE_RELEASE,
		"overdrive_label": "Unit Overdrive",
		"battle_duration_seconds": BATTLE_DURATION_SECONDS,
	},
}

static func all_preset_ids() -> Array[String]:
	return [LAUNCH_FLOOD, TUNING_ECHO, UNIT_QUEUE_BURST]

static func get_preset(preset_id: String) -> Dictionary:
	if not PRESETS.has(preset_id):
		return {}
	return PRESETS[preset_id].duplicate(true)

