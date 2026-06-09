extends SceneTree

const M1_MODEL_PATH := "res://scripts/ball_machine/machine_causality_model.gd"
const MODEL_PATH := "res://scripts/battlefield/battlefield_deploy_model.gd"
const VIEW_PATH := "res://scripts/battlefield/battlefield_deploy_view.gd"
const DEBUG_PATH := "res://scripts/battlefield/battlefield_deploy_debug.gd"
const SCENE_PATH := "res://scenes/battlefield/battlefield_deploy_debug.tscn"

const ENEMY_TEMPLATE_PATHS := [
	"res://resources/enemies/enemy_grunt.tres",
	"res://resources/enemies/enemy_raider.tres",
	"res://resources/enemies/enemy_brute.tres",
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

	print("verify_battlefield_deploy_loop.gd passed: M2 queue entries deploy to live lanes")
	quit(0)


func _check_paths(failures: Array[String]) -> void:
	var required_paths := [
		M1_MODEL_PATH,
		MODEL_PATH,
		VIEW_PATH,
		DEBUG_PATH,
		SCENE_PATH,
	]
	required_paths.append_array(ENEMY_TEMPLATE_PATHS)

	for path in required_paths:
		if not ResourceLoader.exists(path):
			failures.append("Missing M2 resource path: %s" % path)


func _check_model_behaviour(failures: Array[String]) -> void:
	var model_script := ResourceLoader.load(MODEL_PATH)
	var m1_script := ResourceLoader.load(M1_MODEL_PATH)
	if model_script == null or m1_script == null:
		failures.append("Could not load M1/M2 model scripts")
		return

	var model = model_script.new()
	var m1_model = m1_script.new()
	if model == null or m1_model == null:
		failures.append("Could not instantiate M1/M2 models")
		return

	if model.get_selected_lane_name() != "Mid":
		failures.append("Battle starts with wrong default Deploy Lane")

	for lane_name in ["Left", "Mid", "Right"]:
		if not model.select_lane(lane_name):
			failures.append("Could not select lane: %s" % lane_name)
			continue
		if model.get_selected_lane_name() != lane_name:
			failures.append("Selected lane did not update to %s" % lane_name)

	model.reset()
	if not model.select_lane("Left"):
		failures.append("Could not select Left before queue deploy")
	var queue_entry: Dictionary = m1_model.force_unit_slot_queue(1, "Gate")
	if queue_entry.is_empty():
		failures.append("M1 did not create queue entry for M2")
		return

	if not model.enqueue_machine_queue_entry(queue_entry):
		failures.append("M2 model rejected M1 queue entry schema")
	var queue_preview: Array = model.get_queue_preview()
	if queue_preview.is_empty() or queue_preview[0].get("deploy_lane_name", "") != "Left":
		failures.append("Queue head did not preview current Deploy Lane")

	var deployed: Dictionary = model.deploy_next_queue_entry()
	if deployed.is_empty():
		failures.append("Queue head did not deploy")
	elif deployed.get("lane_name", "") != "Left":
		failures.append("Queue deploy did not read current Deploy Lane")

	model.select_lane("Right")
	var deployed_units: Array = model.get_units_for_lane("Left", "player")
	if deployed_units.is_empty():
		failures.append("No player unit stayed on original deployed lane")
	elif deployed_units[0].get("lane_name", "") != "Left":
		failures.append("Existing unit changed lane after Deploy Lane click")

	_check_lane_states_and_danger(model, failures)
	_check_combat_resolution(model, m1_model, failures)


func _check_lane_states_and_danger(model, failures: Array[String]) -> void:
	model.reset()
	model.force_lane_state_for_debug("Left", "pushing")
	model.force_lane_state_for_debug("Mid", "stalled")
	model.force_lane_state_for_debug("Right", "leaking")
	model.force_lane_state_for_debug("Left", "gate broken")
	model.force_lane_state_for_debug("Mid", "invading")

	for expected_state in ["pushing", "stalled", "leaking", "gate broken", "invading"]:
		if not model.has_debug_seen_lane_state(expected_state):
			failures.append("Lane state never became visible: %s" % expected_state)

	model.reset()
	if model.get_lane_danger_tier("Left") != 0:
		failures.append("Empty lane should start at danger tier 0")
	model.set_public_warning("Left", 1)
	if model.get_lane_danger_tier("Left") < 1:
		failures.append("Public warning did not raise danger tier 1")
	model.spawn_enemy("Left", "Enemy Raider", 18.0)
	if model.get_lane_danger_tier("Left") < 2:
		failures.append("Enemy near player gate did not raise danger tier 2")
	model.spawn_enemy("Left", "Enemy Raider", 6.0)
	if model.get_lane_danger_tier("Left") < 3:
		failures.append("Enemy in player base contact did not raise danger tier 3")


func _check_combat_resolution(model, m1_model, failures: Array[String]) -> void:
	model.reset()
	model.select_lane("Mid")
	var queue_entry: Dictionary = m1_model.force_unit_slot_queue(2, "Prime")
	model.enqueue_machine_queue_entry(queue_entry)
	model.deploy_next_queue_entry()
	model.spawn_enemy("Mid", "Enemy Grunt", 18.0)

	var saw_fighting := false
	var saw_death := false
	for _step in range(80):
		model.tick(0.25)
		if model.get_recent_event_states().has("unit attacking"):
			saw_fighting = true
		if model.get_recent_event_states().has("unit died"):
			saw_death = true
			break

	if not saw_fighting:
		failures.append("Enemy and Hive units did not enter combat")
	if not saw_death:
		failures.append("Combat did not produce a unit death")

	model.force_battle_result_for_debug("player_win")
	if model.get_battle_state() != "player_win":
		failures.append("Debug battle did not resolve to player_win")
	model.force_battle_result_for_debug("player_loss")
	if model.get_battle_state() != "player_loss":
		failures.append("Debug battle did not resolve to player_loss")


func _check_debug_scene(failures: Array[String]) -> void:
	var packed := ResourceLoader.load(SCENE_PATH)
	if not packed is PackedScene:
		failures.append("M2 debug scene did not load as PackedScene")
		return

	var instance := (packed as PackedScene).instantiate()
	if instance == null:
		failures.append("M2 debug scene could not instantiate")
		return

	if not instance.has_method("verify_scene_build"):
		failures.append("M2 debug scene missing verify_scene_build()")
	elif not instance.verify_scene_build():
		failures.append("M2 debug scene UI build failed")

	if not instance.has_method("run_debug_control_for_verification"):
		failures.append("M2 debug scene missing run_debug_control_for_verification()")
	else:
		for control_id in [
			"Click Left",
			"Click Mid",
			"Click Right",
			"Generate Queue Entry",
			"Deploy Queue Head",
			"Spawn Enemy",
			"Step Battle",
			"Resolve Win",
			"Resolve Loss",
		]:
			var summary: Dictionary = instance.run_debug_control_for_verification(control_id)
			if summary.is_empty():
				failures.append("M2 debug control returned empty summary: %s" % control_id)

	instance.free()
