extends RefCounted

func test_battle_lab_instantiates_all_visible_regions() -> bool:
	var scene := load("res://scenes/battle_lab.tscn")
	if scene == null or not scene.can_instantiate():
		push_error("battle_lab.tscn must load and instantiate")
		return false
	var root = scene.instantiate()
	var required := ["LaunchLane", "TuningLane", "UnitLane", "FrontlineView"]
	for name in required:
		var child = root.find_child(name, true, false)
		if child == null:
			root.free()
			push_error("Missing visible region: %s" % name)
			return false
		if not child.visible:
			root.free()
			push_error("Region must be visible: %s" % name)
			return false
	root.free()
	return true

func test_causal_chain_order_is_exact() -> bool:
	var root = load("res://scenes/battle_lab.tscn").instantiate()
	var chain = root.find_child("CausalChain", true, false)
	if chain == null:
		root.free()
		push_error("BattleLab must contain CausalChain")
		return false
	var names := []
	for child in chain.get_children():
		names.append(child.name)
	var passed := _assert_array_equals(names, ["LaunchLane", "TuningLane", "UnitLane", "FrontlineView"], "causal chain")
	root.free()
	return passed

func test_axis_views_use_shape_motion_and_timing_not_color_only() -> bool:
	var root = load("res://scenes/battle_lab.tscn").instantiate()
	for name in ["LaunchLane", "TuningLane", "UnitLane"]:
		var lane = root.find_child(name, true, false)
		if not lane.has_method("get_visual_grammar"):
			root.free()
			push_error("%s must expose get_visual_grammar" % name)
			return false
		var grammar := lane.call("get_visual_grammar") as Dictionary
		for key in ["shape", "motion", "timing"]:
			if not grammar.has(key) or String(grammar[key]).is_empty():
				root.free()
				push_error("%s grammar missing %s: %s" % [name, key, grammar])
				return false
		if grammar.get("color_only", true):
			root.free()
			push_error("%s must not be color-only" % name)
			return false
	root.free()
	return true

func test_frontline_view_exposes_three_signatures() -> bool:
	var root = load("res://scenes/battle_lab.tscn").instantiate()
	var frontline = root.find_child("FrontlineView", true, false)
	if frontline == null or not frontline.has_method("available_signatures"):
		root.free()
		push_error("FrontlineView must expose available_signatures")
		return false
	var passed := _assert_array_equals(
		frontline.call("available_signatures"),
		["sustained_flow", "repeated_heavy_hit", "batch_charge_release"],
		"frontline signatures"
	)
	root.free()
	return passed

func test_debug_labels_are_not_primary_readability_source() -> bool:
	var root = load("res://scenes/battle_lab.tscn").instantiate()
	for name in ["LaunchLane", "TuningLane", "UnitLane", "FrontlineView"]:
		var view = root.find_child(name, true, false)
		if not view.has_method("debug_label_is_primary") or view.call("debug_label_is_primary"):
			root.free()
			push_error("%s must not use debug labels as primary readability" % name)
			return false
	root.free()
	return true

func _assert_array_equals(actual: Array, expected: Array, label: String) -> bool:
	if actual.size() != expected.size():
		push_error("%s expected size %d, got %d: %s" % [label, expected.size(), actual.size(), actual])
		return false
	for i in range(expected.size()):
		if actual[i] != expected[i]:
			push_error("%s expected %s, got %s" % [label, expected, actual])
			return false
	return true
