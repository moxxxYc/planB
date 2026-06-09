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
	1: "单位槽 1 / 短牙虫",
	2: "单位槽 2 / 盾壳虫",
	3: "单位槽 3 / 酸囊虫",
	4: "单位槽 4 / 碾壳兽",
}

const BOARD_NAMES := [
	"Launch",
	"Tuning",
	"Unit",
]

const POOL_CAPACITY := 5
const BASE_DEPLOY_DELAY_SECONDS := 0.5
const AUTO_LAUNCH_INTERVAL_SECONDS := 1.2
const AUTO_PHASE_SECONDS := 0.65
const MOTION_TRAIL_LIMIT := 28

const AUTO_TUNING_SEQUENCE := [
	"Gate",
	"Prime",
	"Gate",
	"Echo",
	"Surge",
]

const AUTO_SLOT_SEQUENCE := [
	1,
	1,
	1,
	2,
	1,
]

var battle_time_seconds: float = 0.0
var selected_tuning_result: String = "Gate"
var pool_count: int = 3
var active_ball: Dictionary = {}
var unit_progress: Dictionary = {}
var queue_entries: Array[Dictionary] = []
var event_log: Array[Dictionary] = []
var auto_running := false
var cannon_phase: float = 0.0
var motion_trail: Array[Vector2] = []

var _chain_index := 0
var _auto_sequence_index := 0
var _launch_timer_seconds: float = 0.0
var _flight: Dictionary = {}


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
	auto_running = false
	cannon_phase = 0.0
	motion_trail.clear()
	_chain_index = 0
	_auto_sequence_index = 0
	_launch_timer_seconds = 0.0
	_flight = {
		"in_flight": false,
		"phase": "Idle",
		"phase_elapsed": 0.0,
		"chain_id": "",
		"tuning_result": "Gate",
		"slot_id": 1,
	}


func set_battle_time(seconds: float) -> void:
	battle_time_seconds = max(0.0, seconds)


func set_auto_running(enabled: bool) -> void:
	auto_running = enabled
	if enabled and not bool(_flight.get("in_flight", false)):
		_launch_timer_seconds = min(_launch_timer_seconds, 0.05)


func step_simulation(delta: float) -> void:
	var step: float = clamp(delta, 0.0, 0.2)
	if step <= 0.0:
		return

	battle_time_seconds += step
	cannon_phase = fmod(cannon_phase + step * 1.35, TAU)

	if auto_running:
		_launch_timer_seconds = max(0.0, _launch_timer_seconds - step)
		if _launch_timer_seconds <= 0.0 and not bool(_flight.get("in_flight", false)):
			_start_dynamic_chain()

	if bool(_flight.get("in_flight", false)):
		_advance_dynamic_chain(step)

	_record_motion_sample(_motion_position())


func get_motion_summary() -> Dictionary:
	return {
		"auto_running": auto_running,
		"in_flight": bool(_flight.get("in_flight", false)),
		"active_board": _active_motion_board(),
		"phase": str(_flight.get("phase", "Idle")),
		"phase_progress": _phase_progress(),
		"ball_position": _motion_position(),
		"trail": motion_trail.duplicate(),
		"cannon_angle": sin(cannon_phase) * 0.38,
		"chain_id": str(_flight.get("chain_id", "")),
		"tuning_result": str(_flight.get("tuning_result", selected_tuning_result)),
		"slot_id": int(_flight.get("slot_id", 1)),
	}


func force_tuning_result(tuning_result: String) -> bool:
	if not TUNING_RESULTS.has(tuning_result):
		return false

	_stop_dynamic_chain()
	selected_tuning_result = tuning_result
	var chain_id := _new_chain_id()
	var event := _record_event(
		"Tuning",
		"Natural Hit",
		"调试指定调校结果：%s" % _display_tuning(tuning_result),
		{"tuning_result": tuning_result},
		chain_id
	)
	active_ball = _make_active_ball("Tuning", tuning_result, event["state"], chain_id)
	return true


func force_unit_slot_hit(slot_id: int, tuning_result: String = "") -> Dictionary:
	if not _is_valid_slot(slot_id):
		return {}

	_stop_dynamic_chain()
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

	_stop_dynamic_chain()
	battle_time_seconds = max(battle_time_seconds, float(UNIT_FULL_EXPOSURE_SECONDS[slot_id]))
	var required: int = UNIT_REQUIREMENTS[slot_id]
	var hit_value := _progress_for_tuning(tuning_result)
	unit_progress[slot_id] = max(0, required - hit_value)
	var result := run_forced_chain(tuning_result, slot_id)
	return result.get("queue_entry", {})


func force_blocked_bounce(slot_id: int) -> Dictionary:
	if not _is_valid_slot(slot_id):
		return {}

	_stop_dynamic_chain()
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
		"调校闸门把球送入单位板。",
		{"tuning_result": "Gate"},
		chain_id
	)
	var event := _record_event(
		"Unit",
		"Blocked Bounce",
		"单位槽 %d 的暴露闸门在 %.1f 秒挡住了本次命中。" % [
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

	_stop_dynamic_chain()
	var chain_id := _new_chain_id()
	var component := "Launch"
	var description := ""
	var data := {}

	match state:
		"Split Return":
			pool_count = min(POOL_CAPACITY, pool_count + 2)
			description = "发射仓分裂回流向球池返回了两颗干净球。"
			data = {"pool_count": pool_count}
		"Recycle Return":
			pool_count = min(POOL_CAPACITY, pool_count + 1)
			description = "发射仓回收在落空后向球池返回了一颗干净球。"
			data = {"pool_count": pool_count}
		"Waste":
			description = "发射仓废弃口吞掉了当前球，没有产生有效结算。"
			data = {"pool_count": pool_count}
		"Logic Settlement":
			component = "Tuning"
			description = "预充 / 复写 / 脉冲的结算会在物理球落定后显示。"
			data = {"tuning_result": selected_tuning_result}
		_:
			description = "调试指定物理状态：%s。" % _display_state(state)

	var event := _record_event(component, state, description, data, chain_id)
	active_ball = _make_active_ball(component, state, state, chain_id)
	return event


func run_forced_chain(tuning_result: String, slot_id: int) -> Dictionary:
	if not TUNING_RESULTS.has(tuning_result) or not _is_valid_slot(slot_id):
		return {}

	_stop_dynamic_chain()
	var chain_id := _new_chain_id()
	_record_chain_intro(chain_id)
	selected_tuning_result = tuning_result

	_record_event(
		"Launch",
		"Natural Hit",
		"发射路线板把当前球送入调校路径。",
		{"launch_result": "Tuning Path"},
		chain_id
	)
	_record_event(
		"Tuning",
		"Natural Hit",
		"调校%s槽在进入单位板前标记了这颗球。" % _display_tuning(tuning_result),
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
			"单位槽 %d 在 %.1f 秒尚未完全暴露。" % [
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
		"motion": get_motion_summary(),
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


func _start_dynamic_chain() -> void:
	var tuning_result: String = AUTO_TUNING_SEQUENCE[
		_auto_sequence_index % AUTO_TUNING_SEQUENCE.size()
	]
	var slot_id: int = AUTO_SLOT_SEQUENCE[_auto_sequence_index % AUTO_SLOT_SEQUENCE.size()]
	_auto_sequence_index += 1

	var chain_id := _new_chain_id()
	selected_tuning_result = tuning_result
	_record_chain_intro(chain_id)
	_flight = {
		"in_flight": true,
		"phase": "Launch",
		"phase_elapsed": 0.0,
		"chain_id": chain_id,
		"tuning_result": tuning_result,
		"slot_id": slot_id,
	}
	active_ball = _make_active_ball("Launch", "Tuning Path", "Natural Hit", chain_id)
	motion_trail.clear()
	_record_motion_sample(_motion_position())


func _advance_dynamic_chain(delta: float) -> void:
	_flight["phase_elapsed"] = float(_flight.get("phase_elapsed", 0.0)) + delta
	if float(_flight["phase_elapsed"]) < AUTO_PHASE_SECONDS:
		return

	var overflow: float = float(_flight["phase_elapsed"]) - AUTO_PHASE_SECONDS
	_flight["phase_elapsed"] = 0.0

	match str(_flight.get("phase", "Launch")):
		"Launch":
			_finish_dynamic_launch_phase()
		"Tuning":
			_finish_dynamic_tuning_phase()
		"Unit":
			_finish_dynamic_unit_phase()
		_:
			_stop_dynamic_chain()

	if overflow > 0.0 and bool(_flight.get("in_flight", false)):
		_advance_dynamic_chain(overflow)


func _finish_dynamic_launch_phase() -> void:
	var chain_id := str(_flight.get("chain_id", ""))
	_record_event(
		"Launch",
		"Natural Hit",
		"发射仓动态球路自然落入调校入口。",
		{"launch_result": "Tuning Path"},
		chain_id
	)
	_flight["phase"] = "Tuning"
	active_ball = _make_active_ball(
		"Tuning",
		str(_flight.get("tuning_result", "Gate")),
		"Natural Hit",
		chain_id
	)


func _finish_dynamic_tuning_phase() -> void:
	var tuning_result := str(_flight.get("tuning_result", "Gate"))
	var chain_id := str(_flight.get("chain_id", ""))
	selected_tuning_result = tuning_result
	_record_event(
		"Tuning",
		"Natural Hit",
		"调校%s槽在动态球路中标记了这颗球。" % _display_tuning(tuning_result),
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
	_flight["phase"] = "Unit"
	active_ball = _make_active_ball(
		"Unit",
		"Slot %d" % int(_flight.get("slot_id", 1)),
		"Natural Hit",
		chain_id
	)


func _finish_dynamic_unit_phase() -> void:
	var slot_id := int(_flight.get("slot_id", 1))
	var tuning_result := str(_flight.get("tuning_result", "Gate"))
	var chain_id := str(_flight.get("chain_id", ""))

	if not is_slot_accepting_hit(slot_id):
		var blocked := _record_event(
			"Unit",
			"Blocked Bounce",
			"单位槽 %d 的动态球在 %.1f 秒被暴露闸门弹开。" % [
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
	else:
		_apply_unit_hit(slot_id, tuning_result, chain_id)

	_flight["in_flight"] = false
	_flight["phase"] = "Idle"
	_flight["phase_elapsed"] = 0.0
	_launch_timer_seconds = AUTO_LAUNCH_INTERVAL_SECONDS


func _stop_dynamic_chain() -> void:
	_flight["in_flight"] = false
	_flight["phase"] = "Idle"
	_flight["phase_elapsed"] = 0.0


func _phase_progress() -> float:
	if not bool(_flight.get("in_flight", false)):
		return 0.0
	return clamp(float(_flight.get("phase_elapsed", 0.0)) / AUTO_PHASE_SECONDS, 0.0, 1.0)


func _active_motion_board() -> String:
	if bool(_flight.get("in_flight", false)):
		return str(_flight.get("phase", "Launch"))
	return str(active_ball.get("board", "Launch"))


func _motion_position() -> Vector2:
	if not bool(_flight.get("in_flight", false)):
		return _resting_ball_position()

	var progress := _phase_progress()
	match str(_flight.get("phase", "Launch")):
		"Launch":
			return _polyline_position([
				Vector2(92, 132),
				Vector2(150, 176),
				Vector2(226, 146),
				Vector2(316, 194),
				Vector2(438, 212),
			], progress)
		"Tuning":
			var tuning_index: int = max(
				0,
				int(TUNING_RESULTS.find(str(_flight.get("tuning_result", "Gate"))))
			)
			var end_x := 108.0 + float(tuning_index) * 172.0
			return _polyline_position([
				Vector2(438, 270),
				Vector2(344, 322),
				Vector2(252, 288),
				Vector2(end_x, 354),
			], progress)
		"Unit":
			var slot_id := int(_flight.get("slot_id", 1))
			var end := Vector2(106 + (slot_id - 1) * 166, 512)
			var final_point := end
			if not is_slot_accepting_hit(slot_id):
				final_point += Vector2(34, -42)
			return _polyline_position([
				Vector2(370, 430),
				Vector2(292, 468),
				Vector2(204 + float(slot_id) * 24.0, 444),
				final_point,
			], progress)

	return _resting_ball_position()


func _polyline_position(points: Array[Vector2], progress: float) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	if points.size() == 1:
		return points[0]

	var clamped_progress: float = clamp(progress, 0.0, 1.0)
	var segment_count: int = points.size() - 1
	var segment_progress: float = clamped_progress * float(segment_count)
	var segment_index: int = min(segment_count - 1, int(floor(segment_progress)))
	var local_progress: float = segment_progress - float(segment_index)
	var from_point: Vector2 = points[segment_index]
	var to_point: Vector2 = points[segment_index + 1]
	return from_point.lerp(to_point, local_progress)


func _resting_ball_position() -> Vector2:
	var board: String = active_ball.get("board", "Launch")
	var target: String = active_ball.get("target", "")
	match board:
		"Forge":
			return Vector2(58, 44)
		"Pool":
			return Vector2(128, 54)
		"Launcher":
			return Vector2(92, 132)
		"Tuning":
			var tuning_index: int = max(0, int(TUNING_RESULTS.find(target)))
			return Vector2(124 + tuning_index * 166, 352)
		"Unit":
			var slot_id: int = _slot_id_from_target(target)
			return Vector2(106 + (slot_id - 1) * 166, 512)
		_:
			return Vector2(576, 208)


func _slot_id_from_target(target: String) -> int:
	for slot_id in [1, 2, 3, 4]:
		if target.contains(str(slot_id)):
			return slot_id
	return 1


func _record_motion_sample(position: Vector2) -> void:
	if motion_trail.is_empty() or motion_trail[motion_trail.size() - 1].distance_to(position) > 1.0:
		motion_trail.append(position)
	while motion_trail.size() > MOTION_TRAIL_LIMIT:
		motion_trail.pop_front()


func _record_chain_intro(chain_id: String) -> void:
	if pool_count <= 0:
		pool_count = 1
		_record_event(
			"Forge",
			"Logic Settlement",
		"造球器因球池为空补入了一颗干净球。",
			{"pool_count": pool_count},
			chain_id
		)
	else:
		_record_event(
			"Forge",
			"Logic Settlement",
		"造球器维持球池供给，等待下一次发射。",
			{"pool_count": pool_count},
			chain_id
		)

	pool_count = max(0, pool_count - 1)
	_record_event(
		"Pool",
		"Natural Hit",
		"球池队首进入发射器。",
		{"pool_count": pool_count},
		chain_id
	)
	_record_event(
		"Launcher",
		"Natural Hit",
		"发射器发射了当前干净球。",
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
		"单位槽 %d 接受来自%s的 +%d 进度。" % [
			slot_id,
			_display_tuning(tuning_result),
			progress_added,
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
			"复写复制了单位进度结算，但没有生成第二颗物理球。",
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
			"队列条目 %s 由单位槽 %d 通过%s生成。" % [
				entry["queue_entry_id"],
				slot_id,
				_display_tuning(tuning_result),
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
			return "预充把这次单位命中的价值从 1 提高到 2。"
		"Echo":
			return "复写复制单位进度结算，不复制物理球。"
		"Surge":
			return "脉冲把生成的队列条目标记为 0.25 秒部署延迟。"
		_:
			return "闸门没有额外逻辑结算。"


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


func _display_tuning(tuning_result: String) -> String:
	match tuning_result:
		"Gate":
			return "闸门"
		"Prime":
			return "预充"
		"Echo":
			return "复写"
		"Surge":
			return "脉冲"
	return tuning_result


func _display_state(state: String) -> String:
	match state:
		"Natural Hit":
			return "自然命中"
		"Blocked Bounce":
			return "阻挡反弹"
		"Valid Unit Hit":
			return "有效单位命中"
		"Split Return":
			return "分裂回流"
		"Recycle Return":
			return "回收回流"
		"Waste":
			return "废弃"
		"Logic Settlement":
			return "逻辑结算"
	return state
