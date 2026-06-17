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

	_check_slot_width_contract(model, failures)
	_check_forge_and_launcher_cadence(model, failures)

	for tuning_result in TUNING_RESULTS:
		if not model.select_tuning_result(tuning_result):
			failures.append("Could not force Tuning result: %s" % tuning_result)

	_check_tuning_slot_effects(model, failures)
	_check_launch_slot_effects(model, failures)

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


func _check_forge_and_launcher_cadence(model, failures: Array[String]) -> void:
	if abs(float(model.FORGE_INTERVAL_SECONDS) - 2.2) > 0.001:
		failures.append("Forge cadence should follow design target 2.2s")
	if abs(float(model.AUTO_LAUNCH_INTERVAL_SECONDS) - 1.3) > 0.001:
		failures.append("Launcher cadence should follow design target 1.3s")

	model.reset()
	var initial_supply: Dictionary = model.get_supply_summary()
	if not initial_supply.has("forge_time_remaining"):
		failures.append("Supply summary should expose Forge timing for player-facing rhythm")
	if not initial_supply.has("launcher_time_remaining"):
		failures.append("Supply summary should expose Launcher timing for player-facing rhythm")

	model.pool_count = 0
	model.set_auto_running(true)
	model.step_simulation(0.05)
	var dry_motion: Dictionary = model.get_motion_summary()
	if bool(dry_motion.get("in_flight", false)):
		failures.append("Launcher should not start a ball chain when Pool is empty")
	if int(model.pool_count) != 0:
		failures.append("Launcher dry fire should not instantly create a clean ball")
	if not _chain_has_component_state(model, "Launcher", "Logic Settlement"):
		failures.append("Launcher dry fire should be recorded as a visible settlement")

	model.reset()
	model.pool_count = 0
	model.step_simulation(2.19)
	if int(model.pool_count) != 0:
		failures.append("Forge created a clean ball before 2.2s cadence")
	model.step_simulation(0.02)
	if int(model.pool_count) != 1:
		failures.append("Forge did not create one clean ball at 2.2s cadence")


func _check_slot_width_contract(model, failures: Array[String]) -> void:
	var view_script := ResourceLoader.load(VIEW_PATH)
	if view_script == null:
		failures.append("Could not load machine causality view script")
		return
	var view = view_script.new()
	if view == null:
		failures.append("Could not instantiate machine causality view")
		return
	view.set_model(model)

	var launch_segments: Array = view.call(
		"_slot_segments",
		"Launch",
		["Tuning", "Split", "Recycle", "Waste"],
		Rect2(24, 150, 690, 180)
	)
	var tuning_segments: Array = view.call(
		"_slot_segments",
		"Tuning",
		TUNING_RESULTS,
		Rect2(24, 370, 690, 180)
	)

	var launch_tuning_width := _slot_segment_width(launch_segments, "Tuning")
	var launch_split_width := _slot_segment_width(launch_segments, "Split")
	var launch_recycle_width := _slot_segment_width(launch_segments, "Recycle")
	var launch_waste_width := _slot_segment_width(launch_segments, "Waste")
	if launch_tuning_width <= launch_split_width * 3.0:
		failures.append("Launch Tuning path is not visibly wider than Split")
	if abs(launch_split_width - launch_recycle_width) > 1.0:
		failures.append("Launch Split and Recycle widths should match first-pass 15/15 targets")
	if launch_waste_width >= launch_split_width * 0.5:
		failures.append("Launch Waste slot is not visibly the narrowest result")

	var gate_width := _slot_segment_width(tuning_segments, "Gate")
	var prime_width := _slot_segment_width(tuning_segments, "Prime")
	var echo_width := _slot_segment_width(tuning_segments, "Echo")
	var surge_width := _slot_segment_width(tuning_segments, "Surge")
	if gate_width <= prime_width * 3.0:
		failures.append("Tuning Gate is not visibly wider than reward slots")
	if abs(prime_width - echo_width) > 1.0 or abs(echo_width - surge_width) > 1.0:
		failures.append("Tuning Prime/Echo/Surge widths should match first-pass 15/15/15 targets")
	view.free()


func _check_tuning_slot_effects(model, failures: Array[String]) -> void:
	for tuning_result in TUNING_RESULTS:
		model.reset()
		model.set_battle_time(120.0)
		var before_progress := int(model.unit_progress[4])
		var result: Dictionary = model.run_machine_chain(tuning_result, 4)
		var after_progress := int(model.unit_progress[4])
		var expected_progress := 2 if tuning_result == "Prime" or tuning_result == "Echo" else 1
		if after_progress - before_progress != expected_progress:
			failures.append("%s did not apply expected Unit progress effect" % tuning_result)
		if str(result.get("event", {}).get("state", "")) != "Valid Unit Hit":
			failures.append("%s did not resolve as a valid Unit hit after Tuning" % tuning_result)
		if not _chain_has_component_state(model, "Unit", "Valid Unit Hit"):
			failures.append("%s did not record a Unit hit event after Tuning" % tuning_result)
		if tuning_result != "Gate" and not _chain_has_state(model, "Logic Settlement"):
			failures.append("%s did not record visible logic settlement state" % tuning_result)

	model.reset()
	var surge_entry: Dictionary = model.create_unit_slot_queue(1, "Surge")
	if surge_entry.is_empty():
		failures.append("Surge did not create a queue entry when Unit slot was primed")
	elif abs(float(surge_entry.get("deploy_delay_seconds", 0.0)) - 0.25) > 0.001:
		failures.append("Surge queue entry did not receive 0.25s deploy delay")


func _check_launch_slot_effects(model, failures: Array[String]) -> void:
	model.reset()
	model.pool_count = 1
	var split_before := int(model.pool_count)
	var split_event: Dictionary = model.apply_settlement_state("Split Return")
	var split_after := int(model.pool_count)
	if str(split_event.get("state", "")) != "Split Return" or split_after - split_before != 2:
		failures.append("Split Return did not add two clean balls to Pool")

	model.reset()
	model.pool_count = 1
	var recycle_before := int(model.pool_count)
	var recycle_event: Dictionary = model.apply_settlement_state("Recycle Return")
	var recycle_after := int(model.pool_count)
	if str(recycle_event.get("state", "")) != "Recycle Return" or recycle_after - recycle_before != 1:
		failures.append("Recycle Return did not add one clean ball to Pool")

	model.reset()
	model.pool_count = int(model.POOL_CAPACITY)
	var full_recycle_event: Dictionary = model.apply_settlement_state("Recycle Return")
	var full_recycle_data: Dictionary = full_recycle_event.get("data", {})
	if int(model.pool_count) != int(model.POOL_CAPACITY):
		failures.append("Recycle Return should not exceed Pool capacity")
	if not bool(full_recycle_data.get("return_failed", false)):
		failures.append("Recycle Return at full Pool should record a failed return")

	model.reset()
	model.pool_count = 3
	var waste_before := int(model.pool_count)
	var waste_event: Dictionary = model.apply_settlement_state("Waste")
	var waste_after := int(model.pool_count)
	if str(waste_event.get("state", "")) != "Waste" or waste_after != waste_before:
		failures.append("Waste should not change Pool count")


func _check_dynamic_machine_loop(model, failures: Array[String]) -> void:
	for method_name in ["set_auto_running", "step_simulation", "get_motion_summary"]:
		if not model.has_method(method_name):
			failures.append("M1 dynamic machine model missing %s()" % method_name)
			return

	model.reset()
	var before_large_step_time := float(model.battle_time_seconds)
	model.step_simulation(1.04)
	var large_step_delta := float(model.battle_time_seconds) - before_large_step_time
	if abs(large_step_delta - 1.04) > 0.01:
		failures.append("Dynamic machine simulation lost global speed time on large delta step")
	if model.motion_trail.is_empty():
		failures.append("Dynamic machine large delta step did not record motion samples")

	model.reset()
	model.set_auto_running(true)
	model.step_simulation(0.01)
	var launch_start_motion: Dictionary = model.get_motion_summary()
	var launch_start_position: Vector2 = launch_start_motion.get("ball_position", Vector2.INF)
	var launch_muzzle_position: Vector2 = launch_start_motion.get("launcher_muzzle", Vector2.ZERO)
	if launch_start_position.distance_to(launch_muzzle_position) > 2.0:
		failures.append("Dynamic machine ball does not launch from the cannon muzzle")

	var saw_launch_motion := false
	var saw_tuning_motion := false
	var saw_unit_motion := false
	var saw_split_return := false
	var saw_recycle_return := false
	var saw_waste := false
	var non_tuning_chain_ids: Array[String] = []
	var max_unit_y := -INF
	var previous_position := Vector2.INF
	for _index in range(900):
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
					max_unit_y = max(max_unit_y, ball_position.y)
		previous_position = ball_position
		for event in model.event_log:
			var state := str(event.get("state", ""))
			match state:
				"Split Return":
					saw_split_return = true
					_add_unique_chain_id(non_tuning_chain_ids, event)
				"Recycle Return":
					saw_recycle_return = true
					_add_unique_chain_id(non_tuning_chain_ids, event)
				"Waste":
					saw_waste = true
					_add_unique_chain_id(non_tuning_chain_ids, event)

	if abs(float(model.AUTO_PHASE_SECONDS) - 1.3) > 0.001:
		failures.append("Dynamic machine ball speed should be slowed by doubling phase seconds to 1.3")
	if not saw_split_return:
		failures.append("Dynamic Launch slot result never produced Split Return")
	if not saw_recycle_return:
		failures.append("Dynamic Launch slot result never produced Recycle Return")
	if not saw_waste:
		failures.append("Dynamic Launch slot result never produced Waste")
	if not saw_launch_motion:
		failures.append("Dynamic machine did not show Launch board motion")
	if not saw_tuning_motion:
		failures.append("Dynamic machine did not show Tuning board motion")
	if not saw_unit_motion:
		failures.append("Dynamic machine did not show Unit board motion")
	if max_unit_y < 700.0:
		failures.append("Dynamic machine Unit motion does not visibly enter the third machine board")
	if model.queue_entries.is_empty():
		failures.append("Dynamic machine loop did not create a queue entry")

	for chain_id in non_tuning_chain_ids:
		for event in model.event_log:
			if str(event.get("chain_id", "")) != chain_id:
				continue
			var component := str(event.get("component", ""))
			if component == "Tuning" or component == "Unit":
				failures.append("Non-Tuning Launch result incorrectly continued to %s in %s" % [
					component,
					chain_id,
				])


func _chain_has_state(model, state: String) -> bool:
	for event in model.event_log:
		if str(event.get("state", "")) == state:
			return true
	return false


func _chain_has_component_state(model, component: String, state: String) -> bool:
	for event in model.event_log:
		if str(event.get("component", "")) == component and str(event.get("state", "")) == state:
			return true
	return false


func _slot_segment_width(segments: Array, slot_name: String) -> float:
	for segment in segments:
		if str(segment.get("name", "")) == slot_name:
			var rect: Rect2 = segment.get("rect", Rect2())
			return rect.size.x
	return 0.0


func _add_unique_chain_id(chain_ids: Array[String], event: Dictionary) -> void:
	var chain_id := str(event.get("chain_id", ""))
	if not chain_id.is_empty() and not chain_ids.has(chain_id):
		chain_ids.append(chain_id)
