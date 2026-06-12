extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_verify_hive_unit_values()
	_verify_battle_duration_profile()
	_finish()

func _verify_hive_unit_values() -> void:
	var catalog: Dictionary = BattleUnitDefinition.catalog()
	_expect_unit(catalog, "hive_short_fang", 6, 1, 0.7, 1.5, 10.0)
	_expect_unit(catalog, "hive_shield_shell", 18, 2, 1.4, 1.5, 6.0)
	_expect_unit(catalog, "hive_acid_sac", 8, 3, 1.8, 7.0, 7.0)
	_expect_unit(catalog, "hive_crush_shell_beast", 26, 6, 2.6, 2.0, 5.0)

func _verify_battle_duration_profile() -> void:
	_expect_duration(BattleWaveDefinition.make_for_battle(1), 1, 90.0, 110.0)
	_expect_duration(BattleWaveDefinition.make_for_battle(5), 5, 125.0, 150.0)
	_expect_duration(BattleWaveDefinition.make_for_battle(6), 6, 165.0, 195.0)

func _expect_unit(
	catalog: Dictionary,
	unit_id: String,
	expected_hp: int,
	expected_damage: int,
	expected_interval: float,
	expected_range: float,
	expected_speed: float
) -> void:
	if not catalog.has(unit_id):
		failures.append("BattleUnitDefinition.catalog() missing %s." % unit_id)
		return
	var unit: Object = catalog[unit_id] as Object
	if unit == null:
		failures.append("%s must be a BattleUnitDefinition object." % unit_id)
		return

	_expect_int_property(unit, unit_id, "max_hp", expected_hp)
	_expect_int_property(unit, unit_id, "attack_damage", expected_damage)
	_expect_float_property(unit, unit_id, "attack_interval", expected_interval)
	_expect_float_property(unit, unit_id, "attack_range", expected_range)
	_expect_float_property(unit, unit_id, "move_speed", expected_speed)

func _expect_duration(wave: Object, battle_number: int, expected_min: float, expected_max: float) -> void:
	if wave == null:
		failures.append("BattleWaveDefinition.make_for_battle(%d) returned null." % battle_number)
		return
	if not _has_property(wave, "target_duration_min_seconds"):
		failures.append("Battle %d wave missing target_duration_min_seconds." % battle_number)
		return
	if not _has_property(wave, "target_duration_max_seconds"):
		failures.append("Battle %d wave missing target_duration_max_seconds." % battle_number)
		return
	_expect_float_value(
		float(wave.get("target_duration_min_seconds")),
		expected_min,
		"Battle %d target_duration_min_seconds" % battle_number
	)
	_expect_float_value(
		float(wave.get("target_duration_max_seconds")),
		expected_max,
		"Battle %d target_duration_max_seconds" % battle_number
	)

func _expect_int_property(object: Object, object_id: String, property_name: String, expected: int) -> void:
	if not _has_property(object, property_name):
		failures.append("%s missing property %s." % [object_id, property_name])
		return
	var actual: int = int(object.get(property_name))
	if actual != expected:
		failures.append("%s.%s expected %d, got %d." % [object_id, property_name, expected, actual])

func _expect_float_property(object: Object, object_id: String, property_name: String, expected: float) -> void:
	if not _has_property(object, property_name):
		failures.append("%s missing property %s." % [object_id, property_name])
		return
	_expect_float_value(float(object.get(property_name)), expected, "%s.%s" % [object_id, property_name])

func _expect_float_value(actual: float, expected: float, label: String) -> void:
	if absf(actual - expected) > 0.001:
		failures.append("%s expected %.3f, got %.3f." % [label, expected, actual])

func _has_property(object: Object, property_name: String) -> bool:
	for property_info: Dictionary in object.get_property_list():
		if String(property_info.get("name", "")) == property_name:
			return true
	return false

func _finish() -> void:
	if failures.is_empty():
		print("verify_hive_unit_and_battle_profile: PASS")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
