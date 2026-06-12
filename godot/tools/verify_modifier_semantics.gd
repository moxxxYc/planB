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
	var charge_by_slot: Dictionary = machine.get("surge_buffer_charge_by_slot") as Dictionary
	if not bool(charge_by_slot.get(2, false)):
		failures.append("Surge Buffer must store charge on the Surge hit slot only.")

	machine.apply_physics_result(MachinePhysicsResult.make("Tuning", "Gate", 1, 3, "clean", "verifier"))
	charge_by_slot = machine.get("surge_buffer_charge_by_slot") as Dictionary
	if not bool(charge_by_slot.get(2, false)):
		failures.append("Surge Buffer charge for slot 2 must not be consumed by a slot 1 queue entry.")

	machine.apply_physics_result(MachinePhysicsResult.make("Tuning", "Gate", 2, 5, "clean", "verifier"))
	var last_entry: Dictionary = _last_queue_entry(machine)
	if absf(float(last_entry.get("deploy_delay", -1.0)) - 0.25) > 0.001:
		failures.append("Surge Buffer must attach deploy_delay=0.25 to the charged slot's next queue entry.")
	var source_tags: Array = last_entry.get("source_tags", []) as Array
	if not source_tags.has("Surge Buffer"):
		failures.append("Surge Buffer charged queue entry must include source_tags=[Surge Buffer].")
	charge_by_slot = machine.get("surge_buffer_charge_by_slot") as Dictionary
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
		"apply_physics_result",
	], [
		"queue",
	])
	if machine == null:
		return
	machine.apply_modifier("muster_pair")
	machine.apply_physics_result(MachinePhysicsResult.make("Unit", "QueueEntry", 1, 3, "clean", "verifier"))
	if machine.queue.size() != 1:
		failures.append("Muster Pair first same-slot entry should create exactly one unpaired queue entry.")
		return
	var first_entry: Dictionary = machine.queue[0] as Dictionary
	if int(first_entry.get("count", 1)) != 1 or bool(first_entry.get("paired_entry", false)):
		failures.append("Muster Pair must not mark the first entry as paired before a second same-slot entry appears.")

	machine.apply_physics_result(MachinePhysicsResult.make("Unit", "QueueEntry", 1, 3, "clean", "verifier"))
	if machine.queue.size() != 1:
		failures.append("Muster Pair must merge two same-slot entries within 1.2s into one queue entry.")
		return
	var paired_entry: Dictionary = machine.queue[0] as Dictionary
	if int(paired_entry.get("count", 1)) != 2:
		failures.append("Muster Pair merged entry must have count=2.")
	if not bool(paired_entry.get("paired_entry", false)):
		failures.append("Muster Pair merged entry must set paired_entry=true.")
	var source_tags: Array = paired_entry.get("source_tags", []) as Array
	if not source_tags.has("Muster Pair"):
		failures.append("Muster Pair merged entry must include source_tags=[Muster Pair].")

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
		var ball: Dictionary = ball_variant as Dictionary
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
	return machine.queue[machine.queue.size() - 1] as Dictionary

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

func _finish() -> void:
	if failures.is_empty():
		print("verify_modifier_semantics: PASS")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
