extends SceneTree

const DEBUG_SCENE_PATH: String = "res://scenes/machine/ball_machine_debug.tscn"

var failures: Array[String] = []

func _initialize() -> void:
	_verify_debug_scene_exists_and_runs()
	_finish()

func _verify_debug_scene_exists_and_runs() -> void:
	if not ResourceLoader.exists(DEBUG_SCENE_PATH):
		failures.append("Missing standalone ball machine debug scene at %s." % DEBUG_SCENE_PATH)
		return
	var packed_scene: PackedScene = load(DEBUG_SCENE_PATH) as PackedScene
	if packed_scene == null:
		failures.append("Standalone ball machine debug scene should load as PackedScene.")
		return
	var scene: Node = packed_scene.instantiate()
	if scene == null:
		failures.append("Standalone ball machine debug scene should instantiate.")
		return
	root.add_child(scene)

	if scene.find_child("BattlefieldView", true, false) != null:
		failures.append("Standalone ball machine debug scene must not include BattlefieldView.")
	if scene.find_child("QueueBridgeView", true, false) != null:
		failures.append("Standalone ball machine debug scene must not include QueueBridgeView.")
	if scene.find_child("MachineBoardView", true, false) == null:
		failures.append("Standalone ball machine debug scene must include MachineBoardView.")

	if not scene.has_method("get_debug_contract"):
		failures.append("Standalone ball machine debug scene must expose get_debug_contract().")
		_dispose(scene)
		return

	var initial_contract: Dictionary = scene.call("get_debug_contract") as Dictionary
	_expect_debug_contract(initial_contract, "initial")

	if scene.has_method("advance_debug"):
		scene.call("advance_debug", 3.0)
	else:
		failures.append("Standalone ball machine debug scene must expose advance_debug(seconds).")
	if scene.has_method("manual_launch_clean_for_verifier"):
		scene.call("manual_launch_clean_for_verifier")
	else:
		failures.append("Standalone ball machine debug scene must expose manual_launch_clean_for_verifier().")
	if scene.has_method("apply_modifier_for_debug"):
		scene.call("apply_modifier_for_debug", "slot_primer", {"slot_id": 3})
	else:
		failures.append("Standalone ball machine debug scene must expose apply_modifier_for_debug().")

	var advanced_contract: Dictionary = scene.call("get_debug_contract") as Dictionary
	_expect_debug_contract(advanced_contract, "advanced")
	if float(advanced_contract.get("elapsed", 0.0)) < 3.0:
		failures.append("Standalone ball machine debug scene should advance elapsed time.")
	var machine_contract: Dictionary = _expect_dictionary(advanced_contract.get("machine_contract", {}), "machine_contract")
	if int(machine_contract.get("launcher_turret_visual_source_count", 0)) != 1:
		failures.append("Standalone ball machine debug scene must render exactly one launcher turret source.")
	_expect_machine_render_container(machine_contract, "advanced")
	_dispose(scene)

func _expect_debug_contract(contract: Dictionary, label: String) -> void:
	if String(contract.get("scene_scope", "")) != "ball_machine_only":
		failures.append("%s debug scene scope must be ball_machine_only." % label)
	if not bool(contract.get("has_machine_board", false)):
		failures.append("%s debug scene must have a machine board." % label)
	if bool(contract.get("has_battlefield", true)):
		failures.append("%s debug scene must not have battlefield scope." % label)
	if bool(contract.get("has_queue_bridge", true)):
		failures.append("%s debug scene must not have queue bridge scope." % label)
	if not bool(contract.get("manual_launch_available", false)):
		failures.append("%s debug scene must expose manual launch." % label)
	if not bool(contract.get("advance_available", false)):
		failures.append("%s debug scene must expose manual time advance." % label)
	if int(contract.get("control_button_count", 0)) < 12:
		failures.append("%s debug scene should expose enough tuning controls." % label)
	if int(contract.get("launcher_turret_visual_source_count", 0)) != 1:
		failures.append("%s debug scene must expose one launcher turret visual source." % label)
	var machine_contract: Dictionary = _expect_dictionary(contract.get("machine_contract", {}), "%s machine_contract" % label)
	_expect_machine_render_container(machine_contract, label)

func _expect_machine_render_container(machine_contract: Dictionary, label: String) -> void:
	if not bool(machine_contract.get("clips_physics_children", false)):
		failures.append("%s MachineBoardView must clip physics children inside the standalone stage area." % label)
	if int(machine_contract.get("physics_clip_children_mode", -1)) != CanvasItem.CLIP_CHILDREN_AND_DRAW:
		failures.append("%s MachineBoardView PhysicsStageClip must use clip_children=Clip + Draw." % label)
	if not bool(machine_contract.get("physics_board_uses_stage_clip", false)):
		failures.append("%s MachineBoardView physics board must be parented under PhysicsStageClip." % label)
	if not bool(machine_contract.get("physics_clip_excludes_supply_strip", false)):
		failures.append("%s MachineBoardView PhysicsStageClip must exclude the supply strip." % label)
	var clip_rect_variant: Variant = machine_contract.get("physics_clip_rect", Rect2())
	if not (clip_rect_variant is Rect2):
		failures.append("%s MachineBoardView must expose physics_clip_rect as Rect2." % label)
		return
	var clip_rect: Rect2 = clip_rect_variant as Rect2
	var supply_height: float = float(machine_contract.get("supply_strip_height", 0.0))
	if clip_rect.position.y < supply_height:
		failures.append("%s MachineBoardView PhysicsStageClip starts above supply strip." % label)
	var board_origin_variant: Variant = machine_contract.get("physics_board_canvas_origin", Vector2.INF)
	if not (board_origin_variant is Vector2) or (board_origin_variant as Vector2).distance_to(Vector2.ZERO) > 0.5:
		failures.append("%s MachineBoardView physics board offset must preserve canvas coordinates." % label)
	var physics_board_position_variant: Variant = machine_contract.get("physics_board_position", Vector2.INF)
	if not (physics_board_position_variant is Vector2) or ((physics_board_position_variant as Vector2) + clip_rect.position).distance_to(Vector2.ZERO) > 0.5:
		failures.append("%s MachineBoardView physics board must be offset by negative PhysicsStageClip position." % label)
	var mechanisms: Dictionary = _expect_dictionary(machine_contract.get("moving_mechanisms", {}), "%s moving_mechanisms" % label)
	_expect_visible_mechanism(mechanisms, "LaunchDiverterPaddle", "Launch", label)
	_expect_visible_mechanism(mechanisms, "LaunchReturnFlap", "Launch", label)
	_expect_visible_mechanism(mechanisms, "TuningQualityCam", "Tuning", label)

func _expect_visible_mechanism(mechanisms: Dictionary, mechanism_name: String, stage: String, label: String) -> void:
	var mechanism: Dictionary = _expect_dictionary(mechanisms.get(mechanism_name, {}), "%s %s" % [label, mechanism_name])
	if String(mechanism.get("stage", "")) != stage:
		failures.append("%s %s must belong to %s." % [label, mechanism_name, stage])
	if not bool(mechanism.get("visible", false)):
		failures.append("%s %s must be visible." % [label, mechanism_name])
	if not bool(mechanism.get("plate_visible", false)):
		failures.append("%s %s must expose a visible plate." % [label, mechanism_name])
	if not bool(mechanism.get("highlight_visible", false)):
		failures.append("%s %s must expose a visible highlight." % [label, mechanism_name])
	if not bool(mechanism.get("stage_rect_contains_center", false)):
		failures.append("%s %s center must stay inside the stage." % [label, mechanism_name])
	if not bool(mechanism.get("stage_rect_intersects_bounds", false)):
		failures.append("%s %s visual bounds must intersect the stage." % [label, mechanism_name])
	if float(mechanism.get("minimum_visible_thickness", 0.0)) < 10.0:
		failures.append("%s %s must be thick enough to read." % [label, mechanism_name])

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
		print("verify_ball_machine_debug_scene: PASS")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
