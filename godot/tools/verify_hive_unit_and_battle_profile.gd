extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_verify_hive_unit_values()
	_verify_hive_attack_profile_resolution()
	_verify_battle_duration_profile()
	_finish()

func _verify_hive_unit_values() -> void:
	var catalog: Dictionary = BattleUnitDefinition.catalog()
	_expect_unit(catalog, "hive_short_fang", 6, 1, 0.7, 1.5, 10.0)
	_expect_unit(catalog, "hive_shield_shell", 18, 2, 1.4, 1.5, 6.0)
	_expect_unit(catalog, "hive_acid_sac", 8, 3, 1.8, 7.0, 7.0)
	_expect_unit(catalog, "hive_crush_shell_beast", 26, 6, 2.6, 2.0, 5.0)
	_expect_unit(catalog, "enemy_grunt", 10, 2, 1.0, 3.0, 7.0)
	_expect_unit(catalog, "enemy_raider", 7, 1, 0.7, 2.5, 10.0)
	_expect_unit(catalog, "enemy_brute", 24, 4, 1.4, 3.0, 5.0)
	_verify_hive_special_behavior_values(catalog)

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

func _verify_hive_special_behavior_values(catalog: Dictionary) -> void:
	var acid_sac: Object = _catalog_unit(catalog, "hive_acid_sac")
	if acid_sac != null:
		_expect_string_property_any(acid_sac, "hive_acid_sac", ["attack_profile", "attack_behavior", "behavior_profile"], "acid_projectile")
		_expect_float_property(acid_sac, "hive_acid_sac", "projectile_speed", 14.0)
		_expect_float_property(acid_sac, "hive_acid_sac", "splash_radius", 2.5)
		_expect_int_property(acid_sac, "hive_acid_sac", "max_splash_targets", 2)
		_expect_bool_property_any(acid_sac, "hive_acid_sac", ["can_hit_cross_lane", "cross_lane_enabled"], false)
		_expect_bool_property_any(acid_sac, "hive_acid_sac", ["acid_dot_enabled", "has_dot", "damage_over_time_enabled"], false)
		_expect_bool_property_any(acid_sac, "hive_acid_sac", ["acid_pool_enabled", "leaves_acid_pool", "creates_acid_pool"], false)

	var crush_shell: Object = _catalog_unit(catalog, "hive_crush_shell_beast")
	if crush_shell != null:
		_expect_string_property_any(crush_shell, "hive_crush_shell_beast", ["attack_profile", "attack_behavior", "behavior_profile"], "lane_sweep")
		_expect_float_property(crush_shell, "hive_crush_shell_beast", "sweep_radius", 3.5)
		_expect_int_property(crush_shell, "hive_crush_shell_beast", "max_sweep_targets", 3)
		_expect_bool_property_any(crush_shell, "hive_crush_shell_beast", ["can_hit_cross_lane", "cross_lane_enabled"], false)

	var shield_shell: Object = _catalog_unit(catalog, "hive_shield_shell")
	if shield_shell != null:
		_expect_optional_false_flag_any(shield_shell, "hive_shield_shell", ["has_taunt", "taunt_enabled"])
		_expect_optional_false_flag_any(shield_shell, "hive_shield_shell", ["has_aura", "aura_enabled"])
		_expect_optional_false_flag_any(shield_shell, "hive_shield_shell", ["has_hidden_behavior", "hidden_behavior_enabled"])

func _verify_hive_attack_profile_resolution() -> void:
	_verify_acid_projectile_resolution()
	_verify_crush_sweep_resolution()

func _verify_acid_projectile_resolution() -> void:
	var battlefield := BattlefieldState.new()
	battlefield.configure(1, false, 100)
	battlefield.wave.enemy_spawns = []
	battlefield.deploy_player_queue_entry("Left", {
		"unit_id": "hive_acid_sac",
		"slot_id": 3,
		"source": "Verifier",
		"count": 1,
	})
	var acid_sac: BattleEntityState = _find_entity(battlefield, "hive_acid_sac", BattleUnitDefinition.SIDE_PLAYER)
	if acid_sac == null:
		failures.append("Acid Sac behavior test could not create a player entity.")
		return
	acid_sac.position = 20.0
	battlefield.spawn_base_intruder_for_verifier("enemy_grunt", "Left", 23.0)
	battlefield.spawn_base_intruder_for_verifier("enemy_grunt", "Left", 24.0)
	battlefield.spawn_base_intruder_for_verifier("enemy_grunt", "Left", 25.0)
	battlefield.advance(0.1)
	var damaged_enemies: Array[BattleEntityState] = _damaged_enemy_entities(battlefield)
	if damaged_enemies.size() < 3:
		failures.append("Acid Sac acid_projectile must damage main target plus two same-lane splash targets.")
	if _count_enemy_damage_at_least(damaged_enemies, 3) < 1:
		failures.append("Acid Sac acid_projectile must deal 3 damage to the main target.")
	if _count_enemy_damage_at_least(damaged_enemies, 1) < 3:
		failures.append("Acid Sac acid_projectile splash must deal 1 damage to two additional targets.")

func _verify_crush_sweep_resolution() -> void:
	var battlefield := BattlefieldState.new()
	battlefield.configure(1, false, 100)
	battlefield.wave.enemy_spawns = []
	battlefield.deploy_player_queue_entry("Left", {
		"unit_id": "hive_crush_shell_beast",
		"slot_id": 4,
		"source": "Verifier",
		"count": 1,
	})
	var crush_shell: BattleEntityState = _find_entity(battlefield, "hive_crush_shell_beast", BattleUnitDefinition.SIDE_PLAYER)
	if crush_shell == null:
		failures.append("Crush Shell Beast behavior test could not create a player entity.")
		return
	crush_shell.position = 20.0
	battlefield.spawn_base_intruder_for_verifier("enemy_grunt", "Left", 21.0)
	battlefield.spawn_base_intruder_for_verifier("enemy_grunt", "Left", 22.0)
	battlefield.spawn_base_intruder_for_verifier("enemy_grunt", "Left", 24.0)
	battlefield.spawn_base_intruder_for_verifier("enemy_grunt", "Left", 28.0)
	battlefield.advance(0.1)
	var damaged_enemies: Array[BattleEntityState] = _damaged_enemy_entities(battlefield)
	if _count_enemy_damage_at_least(damaged_enemies, 6) != 3:
		failures.append("Crush Shell Beast lane_sweep must deal 6 damage to exactly three same-lane targets.")

func _catalog_unit(catalog: Dictionary, unit_id: String) -> Object:
	if not catalog.has(unit_id):
		failures.append("BattleUnitDefinition.catalog() missing %s." % unit_id)
		return null
	var unit: Object = catalog[unit_id] as Object
	if unit == null:
		failures.append("%s must be a BattleUnitDefinition object." % unit_id)
	return unit

func _find_entity(battlefield: BattlefieldState, unit_id: String, side: String) -> BattleEntityState:
	for entity: BattleEntityState in battlefield.entities:
		if entity.definition != null and entity.definition.id == unit_id and entity.side == side:
			return entity
	return null

func _damaged_enemy_entities(battlefield: BattlefieldState) -> Array[BattleEntityState]:
	var damaged: Array[BattleEntityState] = []
	for entity: BattleEntityState in battlefield.entities:
		if entity.definition == null or entity.side != BattleUnitDefinition.SIDE_ENEMY:
			continue
		if entity.hp < entity.definition.max_hp:
			damaged.append(entity)
	return damaged

func _count_enemy_damage_at_least(entities: Array[BattleEntityState], damage: int) -> int:
	var count: int = 0
	for entity: BattleEntityState in entities:
		if entity.definition == null:
			continue
		if entity.definition.max_hp - entity.hp >= damage:
			count += 1
	return count

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

func _expect_string_property_any(object: Object, object_id: String, property_names: Array[String], expected: String) -> void:
	for property_name: String in property_names:
		if _has_property(object, property_name):
			var actual: String = String(object.get(property_name))
			if actual != expected:
				failures.append("%s.%s expected %s, got %s." % [object_id, property_name, expected, actual])
			return
	failures.append("%s missing one of equivalent properties: %s." % [object_id, ", ".join(property_names)])

func _expect_bool_property_any(object: Object, object_id: String, property_names: Array[String], expected: bool) -> void:
	for property_name: String in property_names:
		if _has_property(object, property_name):
			var actual: bool = bool(object.get(property_name))
			if actual != expected:
				failures.append("%s.%s expected %s." % [object_id, property_name, str(expected)])
			return
	failures.append("%s missing one of equivalent guardrail properties: %s." % [object_id, ", ".join(property_names)])

func _expect_optional_false_flag_any(object: Object, object_id: String, property_names: Array[String]) -> void:
	for property_name: String in property_names:
		if _has_property(object, property_name) and bool(object.get(property_name)):
			failures.append("%s.%s must be false; Shield Shell should not hide taunt/aura/extra behavior." % [object_id, property_name])

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
