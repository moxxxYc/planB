extends SceneTree

const MachinePhysicsBoardViewScript := preload("res://scripts/ui/machine_physics_board_view.gd")

var failures: Array[String] = []
var observed_results: Array[Dictionary] = []

func _initialize() -> void:
	_verify_seeded_routes()
	_verify_unit_gate_rebound()
	_verify_stage_backflow_guards()
	_finish()

func _verify_seeded_routes() -> void:
	var board: Node = MachinePhysicsBoardViewScript.new()
	root.add_child(board)
	board.landing_resolved.connect(_on_landing_resolved)
	var results: Array[MachinePhysicsResult] = [
		MachinePhysicsResult.make("Launch", "Split", 0, 0, "clean", "verifier_seed", "launch_split"),
		MachinePhysicsResult.make("Launch", "Tuning", 0, 0, "clean", "verifier_seed", "launch_tuning"),
		MachinePhysicsResult.make("Launch", "Recycle", 0, 0, "clean", "verifier_seed", "launch_recycle"),
		MachinePhysicsResult.make("Launch", "Waste", 0, 0, "clean", "verifier_seed", "launch_waste"),
		MachinePhysicsResult.make("Tuning", "Gate", 1, 1, "clean", "verifier_seed", "tuning_gate"),
		MachinePhysicsResult.make("Tuning", "Prime", 1, 2, "clean", "verifier_seed", "tuning_prime"),
		MachinePhysicsResult.make("Tuning", "Echo", 2, 1, "clean", "verifier_seed", "tuning_echo"),
		MachinePhysicsResult.make("Tuning", "Surge", 3, 3, "clean", "verifier_seed", "tuning_surge"),
		MachinePhysicsResult.make("Unit", "UnitHit", 1, 0, "clean", "verifier_seed", "unit_s1"),
		MachinePhysicsResult.make("Unit", "UnitHit", 2, 0, "clean", "verifier_seed", "unit_s2"),
		MachinePhysicsResult.make("Unit", "UnitHit", 3, 0, "clean", "verifier_seed", "unit_s3"),
		MachinePhysicsResult.make("Unit", "UnitHit", 4, 0, "clean", "verifier_seed", "unit_s4"),
	]
	board.call("run_seeded_chain_for_verifier", results)
	_expect_observed("Launch", "Split", 0)
	_expect_observed("Launch", "Tuning", 0)
	_expect_observed("Launch", "Recycle", 0)
	_expect_observed("Launch", "Waste", 0)
	_expect_observed("Tuning", "Gate", 1)
	_expect_observed("Tuning", "Prime", 1)
	_expect_observed("Tuning", "Echo", 2)
	_expect_observed("Tuning", "Surge", 3)
	for slot_id: int in range(1, 5):
		_expect_observed("Unit", "UnitHit", slot_id)
	var contract: Dictionary = board.call("get_runtime_contract") as Dictionary
	if int(contract.get("physics_landing_count", 0)) < results.size():
		failures.append("Seeded landing chain must record every required route.")
	root.remove_child(board)
	board.free()

func _verify_unit_gate_rebound() -> void:
	var board: Node = MachinePhysicsBoardViewScript.new()
	root.add_child(board)
	if not board.has_method("simulate_unit_gate_contact_rebound_for_verifier"):
		failures.append("MachinePhysicsBoardView must expose unit gate rebound simulation.")
		_dispose(board)
		return
	var rebound: Dictionary = board.call("simulate_unit_gate_contact_rebound_for_verifier", 2) as Dictionary
	if int(rebound.get("rebound_count", 0)) <= 0:
		failures.append("Unit gate blocked contact must rebound instead of sticking.")
	var velocity_variant: Variant = rebound.get("linear_velocity", Vector2.ZERO)
	if not (velocity_variant is Vector2) or (velocity_variant as Vector2).length() <= 1.0:
		failures.append("Unit gate rebound must produce non-zero velocity.")
	_dispose(board)

func _verify_stage_backflow_guards() -> void:
	var board: Node = MachinePhysicsBoardViewScript.new()
	root.add_child(board)
	if not board.has_method("simulate_stage_backflow_guard_for_verifier"):
		failures.append("MachinePhysicsBoardView must expose stage backflow guard simulation.")
		_dispose(board)
		return
	for stage: String in ["Tuning", "Unit"]:
		var simulation: Dictionary = board.call("simulate_stage_backflow_guard_for_verifier", stage) as Dictionary
		if not bool(simulation.get("has_guard", false)):
			failures.append("%s must have a top backflow guard." % stage)
		if not bool(simulation.get("would_cross_stage_top_without_guard", false)):
			failures.append("%s backflow guard simulation must cover upward escape." % stage)
		if not bool(simulation.get("guardrail_corrected", false)):
			failures.append("%s guard must keep lower-warehouse balls out of the upper warehouse." % stage)
	_dispose(board)

func _on_landing_resolved(result: MachinePhysicsResult) -> void:
	observed_results.append(result.to_dictionary())

func _expect_observed(component: String, result_id: String, slot_id: int) -> void:
	for result: Dictionary in observed_results:
		if String(result.get("component", "")) == component and String(result.get("result_id", "")) == result_id and int(result.get("slot_id", 0)) == slot_id:
			return
	failures.append("Missing seeded landing result %s:%s slot=%d." % [component, result_id, slot_id])

func _dispose(node: Node) -> void:
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	node.free()

func _finish() -> void:
	if failures.is_empty():
		print("verify_ball_machine_landing_distribution: PASS")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
