extends SceneTree

const BATTLE_SCENE_PATH: String = "res://scenes/run/battle_one_vertical.tscn"
const DEBUG_SCENE_PATH: String = "res://scenes/machine/ball_machine_debug.tscn"
const SETTLE_FRAMES: int = 30
const SAMPLE_FRAMES: int = 420
const HEIGHT_EPSILON: float = 0.5

var failures: Array[String] = []

func _initialize() -> void:
	_run_verification.call_deferred()

func _run_verification() -> void:
	await _verify_scene(BATTLE_SCENE_PATH, "battle")
	await _verify_scene(DEBUG_SCENE_PATH, "debug")
	_finish()

func _verify_scene(scene_path: String, label: String) -> void:
	if not ResourceLoader.exists(scene_path):
		failures.append("%s scene missing: %s" % [label, scene_path])
		return

	var packed_scene: PackedScene = load(scene_path) as PackedScene
	if packed_scene == null:
		failures.append("%s scene should load as PackedScene." % label)
		return

	var scene: Node = packed_scene.instantiate()
	if scene == null:
		failures.append("%s scene should instantiate." % label)
		return

	root.add_child(scene)
	var samples: Dictionary = {}
	for frame: int in range(SETTLE_FRAMES + SAMPLE_FRAMES):
		await physics_frame
		if frame >= SETTLE_FRAMES:
			_sample_scene(scene, samples)

	_verify_stable_samples(label, samples)
	root.remove_child(scene)
	scene.free()

func _sample_scene(scene: Node, samples: Dictionary) -> void:
	for path: String in [
		"SafeArea/RootRows",
		"SafeArea/RootRows/MainColumns",
		"SafeArea/RootRows/MainColumns/MachinePanel",
		"SafeArea/RootRows/MainColumns/MachinePanel/MachineStripView",
		"SafeArea/RootRows/MainColumns/MachinePanel/MachineStripView/MachineBoardView",
		"SafeArea/RootRows/MainColumns/MachinePanel/MachineStripView/MachineLogScroll",
		"SafeArea/RootRows/MainColumns/MachinePanel/MachineBoardView",
		"SafeArea/RootRows/MainColumns/DebugPanel",
		"SafeArea/RootRows/MainColumns/DebugPanel/DebugRows/LogScroll",
		"SafeArea/RootRows/MainColumns/DebugPanel/DebugRows/ContractScroll",
		"SafeArea/RootRows/MainColumns/BridgePanel/QueueBridgeView/QueuePreviewLabel",
		"SafeArea/RootRows/MainColumns/BattlefieldPanel/BattlefieldView",
	]:
		var node: Node = scene.get_node_or_null(path)
		if node is Control:
			_sample_height(samples, path, (node as Control).size.y)

	var machine_board: Control = scene.find_child("MachineBoardView", true, false) as Control
	if machine_board != null:
		_sample_height(samples, "MachineBoardView.find", machine_board.size.y)
		var contract_variant: Variant = machine_board.call("get_visual_contract_summary") if machine_board.has_method("get_visual_contract_summary") else {}
		if contract_variant is Dictionary:
			var contract: Dictionary = contract_variant as Dictionary
			var rects_variant: Variant = contract.get("stage_rects", {})
			if rects_variant is Dictionary:
				var rects: Dictionary = rects_variant as Dictionary
				for stage_name: String in ["Launch", "Tuning", "Unit"]:
					var rect_variant: Variant = rects.get(stage_name, Rect2())
					if rect_variant is Rect2:
						_sample_height(samples, "stage_rect.%s" % stage_name, (rect_variant as Rect2).size.y)

func _sample_height(samples: Dictionary, key: String, value: float) -> void:
	if not samples.has(key):
		samples[key] = {"min": value, "max": value}
		return
	var bucket: Dictionary = samples[key] as Dictionary
	bucket["min"] = minf(float(bucket["min"]), value)
	bucket["max"] = maxf(float(bucket["max"]), value)

func _verify_stable_samples(label: String, samples: Dictionary) -> void:
	for key_variant: Variant in samples.keys():
		var key: String = String(key_variant)
		var bucket: Dictionary = samples[key] as Dictionary
		var min_height: float = float(bucket["min"])
		var max_height: float = float(bucket["max"])
		var delta: float = max_height - min_height
		if delta > HEIGHT_EPSILON:
			failures.append("%s layout height changed during runtime: %s min=%.2f max=%.2f delta=%.2f" % [
				label,
				key,
				min_height,
				max_height,
				delta,
			])

func _finish() -> void:
	if failures.is_empty():
		print("verify_ball_machine_layout_stability: PASS")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
