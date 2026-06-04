extends RefCounted

const OverdriveController = preload("res://scripts/systems/overdrive_controller.gd")

func test_each_preset_exposes_one_matching_overdrive() -> bool:
	var controller = OverdriveController.new()
	var expected := {
		"launch_flood": ["launch", "Launch Overdrive"],
		"tuning_echo": ["tuning", "Tuning Overdrive"],
		"unit_queue_burst": ["unit", "Unit Overdrive"],
	}

	for preset_id in expected:
		var definition := controller.definition_for_preset(preset_id)
		if definition.get("axis_id") != expected[preset_id][0]:
			push_error("%s expected axis %s, got %s" % [preset_id, expected[preset_id][0], definition.get("axis_id")])
			return false
		if definition.get("label") != expected[preset_id][1]:
			push_error("%s expected label %s, got %s" % [preset_id, expected[preset_id][1], definition.get("label")])
			return false
	return true

func test_launch_overdrive_eligibility_is_axis_specific() -> bool:
	var controller = OverdriveController.new()
	if not controller.is_eligible("launch_flood", {"return_balls": true}):
		push_error("Launch should be eligible with return balls")
		return false
	if not controller.is_eligible("launch_flood", {"pool_pressure": true}):
		push_error("Launch should be eligible with Pool pressure")
		return false
	if not controller.is_eligible("launch_flood", {"launcher_throughput": true}):
		push_error("Launch should be eligible with launcher throughput")
		return false
	if controller.is_eligible("launch_flood", {"echo_window": true, "squad_chain": true}):
		push_error("Launch should ignore unrelated Tuning/Unit state")
		return false
	return true

func test_tuning_overdrive_eligibility_is_axis_specific() -> bool:
	var controller = OverdriveController.new()
	if not controller.is_eligible("tuning_echo", {"echo_hot_state": true}):
		push_error("Tuning should be eligible with Echo hot state")
		return false
	if not controller.is_eligible("tuning_echo", {"echo_window": true}):
		push_error("Tuning should be eligible with Echo window")
		return false
	if controller.is_eligible("tuning_echo", {"pool_pressure": true, "squad_chain": true}):
		push_error("Tuning should ignore unrelated Launch/Unit state")
		return false
	return true

func test_unit_overdrive_eligibility_is_axis_specific() -> bool:
	var controller = OverdriveController.new()
	if not controller.is_eligible("unit_queue_burst", {"squad_chain": true}):
		push_error("Unit should be eligible with squad chain")
		return false
	if not controller.is_eligible("unit_queue_burst", {"same_unit_queue_buildup": true}):
		push_error("Unit should be eligible with same-unit queue buildup")
		return false
	if controller.is_eligible("unit_queue_burst", {"pool_pressure": true, "echo_window": true}):
		push_error("Unit should ignore unrelated Launch/Tuning state")
		return false
	return true

func test_activation_logs_amplified_axis_and_component() -> bool:
	var controller = OverdriveController.new()
	var launch_event := controller.activate("launch_flood", {"return_balls": true})
	var tuning_event := controller.activate("tuning_echo", {"echo_window": true})
	var unit_event := controller.activate("unit_queue_burst", {"squad_chain": true})

	return _assert_event(launch_event, "launch", "return_arrows", "axis_amplification") \
		and _assert_event(tuning_event, "tuning", "echo_afterimages", "axis_amplification") \
		and _assert_event(unit_event, "unit", "squad_bracket", "axis_amplification")

func test_unrelated_emergency_use_is_low_yield_without_rescue_effects() -> bool:
	var controller = OverdriveController.new()
	var event := controller.activate("launch_flood", {"base_hp_low": true})
	if event.get("overdrive_yield") != "low_yield":
		push_error("Unrelated use should be low_yield, got %s" % event)
		return false
	for forbidden in ["shield", "heal", "freeze", "clear_screen", "rescue"]:
		if event.get("effect_kind", "") == forbidden:
			push_error("Forbidden panic effect emitted: %s" % forbidden)
			return false
	if event.get("lane") == "base_hp" or event.get("component_id") == "panic_area":
		push_error("Overdrive should not attach to base HP or panic area: %s" % event)
		return false
	return true

func _assert_event(event: Dictionary, axis_id: String, component_id: String, overdrive_yield: String) -> bool:
	if event.get("axis_id") != axis_id:
		push_error("expected axis %s, got %s in %s" % [axis_id, event.get("axis_id"), event])
		return false
	if event.get("component_id") != component_id:
		push_error("expected component %s, got %s in %s" % [component_id, event.get("component_id"), event])
		return false
	if event.get("overdrive_yield") != overdrive_yield:
		push_error("expected yield %s, got %s in %s" % [overdrive_yield, event.get("overdrive_yield"), event])
		return false
	return true
