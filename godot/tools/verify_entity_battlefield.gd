extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_verify_selected_lane_spawn()
	_verify_gate_guardian_win_loss()
	_verify_endpoint_sweep_warning()
	_finish()

func _verify_selected_lane_spawn() -> void:
	var battlefield := BattlefieldState.new()
	battlefield.configure(2, false, 100)
	battlefield.deploy_player_queue_entry("Right", {
		"unit_id": "hive_short_fang",
		"slot_id": 1,
		"source": "Verifier",
		"count": 1,
	})
	if battlefield.get_player_units("Right") != 1:
		failures.append("Selected Right lane should receive the deployed player unit.")
	if battlefield.get_player_units("Left") != 0 or battlefield.get_player_units("Mid") != 0:
		failures.append("Deploying to Right should not create units on non-selected lanes.")
	var snapshot: Dictionary = battlefield.get_lane_snapshot("Right")
	var entities: Array = snapshot.get("entities", []) as Array
	if entities.is_empty():
		failures.append("Battlefield snapshot should include live player entity markers.")

func _verify_gate_guardian_win_loss() -> void:
	var win_field := BattlefieldState.new()
	win_field.configure(4, false, 100, 16)
	for _i: int in range(5):
		win_field.deploy_player_queue_entry("Left", {
			"unit_id": "hive_crush_shell_beast",
			"slot_id": 4,
			"source": "Verifier",
			"count": 1,
		})
	for _i: int in range(180):
		win_field.advance(0.25)
		if win_field.get_battle_result() == BattlefieldState.RESULT_WIN:
			break
	if win_field.get_battle_result() != BattlefieldState.RESULT_WIN:
		failures.append("Entity battlefield should support win by damaging Endpoint Guardian HP.")

	var loss_field := BattlefieldState.new()
	loss_field.configure(5, false, 8, 120)
	loss_field.spawn_enemy_raiders("Left", 3, "Verifier pressure")
	for _i: int in range(200):
		loss_field.advance(0.25)
		if loss_field.get_battle_result() == BattlefieldState.RESULT_LOSS:
			break
	if loss_field.get_battle_result() != BattlefieldState.RESULT_LOSS:
		failures.append("Entity battlefield should support loss by Player Guardian HP reaching 0.")

func _verify_endpoint_sweep_warning() -> void:
	var endpoint := BattlefieldState.new()
	endpoint.configure(6, true, 100, 180)
	endpoint.deploy_player_queue_entry("Mid", {
		"unit_id": "hive_short_fang",
		"slot_id": 1,
		"source": "Verifier",
		"count": 2,
	})
	var saw_warning := false
	var saw_damage_after_warning := false
	for _i: int in range(80):
		endpoint.advance(0.25)
		var snapshot: Dictionary = endpoint.get_lane_snapshot("Mid")
		if bool(snapshot.get("sweep_warning", false)):
			saw_warning = true
		if saw_warning:
			var entities: Array = snapshot.get("entities", []) as Array
			for entity_variant: Variant in entities:
				var entity: Dictionary = entity_variant as Dictionary
				if String(entity.get("side", "")) == "player" and int(entity.get("hp", 10)) < 10:
					saw_damage_after_warning = true
	if not saw_warning:
		failures.append("Endpoint should show a sweep warning before sweep damage.")
	if not saw_damage_after_warning:
		failures.append("Endpoint sweep should damage lane-local player units after warning.")

func _finish() -> void:
	if failures.is_empty():
		print("verify_entity_battlefield: PASS")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
