extends RefCounted

const BattleClock = preload("res://scripts/systems/battle_clock.gd")
const PresetDefs = preload("res://scripts/model/preset_defs.gd")

const STATE_IDLE := "idle"
const STATE_BATTLE_RUNNING := "battle_running"
const STATE_RESULT_PENDING := "result_pending"
const STATE_RESULT_RECORDED := "result_recorded"
const STATE_COMPLETE := "complete"

var state := STATE_IDLE

var _order: Array[String] = []
var _battle_index := -1
var _clock: BattleClock

func start_internal_order() -> void:
	_start_with_order(PresetDefs.all_preset_ids())

func start_playtest_order(seed_value: int) -> void:
	var order := PresetDefs.all_preset_ids()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in range(order.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, i)
		var previous := order[i]
		order[i] = order[swap_index]
		order[swap_index] = previous
	_start_with_order(order)

func get_order() -> Array[String]:
	return _order.duplicate()

func current_preset_id() -> String:
	if _battle_index < 0 or _battle_index >= _order.size():
		return ""
	return _order[_battle_index]

func tick(delta_seconds: float) -> void:
	if state != STATE_BATTLE_RUNNING:
		return
	_clock.tick(delta_seconds)
	if _clock.is_complete():
		state = STATE_RESULT_PENDING

func complete_result() -> void:
	if state != STATE_RESULT_PENDING:
		return
	state = STATE_RESULT_RECORDED
	_battle_index += 1
	if _battle_index >= _order.size():
		state = STATE_COMPLETE
		_clock = null
	else:
		_start_current_battle()

func _start_with_order(order: Array[String]) -> void:
	_order = order.duplicate()
	_battle_index = 0
	_start_current_battle()

func _start_current_battle() -> void:
	var preset := PresetDefs.get_preset(current_preset_id())
	_clock = BattleClock.new(preset.get("battle_duration_seconds", 75.0))
	_clock.start()
	state = STATE_BATTLE_RUNNING

