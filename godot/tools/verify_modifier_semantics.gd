extends SceneTree

const EXPOSURE_STATE_PATH: String = "res://scripts/model/machine/machine_slot_exposure_state.gd"

var failures: Array[String] = []

func _initialize() -> void:
	_verify_junk_sieve_semantics()
	_verify_surge_buffer_semantics()
	_verify_queue_brace_semantics()
	_verify_muster_pair_semantics()
	_verify_echo_latch_semantics()
	_finish()

func _verify_junk_sieve_semantics() -> void:
	var machine: MachineSimulator = _new_machine_for("Junk Sieve", [
		"apply_modifier",
		"advance_step",
	], [
		"forge_progress",
		"pool",
		"queue",
		"event_log",
	])
	if machine == null:
		return
	machine.apply_modifier("junk_sieve")
	machine.forge_progress = -100.0
	machine.pool = [
		{"kind": "junk", "value": 0, "source": "verifier"},
		{"kind": "junk", "value": 0, "source": "verifier"},
		{"kind": "clean", "value": 1, "source": "verifier"},
	]

	machine.advance_step(1.3)
	if machine.queue.size() != 0:
		failures.append("Junk Sieve must discard head Junk as Waste without creating a queue entry.")
	if _count_pool_kind(machine, "clean") != 1:
		failures.append("Junk Sieve must not create a clean ball when filtering Junk.")

	machine.advance_step(1.3)
	if _count_event_log(machine.event_log, "Junk Sieve") > 1:
		failures.append("Junk Sieve must filter at most once per 10s cooldown window.")

func _verify_surge_buffer_semantics() -> void:
	var machine: MachineSimulator = _new_machine_for("Surge Buffer", [
		"apply_modifier",
		"apply_physics_result",
	], [
		"surge_buffer_charge_by_slot",
		"queue",
	])
	if machine == null:
		return
	machine.apply_modifier("surge_buffer")

	machine.apply_physics_result(MachinePhysicsResult.make("Tuning", "Surge", 2, 1, "clean", "verifier"))
	var charge_by_slot: Dictionary = _expect_dictionary(machine.get("surge_buffer_charge_by_slot"), "surge_buffer_charge_by_slot")
	if not bool(charge_by_slot.get(2, false)):
		failures.append("Surge Buffer must store charge on the Surge hit slot only.")

	machine.apply_physics_result(MachinePhysicsResult.make("Tuning", "Gate", 1, 3, "clean", "verifier"))
	charge_by_slot = _expect_dictionary(machine.get("surge_buffer_charge_by_slot"), "surge_buffer_charge_by_slot")
	if not bool(charge_by_slot.get(2, false)):
		failures.append("Surge Buffer charge for slot 2 must not be consumed by a slot 1 queue entry.")

	machine.apply_physics_result(MachinePhysicsResult.make("Tuning", "Gate", 2, 5, "clean", "verifier"))
	var last_entry: Dictionary = _last_queue_entry(machine)
	if absf(float(last_entry.get("deploy_delay", -1.0)) - 0.25) > 0.001:
		failures.append("Surge Buffer must attach deploy_delay=0.25 to the charged slot's next queue entry.")
	var source_tags: Array = _expect_array(last_entry.get("source_tags", []), "Surge Buffer source_tags")
	if not source_tags.has("Surge Buffer"):
		failures.append("Surge Buffer charged queue entry must include source_tags=[Surge Buffer].")
	charge_by_slot = _expect_dictionary(machine.get("surge_buffer_charge_by_slot"), "surge_buffer_charge_by_slot")
	if bool(charge_by_slot.get(2, false)):
		failures.append("Surge Buffer must clear the slot charge after that slot creates a queue entry.")

func _verify_queue_brace_semantics() -> void:
	var machine: MachineSimulator = _new_machine_for("Queue Brace", [
		"apply_modifier",
		"record_empty_deploy_gap",
	], [
		"slot_progress",
	])
	if machine == null:
		return
	machine.apply_modifier("queue_brace")

	var exposure: Object = _new_exposure_state()
	if exposure == null:
		return
	machine.slot_progress = {1: 2, 2: 0, 3: 0, 4: 0}
	machine.call("record_empty_deploy_gap", 3.0, 30.0, exposure)
	if int(machine.slot_progress.get(2, 0)) != 1:
		failures.append("Queue Brace must add +1 to the lowest-progress exposed legal slot after 3s with no deployed queue entry.")
	if int(machine.slot_progress.get(1, 0)) != 2:
		failures.append("Queue Brace must not hard-code compensation to slot 1 when a lower-progress exposed slot exists.")
	machine.call("record_empty_deploy_gap", 3.0, 33.0, exposure)
	if int(machine.slot_progress.get(2, 0)) != 1:
		failures.append("Queue Brace must respect its 12s cooldown after triggering.")

func _verify_muster_pair_semantics() -> void:
	var machine: MachineSimulator = _new_machine_for("Muster Pair", [
		"apply_modifier",
	], [
		"queue",
	])
	if machine == null:
		return
	machine.apply_modifier("muster_pair")

	if machine.has_method("force_muster_pair_timing_sequence_for_verifier"):
		var evidence_variant: Variant = machine.call("force_muster_pair_timing_sequence_for_verifier")
		if not (evidence_variant is Dictionary):
			failures.append("Muster Pair timing verifier helper must return Dictionary evidence.")
			return
		_verify_muster_pair_timing_evidence(evidence_variant as Dictionary)
		return

	var timestamp_method_name: String = _muster_pair_timestamp_method(machine)
	if timestamp_method_name.is_empty():
		failures.append("Muster Pair requires timestamped verifier API: force_muster_pair_timing_sequence_for_verifier(), apply_physics_result_at_time(result, seconds), or apply_timestamped_physics_result(result, seconds).")
		return

	_verify_muster_pair_timestamped_method(timestamp_method_name)

func _verify_echo_latch_semantics() -> void:
	var machine: MachineSimulator = _new_machine_for("Echo Latch", [
		"apply_modifier",
		"apply_physics_result",
	], [
		"slot_progress",
		"queue",
		"event_log",
	])
	if machine == null:
		return
	machine.apply_modifier("echo_latch")
	machine.slot_progress[1] = 2
	machine.apply_physics_result(MachinePhysicsResult.make("Tuning", "Echo", 1, 1, "clean", "verifier"))

	if machine.queue.size() != 1:
		failures.append("Echo Latch must preserve baseline Echo original + one copy without creating extra queue entries.")
	if int(machine.slot_progress.get(1, 0)) != 1:
		failures.append("Echo Latch must not add a third Echo copy or extra +1 progress beyond the baseline copy.")
	if not _event_log_contains_any(machine.event_log, ["ghost", "Ghost", "幽灵", "影子", "残影"]):
		failures.append("Echo Latch must expose a visible ghost hit marker in machine log/telemetry.")

func _new_exposure_state() -> Object:
	if not ResourceLoader.exists(EXPOSURE_STATE_PATH):
		failures.append("Queue Brace semantics require MachineSlotExposureState at %s." % EXPOSURE_STATE_PATH)
		return null
	var exposure_script: Script = load(EXPOSURE_STATE_PATH) as Script
	if exposure_script == null:
		failures.append("MachineSlotExposureState failed to load for Queue Brace semantics.")
		return null
	var exposure: Object = exposure_script.new() as Object
	if exposure == null:
		failures.append("MachineSlotExposureState failed to instantiate for Queue Brace semantics.")
	return exposure

func _count_pool_kind(machine: MachineSimulator, kind: String) -> int:
	var count: int = 0
	for ball_variant: Variant in machine.pool:
		var ball: Dictionary = _expect_dictionary(ball_variant, "machine.pool entry")
		if String(ball.get("kind", "")) == kind:
			count += 1
	return count

func _count_event_log(event_log: Array[String], needle: String) -> int:
	var count: int = 0
	for line: String in event_log:
		if line.contains(needle):
			count += 1
	return count

func _last_queue_entry(machine: MachineSimulator) -> Dictionary:
	if machine.queue.is_empty():
		failures.append("Expected a queue entry but machine.queue is empty.")
		return {}
	return _expect_dictionary(machine.queue[machine.queue.size() - 1], "machine.queue last entry")

func _event_log_contains_any(event_log: Array[String], needles: Array[String]) -> bool:
	for line: String in event_log:
		for needle: String in needles:
			if line.contains(needle):
				return true
	return false

func _new_machine_for(label: String, methods: Array[String], properties: Array[String]) -> MachineSimulator:
	var machine: MachineSimulator = MachineSimulator.new()
	var has_required_api: bool = true
	for method_name: String in methods:
		if not machine.has_method(method_name):
			failures.append("%s requires MachineSimulator.%s()." % [label, method_name])
			has_required_api = false
	for property_name: String in properties:
		if not _has_property(machine, property_name):
			failures.append("%s requires MachineSimulator property %s." % [label, property_name])
			has_required_api = false
	if not has_required_api:
		return null
	return machine

func _has_property(object: Object, property_name: String) -> bool:
	for property_info: Dictionary in object.get_property_list():
		if String(property_info.get("name", "")) == property_name:
			return true
	return false

func _muster_pair_timestamp_method(machine: MachineSimulator) -> String:
	for method_name: String in ["apply_physics_result_at_time", "apply_timestamped_physics_result"]:
		if machine.has_method(method_name):
			return method_name
	return ""

func _verify_muster_pair_timestamped_method(method_name: String) -> void:
	var within_machine: MachineSimulator = _new_machine_for("Muster Pair timestamped within-window", [
		"apply_modifier",
		method_name,
	], [
		"queue",
	])
	if within_machine == null:
		return
	within_machine.apply_modifier("muster_pair")
	within_machine.call(method_name, _muster_pair_result(), 0.0)
	_expect_muster_pair_queue_state(within_machine.queue, 1, 1, false, "Muster Pair t=0 first entry")
	within_machine.call(method_name, _muster_pair_result(), 1.0)
	_expect_muster_pair_queue_state(within_machine.queue, 1, 2, true, "Muster Pair t=1.0 within 1.2s")

	var outside_machine: MachineSimulator = _new_machine_for("Muster Pair timestamped outside-window", [
		"apply_modifier",
		method_name,
	], [
		"queue",
	])
	if outside_machine == null:
		return
	outside_machine.apply_modifier("muster_pair")
	outside_machine.call(method_name, _muster_pair_result(), 0.0)
	outside_machine.call(method_name, _muster_pair_result(), 1.3)
	_expect_muster_pair_outside_window_state(outside_machine.queue, "Muster Pair t=1.3 outside 1.2s")

func _verify_muster_pair_timing_evidence(record: Dictionary) -> void:
	_expect_float_close(record, "window_seconds", 1.2, 0.001, "Muster Pair timing evidence")
	var within: Dictionary = _expect_dictionary(record.get("within_window", {}), "Muster Pair within_window")
	var outside: Dictionary = _expect_dictionary(record.get("outside_window", {}), "Muster Pair outside_window")
	if within.is_empty() or outside.is_empty():
		return
	_expect_float_close(within, "first_time", 0.0, 0.001, "Muster Pair within_window")
	_expect_float_close(within, "second_time", 1.0, 0.001, "Muster Pair within_window")
	_expect_float_close(outside, "first_time", 0.0, 0.001, "Muster Pair outside_window")
	_expect_float_close(outside, "second_time", 1.3, 0.001, "Muster Pair outside_window")
	_expect_muster_pair_queue_state(_queue_snapshot(within, ["after_first_queue", "queue_after_first"]), 1, 1, false, "Muster Pair within_window after first")
	_expect_muster_pair_queue_state(_queue_snapshot(within, ["after_second_queue", "queue_after_second"]), 1, 2, true, "Muster Pair within_window after second")
	_expect_muster_pair_outside_window_state(_queue_snapshot(outside, ["after_second_queue", "queue_after_second"]), "Muster Pair outside_window after second")

func _muster_pair_result() -> MachinePhysicsResult:
	return MachinePhysicsResult.make("Unit", "QueueEntry", 1, 3, "clean", "verifier")

func _expect_muster_pair_queue_state(queue_snapshot: Array, expected_size: int, expected_count: int, expected_paired: bool, label: String) -> void:
	if queue_snapshot.size() != expected_size:
		failures.append("%s expected queue size %d, got %d." % [label, expected_size, queue_snapshot.size()])
		return
	var entry: Dictionary = _expect_dictionary(queue_snapshot[0], "%s queue[0]" % label)
	if int(entry.get("count", 1)) != expected_count:
		failures.append("%s expected count=%d." % [label, expected_count])
	if bool(entry.get("paired_entry", false)) != expected_paired:
		failures.append("%s expected paired_entry=%s." % [label, str(expected_paired)])
	if expected_paired:
		var source_tags: Array = _expect_array(entry.get("source_tags", []), "%s source_tags" % label)
		if not source_tags.has("Muster Pair"):
			failures.append("%s must include source_tags=[Muster Pair]." % label)

func _expect_muster_pair_outside_window_state(queue_snapshot: Array, label: String) -> void:
	if queue_snapshot.size() != 2:
		failures.append("%s expected two separate unpaired entries." % label)
		return
	for index: int in range(queue_snapshot.size()):
		var entry: Dictionary = _expect_dictionary(queue_snapshot[index], "%s queue[%d]" % [label, index])
		if int(entry.get("count", 1)) != 1 or bool(entry.get("paired_entry", false)):
			failures.append("%s must not merge or mark paired_entry outside the 1.2s window." % label)

func _queue_snapshot(record: Dictionary, keys: Array[String]) -> Array:
	for key: String in keys:
		if record.has(key):
			return _expect_array(record.get(key), "Muster Pair %s" % key)
	failures.append("Muster Pair timing evidence missing queue snapshot in one of: %s." % ", ".join(keys))
	return []

func _expect_float_close(record: Dictionary, key: String, expected: float, tolerance: float, label: String) -> void:
	if not record.has(key):
		failures.append("%s missing %s." % [label, key])
		return
	var value: Variant = record.get(key)
	if not (value is int or value is float):
		failures.append("%s.%s must be numeric." % [label, key])
		return
	var actual: float = float(value)
	if absf(actual - expected) > tolerance:
		failures.append("%s.%s expected %.3f, got %.3f." % [label, key, expected, actual])

func _expect_dictionary(value: Variant, label: String) -> Dictionary:
	if not (value is Dictionary):
		failures.append("%s must be a Dictionary, got %s." % [label, type_string(typeof(value))])
		return {}
	return value as Dictionary

func _expect_array(value: Variant, label: String) -> Array:
	if not (value is Array):
		failures.append("%s must be an Array, got %s." % [label, type_string(typeof(value))])
		return []
	return value as Array

func _finish() -> void:
	if failures.is_empty():
		print("verify_modifier_semantics: PASS")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
