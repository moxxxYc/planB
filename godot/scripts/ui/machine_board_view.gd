class_name MachineBoardView
extends Control

signal landing_resolved(result: MachinePhysicsResult)

const MachinePhysicsBoardViewScript := preload("res://scripts/ui/machine_physics_board_view.gd")

const FORGE_CYCLE_SECONDS: float = 2.2
const LAUNCHER_CYCLE_SECONDS: float = 1.3
const QUEUE_PREVIEW_COUNT: int = 3
const SLOT_REQUIREMENTS: Dictionary = {1: 3, 2: 5, 3: 8, 4: 12}

const COLOR_BG: Color = Color("#171a18")
const COLOR_PANEL: Color = Color("#2a2d29")
const COLOR_TRIM: Color = Color("#9b7a4a")
const COLOR_TEXT: Color = Color("#e8e1d2")
const COLOR_MUTED: Color = Color("#7f8178")
const COLOR_LAUNCH: Color = Color("#7bcb6b")
const COLOR_TUNING: Color = Color("#e6b450")
const COLOR_UNIT: Color = Color("#c58be8")
const COLOR_ACTIVE: Color = Color("#f4f0d8")
const COLOR_QUEUE: Color = Color("#56b4e9")
const COLOR_COUNTER_TARGET: Color = Color("#ff8a66")

const MIN_VIEW_SIZE: Vector2 = Vector2(380.0, 600.0)
const SUPPLY_STRIP_HEIGHT: float = 164.0
const POOL_BALL_RADIUS: float = 16.0
const POOL_BALL_RING_RADIUS: float = 20.0
const LAUNCH_SLOT_ORDER: Array[String] = ["Split", "Tuning", "Recycle", "Waste"]
const TUNING_SLOT_ORDER: Array[String] = ["Prime", "Gate", "Echo", "Surge"]
const UNIT_SLOT_ORDER: Array[String] = ["S1", "S2", "S3", "S4"]
const BOARD_SUBTITLES: Dictionary = {
	"Launch": "Split / Tuning / Recycle / Waste",
	"Tuning": "Prime / Gate / Echo / Surge",
	"Unit": "S1 / S2 / S3 / S4",
}

var forge_ratio: float = 0.0
var launcher_ratio: float = 0.0
var pool_count: int = 0
var pool_capacity: int = 5
var pool_balls: Array[String] = []
var queue_count: int = 0
var slot_progress: Dictionary = {1: 0, 2: 0, 3: 0, 4: 0}
var last_launch_result: String = ""
var last_tuning_result: String = ""
var last_queue_unit: String = ""
var active_board_index: int = 0
var counter_target_component: String = ""
var physics_clip: Control = null
var physics_board: MachinePhysicsBoardView = null
var physics_landing_count: int = 0
var last_physics_result: Dictionary = {}
var last_machine_chain_sample: Dictionary = {}
var physics_queue_chain_count: int = 0
var last_physics_queue_chain: Dictionary = {}
var exposure_gate_snapshot: Dictionary = {}
var blocked_bounce_count: int = 0
var last_blocked_bounce: Dictionary = {}
var has_unit_gate_blockers: bool = false
var _last_physics_layout_size: Vector2 = Vector2(-1.0, -1.0)

func _ready() -> void:
	clip_contents = true
	custom_minimum_size = MIN_VIEW_SIZE
	_ensure_physics_board()
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)
	_layout_physics_board()
	queue_redraw()

func render(machine, p_counter_target_component: String = "") -> void:
	_ensure_physics_board()
	if machine.has_method("get_exposure_state"):
		var next_exposure_state = machine.call("get_exposure_state")
		if next_exposure_state != null:
			physics_board.set_exposure_state(next_exposure_state)
	if machine.has_method("get_battle_elapsed"):
		physics_board.set_battle_elapsed(float(machine.call("get_battle_elapsed")))
	forge_ratio = clampf(machine.forge_progress / FORGE_CYCLE_SECONDS, 0.0, 1.0)
	launcher_ratio = clampf(machine.launcher_progress / LAUNCHER_CYCLE_SECONDS, 0.0, 1.0)
	pool_count = machine.pool.size()
	pool_balls = []
	for ball: Dictionary in machine.pool:
		pool_balls.append(String(ball.get("kind", "clean")))
	pool_capacity = _machine_pool_capacity(machine)
	queue_count = machine.queue.size()
	slot_progress = {
		1: int(machine.slot_progress.get(1, 0)),
		2: int(machine.slot_progress.get(2, 0)),
		3: int(machine.slot_progress.get(3, 0)),
		4: int(machine.slot_progress.get(4, 0)),
	}
	_update_recent_results(machine.event_log)
	active_board_index = _active_board_from_ratio(launcher_ratio)
	counter_target_component = p_counter_target_component
	if machine.has_method("get_machine_chain_sample"):
		last_machine_chain_sample = machine.call("get_machine_chain_sample") as Dictionary
	if machine.has_method("get_physics_queue_chain_count"):
		physics_queue_chain_count = int(machine.call("get_physics_queue_chain_count"))
	if machine.has_method("get_physics_queue_chains_for_verifier"):
		var chains: Array = machine.call("get_physics_queue_chains_for_verifier") as Array
		if not chains.is_empty() and chains[chains.size() - 1] is Dictionary:
			last_physics_queue_chain = (chains[chains.size() - 1] as Dictionary).duplicate(true)
	_layout_physics_board()
	_update_exposure_contract_from_physics_board()
	queue_redraw()

func get_visual_contract_summary() -> Dictionary:
	_ensure_physics_board()
	var board_contract: Dictionary = physics_board.get_runtime_contract()
	_apply_exposure_contract(board_contract)
	var physics_landing_count_value: int = int(board_contract.get("physics_landing_count", physics_landing_count))
	var last_result_variant: Variant = board_contract.get("last_physics_result", last_physics_result)
	var last_result_source: String = ""
	if last_result_variant is Dictionary:
		last_result_source = String((last_result_variant as Dictionary).get("source", ""))
	var has_physics_signal_wiring: bool = physics_board.landing_resolved.is_connected(_on_physics_board_landing_resolved)
	var runtime_physics_drives_results: bool = (
		has_physics_signal_wiring
		and physics_board.has_method("launch_ball")
		and bool(board_contract.get("has_physics_contract_nodes", false))
	)
	if physics_landing_count_value > 0:
		runtime_physics_drives_results = runtime_physics_drives_results and last_result_source == "physics"

	return {
		"board_count": 3,
		"pool_slot_count": pool_capacity,
		"queue_preview_count": QUEUE_PREVIEW_COUNT,
		"unit_slot_count": 4,
		"has_schematic_active_ball_overlay": false,
		"has_schematic_peg_overlay": false,
		"has_visible_rigidbody_ball": bool(board_contract.get("has_visible_rigidbody_ball", false)),
		"runtime_physics_drives_results": runtime_physics_drives_results,
		"runtime_uses_preselected_target_labels": bool(board_contract.get("runtime_uses_preselected_target_labels", true)),
		"bin_width_ratios": (board_contract.get("bin_width_ratios", {}) as Dictionary).duplicate(true),
		"bin_orders": (board_contract.get("bin_orders", {}) as Dictionary).duplicate(true),
		"stage_rects": (board_contract.get("stage_rects", {}) as Dictionary).duplicate(true),
		"stage_bottom_catchers": (board_contract.get("stage_bottom_catchers", {}) as Dictionary).duplicate(true),
		"moving_mechanism_counts": (board_contract.get("moving_mechanism_counts", {}) as Dictionary).duplicate(true),
		"moving_mechanisms": (board_contract.get("moving_mechanisms", {}) as Dictionary).duplicate(true),
		"clips_physics_children": physics_clip != null and physics_clip.clip_contents,
		"physics_clip_children_mode": int(physics_clip.clip_children) if physics_clip != null else -1,
		"physics_board_uses_stage_clip": physics_clip != null and physics_board != null and physics_board.get_parent() == physics_clip,
		"physics_clip_rect": _current_physics_clip_rect(),
		"physics_clip_excludes_supply_strip": _current_physics_clip_rect().position.y >= SUPPLY_STRIP_HEIGHT,
		"physics_board_position": physics_board.position,
		"physics_board_canvas_origin": (physics_clip.position + physics_board.position) if physics_clip != null else physics_board.position,
		"schematic_slot_width_ratios": _schematic_slot_width_ratio_snapshot(),
		"schematic_slot_orders": _schematic_slot_order_snapshot(),
		"board_subtitles": _board_subtitle_snapshot(),
		"launcher_turret": (board_contract.get("launcher_turret", {}) as Dictionary).duplicate(true),
		"launcher_turret_visual_source": "MachinePhysicsBoardView",
		"launcher_turret_visual_source_count": 1,
		"active_ball_position": board_contract.get("active_ball_position", Vector2.INF),
		"active_ball_chain_id": String(board_contract.get("active_ball_chain_id", "")),
		"active_ball_at_visible_muzzle": bool(board_contract.get("active_ball_at_visible_muzzle", false)),
		"ball_stage_snapshot": (board_contract.get("ball_stage_snapshot", {}) as Dictionary).duplicate(true),
		"physics_tick_count": int(board_contract.get("physics_tick_count", 0)),
		"physics_landing_count": physics_landing_count_value,
		"last_physics_result": last_result_variant,
		"physics_queue_chain_count": physics_queue_chain_count,
		"last_physics_queue_chain": last_physics_queue_chain.duplicate(true),
		"machine_chain_sample": last_machine_chain_sample.duplicate(true),
		"exposure_gate_snapshot": (board_contract.get("exposure_gate_snapshot", {}) as Dictionary).duplicate(true),
		"blocked_bounce_count": int(board_contract.get("blocked_bounce_count", 0)),
		"last_blocked_bounce": (board_contract.get("last_blocked_bounce", {}) as Dictionary).duplicate(true),
		"has_unit_gate_blockers": bool(board_contract.get("has_unit_gate_blockers", false)),
		"pool_count": pool_count,
		"queue_count": queue_count,
		"active_board_index": active_board_index,
		"counter_target_component": counter_target_component,
		"last_launch_result": last_launch_result,
		"last_tuning_result": last_tuning_result,
		"tuning_slots_distinguished_by_shape": true,
		"tuning_slot_shape_tokens": _tuning_slot_shape_tokens(),
		"machine_board_min_height": MIN_VIEW_SIZE.y,
		"supply_strip_height": SUPPLY_STRIP_HEIGHT,
		"pool_ball_radius": POOL_BALL_RADIUS,
		"pool_ball_ring_radius": POOL_BALL_RING_RADIUS,
	}

func launch_ball(ball: Dictionary, battle_elapsed: float) -> void:
	_ensure_physics_board()
	physics_board.launch_ball(ball, battle_elapsed)

func set_exposure_state(exposure_state) -> void:
	_ensure_physics_board()
	physics_board.set_exposure_state(exposure_state)

func set_battle_elapsed(seconds: float) -> void:
	_ensure_physics_board()
	physics_board.set_battle_elapsed(seconds)

func set_redirect_resolver(resolver: Callable) -> void:
	_ensure_physics_board()
	physics_board.set_redirect_resolver(resolver)

func emit_seeded_landing_for_verifier(result: MachinePhysicsResult) -> MachinePhysicsResult:
	_ensure_physics_board()
	return physics_board.emit_seeded_landing_for_verifier(result)

func run_seeded_chain_for_verifier(results: Array[MachinePhysicsResult]) -> void:
	_ensure_physics_board()
	physics_board.run_seeded_chain_for_verifier(results)

func get_runtime_contract() -> Dictionary:
	_ensure_physics_board()
	return physics_board.get_runtime_contract()

func _on_resized() -> void:
	_layout_physics_board()
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, COLOR_BG, true)
	draw_rect(rect, COLOR_TRIM, false, 2.0)
	_draw_supply_strip(rect)
	_draw_machine_boards(rect)
	_draw_queue_preview(rect)

func _draw_supply_strip(rect: Rect2) -> void:
	var font := get_theme_default_font()
	var left := rect.position.x + 14.0
	var top := rect.position.y + 14.0
	var width := rect.size.x - 28.0
	var strip_rect := Rect2(left, top, width, SUPPLY_STRIP_HEIGHT)

	draw_rect(strip_rect, COLOR_PANEL, true)
	draw_rect(strip_rect, COLOR_LAUNCH, false, 2.0)

	_draw_text(font, Vector2(left + 12.0, top + 22.0), "供给球仓", 15, COLOR_TEXT)
	_draw_text(font, Vector2(left + 96.0, top + 22.0), "Forge / Pool / Launcher", 12, COLOR_MUTED)
	_draw_text(font, Vector2(left + width - 92.0, top + 22.0), "Pool %d / %d" % [pool_count, pool_capacity], 13, COLOR_ACTIVE)

	var bar_width := maxf(88.0, width * 0.34)
	_draw_text(font, Vector2(left + 12.0, top + 46.0), "Forge 造球 %.0f%%" % (forge_ratio * 100.0), 11, COLOR_MUTED)
	_draw_bar(Rect2(left + 12.0, top + 52.0, bar_width, 8.0), forge_ratio, COLOR_LAUNCH)
	_draw_text(font, Vector2(left + width - bar_width - 12.0, top + 46.0), "Launcher 发射 %.0f%%" % (launcher_ratio * 100.0), 11, COLOR_MUTED)
	_draw_bar(Rect2(left + width - bar_width - 12.0, top + 52.0, bar_width, 8.0), launcher_ratio, COLOR_TUNING)

	var pool_rect := Rect2(left + 12.0, top + 72.0, width - 24.0, 76.0)
	draw_rect(pool_rect, COLOR_BG, true)
	draw_rect(pool_rect, COLOR_TRIM, false, 1.5)
	_draw_text(font, pool_rect.position + Vector2(12.0, 22.0), "Pool 球仓", 13, COLOR_TEXT)
	if _targets_pool():
		draw_rect(pool_rect.grow(3.0), COLOR_COUNTER_TARGET, false, 3.0)
		_draw_text(font, pool_rect.position + Vector2(pool_rect.size.x - 82.0, 22.0), "反制目标", 12, COLOR_COUNTER_TARGET)

	var slot_gap := 12.0
	var visible_capacity: int = maxi(1, pool_capacity)
	var total_slot_width := float(visible_capacity) * POOL_BALL_RADIUS * 2.0 + float(visible_capacity - 1) * slot_gap
	var pool_left := pool_rect.position.x + maxf(0.0, (pool_rect.size.x - total_slot_width) * 0.5)
	var pool_y := pool_rect.position.y + 52.0
	var first_ball_x := pool_left + POOL_BALL_RADIUS
	var last_ball_x := first_ball_x + float(visible_capacity - 1) * (POOL_BALL_RADIUS * 2.0 + slot_gap)

	draw_line(Vector2(pool_rect.position.x + 18.0, pool_y), Vector2(first_ball_x - POOL_BALL_RING_RADIUS - 10.0, pool_y), COLOR_LAUNCH, 3.0, true)
	draw_line(Vector2(last_ball_x + POOL_BALL_RING_RADIUS + 10.0, pool_y), Vector2(pool_rect.end.x - 18.0, pool_y), COLOR_TUNING, 3.0, true)
	for index: int in range(visible_capacity):
		var center := Vector2(first_ball_x + float(index) * (POOL_BALL_RADIUS * 2.0 + slot_gap), pool_y)
		var filled := index < pool_count
		var kind := String(pool_balls[index]) if index < pool_balls.size() else ""
		draw_circle(center, POOL_BALL_RING_RADIUS, COLOR_TRIM)
		if filled and kind == "junk":
			draw_circle(center, POOL_BALL_RADIUS, Color("#6f5f35"))
			draw_line(center + Vector2(-9.0, -9.0), center + Vector2(9.0, 9.0), COLOR_ACTIVE, 2.0, true)
			draw_line(center + Vector2(9.0, -9.0), center + Vector2(-9.0, 9.0), COLOR_ACTIVE, 2.0, true)
		else:
			draw_circle(center, POOL_BALL_RADIUS, COLOR_LAUNCH if filled else COLOR_PANEL)
		if filled:
			draw_arc(center, POOL_BALL_RING_RADIUS + 3.0, 0.0, TAU, 24, COLOR_ACTIVE, 2.0, true)

func _draw_machine_boards(rect: Rect2) -> void:
	var board_top := rect.position.y + SUPPLY_STRIP_HEIGHT + 32.0
	var board_gap := 12.0
	var queue_height := 64.0
	var available_height := rect.size.y - board_top - queue_height - board_gap * 2.0 - 18.0
	var board_height := maxf(96.0, available_height / 3.0)
	var board_rect := Rect2(rect.position.x + 14.0, board_top, rect.size.x - 28.0, board_height)

	_draw_board(board_rect, "Launch", String(BOARD_SUBTITLES["Launch"]), COLOR_LAUNCH, active_board_index == 0, _targets_pool())
	_draw_launch_slots(board_rect)

	board_rect.position.y += board_height + board_gap
	_draw_board(board_rect, "Tuning", String(BOARD_SUBTITLES["Tuning"]), COLOR_TUNING, active_board_index == 1, _targets_echo())
	_draw_tuning_slots(board_rect)

	board_rect.position.y += board_height + board_gap
	_draw_board(board_rect, "Unit", String(BOARD_SUBTITLES["Unit"]), COLOR_UNIT, active_board_index == 2, _targets_unit_or_queue())
	_draw_unit_slots(board_rect)

func _ensure_physics_board() -> void:
	clip_contents = true
	if physics_clip == null or not is_instance_valid(physics_clip):
		physics_clip = Control.new()
		physics_clip.name = "PhysicsStageClip"
		physics_clip.clip_contents = true
		physics_clip.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		physics_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		physics_clip.z_index = 4
		add_child(physics_clip)
	if physics_board != null and is_instance_valid(physics_board):
		return
	physics_board = MachinePhysicsBoardViewScript.new() as MachinePhysicsBoardView
	physics_board.name = "MachinePhysicsBoardView"
	physics_board.position = Vector2.ZERO
	physics_clip.add_child(physics_board)
	if not physics_board.landing_resolved.is_connected(_on_physics_board_landing_resolved):
		physics_board.landing_resolved.connect(_on_physics_board_landing_resolved)
	_layout_physics_board()

func _layout_physics_board() -> void:
	if physics_board == null or not is_instance_valid(physics_board):
		return
	var current_size: Vector2 = _stable_layout_size()
	_update_physics_clip_for_size(current_size)
	if current_size.is_equal_approx(_last_physics_layout_size):
		_update_exposure_contract_from_physics_board()
		return
	_last_physics_layout_size = current_size
	physics_board.set_stage_rects(_stage_rects_for_size(current_size))
	_update_exposure_contract_from_physics_board()

func _update_exposure_contract_from_physics_board() -> void:
	if physics_board == null or not is_instance_valid(physics_board):
		return
	var board_contract: Dictionary = physics_board.get_runtime_contract()
	_apply_exposure_contract(board_contract)

func _apply_exposure_contract(board_contract: Dictionary) -> void:
	exposure_gate_snapshot = (board_contract.get("exposure_gate_snapshot", {}) as Dictionary).duplicate(true)
	blocked_bounce_count = int(board_contract.get("blocked_bounce_count", 0))
	var bounce_variant: Variant = board_contract.get("last_blocked_bounce", {})
	if bounce_variant is Dictionary:
		last_blocked_bounce = (bounce_variant as Dictionary).duplicate(true)
	else:
		last_blocked_bounce = {}
	has_unit_gate_blockers = bool(board_contract.get("has_unit_gate_blockers", false))

func _stage_rects_for_current_size() -> Dictionary:
	return _stage_rects_for_size(_stable_layout_size())

func _stable_layout_size() -> Vector2:
	var current_size: Vector2 = size
	if current_size.x <= 0.0 or current_size.y <= 0.0:
		current_size = MIN_VIEW_SIZE
	return current_size

func _stage_rects_for_size(current_size: Vector2) -> Dictionary:
	var rect := Rect2(Vector2.ZERO, current_size)
	var board_top := rect.position.y + SUPPLY_STRIP_HEIGHT + 32.0
	var board_gap := 12.0
	var queue_height := 64.0
	var available_height := rect.size.y - board_top - queue_height - board_gap * 2.0 - 18.0
	var board_height := maxf(96.0, available_height / 3.0)
	var board_rect := Rect2(rect.position.x + 14.0, board_top, rect.size.x - 28.0, board_height)
	return {
		"Launch": board_rect,
		"Tuning": Rect2(board_rect.position + Vector2(0.0, board_height + board_gap), board_rect.size),
		"Unit": Rect2(board_rect.position + Vector2(0.0, (board_height + board_gap) * 2.0), board_rect.size),
	}

func _update_physics_clip_for_size(current_size: Vector2) -> void:
	if physics_clip == null or not is_instance_valid(physics_clip):
		return
	var clip_rect: Rect2 = _physics_clip_rect_for_size(current_size)
	physics_clip.position = clip_rect.position
	physics_clip.size = clip_rect.size
	if physics_board != null and is_instance_valid(physics_board):
		physics_board.position = -clip_rect.position

func _current_physics_clip_rect() -> Rect2:
	if physics_clip == null or not is_instance_valid(physics_clip):
		return Rect2()
	return Rect2(physics_clip.position, physics_clip.size)

func _physics_clip_rect_for_size(current_size: Vector2) -> Rect2:
	var stage_rects: Dictionary = _stage_rects_for_size(current_size)
	var clip_rect: Rect2 = stage_rects["Launch"] as Rect2
	clip_rect = clip_rect.merge(stage_rects["Tuning"] as Rect2)
	clip_rect = clip_rect.merge(stage_rects["Unit"] as Rect2)
	return clip_rect

func _on_physics_board_landing_resolved(result: MachinePhysicsResult) -> void:
	physics_landing_count += 1
	last_physics_result = result.to_dictionary()
	landing_resolved.emit(result)

func _draw_board(board_rect: Rect2, title: String, subtitle: String, accent: Color, is_active: bool, is_counter_target: bool = false) -> void:
	var font := get_theme_default_font()
	var border_width := 3.5 if is_counter_target else (3.0 if is_active else 1.5)
	draw_rect(board_rect, COLOR_PANEL, true)
	draw_rect(board_rect, COLOR_COUNTER_TARGET if is_counter_target else (accent if is_active else COLOR_TRIM), false, border_width)
	_draw_text(font, board_rect.position + Vector2(10.0, 18.0), title, 15, accent)
	_draw_text(font, board_rect.position + Vector2(90.0, 18.0), subtitle, 12, COLOR_MUTED)
	if is_counter_target:
		_draw_text(font, board_rect.position + Vector2(board_rect.size.x - 82.0, 18.0), "反制目标", 12, COLOR_COUNTER_TARGET)

func _draw_launch_slots(board_rect: Rect2) -> void:
	_draw_result_slots(board_rect, "Launch", LAUNCH_SLOT_ORDER, COLOR_LAUNCH, last_launch_result)

func _draw_tuning_slots(board_rect: Rect2) -> void:
	_draw_result_slots(board_rect, "Tuning", TUNING_SLOT_ORDER, COLOR_TUNING, last_tuning_result, "Echo" if _targets_echo() else "")
	if String(last_physics_result.get("feedback_state", "")) == "Forced Redirect":
		var font := get_theme_default_font()
		var rail_start := board_rect.position + Vector2(board_rect.size.x * 0.32, 42.0)
		var rail_end := board_rect.position + Vector2(board_rect.size.x * 0.68, 42.0)
		draw_line(rail_start, rail_end, COLOR_ACTIVE, 3.0, true)
		_draw_text(font, rail_start + Vector2(8.0, -6.0), "强制导轨", 10, COLOR_ACTIVE)

func _draw_result_slots(board_rect: Rect2, stage: String, labels: Array[String], accent: Color, active_label: String, counter_target_label: String = "") -> void:
	var font := get_theme_default_font()
	var gap := 6.0
	var total_gap: float = gap * float(maxi(0, labels.size() - 1))
	var usable_width: float = maxf(32.0, board_rect.size.x - 20.0 - total_gap)
	var total_weight: float = 0.0
	for label: String in labels:
		total_weight += _schematic_slot_weight_for_label(stage, label)
	var cursor_x: float = board_rect.position.x + 10.0
	var slot_y := board_rect.position.y + board_rect.size.y - 28.0
	for index: int in range(labels.size()):
		var label := labels[index]
		var slot_width: float = usable_width * (_schematic_slot_weight_for_label(stage, label) / maxf(total_weight, 0.001))
		var slot_rect := Rect2(cursor_x, slot_y, slot_width, 20.0)
		var is_active := active_label == label or (label == "Tuning" and active_label == "Tuning")
		var is_counter_target := counter_target_label == label
		draw_rect(slot_rect, accent.darkened(0.25) if is_active else COLOR_BG, true)
		draw_rect(slot_rect, COLOR_COUNTER_TARGET if is_counter_target else (accent if is_active else COLOR_TRIM), false, 2.0 if is_counter_target else 1.0)
		_draw_result_slot_shape_token(slot_rect, label, accent, is_active)
		var text_x: float = 20.0 if _has_tuning_slot_shape(label) else 4.0
		_draw_text(font, slot_rect.position + Vector2(text_x, 14.0), _slot_display_label(label), 10, COLOR_TEXT)
		cursor_x += slot_width + gap

func _draw_result_slot_shape_token(slot_rect: Rect2, label: String, accent: Color, is_active: bool) -> void:
	if not _has_tuning_slot_shape(label):
		return
	var color: Color = COLOR_ACTIVE if is_active else accent
	var center := slot_rect.position + Vector2(10.0, slot_rect.size.y * 0.5)
	match label:
		"Gate":
			draw_line(center + Vector2(-5.0, -6.0), center + Vector2(-5.0, 6.0), color, 1.8, true)
			draw_line(center + Vector2(4.0, -6.0), center + Vector2(4.0, 6.0), color, 1.8, true)
			draw_line(center + Vector2(-5.0, -6.0), center + Vector2(4.0, -6.0), color, 1.8, true)
		"Prime":
			draw_circle(center, 4.4, color)
			draw_line(center + Vector2(-7.0, 0.0), center + Vector2(7.0, 0.0), color.darkened(0.2), 1.2, true)
			draw_line(center + Vector2(0.0, -7.0), center + Vector2(0.0, 7.0), color.darkened(0.2), 1.2, true)
		"Echo":
			draw_circle(center + Vector2(-3.2, 0.0), 3.2, color)
			draw_circle(center + Vector2(3.2, 0.0), 3.2, color.darkened(0.22))
		"Surge":
			draw_line(center + Vector2(-7.0, 4.0), center + Vector2(-2.0, -5.0), color, 1.8, true)
			draw_line(center + Vector2(-2.0, -5.0), center + Vector2(2.0, 5.0), color, 1.8, true)
			draw_line(center + Vector2(2.0, 5.0), center + Vector2(7.0, -4.0), color, 1.8, true)

func _has_tuning_slot_shape(label: String) -> bool:
	return ["Gate", "Prime", "Echo", "Surge"].has(label)

func _tuning_slot_shape_tokens() -> Dictionary:
	return {
		"Gate": "wide_entry",
		"Prime": "charge_core",
		"Echo": "double_hit",
		"Surge": "pulse_wave",
	}

func _schematic_slot_width_ratio_snapshot() -> Dictionary:
	return {
		"Launch": _schematic_slot_ratios_for_labels("Launch", LAUNCH_SLOT_ORDER),
		"Tuning": _schematic_slot_ratios_for_labels("Tuning", TUNING_SLOT_ORDER),
		"Unit": _schematic_slot_ratios_for_labels("Unit", UNIT_SLOT_ORDER),
	}

func _schematic_slot_order_snapshot() -> Dictionary:
	return {
		"Launch": LAUNCH_SLOT_ORDER.duplicate(),
		"Tuning": TUNING_SLOT_ORDER.duplicate(),
		"Unit": UNIT_SLOT_ORDER.duplicate(),
	}

func _board_subtitle_snapshot() -> Dictionary:
	return BOARD_SUBTITLES.duplicate()

func _schematic_slot_ratios_for_labels(stage: String, labels: Array[String]) -> Dictionary:
	var total_weight: float = 0.0
	for label: String in labels:
		total_weight += _schematic_slot_weight_for_label(stage, label)
	var ratios: Dictionary = {}
	for label: String in labels:
		ratios[label] = _schematic_slot_weight_for_label(stage, label) / maxf(total_weight, 0.001)
	return ratios

func _schematic_slot_weight_for_label(stage: String, label: String) -> float:
	if stage == "Launch":
		match label:
			"Tuning":
				return 0.65
			"Split", "Recycle":
				return 0.15
			"Waste":
				return 0.05
			_:
				return 1.0
	if stage == "Tuning":
		match label:
			"Gate":
				return 0.55
			"Prime", "Echo", "Surge":
				return 0.15
			_:
				return 1.0
	return 1.0

func _slot_display_label(label: String) -> String:
	match label:
		"Split":
			return "分流"
		"Recycle":
			return "回流"
		"Waste":
			return "废弃"
		_:
			return label

func _draw_unit_slots(board_rect: Rect2) -> void:
	var font := get_theme_default_font()
	var gap := 8.0
	var slot_width := (board_rect.size.x - 20.0 - gap * 3.0) / 4.0
	var slot_y := board_rect.position.y + board_rect.size.y - 31.0
	if not last_blocked_bounce.is_empty():
		var blocked_slot_id: int = int(last_blocked_bounce.get("slot_id", 0))
		var target_slot_id: int = int(last_blocked_bounce.get("target_slot_id", 0))
		var bounce_message: String = String(last_blocked_bounce.get("message", ""))
		if bounce_message.is_empty():
			bounce_message = "Unit：S%d 暴露闸门挡开，球转向 S%d" % [blocked_slot_id, target_slot_id]
		_draw_text(font, board_rect.position + Vector2(10.0, 39.0), bounce_message, 10, COLOR_COUNTER_TARGET)
	for slot_id: int in range(1, 5):
		var progress: int = int(slot_progress.get(slot_id, 0))
		var required: int = int(SLOT_REQUIREMENTS[slot_id])
		var ratio := clampf(float(progress) / float(required), 0.0, 1.0)
		var exposure_info: Dictionary = _exposure_slot_info(slot_id)
		var exposure_ratio: float = clampf(float(exposure_info.get("ratio", 1.0 if slot_id == 1 else 0.0)), 0.0, 1.0)
		var is_open: bool = bool(exposure_info.get("open", exposure_ratio > 0.0))
		var is_fully_exposed: bool = bool(exposure_info.get("fully_exposed", exposure_ratio >= 1.0))
		var slot_rect := Rect2(board_rect.position.x + 10.0 + float(slot_id - 1) * (slot_width + gap), slot_y, slot_width, 23.0)
		draw_rect(slot_rect, COLOR_BG, true)
		draw_rect(Rect2(slot_rect.position, Vector2(slot_rect.size.x * ratio, slot_rect.size.y)), COLOR_UNIT.darkened(0.2), true)
		if exposure_ratio < 1.0:
			var closed_rect := Rect2(
				slot_rect.position + Vector2(slot_rect.size.x * exposure_ratio, 0.0),
				Vector2(slot_rect.size.x * (1.0 - exposure_ratio), slot_rect.size.y)
			)
			draw_rect(closed_rect, Color("#443848"), true)
			draw_rect(closed_rect, COLOR_MUTED, false, 1.0)
			if exposure_ratio > 0.0:
				var gate_x: float = slot_rect.position.x + slot_rect.size.x * exposure_ratio
				draw_line(Vector2(gate_x, slot_rect.position.y), Vector2(gate_x, slot_rect.end.y), COLOR_ACTIVE, 1.5, true)
		draw_rect(slot_rect, COLOR_UNIT, false, 1.0)
		var gate_text: String = "已开" if is_fully_exposed else ("开%.0f%%" % (exposure_ratio * 100.0) if is_open else "未开")
		_draw_text(font, slot_rect.position + Vector2(4.0, 15.0), "S%d %s %d/%d" % [slot_id, gate_text, progress, required], 9, COLOR_TEXT)

func _draw_queue_preview(rect: Rect2) -> void:
	var font := get_theme_default_font()
	var left := rect.position.x + 14.0
	var bottom := rect.position.y + rect.size.y - 54.0
	var width := rect.size.x - 28.0
	_draw_text(font, Vector2(left, bottom), "队列预览", 14, COLOR_QUEUE)
	for index: int in range(QUEUE_PREVIEW_COUNT):
		var item_rect := Rect2(left + 78.0 + float(index) * 58.0, bottom - 15.0, 46.0, 24.0)
		var filled := index < queue_count
		draw_rect(item_rect, COLOR_QUEUE.darkened(0.25) if filled else COLOR_PANEL, true)
		draw_rect(item_rect, COLOR_QUEUE if filled else COLOR_TRIM, false, 1.0)
		_draw_text(font, item_rect.position + Vector2(8.0, 16.0), "单位" if filled else "空", 10, COLOR_TEXT if filled else COLOR_MUTED)
	if not last_queue_unit.is_empty():
		_draw_text(font, Vector2(left + width - 150.0, bottom + 1.0), "最近入队：%s" % _unit_name(last_queue_unit), 11, COLOR_TEXT)
	if _targets_unit_or_queue():
		draw_rect(Rect2(left + 74.0, bottom - 19.0, 180.0, 32.0), COLOR_COUNTER_TARGET, false, 2.0)

func _targets_pool() -> bool:
	return counter_target_component.contains("Pool")

func _targets_echo() -> bool:
	return counter_target_component.contains("Echo")

func _targets_unit_or_queue() -> bool:
	return counter_target_component.contains("Unit") or counter_target_component.contains("Queue")

func _draw_bar(bar_rect: Rect2, ratio: float, fill_color: Color) -> void:
	draw_rect(bar_rect, COLOR_PANEL, true)
	draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * ratio, bar_rect.size.y)), fill_color, true)
	draw_rect(bar_rect, COLOR_TRIM, false, 1.0)

func _draw_text(font: Font, draw_position: Vector2, text: String, font_size: int, color: Color) -> void:
	if font == null:
		return
	draw_string(font, draw_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)

func _active_board_from_ratio(ratio: float) -> int:
	if pool_count <= 0 and ratio < 0.15:
		return 0
	if ratio < 0.34:
		return 0
	if ratio < 0.67:
		return 1
	return 2

func _machine_pool_capacity(machine) -> int:
	if machine.has_method("get_pool_capacity"):
		return maxi(1, int(machine.call("get_pool_capacity")))

	var capacity_value: Variant = machine.get("pool_capacity")
	if capacity_value != null:
		return maxi(1, int(capacity_value))
	return 5

func _update_recent_results(event_log: Array[String]) -> void:
	last_launch_result = ""
	last_tuning_result = ""
	last_queue_unit = ""
	for index: int in range(event_log.size() - 1, -1, -1):
		var log_line: String = event_log[index]
		if last_queue_unit.is_empty() and log_line.begins_with("Unit:QueueEntry"):
			last_queue_unit = _extract_unit_id(log_line)
		if last_tuning_result.is_empty() and log_line.begins_with("Tuning:"):
			last_tuning_result = log_line.get_slice(":", 1).get_slice(" ", 0)
		if last_launch_result.is_empty() and log_line.begins_with("Launch:"):
			last_launch_result = log_line.get_slice(":", 1).get_slice(" ", 0)
		if not last_queue_unit.is_empty() and not last_tuning_result.is_empty() and not last_launch_result.is_empty():
			return

func _extract_unit_id(log_line: String) -> String:
	var marker := "\"unit_id\": \""
	var start := log_line.find(marker)
	if start == -1:
		return ""
	start += marker.length()
	var end := log_line.find("\"", start)
	if end == -1:
		return ""
	return log_line.substr(start, end - start)

func _unit_name(unit_id: String) -> String:
	match unit_id:
		"hive_short_fang":
			return "短牙"
		"hive_shield_shell":
			return "盾壳"
		"hive_acid_sac":
			return "酸囊"
		"hive_crush_shell_beast":
			return "碾壳兽"
		_:
			return "未知单位"

func _exposure_slot_info(slot_id: int) -> Dictionary:
	var slots_variant: Variant = exposure_gate_snapshot.get("slots", {})
	if not (slots_variant is Dictionary):
		return {}
	var slots: Dictionary = slots_variant as Dictionary
	if slots.has(slot_id) and slots[slot_id] is Dictionary:
		return (slots[slot_id] as Dictionary).duplicate(true)
	var slot_key: String = str(slot_id)
	if slots.has(slot_key) and slots[slot_key] is Dictionary:
		return (slots[slot_key] as Dictionary).duplicate(true)
	return {}
