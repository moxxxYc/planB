class_name MachineSimulator
extends RefCounted

const MachineSlotExposureStateScript := preload("res://scripts/model/machine/machine_slot_exposure_state.gd")

const SLOT_REQUIREMENTS: Dictionary = {
	1: 3,
	2: 5,
	3: 8,
	4: 12,
}
const QUEUE_BRACE_MISS_THRESHOLD: int = 3
const QUEUE_BRACE_COMPENSATION_VALUE: int = 1
const MAX_PENDING_PHYSICS_CHAINS: int = 24
const MAX_PHYSICS_QUEUE_CHAIN_TELEMETRY: int = 12

var forge_progress: float = 0.0
var launcher_progress: float = 0.0
var pool_capacity: int = 5
var prime_value_bonus: int = 1
var surge_buffer_charge: int = 0
var queue_brace_gap_count: int = 0
var pool: Array[Dictionary] = []
var slot_progress: Dictionary = {1: 0, 2: 0, 3: 0, 4: 0}
var slot_progress_floor: Dictionary = {}
var queue: Array[Dictionary] = []
var event_log: Array[String] = []
var front_recycle_enabled: bool = false
var surge_buffer_enabled: bool = false
var queue_brace_enabled: bool = false
var junk_sieve_enabled: bool = false
var muster_pair_enabled: bool = false
var echo_latch_enabled: bool = false
var echo_breaker_active: bool = false
var echo_breaker_charges: int = 0
var pool_polluter_junk_count: int = 0
var counter_log: Array[String] = []
var active_modifier_ids: Array[String] = []
var active_modifier_markers: Array[String] = []
var battle_elapsed: float = 0.0
var exposure_state: RefCounted = MachineSlotExposureStateScript.new()
var guardian_contract: RefCounted = null
var _step_index: int = 0
var _next_chain_index: int = 0
var _pending_physics_chains: Dictionary = {}
var _pending_chain_order: Array[String] = []
var _last_machine_chain_sample: Dictionary = {}
var _physics_queue_chains: Array[Dictionary] = []

func set_exposure_state(p_exposure_state: RefCounted) -> void:
	if not _has_exposure_state_contract(p_exposure_state):
		return
	exposure_state = p_exposure_state

func set_guardian_contract(p_guardian_contract: RefCounted) -> void:
	if p_guardian_contract == null:
		guardian_contract = null
		return
	for method_name: String in [
		"on_launch_recycle",
		"on_tuning_result",
		"consume_machine_event_log",
	]:
		if not p_guardian_contract.has_method(method_name):
			return
	guardian_contract = p_guardian_contract

func get_exposure_state() -> RefCounted:
	return exposure_state

func set_battle_elapsed(seconds: float) -> void:
	battle_elapsed = maxf(0.0, seconds)

func get_battle_elapsed() -> float:
	return battle_elapsed

func get_exposure_gate_snapshot() -> Dictionary:
	if exposure_state == null:
		return {}
	return exposure_state.call("snapshot", battle_elapsed) as Dictionary

func apply_modifier(modifier_id: String, payload: Dictionary = {}) -> void:
	var slot_id: int = int(payload.get("slot_id", 1))
	var active_key: String = _modifier_active_key(modifier_id, slot_id)
	if active_key.is_empty():
		return
	if active_modifier_ids.has(active_key):
		return

	var effect_marker: String = ""
	match modifier_id:
		"pool_pocket":
			pool_capacity = mini(pool_capacity + 1, 6)
			effect_marker = "pool_capacity=%d" % pool_capacity
		"prime_charge":
			prime_value_bonus = 2
			effect_marker = "prime_value_bonus=%d" % prime_value_bonus
		"slot_primer":
			slot_progress_floor[slot_id] = 1
			slot_progress[slot_id] = maxi(int(slot_progress.get(slot_id, 0)), 1)
			effect_marker = "slot_id=%d floor=1" % slot_id
		"front_recycle":
			front_recycle_enabled = true
			effect_marker = "front_recycle_enabled=true front_insert=true"
		"surge_buffer":
			surge_buffer_enabled = true
			effect_marker = "surge_buffer_enabled=true max=1"
		"queue_brace":
			queue_brace_enabled = true
			effect_marker = "queue_brace_enabled=true threshold=%d S1+1" % QUEUE_BRACE_MISS_THRESHOLD
		"junk_sieve":
			junk_sieve_enabled = true
			effect_marker = "junk_sieve_enabled=true"
		"muster_pair":
			muster_pair_enabled = true
			effect_marker = "muster_pair_enabled=true same_slot_pair=true"
		"echo_latch":
			echo_latch_enabled = true
			effect_marker = "echo_latch_enabled=true repeated_hit=true"
		_:
			push_error("Unknown machine modifier: %s" % modifier_id)
			return

	active_modifier_ids.append(active_key)
	active_modifier_markers.append("%s (%s, %s)" % [
		_modifier_display_name(modifier_id),
		_modifier_axis(modifier_id),
		effect_marker,
	])
	event_log.append("Modifier:%s axis=%s key=%s id=%s %s" % [
		_modifier_display_name(modifier_id),
		_modifier_axis(modifier_id),
		active_key,
		modifier_id,
		effect_marker,
	])
	if modifier_id == "junk_sieve" or modifier_id == "muster_pair":
		counter_log.append(event_log[event_log.size() - 1])

func advance_supply(delta: float) -> Array[Dictionary]:
	var launch_requests: Array[Dictionary] = []
	forge_progress += delta
	launcher_progress += delta

	if forge_progress >= 2.2:
		forge_progress -= 2.2
		_add_pool_ball("clean")

	if launcher_progress >= 1.3 and not pool.is_empty():
		launcher_progress -= 1.3
		var ball: Dictionary = pool.pop_front()
		var launch_request: Dictionary = _make_launch_request(ball)
		_begin_machine_chain(launch_request)
		event_log.append("Launch.Launcher fired %s ball to visible physics" % String(launch_request.get("kind", "clean")))
		launch_requests.append(launch_request)

	return launch_requests

# Legacy verifier wrapper. Normal Battle runtime calls advance_supply() and waits
# for MachinePhysicsBoardView body_entered landings instead of resolving patterns.
func advance_step(delta: float) -> Array[Dictionary]:
	var produced_entries: Array[Dictionary] = []
	var launch_requests: Array[Dictionary] = advance_supply(delta)
	for launch_request: Dictionary in launch_requests:
		produced_entries.append_array(apply_verifier_seeded_chain_for_ball(launch_request))
	return produced_entries

func apply_physics_result(result: MachinePhysicsResult) -> Array[Dictionary]:
	if result == null:
		return []
	if result.component == "Unit" and result.result_id == "ExposureBlocked":
		_register_physics_result(result)
		event_log.append("Unit：S%d 暴露闸门挡开，球未产生 Unit 进度" % clampi(result.slot_id, 1, 4))
		_commit_queue_chain_if_needed(result, [])
		return []
	if result.component == "Unit" and exposure_state != null:
		var guarded_slot_id: int = clampi(result.slot_id, 1, 4)
		var guard_elapsed: float = maxf(battle_elapsed, result.battle_elapsed)
		if not bool(exposure_state.call("is_slot_open_for_progress", guarded_slot_id, guard_elapsed)):
			var blocked_result := MachinePhysicsResult.make(
				"Unit",
				"ExposureBlocked",
				guarded_slot_id,
				0,
				result.ball_kind,
				result.source,
				result.chain_id,
				guard_elapsed
			)
			_register_physics_result(blocked_result)
			event_log.append("Unit：S%d 暴露闸门未开启，球被挡开" % guarded_slot_id)
			_commit_queue_chain_if_needed(blocked_result, [])
			return []
	if result.component == "Tuning" and guardian_contract != null:
		result.result_id = String(guardian_contract.call("on_tuning_result", result.result_id))
		_drain_guardian_machine_logs()
	_register_physics_result(result)
	var produced_entries: Array[Dictionary] = []
	match result.component:
		"Launch":
			produced_entries = _apply_launch_physics_result(result)
		"Tuning":
			produced_entries = _apply_tuning_physics_result(result)
		"Unit":
			produced_entries = _apply_unit_physics_result(result)
		_:
			push_error("Unknown machine physics component: %s" % result.component)
	_commit_queue_chain_if_needed(result, produced_entries)
	return produced_entries

func apply_verifier_seeded_chain_for_ball(ball: Dictionary) -> Array[Dictionary]:
	_step_index += 1
	var chain_id: String = String(ball.get("chain_id", "")).strip_edges()
	if chain_id.is_empty():
		chain_id = _next_chain_id("verifier_seed")
		ball["chain_id"] = chain_id

	var ball_kind: String = "junk" if String(ball.get("kind", "clean")) == "junk" else "clean"
	if ball_kind == "junk":
		if junk_sieve_enabled:
			pool_polluter_junk_count = maxi(0, pool_polluter_junk_count - 1)
			_append_counter_event("Modifier:Junk Sieve 过滤 Junk，Pool 污染被清理")
		else:
			pool_polluter_junk_count = maxi(0, pool_polluter_junk_count - 1)
			_append_counter_event("Counter:Pool Polluter Junk 发射后无有效 Unit 结算")
		return _finalize_queue_output([], 0, 0)

	var produced_entries: Array[Dictionary] = []
	for result: MachinePhysicsResult in build_verifier_seeded_chain_for_ball(ball, _step_index):
		produced_entries.append_array(apply_physics_result(result))
	return produced_entries

func build_verifier_seeded_chain_for_ball(ball: Dictionary, step: int = -1) -> Array[MachinePhysicsResult]:
	if step < 0:
		_step_index += 1
	var verifier_step: int = _step_index if step < 0 else step
	var chain_id: String = String(ball.get("chain_id", "")).strip_edges()
	if chain_id.is_empty():
		chain_id = _next_chain_id("verifier_seed")
	var ball_kind: String = "junk" if String(ball.get("kind", "clean")) == "junk" else "clean"
	if ball_kind == "junk":
		return [
			MachinePhysicsResult.make("Launch", "Waste", 0, 0, ball_kind, "verifier_seed", chain_id)
		]
	var launch_result: String = _launch_result_for_verifier_step(verifier_step)
	var results: Array[MachinePhysicsResult] = [
		MachinePhysicsResult.make("Launch", launch_result, 0, 0, ball_kind, "verifier_seed", chain_id)
	]
	if launch_result != "Tuning":
		return results

	var tuning_result: String = _tuning_result_for_verifier_step(verifier_step)
	var slot_id: int = _slot_for_verifier_step(verifier_step)
	var seeded_elapsed: float = _seeded_battle_elapsed_for_slot(slot_id)
	results.append(MachinePhysicsResult.make("Tuning", tuning_result, 0, int(ball.get("value", 1)), ball_kind, "verifier_seed", chain_id))
	results.append(MachinePhysicsResult.make("Unit", "UnitHit", slot_id, 0, ball_kind, "verifier_seed", chain_id, seeded_elapsed))
	return results

func get_machine_chain_sample() -> Dictionary:
	return _last_machine_chain_sample.duplicate(true)

func get_physics_queue_chains_for_verifier() -> Array[Dictionary]:
	return _physics_queue_chains.duplicate(true)

func get_physics_queue_chain_count() -> int:
	return _physics_queue_chains.size()

func has_queue_entry() -> bool:
	return not queue.is_empty()

func pop_queue_entry() -> Dictionary:
	if queue.is_empty():
		return {}
	return queue.pop_front()

func add_guardian_clean_pool_ball() -> bool:
	return _add_pool_ball("clean")

func _add_pool_ball(kind: String) -> bool:
	if pool.size() >= pool_capacity:
		event_log.append("Launch.Pool full rejected %s" % kind)
		return false
	pool.append({"kind": kind, "value": 1})
	event_log.append("Launch.Forge added %s ball" % kind)
	return true

func _add_pool_ball_front(kind: String, source: String) -> bool:
	if pool.size() >= pool_capacity:
		event_log.append("Modifier:%s front recycle rejected %s ball pool full" % [source, kind])
		return false
	pool.push_front({"kind": kind, "value": 1})
	event_log.append("Modifier:%s returned %s ball to Pool front" % [source, kind])
	return true

func _apply_unit_hit(
	slot_id: int,
	value: int,
	source: String,
	chain_id: String = "",
	source_tags: Array[String] = []
) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	slot_progress[slot_id] = int(slot_progress[slot_id]) + value
	var required: int = int(SLOT_REQUIREMENTS[slot_id])

	if int(slot_progress[slot_id]) >= required:
		slot_progress[slot_id] = int(slot_progress[slot_id]) - required
		var entry: Dictionary = {
			"unit_id": _unit_id_for_slot(slot_id),
			"slot_id": slot_id,
			"source": source,
			"count": 1,
		}
		if not chain_id.is_empty():
			entry["chain_id"] = chain_id
		if not source_tags.is_empty():
			entry["source_tags"] = source_tags.duplicate()
		entries.append(entry)

	var floor_value: int = int(slot_progress_floor.get(slot_id, 0))
	slot_progress[slot_id] = maxi(int(slot_progress[slot_id]), floor_value)

	return entries

func _finalize_queue_output(
	added_entries: Array[Dictionary],
	natural_slot_id: int,
	natural_value: int,
	chain_id: String = "",
	source_tags: Array[String] = []
) -> Array[Dictionary]:
	var output_entries: Array[Dictionary] = added_entries.duplicate(true)
	if output_entries.is_empty():
		_maybe_apply_queue_brace(output_entries)
	else:
		queue_brace_gap_count = 0

	if muster_pair_enabled:
		for entry: Dictionary in output_entries:
			if String(entry.get("source", "")) != "QueueBrace":
				entry["count"] = int(entry.get("count", 1)) + 1
				_append_counter_event("Modifier:Muster Pair 同槽成对出兵")
				break

	for entry: Dictionary in output_entries:
		if not chain_id.is_empty() and not entry.has("chain_id"):
			entry["chain_id"] = chain_id
		if not source_tags.is_empty():
			var merged_tags: Array = []
			if entry.get("source_tags", []) is Array:
				merged_tags = (entry.get("source_tags", []) as Array).duplicate()
			for tag: String in source_tags:
				if not merged_tags.has(tag):
					merged_tags.append(tag)
			entry["source_tags"] = merged_tags
		queue.append(entry)
		var entry_slot_id: int = int(entry.get("slot_id", natural_slot_id))
		var entry_value: int = QUEUE_BRACE_COMPENSATION_VALUE if String(entry.get("source", "")) == "QueueBrace" else natural_value
		event_log.append(MachineResult.new("Unit", "QueueEntry", entry_slot_id, entry_value, entry).to_log_line())
		if String(entry.get("source", "")).contains("physics"):
			event_log.append("Unit：S%d 槽满，%s进入 Queue" % [entry_slot_id, _unit_name_for_player(String(entry.get("unit_id", "")))])
	return output_entries

func _maybe_apply_queue_brace(output_entries: Array[Dictionary]) -> void:
	if not queue_brace_enabled:
		return

	queue_brace_gap_count += 1
	if queue_brace_gap_count < QUEUE_BRACE_MISS_THRESHOLD:
		return

	queue_brace_gap_count = 0
	var brace_entries: Array[Dictionary] = _apply_unit_hit(1, QUEUE_BRACE_COMPENSATION_VALUE, "QueueBrace")
	event_log.append("Modifier:Queue Brace S1 +1 after %d no-Queue routes" % QUEUE_BRACE_MISS_THRESHOLD)
	output_entries.append_array(brace_entries)

func get_modifier_marker_text() -> String:
	if active_modifier_markers.is_empty():
		return "本局机器修正：无"

	var marker_text := PackedStringArray()
	for marker: String in active_modifier_markers:
		marker_text.append(marker)
	return "本局机器修正：%s" % ", ".join(marker_text)

func get_pool_capacity() -> int:
	return pool_capacity

func _apply_launch_physics_result(result: MachinePhysicsResult) -> Array[Dictionary]:
	if result.ball_kind == "junk":
		if junk_sieve_enabled:
			pool_polluter_junk_count = maxi(0, pool_polluter_junk_count - 1)
			_append_counter_event("Modifier:Junk Sieve 过滤 Junk，Pool 污染被清理")
		else:
			pool_polluter_junk_count = maxi(0, pool_polluter_junk_count - 1)
			_append_counter_event("Counter:Pool Polluter Junk 发射后无有效 Unit 结算")
		return _finalize_queue_output([], 0, 0, result.chain_id, [result.source])

	event_log.append(MachineResult.new("Launch", result.result_id, 0, 0, {}).to_log_line())
	if result.source == "physics":
		event_log.append("物理落点：Launch -> %s" % result.result_id)
	match result.result_id:
		"Tuning":
			return []
		"Split":
			_add_pool_ball("clean")
			_add_pool_ball("clean")
			return _finalize_queue_output([], 0, 0, result.chain_id, [result.source])
		"Recycle":
			if front_recycle_enabled:
				_add_pool_ball_front("clean", "Front Recycle")
			else:
				_add_pool_ball("clean")
			if guardian_contract != null:
				guardian_contract.call("on_launch_recycle", self)
				_drain_guardian_machine_logs()
			return _finalize_queue_output([], 0, 0, result.chain_id, [result.source])
		"Waste":
			event_log.append("Launch.Waste consumed physics ball")
			return _finalize_queue_output([], 0, 0, result.chain_id, [result.source])
		_:
			push_error("Unknown Launch physics result: %s" % result.result_id)
	return []

func _apply_tuning_physics_result(result: MachinePhysicsResult) -> Array[Dictionary]:
	if _is_staged_physics_source(result.source):
		var chain: Dictionary = _chain_for_result(result)
		var value: int = _value_for_tuning_result(result)
		chain["tuning_result_id"] = result.result_id
		chain["tuning_value"] = value
		_pending_physics_chains[result.chain_id] = chain
		event_log.append(MachineResult.new("Tuning", result.result_id, maxi(0, result.slot_id), value, {}).to_log_line())
		return []

	return _apply_tuning_direct_result(result)

func _apply_tuning_direct_result(result: MachinePhysicsResult) -> Array[Dictionary]:
	var slot_id: int = clampi(result.slot_id, 1, 4)
	var value: int = maxi(1, result.value)
	var entries: Array[Dictionary] = _apply_unit_hit(slot_id, value, result.result_id, result.chain_id, [result.source, result.result_id])
	if result.result_id == "Echo":
		entries.append_array(_apply_unit_hit(slot_id, value, "EchoCopy", result.chain_id, [result.source, "EchoCopy"]))
		if echo_latch_enabled:
			entries.append_array(_apply_unit_hit(slot_id, 1, "EchoLatch", result.chain_id, [result.source, "EchoLatch"]))
			event_log.append("Modifier:Echo Latch physics repeated hit")
	event_log.append(MachineResult.new("Tuning", result.result_id, slot_id, value, {}).to_log_line())
	return _finalize_queue_output(entries, slot_id, value, result.chain_id, [result.source, result.result_id])

func _apply_unit_physics_result(result: MachinePhysicsResult) -> Array[Dictionary]:
	var chain: Dictionary = _chain_for_result(result)
	var tuning_result: String = String(chain.get("tuning_result_id", "Gate"))
	var slot_id: int = clampi(result.slot_id, 1, 4)
	var value: int = int(chain.get("tuning_value", result.value))
	if value <= 0:
		value = maxi(1, result.value)
	var source_tags: Array[String] = [result.source, tuning_result]
	var entries: Array[Dictionary] = _apply_unit_hit(slot_id, value, result.source, result.chain_id, source_tags)

	if result.source == "physics":
		event_log.append("物理落点：Tuning %s -> S%d +%d" % [tuning_result, slot_id, value])

	if tuning_result == "Echo":
		if echo_breaker_active and echo_breaker_charges > 0:
			echo_breaker_charges -= 1
			echo_breaker_active = false
			_append_counter_event("Counter:Echo Breaker Echo 复制降级为 Gate")
		else:
			entries.append_array(_apply_unit_hit(slot_id, value, result.source, result.chain_id, [result.source, "EchoCopy"]))
			if echo_latch_enabled:
				entries.append_array(_apply_unit_hit(slot_id, 1, result.source, result.chain_id, [result.source, "EchoLatch"]))
				event_log.append("Modifier:Echo Latch physics ghost hit marker")

	var produced_entries: Array[Dictionary] = _finalize_queue_output(entries, slot_id, value, result.chain_id, source_tags)
	if surge_buffer_enabled and tuning_result == "Surge" and produced_entries.is_empty():
		surge_buffer_charge = mini(1, surge_buffer_charge + 1)
		event_log.append("Modifier:Surge Buffer stored buffer=1 after Surge no Queue")

	return produced_entries

func apply_pool_polluter_junk() -> bool:
	if pool_polluter_junk_count >= 2:
		_append_counter_event("Counter:Pool Polluter 上限已满，未继续插入 Junk")
		return false
	if pool.size() >= pool_capacity:
		_append_counter_event("Counter:Pool Polluter 因 Pool 已满未插入 Junk")
		return false
	pool.append({"kind": "junk", "value": 0, "source": "Pool Polluter"})
	pool_polluter_junk_count += 1
	_append_counter_event("Counter:Pool Polluter Junk 插入 Pool 槽 %d" % pool.size())
	return true

func arm_echo_breaker() -> void:
	echo_breaker_active = true
	echo_breaker_charges = 1
	_append_counter_event("Counter:Echo Breaker 已锁定 Echo 槽")

func _append_counter_event(log_line: String) -> void:
	event_log.append(log_line)
	counter_log.append(log_line)
	while counter_log.size() > 8:
		counter_log.pop_front()

func _drain_guardian_machine_logs() -> void:
	if guardian_contract == null or not guardian_contract.has_method("consume_machine_event_log"):
		return
	var drained_variant: Variant = guardian_contract.call("consume_machine_event_log")
	if not (drained_variant is Array):
		return
	for log_variant: Variant in drained_variant:
		event_log.append(String(log_variant))

func _modifier_display_name(modifier_id: String) -> String:
	match modifier_id:
		"pool_pocket":
			return "Pool Pocket"
		"prime_charge":
			return "Prime Charge"
		"slot_primer":
			return "Slot Primer"
		"front_recycle":
			return "Front Recycle"
		"surge_buffer":
			return "Surge Buffer"
		"queue_brace":
			return "Queue Brace"
		"junk_sieve":
			return "Junk Sieve"
		"muster_pair":
			return "Muster Pair"
		"echo_latch":
			return "Echo Latch"
		_:
			return modifier_id

func _modifier_axis(modifier_id: String) -> String:
	match modifier_id:
		"pool_pocket", "front_recycle", "junk_sieve":
			return "Launch"
		"prime_charge", "surge_buffer", "echo_latch":
			return "Tuning"
		"slot_primer", "queue_brace", "muster_pair":
			return "Unit"
		_:
			return "Unknown"

func _modifier_active_key(modifier_id: String, slot_id: int) -> String:
	match modifier_id:
		"slot_primer":
			if not SLOT_REQUIREMENTS.has(slot_id):
				push_error("Unknown Slot Primer slot_id: %d" % slot_id)
				return ""
			return "%s:%d" % [modifier_id, slot_id]
		"pool_pocket", "prime_charge", "front_recycle", "surge_buffer", "queue_brace", "junk_sieve", "muster_pair", "echo_latch":
			return modifier_id
		_:
			push_error("Unknown machine modifier: %s" % modifier_id)
			return ""

func _make_launch_request(ball: Dictionary) -> Dictionary:
	var request: Dictionary = ball.duplicate(true)
	request["kind"] = String(request.get("kind", "clean"))
	request["value"] = int(request.get("value", 1))
	request["chain_id"] = _next_chain_id("physics")
	request["source"] = "pool"
	return request

func _next_chain_id(prefix: String) -> String:
	_next_chain_index += 1
	return "%s_chain_%04d" % [prefix, _next_chain_index]

func _begin_machine_chain(ball: Dictionary) -> void:
	var chain_id: String = String(ball.get("chain_id", "")).strip_edges()
	if chain_id.is_empty():
		return
	var chain: Dictionary = {
		"chain_id": chain_id,
		"pool": ball.duplicate(true),
		"pool_to_launch": true,
		"results": [],
		"queue_entries": [],
		"source": "physics",
	}
	_pending_physics_chains[chain_id] = chain
	_remember_pending_chain(chain_id)
	_last_machine_chain_sample = chain.duplicate(true)

func _register_physics_result(result: MachinePhysicsResult) -> void:
	if result.chain_id.strip_edges().is_empty():
		result.chain_id = _next_chain_id(result.source)
	var chain: Dictionary = _chain_for_result(result)
	chain["source"] = result.source
	var result_dict: Dictionary = result.to_dictionary()
	match result.component:
		"Launch":
			chain["launch_physics_result"] = result_dict
		"Tuning":
			chain["tuning_physics_result"] = result_dict
		"Unit":
			chain["unit_physics_result"] = result_dict
		_:
			pass
	var results: Array = []
	if chain.get("results", []) is Array:
		results = chain.get("results", []) as Array
	results.append(result_dict)
	chain["results"] = results
	_pending_physics_chains[result.chain_id] = chain
	_remember_pending_chain(result.chain_id)
	_last_machine_chain_sample = chain.duplicate(true)

func _chain_for_result(result: MachinePhysicsResult) -> Dictionary:
	var chain_id: String = result.chain_id.strip_edges()
	if chain_id.is_empty():
		chain_id = _next_chain_id(result.source)
		result.chain_id = chain_id
	if _pending_physics_chains.has(chain_id):
		return (_pending_physics_chains[chain_id] as Dictionary).duplicate(true)
	return {
		"chain_id": chain_id,
		"pool": {
			"kind": result.ball_kind,
			"value": maxi(1, result.value),
		},
		"results": [],
		"queue_entries": [],
		"source": result.source,
	}

func _commit_queue_chain_if_needed(result: MachinePhysicsResult, produced_entries: Array[Dictionary]) -> void:
	var chain: Dictionary = _chain_for_result(result)
	if not produced_entries.is_empty():
		var queue_entries: Array = []
		if chain.get("queue_entries", []) is Array:
			queue_entries = chain.get("queue_entries", []) as Array
		for entry: Dictionary in produced_entries:
			queue_entries.append(entry.duplicate(true))
		chain["queue_entries"] = queue_entries
	_last_machine_chain_sample = chain.duplicate(true)

	if result.source == "physics" and not produced_entries.is_empty():
		_physics_queue_chains.append(chain.duplicate(true))
		while _physics_queue_chains.size() > MAX_PHYSICS_QUEUE_CHAIN_TELEMETRY:
			_physics_queue_chains.pop_front()

	if _is_terminal_physics_chain_result(result):
		_erase_pending_chain(result.chain_id)
	else:
		_pending_physics_chains[result.chain_id] = chain
		_remember_pending_chain(result.chain_id)

func _is_terminal_physics_chain_result(result: MachinePhysicsResult) -> bool:
	if result.component == "Unit":
		return true
	if result.component == "Launch":
		return result.result_id != "Tuning" or result.ball_kind == "junk"
	if result.component == "Tuning":
		return not _is_staged_physics_source(result.source)
	return true

func _remember_pending_chain(chain_id: String) -> void:
	if chain_id.strip_edges().is_empty():
		return
	if not _pending_chain_order.has(chain_id):
		_pending_chain_order.append(chain_id)
	while _pending_chain_order.size() > MAX_PENDING_PHYSICS_CHAINS:
		var stale_chain_id: String = _pending_chain_order.pop_front()
		_pending_physics_chains.erase(stale_chain_id)

func _erase_pending_chain(chain_id: String) -> void:
	if chain_id.strip_edges().is_empty():
		return
	_pending_physics_chains.erase(chain_id)
	_pending_chain_order.erase(chain_id)

func _is_staged_physics_source(source: String) -> bool:
	return source == "physics" or source == "verifier_seed"

func _has_exposure_state_contract(candidate: Object) -> bool:
	if candidate == null:
		return false
	for method_name: String in [
		"get_exposure_ratio",
		"is_slot_open_for_progress",
		"is_slot_fully_exposed",
		"snapshot",
		"lowest_progress_legal_slot",
	]:
		if not candidate.has_method(method_name):
			return false
	return true

func _value_for_tuning_result(result: MachinePhysicsResult) -> int:
	var value: int = maxi(1, result.value)
	if result.result_id == "Prime":
		value += prime_value_bonus
	if surge_buffer_enabled and surge_buffer_charge > 0:
		surge_buffer_charge = 0
		value += 1
		event_log.append("Modifier:Surge Buffer consumed buffer value+1 on %s" % result.result_id)
	return value

func _unit_name_for_player(unit_id: String) -> String:
	match unit_id:
		"hive_short_fang":
			return "短牙虫"
		"hive_shield_shell":
			return "盾壳虫"
		"hive_acid_sac":
			return "酸囊虫"
		"hive_crush_shell_beast":
			return "碾壳兽"
		_:
			return "未知单位"

func _launch_result_for_verifier_step(step: int) -> String:
	var pattern: Array[String] = ["Tuning", "Tuning", "Split", "Tuning", "Recycle", "Tuning", "Waste", "Tuning"]
	return pattern[(step - 1) % pattern.size()]

func _tuning_result_for_verifier_step(step: int) -> String:
	var pattern: Array[String] = ["Gate", "Prime", "Gate", "Echo", "Gate", "Surge"]
	return pattern[(step - 1) % pattern.size()]

func _slot_for_verifier_step(step: int) -> int:
	var pattern: Array[int] = [1, 1, 2, 1, 2, 3, 1, 4]
	return pattern[(step - 1) % pattern.size()]

func _seeded_battle_elapsed_for_slot(slot_id: int) -> float:
	if exposure_state == null:
		return battle_elapsed
	var snapshot: Dictionary = exposure_state.call("snapshot", battle_elapsed) as Dictionary
	var slots_variant: Variant = snapshot.get("slots", {})
	if slots_variant is Dictionary:
		var slots: Dictionary = slots_variant as Dictionary
		if slots.has(slot_id) and slots[slot_id] is Dictionary:
			var slot_info: Dictionary = slots[slot_id] as Dictionary
			return maxf(battle_elapsed, float(slot_info.get("start_seconds", battle_elapsed)))
	return battle_elapsed

func _unit_id_for_slot(slot_id: int) -> String:
	match slot_id:
		1:
			return "hive_short_fang"
		2:
			return "hive_shield_shell"
		3:
			return "hive_acid_sac"
		4:
			return "hive_crush_shell_beast"
		_:
			return "unknown_unit"
