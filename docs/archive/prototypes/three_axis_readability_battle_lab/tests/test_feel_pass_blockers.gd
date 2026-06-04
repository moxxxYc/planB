extends RefCounted

const PresetDefs = preload("res://scripts/model/preset_defs.gd")

func test_overdrive_button_is_axis_bound_to_current_preset() -> bool:
	var root = _battle_lab()
	if not root.has_method("get_overdrive_ui_snapshot"):
		return _fail(root, "BattleLab must expose Overdrive UI state")

	var snapshot: Dictionary = root.call("get_overdrive_ui_snapshot")
	root.free()

	if not snapshot.get("button_present", false):
		push_error("Main BattleLab scene must include a clickable Overdrive button: %s" % snapshot)
		return false
	if snapshot.get("axis_id", "") != "launch":
		push_error("First preset Overdrive must bind to Launch axis: %s" % snapshot)
		return false
	if snapshot.get("anchor_lane", "") != "LaunchLane":
		push_error("Launch Overdrive button must be attached to the Launch lane: %s" % snapshot)
		return false
	if String(snapshot.get("label", "")).find("Launch") == -1:
		push_error("Overdrive label must name the bound axis: %s" % snapshot)
		return false
	if snapshot.get("target_component", "") != "return_arrows":
		push_error("Launch Overdrive must amplify a Launch component, not a global rescue: %s" % snapshot)
		return false
	if snapshot.get("is_global_rescue", true):
		push_error("Overdrive must not read as a global rescue button: %s" % snapshot)
		return false
	return true

func test_overdrive_click_has_axis_local_visual_response_within_250ms() -> bool:
	var root = _battle_lab()
	if not root.has_method("press_overdrive_for_test") or not root.has_method("get_overdrive_ui_snapshot"):
		return _fail(root, "BattleLab must expose testable Overdrive click behavior")

	root.call("press_overdrive_for_test")
	root.call("advance_for_test", 0.24)
	var snapshot: Dictionary = root.call("get_overdrive_ui_snapshot")
	root.free()

	if not snapshot.get("visual_response_active", false):
		push_error("Overdrive click must create a visible response within 250ms: %s" % snapshot)
		return false
	if float(snapshot.get("visual_response_age_seconds", 999.0)) > 0.25:
		push_error("Overdrive visual response is too late: %s" % snapshot)
		return false
	if snapshot.get("visual_response_axis", "") != snapshot.get("axis_id", ""):
		push_error("Overdrive response must stay on the bound axis: %s" % snapshot)
		return false
	if snapshot.get("is_global_rescue", true):
		push_error("Clicked Overdrive must still not become a global rescue button: %s" % snapshot)
		return false
	return true

func test_frontline_primary_signature_is_p0_for_each_preset() -> bool:
	var expected_by_preset := {
		PresetDefs.LAUNCH_FLOOD: PresetDefs.SUSTAINED_FLOW,
		PresetDefs.TUNING_ECHO: PresetDefs.REPEATED_HEAVY_HIT,
		PresetDefs.UNIT_QUEUE_BURST: PresetDefs.BATCH_CHARGE_RELEASE,
	}

	for preset_id in expected_by_preset.keys():
		var root = _battle_lab()
		if not root.has_method("start_preset_for_test"):
			return _fail(root, "BattleLab must allow deterministic preset selection in tests")
		root.call("start_preset_for_test", preset_id)
		root.call("advance_for_test", 1.0)
		var snapshot: Dictionary = root.call("get_motion_snapshot").get("frontline_snapshot", {})
		root.free()

		var expected_signature: String = expected_by_preset[preset_id]
		if snapshot.get("primary_signature", "") != expected_signature:
			push_error("%s must make %s the frontline P0: %s" % [preset_id, expected_signature, snapshot])
			return false
		var weights: Dictionary = snapshot.get("signature_weights", {})
		if float(weights.get(expected_signature, 0.0)) < 0.9:
			push_error("Primary frontline signature must dominate: %s" % snapshot)
			return false
		for signature_id in weights.keys():
			if signature_id == expected_signature:
				continue
			if float(weights[signature_id]) > 0.35:
				push_error("Inactive frontline signatures must not compete equally with P0: %s" % snapshot)
				return false
	return true

func test_result_screen_layers_do_not_obscure_battle_or_event_strip() -> bool:
	var root = _battle_lab()
	root.call("advance_for_test", 75.0)
	if not root.call("result_screen_is_visible"):
		return _fail(root, "Result screen must become visible after battle end")
	if not root.has_method("get_result_layout_snapshot"):
		return _fail(root, "BattleLab must expose result layout separation state")

	var snapshot: Dictionary = root.call("get_result_layout_snapshot")
	root.free()

	if snapshot.get("answer_key_visible", true):
		push_error("Result screen must not reveal the answer key before answers: %s" % snapshot)
		return false
	if not snapshot.get("has_frozen_battle_view", false):
		push_error("Result screen must preserve a frozen battle view layer: %s" % snapshot)
		return false
	if _rects_overlap(snapshot.get("event_strip_rect", Rect2()), snapshot.get("answer_panel_rect", Rect2())):
		push_error("Event strip and answer fields must not overlap: %s" % snapshot)
		return false
	if _rects_overlap(snapshot.get("frozen_battle_rect", Rect2()), snapshot.get("answer_panel_rect", Rect2())):
		push_error("Frozen battle view and answer fields must not overlap: %s" % snapshot)
		return false
	if not snapshot.get("event_strip_above_answer_fields", false):
		push_error("Event strip must be a separate layer above answer fields: %s" % snapshot)
		return false
	return true

func _battle_lab() -> Control:
	var root: Control = load("res://scenes/battle_lab.tscn").instantiate()
	return root

func _rects_overlap(a: Rect2, b: Rect2) -> bool:
	return a.intersects(b, true)

func _fail(root: Node, message: String) -> bool:
	root.free()
	push_error(message)
	return false
