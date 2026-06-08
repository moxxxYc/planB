class_name MachineCausalityModel
extends RefCounted

const TUNING_RESULTS := [
	"Gate",
	"Prime",
	"Echo",
	"Surge",
]

const SETTLEMENT_STATES := [
	"Natural Hit",
	"Blocked Bounce",
	"Valid Unit Hit",
	"Split Return",
	"Recycle Return",
	"Waste",
	"Logic Settlement",
]

const UNIT_REQUIREMENTS := {
	1: 3,
	2: 5,
	3: 8,
	4: 12,
}

const UNIT_EXPOSURE_START_SECONDS := {
	1: 0.0,
	2: 12.0,
	3: 36.0,
	4: 72.0,
}

const UNIT_FULL_EXPOSURE_SECONDS := {
	1: 0.0,
	2: 24.0,
	3: 54.0,
	4: 96.0,
}

const UNIT_LABELS := {
	1: "Slot 1 / 短牙虫",
	2: "Slot 2 / 盾壳虫",
	3: "Slot 3 / 酸囊虫",
	4: "Slot 4 / 碾壳兽",
}

const BOARD_NAMES := [
	"Launch",
	"Tuning",
	"Unit",
]

const POOL_CAPACITY := 5
const BASE_DEPLOY_DELAY_SECONDS := 0.5

var battle_time_seconds: float = 0.0
var selected_tuning_result: String = "Gate"
var pool_count: int = 3
var active_ball: Dictionary = {}
var unit_progress: Dictionary = {}
var queue_entries: Array[Dictionary] = []
var event_log: Array[Dictionary] = []

var _chain_index := 0


func _init() -> void:
	reset()


func reset() -> void:
	battle_time_seconds = 0.0
	selected_tuning_result = "Gate"
	pool_count = 3
	active_ball = {
		"board": "Launch",
		"target": "Pool",
		"state": "Ready",
		"chain_id": "",
	}
	unit_progress = {}
	for slot_id in UNIT_REQUIREMENTS.keys():
		unit_progress[slot_id] = 0
	queue_entries.clear()
	event_log.clear()
	_chain_index = 0


func set_battle_time(seconds: float) -> void:
	battle_time_seconds = max(0.0, seconds)


func force_tuning_result(tuning_result: String) -> bool:
	if not TUNING_RESULTS.has(tuning_result):
		return false

	selected_tuning_result = tuning_result
	var chain_id := _new_chain_id()
	var event := _record_event(
		"Tuning",
		"Natural Hit",
		"Debug forced Tuning result: %s" % tuning_result,
		{"tuning_result": tuning_result},
		chain_id
	)
	active_ball = _make_active_ball("Tuning", tuning_result, event["state"], chain_id)
	return true


func force_unit_slot_hit(slot_id: int, tuning_result: String = "") -> Dictionary:
	if not _is_valid_slot(slot_id):
		return {}

	var result := selected_tuning_result if tuning_result.is_empty() else tuning_result
	if not TUNING_RESULTS.has(result):
		return {}

	battle_time_seconds = max(battle_time_seconds, float(UNIT_FULL_EXPOSURE_SECONDS[slot_id]))
	return run_forced_chain(result, slot_id)


func force_unit_slot_queue(slot_id: int, tuning_result: String = "Gate") -> Dictionary:
	if not _is_valid_slot(slot_id):
		return {}
	if not TUNING_RESULTS.has(tuning_result):
		return {}

	battle_time_seconds = max(battle_time_seconds, float(UNIT_FULL_EXPOSURE_SECONDS[slot_id]))
	var required: int = UNIT_REQUIREMENTS[slot_id]
	var hit_value := _progress_for_tuning(tuning_result)
	unit_progress[slot_id] = max(0, required - hit_value)
	var result := run_forced_chain(tuning_result, slot_id)
	return result.get("queue_entry", {})


func force_blocked_bounce(slot_id: int) -> Dictionary:
	if not _is_valid_slot(slot_id):
		return {}

	var full_time: float = UNIT_FULL_EXPOSURE_SECONDS[slot_id]
	if full_time <= 0.0:
		slot_id = 2
		full_time = UNIT_FULL_EXPOSURE_SECONDS[slot_id]

	battle_time_seconds = min(battle_time_seconds, max(0.0, full_time - 1.0))
	var chain_id := _new_chain_id()
	_record_chain_intro(chain_id)
	selected_tuning_result = "Gate"
	_record_event(
		"Tuning",
		"Natural Hit",
		"Tuning Gate passed the ball into the Unit board.",
		{"tuning_result": "Gate"},
		chain_id
	)
	var event := _record_event(
		"Unit",
		"Blocked Bounce",
		"Unit Slot %d exposure gate blocked the forced hit at %.1fs." % [
			slot_id,
			battle_time_seconds,
		],
		{
			"slot_id": slot_id,
			"exposure_ratio": get_slot_exposure_ratio(slot_id),
		},
		chain_id
	)
	active_ball = _make_active_ball("Unit", "Slot %d" % slot_id, event["state"], chain_id)
	return event


func force_settlement_state(state: String) -> Dictionary:
	if not SETTLEMENT_STATES.has(state):
		return {}

	var chain_id := _new_chain_id()
	var component := "Launch"
	var description := ""
	var data := {}

	match state:
		"Split Return":
			pool_count = min(POOL_CAPACITY, pool_count + 2)
			description = "Launch Split returned two clean balls to Pool."
			data = {"pool_count": pool_count}
		"Recycle Return":
			pool_count = min(POOL_CAPACITY, pool_count + 1)
			description = "Launch Recycle returned one clean ball to Pool after a miss."
			data = {"pool_count": pool_count}
		"Waste":
			description = "Launch Waste consumed the active ball without valid settlement."
			data = {"pool_count": pool_count}
		"Logic Settlement":
			component = "Tuning"
			description = "Prime / Echo / Surge settlement is shown after the physical ball lands."
			data = {"tuning_result": selected_tuning_result}
		_:
			description = "Debug forced physical state: %s." % state

	var event := _record_event(component, state, description, data, chain_id)
	active_ball = _make_active_ball(component, state, state, chain_id)
	return event


func run_forced_chain(tuning_result: String, slot_id: int) -> Dictionary:
	if not TUNING_RESULTS.has(tuning_result) or not _is_valid_slot(slot_id):
		return {}

	var chain_id := _new_chain_id()
	_record_chain_intro(chain_id)
	selected_tuning_result = tuning_result

	_record_event(
		"Launch",
		"Natural Hit",
		"Launch Route Board sent the active ball into the Tuning path.",
		{"launch_result": "Tuning Path"},
		chain_id
	)
	_record_event(
		"Tuning",
		"Natural Hit",
		"Tuning %s slot marked the ball before Unit." % tuning_result,
		{"tuning_result": tuning_result},
		chain_id
	)

	if tuning_result != "Gate":
		_record_event(
			"Tuning",
			"Logic Settlement",
			_tuning_logic_description(tuning_result),
			{
				"tuning_result": tuning_result,
				"progress_value": _progress_for_tuning(tuning_result),
			},
			chain_id
		)

	if not is_slot_accepting_hit(slot_id):
		var blocked := _record_event(
			"Unit",
			"Blocked Bounce",
			"Unit Slot %d is not fully exposed at %.1fs." % [
				slot_id,
				battle_time_seconds,
			],
			{
				"slot_id": slot_id,
				"exposure_ratio": get_slot_exposure_ratio(slot_id),
			},
			chain_id
		)
		active_ball = _make_active_ball("Unit", "Slot %d" % slot_id, blocked["state"], chain_id)
		return {
			"event": blocked,
			"queue_entry": {},
		}

	var entry := _apply_unit_hit(slot_id, tuning_result, chain_id)
	return {
		"event": event_log[event_log.size() - 1],
		"queue_entry": entry,
	}


func is_slot_accepting_hit(slot_id: int) -> bool:
	return _is_valid_slot(slot_id) and get_slot_exposure_ratio(slot_id) >= 1.0


func get_slot_exposure_ratio(slot_id: int) -> float:
	if not _is_valid_slot(slot_id):
		return 0.0

	var start_time: float = UNIT_EXPOSURE_START_SECONDS[slot_id]
	var full_time: float = UNIT_FULL_EXPOSURE_SECONDS[slot_id]
	if full_time <= start_time:
		return 1.0
	if battle_time_seconds < start_time:
		return 0.0
	if battle_time_seconds >= full_time:
		return 1.0
	return (battle_time_seconds - start_time) / (full_time - start_time)


func get_unit_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	for slot_id in [1, 2, 3, 4]:
		slots.append({
			"slot_id": slot_id,
			"label": UNIT_LABELS[slot_id],
			"progress_current": unit_progress[slot_id],
			"progress_required": UNIT_REQUIREMENTS[slot_id],
			"exposure_start_seconds": UNIT_EXPOSURE_START_SECONDS[slot_id],
			"full_exposure_seconds": UNIT_FULL_EXPOSURE_SECONDS[slot_id],
			"exposure_ratio": get_slot_exposure_ratio(slot_id),
			"accepting_hit": is_slot_accepting_hit(slot_id),
		})
	return slots


func get_supply_summary() -> Dictionary:
	return {
		"forge": "clean ball cadence placeholder",
		"pool_count": pool_count,
		"pool_capacity": POOL_CAPACITY,
		"launcher": "active",
	}


func get_debug_summary() -> Dictionary:
	return {
		"boards": BOARD_NAMES.duplicate(),
		"tuning_results": TUNING_RESULTS.duplicate(),
		"unit_slots": get_unit_slots(),
		"debug_controls": [
			"force_tuning_result",
			"force_unit_slot_hit",
			"force_blocked_bounce",
			"force_split_return",
			"force_recycle_return",
			"force_waste",
			"force_logic_settlement",
		],
		"queue_entries": queue_entries.duplicate(true),
		"event_log": event_log.duplicate(true),
	}


func _record_chain_intro(chain_id: String) -> void:
	if pool_count <= 0:
		pool_count = 1
		_record_event(
			"Forge",
			"Logic Settlement",
			"Forge supplied one clean ball because Pool was empty.",
			{"pool_count": pool_count},
			chain_id
		)
	else:
		_record_event(
			"Forge",
			"Logic Settlement",
			"Forge keeps Pool supplied for the next launch.",
			{"pool_count": pool_count},
			chain_id
		)

	pool_count = max(0, pool_count - 1)
	_record_event(
		"Pool",
		"Natural Hit",
		"Pool head moved into Launcher.",
		{"pool_count": pool_count},
		chain_id
	)
	_record_event(
		"Launcher",
		"Natural Hit",
		"Launcher fired the active clean ball.",
		{"pool_count": pool_count},
		chain_id
	)
	active_ball = _make_active_ball("Launch", "Tuning Path", "Natural Hit", chain_id)


func _apply_unit_hit(slot_id: int, tuning_result: String, chain_id: String) -> Dictionary:
	var progress_added := _progress_for_tuning(tuning_result)
	var current_progress: int = unit_progress[slot_id]
	var required: int = UNIT_REQUIREMENTS[slot_id]
	unit_progress[slot_id] = current_progress + progress_added

	_record_event(
		"Unit",
		"Valid Unit Hit",
		"Unit Slot %d accepted +%d progress from %s." % [
			slot_id,
			progress_added,
			tuning_result,
		],
		{
			"slot_id": slot_id,
			"progress_added": progress_added,
			"progress_current": unit_progress[slot_id],
			"progress_required": required,
		},
		chain_id
	)

	if tuning_result == "Echo":
		_record_event(
			"Tuning",
			"Logic Settlement",
			"Echo copied Unit progress without spawning a second physical ball.",
			{"slot_id": slot_id},
			chain_id
		)

	var entry: Dictionary = {}
	if unit_progress[slot_id] >= required:
		unit_progress[slot_id] -= required
		entry = _make_queue_entry(slot_id, tuning_result, progress_added, chain_id)
		queue_entries.append(entry)
		_record_event(
			"Queue",
			"Logic Settlement",
			"Queue entry %s generated from Unit Slot %d via %s." % [
				entry["queue_entry_id"],
				slot_id,
				tuning_result,
			],
			entry,
			chain_id
		)

	active_ball = _make_active_ball("Unit", "Slot %d" % slot_id, "Valid Unit Hit", chain_id)
	return entry


func _make_queue_entry(
	slot_id: int,
	tuning_result: String,
	progress_added: int,
	chain_id: String
) -> Dictionary:
	var deploy_delay := BASE_DEPLOY_DELAY_SECONDS
	if tuning_result == "Surge":
		deploy_delay = 0.25

	return {
		"queue_entry_id": "%s-Q%02d" % [chain_id, queue_entries.size() + 1],
		"source_slot_id": slot_id,
		"source_slot_label": UNIT_LABELS[slot_id],
		"tuning_result": tuning_result,
		"progress_added": progress_added,
		"deploy_delay_seconds": deploy_delay,
		"trigger_chain": "%s Launch->Tuning->Unit->Queue" % chain_id,
	}


func _progress_for_tuning(tuning_result: String) -> int:
	match tuning_result:
		"Prime":
			return 2
		"Echo":
			return 2
		_:
			return 1


func _tuning_logic_description(tuning_result: String) -> String:
	match tuning_result:
		"Prime":
			return "Prime raises this Unit hit value from 1 to 2."
		"Echo":
			return "Echo copies the Unit progress settlement, not the physical ball."
		"Surge":
			return "Surge marks a generated queue entry for 0.25s deploy delay."
		_:
			return "Gate has no extra logic settlement."


func _record_event(
	component: String,
	state: String,
	description: String,
	data: Dictionary,
	chain_id: String
) -> Dictionary:
	var event := {
		"chain_id": chain_id,
		"component": component,
		"state": state,
		"description": description,
		"data": data.duplicate(true),
	}
	event_log.append(event)
	if event_log.size() > 32:
		event_log.pop_front()
	return event


func _make_active_ball(board: String, target: String, state: String, chain_id: String) -> Dictionary:
	return {
		"board": board,
		"target": target,
		"state": state,
		"chain_id": chain_id,
	}


func _new_chain_id() -> String:
	_chain_index += 1
	return "M1-%03d" % _chain_index


func _is_valid_slot(slot_id: int) -> bool:
	return UNIT_REQUIREMENTS.has(slot_id)
