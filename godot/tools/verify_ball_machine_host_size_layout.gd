extends SceneTree

const SHARED_SCENE_PATH: String = "res://scenes/machine/ball_machine_view.tscn"
const EPSILON: float = 0.5

var failures: Array[String] = []
var sizes: Array[Vector2] = [
	Vector2(720.0, 760.0),
	Vector2(960.0, 760.0),
	Vector2(1280.0, 720.0),
	Vector2(1024.0, 768.0),
	Vector2(844.0, 600.0),
]

func _initialize() -> void:
	_run_verification.call_deferred()

func _run_verification() -> void:
	for size: Vector2 in sizes:
		await _verify_size(size)
	_finish()

func _verify_size(size: Vector2) -> void:
	var packed: PackedScene = load(SHARED_SCENE_PATH) as PackedScene
	if packed == null:
		failures.append("BallMachineView scene must load: %s." % SHARED_SCENE_PATH)
		return
	var host := Control.new()
	host.name = "Host%sx%s" % [int(size.x), int(size.y)]
	host.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	host.position = Vector2.ZERO
	host.size = size
	root.add_child(host)
	var view := packed.instantiate() as Control
	if view == null:
		failures.append("BallMachineView scene must instantiate as Control.")
		_dispose(host)
		return
	host.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	await process_frame

	var contract: Dictionary = view.call("get_visual_contract_summary") as Dictionary
	_expect_contract(contract, size)
	_dispose(host)

func _expect_contract(contract: Dictionary, size: Vector2) -> void:
	var label: String = "%dx%d" % [int(size.x), int(size.y)]
	if String(contract.get("shared_component", "")) != "BallMachineView":
		failures.append("%s must use shared BallMachineView." % label)
	if String(contract.get("layout_metrics_source", "")) != "MachineBoardLayoutMetrics":
		failures.append("%s must use MachineBoardLayoutMetrics." % label)
	if not bool(contract.get("layout_metrics_readable", false)):
		failures.append("%s layout metrics must remain readable." % label)
	_expect_stage_rects(contract, label)
	_expect_moving_overlay(contract, label)

func _expect_stage_rects(contract: Dictionary, label: String) -> void:
	var visible_rects: Dictionary = _expect_dictionary(contract.get("visible_stage_rects", {}), "%s visible_stage_rects" % label)
	var physics_rects: Dictionary = _expect_dictionary(contract.get("stage_rects", {}), "%s stage_rects" % label)
	var merged := Rect2()
	var has_merged := false
	for stage: String in ["Launch", "Tuning", "Unit"]:
		var visible_rect: Rect2 = _stage_info_to_rect(visible_rects.get(stage, {}), "%s visible %s" % [label, stage])
		var physics_rect: Rect2 = _stage_info_to_rect(physics_rects.get(stage, {}), "%s physics %s" % [label, stage])
		if visible_rect.size.x < 300.0 or visible_rect.size.y < 96.0:
			failures.append("%s %s stage unreadable: %s." % [label, stage, str(visible_rect)])
		if not _rects_close(visible_rect, physics_rect):
			failures.append("%s %s visible and physics rects must align." % [label, stage])
		merged = visible_rect if not has_merged else merged.merge(visible_rect)
		has_merged = true
	var clip_variant: Variant = contract.get("physics_clip_rect", Rect2())
	if not (clip_variant is Rect2) or not _rects_close(clip_variant as Rect2, merged):
		failures.append("%s physics clip must match merged stage rects." % label)

func _expect_moving_overlay(contract: Dictionary, label: String) -> void:
	if not bool(contract.get("draws_moving_mechanism_overlay", false)):
		failures.append("%s must draw moving mechanism overlay." % label)
	var overlay: Dictionary = _expect_dictionary(contract.get("moving_mechanism_overlay", {}), "%s moving_mechanism_overlay" % label)
	if not bool(overlay.get("all_required_drawable", false)):
		failures.append("%s all required moving mechanisms must be drawable." % label)
	var mechanisms: Dictionary = _expect_dictionary(contract.get("moving_mechanisms", {}), "%s moving_mechanisms" % label)
	var counts: Dictionary = _expect_dictionary(contract.get("moving_mechanism_counts", {}), "%s moving_mechanism_counts" % label)
	if int(counts.get("Launch", 0)) != 1:
		failures.append("%s Launch must keep exactly one moving peg row at every host size." % label)
	if int(counts.get("Tuning", 0)) != 1:
		failures.append("%s Tuning must keep exactly one moving peg band at every host size." % label)
	if int(counts.get("Unit", 0)) != 0:
		failures.append("%s Unit must not gain moving peg mechanisms at any host size." % label)
	for mechanism_name: String in ["LaunchMovingPegRow", "TuningMovingPegBand"]:
		var mechanism: Dictionary = _expect_dictionary(mechanisms.get(mechanism_name, {}), "%s %s" % [label, mechanism_name])
		if not bool(mechanism.get("stage_rect_contains_center", false)):
			failures.append("%s %s center must stay inside owning stage." % [label, mechanism_name])
		if not bool(mechanism.get("stage_rect_intersects_bounds", false)):
			failures.append("%s %s bounds must intersect owning stage." % [label, mechanism_name])
		if not bool(mechanism.get("all_pegs_inside_stage", false)):
			failures.append("%s %s pegs must stay inside owning stage." % [label, mechanism_name])
		if bool(mechanism.get("has_large_plate", true)):
			failures.append("%s %s must not fall back to a large moving plate." % [label, mechanism_name])
		if float(mechanism.get("horizontal_sweep_coverage_ratio", 0.0)) < 0.98:
			failures.append("%s %s moving pegs must sweep across full host width." % [label, mechanism_name])
		if float(mechanism.get("horizontal_visible_coverage_ratio", 0.0)) < 0.90:
			failures.append("%s %s moving pegs must stay visibly distributed across full host width." % [label, mechanism_name])

func _stage_info_to_rect(value: Variant, field_label: String) -> Rect2:
	if value is Rect2:
		return value as Rect2
	if not (value is Dictionary):
		failures.append("%s must be a Dictionary or Rect2." % field_label)
		return Rect2()
	var info: Dictionary = value as Dictionary
	var position_variant: Variant = info.get("position", Vector2.INF)
	var size_variant: Variant = info.get("size", Vector2.ZERO)
	if not (position_variant is Vector2) or not (size_variant is Vector2):
		failures.append("%s must expose Vector2 position and size." % field_label)
		return Rect2()
	return Rect2(position_variant as Vector2, size_variant as Vector2)

func _rects_close(a: Rect2, b: Rect2) -> bool:
	return a.position.distance_to(b.position) <= EPSILON and a.size.distance_to(b.size) <= EPSILON

func _expect_dictionary(value: Variant, label: String) -> Dictionary:
	if not (value is Dictionary):
		failures.append("%s must be a Dictionary, got %s." % [label, type_string(typeof(value))])
		return {}
	return value as Dictionary

func _dispose(node: Node) -> void:
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	node.free()

func _finish() -> void:
	if failures.is_empty():
		print("verify_ball_machine_host_size_layout: PASS")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
