extends SceneTree

const DEBUG_SCENE_PATH: String = "res://scenes/machine/ball_machine_debug.tscn"
const BATTLE_SCENE_PATH: String = "res://scenes/run/battle_one_vertical.tscn"
const SHARED_SCENE_PATH: String = "res://scenes/machine/ball_machine_view.tscn"
const REQUIRED_METHODS: Array[String] = [
	"render",
	"launch_ball",
	"set_exposure_state",
	"set_battle_elapsed",
	"set_redirect_resolver",
	"emit_seeded_landing_for_verifier",
	"run_seeded_chain_for_verifier",
	"get_visual_contract_summary",
	"get_runtime_contract",
]

var failures: Array[String] = []

func _initialize() -> void:
	_verify_shared_scene_exists()
	_verify_host(DEBUG_SCENE_PATH, "debug")
	_verify_host(BATTLE_SCENE_PATH, "battle")
	_finish()

func _verify_shared_scene_exists() -> void:
	if not ResourceLoader.exists(SHARED_SCENE_PATH):
		failures.append("Missing shared BallMachineView scene at %s." % SHARED_SCENE_PATH)

func _verify_host(scene_path: String, label: String) -> void:
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		failures.append("%s scene must load: %s." % [label, scene_path])
		return
	var scene: Node = packed.instantiate()
	if scene == null:
		failures.append("%s scene must instantiate: %s." % [label, scene_path])
		return
	root.add_child(scene)

	var shared_views: Array[Node] = scene.find_children("BallMachineView", "", true, false)
	if shared_views.size() != 1:
		failures.append("%s scene must host exactly one BallMachineView, found %d." % [label, shared_views.size()])
	else:
		_expect_shared_view_contract(shared_views[0], label)
		_expect_no_private_board(scene, shared_views[0], label)

	root.remove_child(scene)
	scene.free()

func _expect_shared_view_contract(shared_view: Node, label: String) -> void:
	for method_name: String in REQUIRED_METHODS:
		if not shared_view.has_method(method_name):
			failures.append("%s BallMachineView missing method %s." % [label, method_name])
	if not shared_view.has_signal("landing_resolved"):
		failures.append("%s BallMachineView must emit landing_resolved." % label)

func _expect_no_private_board(scene: Node, shared_view: Node, label: String) -> void:
	var private_board_count: int = 0
	for node: Node in scene.find_children("MachineBoardView", "", true, false):
		if node.get_parent() != shared_view:
			private_board_count += 1
	if private_board_count > 0:
		failures.append("%s scene must not host a private MachineBoardView outside BallMachineView." % label)

func _finish() -> void:
	if failures.is_empty():
		print("verify_ball_machine_shared_view_contract: PASS")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
