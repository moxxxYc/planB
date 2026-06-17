class_name BallMachineView
extends Control

signal landing_resolved(result: MachinePhysicsResult)

const MachineBoardViewScript := preload("res://scripts/ui/machine_board_view.gd")

@onready var machine_board: MachineBoardViewScript = %MachineBoardView

func _ready() -> void:
	_ensure_nodes()
	_connect_board()

func render(machine, counter_target_component: String = "") -> void:
	_ensure_nodes()
	machine_board.render(machine, counter_target_component)

func launch_ball(ball: Dictionary, battle_elapsed: float) -> void:
	_ensure_nodes()
	machine_board.launch_ball(ball, battle_elapsed)

func set_exposure_state(exposure_state) -> void:
	_ensure_nodes()
	machine_board.set_exposure_state(exposure_state)

func set_battle_elapsed(seconds: float) -> void:
	_ensure_nodes()
	machine_board.set_battle_elapsed(seconds)

func set_redirect_resolver(resolver: Callable) -> void:
	_ensure_nodes()
	machine_board.set_redirect_resolver(resolver)

func emit_seeded_landing_for_verifier(result: MachinePhysicsResult) -> MachinePhysicsResult:
	_ensure_nodes()
	return machine_board.emit_seeded_landing_for_verifier(result)

func run_seeded_chain_for_verifier(results: Array[MachinePhysicsResult]) -> void:
	_ensure_nodes()
	machine_board.run_seeded_chain_for_verifier(results)

func get_visual_contract_summary() -> Dictionary:
	_ensure_nodes()
	var contract: Dictionary = machine_board.get_visual_contract_summary()
	contract["shared_component"] = "BallMachineView"
	return contract

func get_runtime_contract() -> Dictionary:
	_ensure_nodes()
	return machine_board.get_runtime_contract()

func _ensure_nodes() -> void:
	if machine_board == null:
		machine_board = get_node_or_null("%MachineBoardView") as MachineBoardViewScript
	_connect_board()

func _connect_board() -> void:
	if machine_board == null:
		return
	if not machine_board.landing_resolved.is_connected(_on_board_landing_resolved):
		machine_board.landing_resolved.connect(_on_board_landing_resolved)

func _on_board_landing_resolved(result: MachinePhysicsResult) -> void:
	landing_resolved.emit(result)
