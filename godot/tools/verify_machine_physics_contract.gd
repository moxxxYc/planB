extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_verify_physics_board_contract()
	_verify_machine_accepts_physics_result()
	_finish()

func _verify_physics_board_contract() -> void:
	var board_script: Script = load("res://scripts/ui/machine_physics_board_view.gd") as Script
	if board_script == null:
		failures.append("MachinePhysicsBoardView script should load.")
		return
	var board: Node = board_script.new() as Node
	root.add_child(board)
	if not board.has_method("has_physics_contract_nodes") or not bool(board.call("has_physics_contract_nodes")):
		failures.append("MachinePhysicsBoardView should expose RigidBody2D ball, StaticBody2D peg, and Area2D bin.")
	var result: MachinePhysicsResult = board.call("emit_deterministic_landing") as MachinePhysicsResult
	if result == null or result.component.is_empty() or result.result_id.is_empty():
		failures.append("MachinePhysicsBoardView deterministic landing should emit a typed physics result.")
	root.remove_child(board)
	board.free()

func _verify_machine_accepts_physics_result() -> void:
	var machine := MachineSimulator.new()
	if not machine.has_method("apply_physics_result"):
		failures.append("MachineSimulator missing apply_physics_result().")
		return
	machine.apply_physics_result(MachinePhysicsResult.make("Unit", "QueueEntry", 1, 3, "clean", "physics"))
	if not machine.has_queue_entry():
		failures.append("Machine physics Unit result should produce a queue entry.")
	var log_text := "\n".join(machine.event_log)
	if not log_text.contains("Unit:QueueEntry"):
		failures.append("Machine physics result should preserve Unit:QueueEntry causality log.")

func _finish() -> void:
	if failures.is_empty():
		print("verify_machine_physics_contract: PASS")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
