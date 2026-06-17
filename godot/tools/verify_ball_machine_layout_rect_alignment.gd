extends SceneTree

const MachineBoardViewScript := preload("res://scripts/ui/machine_board_view.gd")
const EPSILON: float = 0.5

var failures: Array[String] = []

func _initialize() -> void:
	_verify_board_size(Vector2(720.0, 760.0), "base")
	_verify_board_size(Vector2(960.0, 760.0), "wide")
	_finish()

func _verify_board_size(size: Vector2, label: String) -> void:
	var board: Control = MachineBoardViewScript.new() as Control
	if board == null:
		failures.append("%s MachineBoardView should instantiate." % label)
		return
	board.size = size
	root.add_child(board)
	var contract: Dictionary = board.call("get_visual_contract_summary") as Dictionary
	_expect_layout_rect_alignment(contract, label)
	_expect_slot_contract(contract, label)
	root.remove_child(board)
	board.free()

func _expect_layout_rect_alignment(contract: Dictionary, label: String) -> void:
	if String(contract.get("layout_metrics_source", "")) != "MachineBoardLayoutMetrics":
		failures.append("%s layout metrics source must be MachineBoardLayoutMetrics." % label)
	if not bool(contract.get("layout_metrics_readable", false)):
		failures.append("%s layout metrics must remain readable." % label)

	var visible_rects: Dictionary = _expect_dictionary(contract.get("visible_stage_rects", {}), "%s visible_stage_rects" % label)
	var physics_rects: Dictionary = _expect_dictionary(contract.get("stage_rects", {}), "%s stage_rects" % label)
	var merged: Rect2 = Rect2()
	var has_merged := false
	for stage: String in ["Launch", "Tuning", "Unit"]:
		var visible_rect: Rect2 = _stage_info_to_rect(visible_rects.get(stage, {}), "%s visible %s" % [label, stage])
		var physics_rect: Rect2 = _stage_info_to_rect(physics_rects.get(stage, {}), "%s physics %s" % [label, stage])
		if not _rects_close(visible_rect, physics_rect):
			failures.append("%s %s visible rect and physics rect must match. visible=%s physics=%s" % [
				label,
				stage,
				str(visible_rect),
				str(physics_rect),
			])
		merged = visible_rect if not has_merged else merged.merge(visible_rect)
		has_merged = true

	var clip_variant: Variant = contract.get("physics_clip_rect", Rect2())
	if not (clip_variant is Rect2):
		failures.append("%s physics_clip_rect must be Rect2." % label)
		return
	var clip_rect: Rect2 = clip_variant as Rect2
	if not _rects_close(clip_rect, merged):
		failures.append("%s physics_clip_rect must match merged stage rects. clip=%s merged=%s" % [label, str(clip_rect), str(merged)])

func _expect_slot_contract(contract: Dictionary, label: String) -> void:
	var orders: Dictionary = _expect_dictionary(contract.get("schematic_slot_orders", {}), "%s schematic_slot_orders" % label)
	_expect_order(orders.get("Launch", []), ["Split", "Tuning", "Recycle", "Waste"], "%s Launch order" % label)
	_expect_order(orders.get("Tuning", []), ["Prime", "Gate", "Echo", "Surge"], "%s Tuning order" % label)
	_expect_order(orders.get("Unit", []), ["S1", "S2", "S3", "S4"], "%s Unit order" % label)

	var ratios: Dictionary = _expect_dictionary(contract.get("schematic_slot_width_ratios", {}), "%s schematic_slot_width_ratios" % label)
	_expect_ratio_sum(ratios.get("Launch", {}), "%s Launch ratios" % label)
	_expect_ratio_sum(ratios.get("Tuning", {}), "%s Tuning ratios" % label)
	_expect_ratio_sum(ratios.get("Unit", {}), "%s Unit ratios" % label)

func _expect_order(value: Variant, expected: Array[String], label: String) -> void:
	if not (value is Array):
		failures.append("%s must be an Array." % label)
		return
	var actual: Array = value as Array
	if actual.size() != expected.size():
		failures.append("%s size mismatch: %s." % [label, str(actual)])
		return
	for index: int in range(expected.size()):
		if String(actual[index]) != expected[index]:
			failures.append("%s mismatch at %d: expected %s got %s." % [label, index, expected[index], String(actual[index])])

func _expect_ratio_sum(value: Variant, label: String) -> void:
	if not (value is Dictionary):
		failures.append("%s must be a Dictionary." % label)
		return
	var ratios: Dictionary = value as Dictionary
	var sum := 0.0
	for key: Variant in ratios.keys():
		sum += float(ratios[key])
	if absf(sum - 1.0) > 0.01:
		failures.append("%s must sum to 1.0, got %.3f." % [label, sum])

func _stage_info_to_rect(value: Variant, label: String) -> Rect2:
	if value is Rect2:
		return value as Rect2
	if not (value is Dictionary):
		failures.append("%s must be a Dictionary or Rect2." % label)
		return Rect2()
	var info: Dictionary = value as Dictionary
	var position_variant: Variant = info.get("position", Vector2.INF)
	var size_variant: Variant = info.get("size", Vector2.ZERO)
	if not (position_variant is Vector2) or not (size_variant is Vector2):
		failures.append("%s must expose Vector2 position and size." % label)
		return Rect2()
	return Rect2(position_variant as Vector2, size_variant as Vector2)

func _rects_close(a: Rect2, b: Rect2) -> bool:
	return a.position.distance_to(b.position) <= EPSILON and a.size.distance_to(b.size) <= EPSILON

func _expect_dictionary(value: Variant, label: String) -> Dictionary:
	if not (value is Dictionary):
		failures.append("%s must be a Dictionary, got %s." % [label, type_string(typeof(value))])
		return {}
	return value as Dictionary

func _finish() -> void:
	if failures.is_empty():
		print("verify_ball_machine_layout_rect_alignment: PASS")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
