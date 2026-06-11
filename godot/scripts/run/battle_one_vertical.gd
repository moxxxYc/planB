class_name BattleOneVertical
extends Control

const MachineStripViewScript := preload("res://scripts/ui/machine_strip_view.gd")
const QueueBridgeViewScript := preload("res://scripts/ui/queue_bridge_view.gd")
const BattlefieldViewScript := preload("res://scripts/ui/battlefield_view.gd")

const DEPLOY_TICK_SECONDS: float = 0.5
const BRIDGE_TRANSFER_DWELL_SECONDS: float = 1.5

@onready var machine_view: MachineStripViewScript = %MachineStripView
@onready var bridge_view: QueueBridgeViewScript = %QueueBridgeView
@onready var battlefield_view: BattlefieldViewScript = %BattlefieldView
@onready var status_label: Label = %StatusLabel

var machine: MachineSimulator = MachineSimulator.new()
var deploy: DeployLaneModel = DeployLaneModel.new()
var lanes: BattleLaneState = BattleLaneState.new()
var deploy_timer: float = 0.0
var elapsed: float = 0.0
var bridge_transfer_timer: float = 0.0

func _ready() -> void:
	_ensure_views()
	battlefield_view.lane_clicked.connect(_on_lane_clicked)
	_render()

func _process(delta: float) -> void:
	advance_simulation(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("deploy_left"):
		select_deploy_lane("Left")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("deploy_mid"):
		select_deploy_lane("Mid")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("deploy_right"):
		select_deploy_lane("Right")
		get_viewport().set_input_as_handled()

func select_deploy_lane(lane: String) -> void:
	deploy.select_lane(lane)
	_render()

func get_selected_lane() -> String:
	return deploy.current_lane

func get_lane_units(lane: String) -> int:
	return lanes.get_player_units(lane)

func get_lane_button_text(lane: String) -> String:
	_ensure_views()
	return battlefield_view.get_lane_button_text(lane)

func get_bridge_lane_text() -> String:
	_ensure_views()
	return bridge_view.get_lane_label_text()

func get_spawn_port_text() -> String:
	_ensure_views()
	return bridge_view.get_spawn_port_text()

func get_bridge_route_text() -> String:
	_ensure_views()
	return bridge_view.get_bridge_route_text()

func get_queue_count() -> int:
	return machine.queue.size()

func get_machine_event_count() -> int:
	return machine.event_log.size()

func get_machine_visual_contract() -> Dictionary:
	_ensure_views()
	return machine_view.get_visual_contract_summary()

func get_machine_readable_log_text() -> String:
	_ensure_views()
	return machine_view.get_readable_log_text()

func get_bridge_transfer_text() -> String:
	_ensure_views()
	return bridge_view.get_transfer_text()

func get_battle_result() -> String:
	return lanes.get_battle_result()

func get_battle_result_text() -> String:
	return lanes.get_result_text()

func advance_simulation(delta: float) -> void:
	elapsed += delta
	_advance_bridge_transfer(delta)
	machine.advance_step(delta)
	deploy_timer += delta
	while deploy_timer >= DEPLOY_TICK_SECONDS:
		deploy_timer -= DEPLOY_TICK_SECONDS
		_deploy_queue_head()
	lanes.advance_battle(delta)
	_render()

func _on_lane_clicked(lane: String) -> void:
	select_deploy_lane(lane)

func _deploy_queue_head() -> void:
	if not machine.has_queue_entry():
		return

	var entry: Dictionary = machine.pop_queue_entry()
	lanes.apply_player_deploy(deploy.current_lane, entry)
	bridge_transfer_timer = BRIDGE_TRANSFER_DWELL_SECONDS
	bridge_view.show_deploy_transfer(deploy.current_lane, entry)

func _render() -> void:
	_ensure_views()
	machine_view.render(machine)
	bridge_view.render(machine, deploy)
	battlefield_view.render(deploy, lanes)
	if lanes.get_battle_result() == BattleLaneState.RESULT_RUNNING:
		status_label.text = "战斗 1 | %.1fs | Queue 从当前出兵口部署，不从 Guardian 出兵。" % elapsed
	else:
		status_label.text = "战斗 1 | %.1fs | %s" % [elapsed, lanes.get_result_text()]

func _advance_bridge_transfer(delta: float) -> void:
	if bridge_transfer_timer <= 0.0:
		return
	bridge_transfer_timer = maxf(0.0, bridge_transfer_timer - delta)
	if bridge_transfer_timer <= 0.0:
		_ensure_views()
		bridge_view.clear_deploy_transfer()

func _ensure_views() -> void:
	if machine_view == null:
		machine_view = get_node("SafeArea/RootRows/MainColumns/MachinePanel/MachineStripView") as MachineStripViewScript
	if bridge_view == null:
		bridge_view = get_node("SafeArea/RootRows/MainColumns/BridgePanel/QueueBridgeView") as QueueBridgeViewScript
	if battlefield_view == null:
		battlefield_view = get_node("SafeArea/RootRows/MainColumns/BattlefieldPanel/BattlefieldView") as BattlefieldViewScript
	if status_label == null:
		status_label = get_node("SafeArea/RootRows/StatusBar/StatusLabel") as Label
