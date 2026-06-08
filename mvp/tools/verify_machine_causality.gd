extends SceneTree

const MODEL_PATH := "res://scripts/ball_machine/machine_causality_model.gd"
const VIEW_PATH := "res://scripts/ball_machine/machine_causality_view.gd"
const DEBUG_PATH := "res://scripts/ball_machine/machine_causality_debug.gd"
const SCENE_PATH := "res://scenes/ball_machine/machine_causality_debug.tscn"

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
		_check_debug_scene(failures)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	print("verify_machine_causality.gd passed: M1 machine chain creates traceable queue entries")
	quit(0)


func _check_paths(failures: Array[String]) -> void:
	for path in [MODEL_PATH, VIEW_PATH, DEBUG_PATH, SCENE_PATH]:
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
		if not model.force_tuning_result(tuning_result):
			failures.append("Could not force Tuning result: %s" % tuning_result)

	for slot_id in [1, 2, 3, 4]:
		model.reset()
		var entry: Dictionary = model.force_unit_slot_queue(slot_id, "Prime")
		if entry.is_empty():
			failures.append("No queue entry generated for Unit slot %d" % slot_id)
			continue
		if entry.get("source_slot_id", -1) != slot_id:
			failures.append("Queue entry source slot mismatch for Unit slot %d" % slot_id)
		if not str(entry.get("trigger_chain", "")).contains("Launch->Tuning->Unit"):
			failures.append("Queue entry missing machine trigger chain for Unit slot %d" % slot_id)

	model.reset()
	var blocked: Dictionary = model.force_blocked_bounce(4)
	if blocked.get("state", "") != "Blocked Bounce":
		failures.append("Blocked bounce debug state did not report Blocked Bounce")

	for settlement_state in ["Recycle Return", "Waste", "Logic Settlement"]:
		var event: Dictionary = model.force_settlement_state(settlement_state)
		if event.get("state", "") != settlement_state:
			failures.append("Could not force settlement state: %s" % settlement_state)


func _check_debug_scene(failures: Array[String]) -> void:
	var packed := ResourceLoader.load(SCENE_PATH)
	if not packed is PackedScene:
		failures.append("M1 debug scene did not load as PackedScene")
		return

	var instance := (packed as PackedScene).instantiate()
	if instance == null:
		failures.append("M1 debug scene could not instantiate")
		return

	if not instance.has_method("verify_scene_build"):
		failures.append("M1 debug scene missing verify_scene_build()")
	elif not instance.verify_scene_build():
		failures.append("M1 debug scene UI build failed")

	if not instance.has_method("get_debug_summary"):
		failures.append("M1 debug scene missing get_debug_summary()")
	else:
		var summary: Dictionary = instance.get_debug_summary()
		for key in ["boards", "tuning_results", "unit_slots", "debug_controls"]:
			if not summary.has(key):
				failures.append("M1 debug summary missing key: %s" % key)
		_check_debug_controls(instance, summary, failures)

	instance.free()


func _check_debug_controls(instance: Node, summary: Dictionary, failures: Array[String]) -> void:
	if not instance.has_method("run_debug_control_for_verification"):
		failures.append("M1 debug scene missing run_debug_control_for_verification()")
		return

	var controls: Array = summary.get("debug_controls", [])
	for control_id in controls:
		var before_log_size: int = summary.get("event_log", []).size()
		summary = instance.run_debug_control_for_verification(str(control_id))
		var after_log_size: int = summary.get("event_log", []).size()
		if after_log_size < before_log_size:
			failures.append("Debug control reduced event log unexpectedly: %s" % control_id)

	var queue_entries: Array = summary.get("queue_entries", [])
	var has_traceable_entry := false
	for entry in queue_entries:
		if (
			entry.has("source_slot_id")
			and str(entry.get("trigger_chain", "")).contains("Launch->Tuning->Unit")
		):
			has_traceable_entry = true
			break
	if not has_traceable_entry:
		failures.append("Debug controls did not leave a traceable queue entry")
