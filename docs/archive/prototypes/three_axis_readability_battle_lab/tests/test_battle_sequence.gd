extends RefCounted

const BattleClock = preload("res://scripts/systems/battle_clock.gd")
const BattleSequence = preload("res://scripts/systems/battle_sequence.gd")

func test_default_internal_order_is_exact() -> bool:
	var sequence = BattleSequence.new()
	sequence.start_internal_order()
	return _assert_array_equals(
		sequence.get_order(),
		["launch_flood", "tuning_echo", "unit_queue_burst"],
		"default order"
	)

func test_seeded_playtest_order_contains_each_preset_once() -> bool:
	var sequence_a = BattleSequence.new()
	var sequence_b = BattleSequence.new()
	sequence_a.start_playtest_order(10603)
	sequence_b.start_playtest_order(10603)

	if not _assert_array_equals(sequence_a.get_order(), sequence_b.get_order(), "seeded order repeatability"):
		return false

	var sorted_order := sequence_a.get_order()
	sorted_order.sort()
	return _assert_array_equals(
		sorted_order,
		["launch_flood", "tuning_echo", "unit_queue_burst"],
		"seeded order membership"
	)

func test_clock_starts_at_zero_and_ends_at_75() -> bool:
	var clock = BattleClock.new(75.0)
	clock.start()
	if not is_equal_approx(clock.time_seconds, 0.0):
		push_error("clock should start at 0.0, got %s" % clock.time_seconds)
		return false
	if clock.is_complete():
		push_error("clock should not be complete immediately after start")
		return false

	clock.tick(74.9)
	if clock.is_complete():
		push_error("clock should not complete before 75 seconds")
		return false

	clock.tick(0.1)
	if not clock.is_complete():
		push_error("clock should complete at 75 seconds")
		return false
	if not is_equal_approx(clock.time_seconds, 75.0):
		push_error("clock should clamp to 75.0, got %s" % clock.time_seconds)
		return false
	return true

func test_sequence_enters_result_after_battle_end() -> bool:
	var sequence = BattleSequence.new()
	sequence.start_internal_order()
	if sequence.state != BattleSequence.STATE_BATTLE_RUNNING:
		push_error("sequence should start in battle_running, got %s" % sequence.state)
		return false

	sequence.tick(75.0)
	if sequence.state != BattleSequence.STATE_RESULT_PENDING:
		push_error("sequence should enter result_pending after battle end, got %s" % sequence.state)
		return false
	if sequence.current_preset_id() != "launch_flood":
		push_error("result should still refer to completed battle")
		return false
	return true

func test_sequence_completes_after_three_recorded_results() -> bool:
	var sequence = BattleSequence.new()
	sequence.start_internal_order()

	for expected_preset in ["launch_flood", "tuning_echo", "unit_queue_burst"]:
		if sequence.current_preset_id() != expected_preset:
			push_error("expected current preset %s, got %s" % [expected_preset, sequence.current_preset_id()])
			return false
		sequence.tick(75.0)
		if sequence.state != BattleSequence.STATE_RESULT_PENDING:
			push_error("expected result_pending for %s" % expected_preset)
			return false
		sequence.complete_result()

	if sequence.state != BattleSequence.STATE_COMPLETE:
		push_error("sequence should complete after three result flows, got %s" % sequence.state)
		return false
	return true

func _assert_array_equals(actual: Array, expected: Array, label: String) -> bool:
	if actual.size() != expected.size():
		push_error("%s expected size %d, got %d: %s" % [label, expected.size(), actual.size(), actual])
		return false
	for i in range(expected.size()):
		if actual[i] != expected[i]:
			push_error("%s expected %s, got %s" % [label, expected, actual])
			return false
	return true
