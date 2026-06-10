extends SceneTree

const MODEL_PATH := "res://scripts/ball_machine/machine_causality_model.gd"
const VIEW_PATH := "res://scripts/ball_machine/machine_causality_view.gd"

const TUNING_RESULTS := [
	"Gate",
	"Prime",
	"Echo",
	"Surge",
]


func _init() -> void:
	var failures: Array[String] = []

	_check_paths(failures)
	if failures.is_empty():
		_check_model_behaviour(failures)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	print("verify_machine_causality.gd passed: M1 machine chain creates traceable queue entries")
	quit(0)


func _check_paths(failures: Array[String]) -> void:
	for path in [MODEL_PATH, VIEW_PATH]:
		if not ResourceLoader.exists(path):
			failures.append("Missing M1 resource path: %s" % path)


func _check_model_behaviour(failures: Array[String]) -> void:
	var script := ResourceLoader.load(MODEL_PATH)
	if script == null:
		failures.append("Could not load machine causality model script")
		return

	var model = script.new()
	if model == null:
		failures.append("Could not instantiate machine causality model")
		return

	for tuning_result in TUNING_RESULTS:
		if not model.select_tuning_result(tuning_result):
			failures.append("Could not force Tuning result: %s" % tuning_result)

	for slot_id in [1, 2, 3, 4]:
		model.reset()
		var entry: Dictionary = model.create_unit_slot_queue(slot_id, "Prime")
		if entry.is_empty():
			failures.append("No queue entry generated for Unit slot %d" % slot_id)
			continue
		if entry.get("source_slot_id", -1) != slot_id:
			failures.append("Queue entry source slot mismatch for Unit slot %d" % slot_id)
		if not str(entry.get("trigger_chain", "")).contains("Launch->Tuning->Unit"):
			failures.append("Queue entry missing machine trigger chain for Unit slot %d" % slot_id)

	model.reset()
	var blocked: Dictionary = model.create_blocked_bounce(4)
	if blocked.get("state", "") != "Blocked Bounce":
		failures.append("Blocked bounce state did not report Blocked Bounce")

	for settlement_state in ["Recycle Return", "Waste", "Logic Settlement"]:
		var event: Dictionary = model.apply_settlement_state(settlement_state)
		if event.get("state", "") != settlement_state:
			failures.append("Could not force settlement state: %s" % settlement_state)

	_check_dynamic_machine_loop(model, failures)


func _check_dynamic_machine_loop(model, failures: Array[String]) -> void:
	for method_name in ["set_auto_running", "step_simulation", "get_motion_summary"]:
		if not model.has_method(method_name):
			failures.append("M1 dynamic machine model missing %s()" % method_name)
			return

	model.reset()
	model.set_auto_running(true)
	var saw_launch_motion := false
	var saw_tuning_motion := false
	var saw_unit_motion := false
	var previous_position := Vector2.INF
	for _index in range(120):
		model.step_simulation(0.05)
		var motion: Dictionary = model.get_motion_summary()
		var ball_position: Vector2 = motion.get("ball_position", Vector2.INF)
		if previous_position != Vector2.INF and ball_position.distance_to(previous_position) > 0.01:
			match str(motion.get("active_board", "")):
				"Launch":
					saw_launch_motion = true
				"Tuning":
					saw_tuning_motion = true
				"Unit":
					saw_unit_motion = true
		previous_position = ball_position

	if not saw_launch_motion:
		failures.append("Dynamic machine did not show Launch board motion")
	if not saw_tuning_motion:
		failures.append("Dynamic machine did not show Tuning board motion")
	if not saw_unit_motion:
		failures.append("Dynamic machine did not show Unit board motion")
	if model.queue_entries.is_empty():
		failures.append("Dynamic machine loop did not create a queue entry")
