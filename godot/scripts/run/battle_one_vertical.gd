class_name BattleOneVertical
extends Control

const MachineStripViewScript := preload("res://scripts/ui/machine_strip_view.gd")
const QueueBridgeViewScript := preload("res://scripts/ui/queue_bridge_view.gd")
const BattlefieldViewScript := preload("res://scripts/ui/battlefield_view.gd")
const CounterStateScript := preload("res://scripts/model/counter/counter_state.gd")

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
var battle_number: int = 1
var run_session: RunSessionModel = null
var run_payload: Dictionary = {}
var counter_state = null
var counter_definition: Resource = null
var counter_effect_applied: bool = false
var no_deploy_timer: float = 0.0
var last_deploy_elapsed: float = 0.0
var stagger_warning_timer: float = 0.0
var pool_polluter_insert_timer: float = 0.0
var active_counter_record: Dictionary = {}

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
	return _battle_result_text()

func get_active_counter_banner_text() -> String:
	if counter_state == null:
		return "反制：无"
	var banner: String = String(counter_state.call("banner_text"))
	if not banner.contains("预警"):
		banner = "%s | 预警后生效" % banner
	if _counter_definition_id() == "stagger_punisher" and not banner.contains("队列空档"):
		banner = "%s | 队列空档" % banner
	return banner

func get_active_counter_record() -> Dictionary:
	if counter_state == null:
		return {}
	return (counter_state.call("to_record") as Dictionary).duplicate(true)

func get_active_machine_log_text() -> String:
	_ensure_views()
	var raw_log := PackedStringArray()
	for log_line: String in machine.event_log:
		raw_log.append(log_line)
	return "%s\n%s" % [machine_view.get_readable_log_text(), "\n".join(raw_log)]

func configure_for_run(p_battle_number: int, p_session: RunSessionModel, payload: Dictionary = {}) -> void:
	battle_number = maxi(1, p_battle_number)
	run_session = p_session
	run_payload = payload.duplicate(true)
	_configure_counter_runtime(payload)
	_apply_run_modifiers()
	_render()

func get_battle_modifier_marker_text() -> String:
	return machine.get_modifier_marker_text()

func advance_simulation(delta: float) -> void:
	elapsed += delta
	_advance_bridge_transfer(delta)
	_advance_counter(delta)
	machine.advance_step(delta)
	deploy_timer += delta
	while deploy_timer >= DEPLOY_TICK_SECONDS:
		deploy_timer -= DEPLOY_TICK_SECONDS
		_deploy_queue_head()
	lanes.advance_battle(delta)
	_render()

func advance_for_verifier(seconds: float) -> void:
	var steps: int = maxi(1, int(ceil(seconds / 0.25)))
	for _i: int in range(steps):
		advance_simulation(seconds / float(steps))

func _on_lane_clicked(lane: String) -> void:
	select_deploy_lane(lane)

func _deploy_queue_head() -> void:
	if not machine.has_queue_entry():
		return

	var entry: Dictionary = machine.pop_queue_entry()
	lanes.apply_player_deploy(deploy.current_lane, entry)
	if deploy.current_lane == "Left":
		no_deploy_timer = 0.0
		last_deploy_elapsed = elapsed
	bridge_transfer_timer = BRIDGE_TRANSFER_DWELL_SECONDS
	bridge_view.show_deploy_transfer(deploy.current_lane, entry)

func _render() -> void:
	_ensure_views()
	machine_view.render(machine)
	bridge_view.render(machine, deploy)
	battlefield_view.render(deploy, lanes)
	if lanes.get_battle_result() == BattleLaneState.RESULT_RUNNING:
		var counter_text: String = " | %s" % get_active_counter_banner_text() if battle_number == 3 else ""
		status_label.text = "%s | %.1fs | 部署：%s | 修正：%s%s" % [
			_battle_label(),
			elapsed,
			_lane_name(deploy.current_lane),
			_active_modifier_names(),
			counter_text,
		]
	else:
		status_label.text = "%s | %.1fs | %s" % [_battle_label(), elapsed, _battle_result_text()]

func _apply_run_modifiers() -> void:
	if run_session == null:
		return

	if battle_number >= 2 and not run_session.reward_one_id.is_empty():
		machine.apply_modifier(run_session.reward_one_id, _modifier_payload(run_session.reward_one_id))
	if battle_number >= 3 and not run_session.shop_purchase_id.is_empty():
		machine.apply_modifier(run_session.shop_purchase_id, _modifier_payload(run_session.shop_purchase_id))

func _modifier_payload(modifier_id: String) -> Dictionary:
	if run_payload.has(modifier_id):
		var modifier_payload: Variant = run_payload[modifier_id]
		if modifier_payload is Dictionary:
			return modifier_payload
	return {}

func _configure_counter_runtime(payload: Dictionary) -> void:
	counter_state = null
	counter_definition = null
	counter_effect_applied = false
	no_deploy_timer = 0.0
	last_deploy_elapsed = 0.0
	stagger_warning_timer = 0.0
	pool_polluter_insert_timer = 0.0
	active_counter_record = {}
	if battle_number != 3 or not payload.has("counter_definition"):
		return
	counter_definition = payload["counter_definition"] as Resource
	if counter_definition == null:
		return
	counter_state = CounterStateScript.new()
	counter_state.call("configure", counter_definition, String(payload.get("counter_response_link", "无")))
	active_counter_record = counter_state.call("to_record") as Dictionary

func _advance_counter(delta: float) -> void:
	if counter_state == null:
		return
	counter_state.call("advance", delta)
	match _counter_definition_id():
		"pool_polluter":
			_advance_pool_polluter(delta)
		"echo_breaker":
			_advance_echo_breaker()
		"stagger_punisher":
			_advance_stagger_punisher(delta)
	active_counter_record = (counter_state.call("to_record") as Dictionary).duplicate(true)

func _advance_pool_polluter(delta: float) -> void:
	if not bool(counter_state.call("is_active")):
		return
	if int(counter_state.get("trigger_count")) >= 3:
		return
	if int(counter_state.get("trigger_count")) > 0:
		pool_polluter_insert_timer = maxf(0.0, pool_polluter_insert_timer - delta)
		if pool_polluter_insert_timer > 0.0:
			return
	if machine.apply_pool_polluter_junk():
		counter_state.set("visible_effect", "Junk 插入 Pool")
		counter_state.set("trigger_count", int(counter_state.get("trigger_count")) + 1)
		pool_polluter_insert_timer = 6.0

func _advance_echo_breaker() -> void:
	if not bool(counter_state.call("is_active")):
		return
	if counter_effect_applied:
		return
	machine.arm_echo_breaker()
	counter_state.set("visible_effect", "Echo 复制降级为 Gate")
	counter_state.set("trigger_count", int(counter_state.get("trigger_count")) + 1)
	counter_effect_applied = true

func _advance_stagger_punisher(delta: float) -> void:
	if not bool(counter_state.call("is_active")):
		return
	if int(counter_state.get("trigger_count")) >= 2:
		return
	no_deploy_timer = maxf(0.0, elapsed - last_deploy_elapsed)
	if no_deploy_timer >= 3.0 and stagger_warning_timer <= 0.0:
		stagger_warning_timer = 3.0
		lanes.set_lane_danger("Left", 2, "Stagger Punisher 队列空档预警")
	if stagger_warning_timer > 0.0:
		stagger_warning_timer = maxf(0.0, stagger_warning_timer - delta)
		if stagger_warning_timer <= 0.0 and no_deploy_timer >= 4.0:
			lanes.spawn_enemy_raiders("Left", 2, "Queue 空档惩罚")
			counter_state.set("visible_effect", "Raider 因 Queue 空档出现")
			counter_state.set("trigger_count", int(counter_state.get("trigger_count")) + 1)
			no_deploy_timer = 0.0
			last_deploy_elapsed = elapsed

func _counter_definition_id() -> String:
	if counter_definition == null:
		return ""
	return String(counter_definition.get("id"))

func _battle_label() -> String:
	return "战斗 %d" % battle_number

func _active_modifier_names() -> String:
	if run_session == null:
		return "无"
	var names := PackedStringArray()
	if battle_number >= 2 and not run_session.reward_one_id.is_empty():
		names.append(_modifier_display_name(run_session.reward_one_id))
	if battle_number >= 3 and not run_session.shop_purchase_id.is_empty():
		names.append(_modifier_display_name(run_session.shop_purchase_id))
	if names.is_empty():
		return "无"
	return " + ".join(names)

func _modifier_display_name(modifier_id: String) -> String:
	match modifier_id:
		"pool_pocket":
			return "Pool Pocket"
		"prime_charge":
			return "Prime Charge"
		"slot_primer":
			return "Slot Primer"
		"front_recycle":
			return "Front Recycle"
		"surge_buffer":
			return "Surge Buffer"
		"queue_brace":
			return "Queue Brace"
		"junk_sieve":
			return "Junk Sieve"
		"muster_pair":
			return "Muster Pair"
		_:
			return modifier_id

func _lane_name(lane: String) -> String:
	match lane:
		"Left":
			return "左路"
		"Mid":
			return "中路"
		"Right":
			return "右路"
		_:
			return lane

func _battle_result_text() -> String:
	return lanes.get_result_text().replace("战斗 1", _battle_label())

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
