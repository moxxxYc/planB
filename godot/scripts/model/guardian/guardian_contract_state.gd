class_name GuardianContractState
extends RefCounted

const GUARDIAN_VEIN_MOTHER: String = "hive_vein_mother"
const GUARDIAN_ACID_CROWN: String = "hive_acid_crown_mother"
const RECYCLE_TRIGGER_CHANCE: float = 0.15
const RECYCLE_PITY_TRIGGER_COUNT: int = 6
const GATE_TO_PRIME_COUNT: int = 6
const VEIN_TETHER_COOLDOWN_SECONDS: float = 8.0
const ACID_COUNTER_COOLDOWN_SECONDS: float = 6.0

var guardian_id: String = ""
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var legal_recycle_count: int = 0
var recycle_pity_count: int = 0
var recycle_trigger_count: int = 0
var gate_miss_count: int = 0
var gate_conversion_count: int = 0
var tether_cooldown: float = 0.0
var acid_counter_cooldown: float = 0.0
var recycle_random_enabled: bool = true
var machine_event_log: Array[String] = []
var tactical_event_log: Array[String] = []
var gate_result_sequence: Array[Dictionary] = []
var last_recycle_record: Dictionary = {}
var last_gate_record: Dictionary = {}
var last_tether_record: Dictionary = {}
var last_acid_counter_record: Dictionary = {}

func configure(p_guardian_id: String, rng_seed: int = 0) -> void:
	guardian_id = p_guardian_id
	rng.seed = int(rng_seed)
	reset_for_battle()

func reset_for_battle() -> void:
	legal_recycle_count = 0
	recycle_pity_count = 0
	recycle_trigger_count = 0
	gate_miss_count = 0
	gate_conversion_count = 0
	tether_cooldown = 0.0
	acid_counter_cooldown = 0.0
	machine_event_log.clear()
	tactical_event_log.clear()
	gate_result_sequence.clear()
	last_recycle_record = {}
	last_gate_record = {}
	last_tether_record = {}
	last_acid_counter_record = {}

func advance(delta: float) -> void:
	tether_cooldown = maxf(0.0, tether_cooldown - delta)
	acid_counter_cooldown = maxf(0.0, acid_counter_cooldown - delta)

func on_launch_recycle(machine: MachineSimulator) -> bool:
	if guardian_id != GUARDIAN_VEIN_MOTHER or machine == null:
		return false

	legal_recycle_count += 1
	var roll: float = rng.randf()
	var pity_would_trigger: bool = recycle_pity_count + 1 >= RECYCLE_PITY_TRIGGER_COUNT
	var triggered: bool = (recycle_random_enabled and roll < RECYCLE_TRIGGER_CHANCE) or pity_would_trigger
	var pool_count_before: int = machine.pool.size()
	var inserted: bool = false
	var pool_full_rejected: bool = false

	if triggered:
		inserted = machine.add_guardian_clean_pool_ball()
		pool_full_rejected = not inserted
		recycle_trigger_count += 1
		recycle_pity_count = 0
		if inserted:
			machine_event_log.append("守护者契约：巢脉回流触发，Recycle 额外返回 1 颗净球")
		else:
			machine_event_log.append("守护者契约：巢脉回流触发，但 Pool 已满，额外净球被拒绝")
	else:
		recycle_pity_count += 1

	last_recycle_record = {
		"triggered": triggered,
		"roll": roll,
		"legal_recycle_count": legal_recycle_count,
		"pity_count": recycle_pity_count,
		"extra_clean_ball_count": 1 if inserted else 0,
		"pool_count_before": pool_count_before,
		"pool_count_after": machine.pool.size(),
		"pool_full_rejected": pool_full_rejected,
		"pity_reset": triggered and recycle_pity_count == 0,
		"reset_per_battle": true,
		"source": "Guardian.StrategicSkill",
		"contract_layer": "strategic_machine",
		"machine_event_log": machine_event_log.duplicate(),
	}
	return triggered

func on_tuning_result(result_id: String) -> String:
	if guardian_id != GUARDIAN_ACID_CROWN:
		_remember_gate_sequence(result_id, result_id)
		return result_id
	if result_id != "Gate":
		_remember_gate_sequence(result_id, result_id)
		return result_id

	gate_miss_count += 1
	var final_result: String = result_id
	var converted: bool = false
	if gate_miss_count >= GATE_TO_PRIME_COUNT:
		final_result = "Prime"
		converted = true
		gate_conversion_count += 1
		gate_miss_count = 0
		machine_event_log.append("守护者契约：酸冠入槽，本次 Gate 转为 Prime")

	_remember_gate_sequence(result_id, final_result)
	last_gate_record = {
		"converted": converted,
		"gate_count": GATE_TO_PRIME_COUNT if converted else gate_miss_count,
		"current_gate_miss_count": gate_miss_count,
		"original_result": result_id,
		"final_result": final_result,
		"reset": converted and gate_miss_count == 0,
		"reset_per_battle": true,
		"counted_only_gate": true,
		"no_cross_axis": true,
		"source": "Guardian.StrategicSkill",
		"contract_layer": "strategic_machine",
		"result_sequence": gate_result_sequence.duplicate(true),
		"machine_event_log": machine_event_log.duplicate(),
	}
	return final_result

func on_player_guardian_damaged(attacker: BattleEntityState, battlefield: BattlefieldState) -> void:
	if guardian_id != GUARDIAN_ACID_CROWN or attacker == null or battlefield == null:
		return
	if acid_counter_cooldown > 0.0:
		battlefield.record_guardian_contract_event("酸冠反喷冷却中：本次受击不储存额外触发")
		return
	last_acid_counter_record = battlefield.apply_acid_counterattack(attacker)
	acid_counter_cooldown = ACID_COUNTER_COOLDOWN_SECONDS
	if not last_acid_counter_record.is_empty():
		tactical_event_log.append("酸冠反喷")

func on_base_zone_intruder(intruder: BattleEntityState, battlefield: BattlefieldState) -> void:
	if guardian_id != GUARDIAN_VEIN_MOTHER or intruder == null or battlefield == null:
		return
	if tether_cooldown > 0.0:
		return
	var target: BattleEntityState = battlefield.closest_player_base_intruder()
	if target == null:
		return
	last_tether_record = battlefield.apply_vein_tether(target)
	tether_cooldown = VEIN_TETHER_COOLDOWN_SECONDS
	if not last_tether_record.is_empty():
		tactical_event_log.append("巢脉牵缚")

func telemetry_snapshot() -> Dictionary:
	return {
		"guardian_id": guardian_id,
		"legal_recycle_count": legal_recycle_count,
		"recycle_pity_count": recycle_pity_count,
		"recycle_trigger_count": recycle_trigger_count,
		"gate_miss_count": gate_miss_count,
		"gate_conversion_count": gate_conversion_count,
		"tether_cooldown": tether_cooldown,
		"acid_counter_cooldown": acid_counter_cooldown,
		"last_recycle_record": last_recycle_record.duplicate(true),
		"last_gate_record": last_gate_record.duplicate(true),
		"last_tether_record": last_tether_record.duplicate(true),
		"last_acid_counter_record": last_acid_counter_record.duplicate(true),
		"machine_event_log": machine_event_log.duplicate(),
		"tactical_event_log": tactical_event_log.duplicate(),
	}

func force_recycle_sequence_for_verifier(machine: MachineSimulator, count: int) -> Dictionary:
	if machine == null:
		return {}
	reset_for_battle()
	var was_random_enabled: bool = recycle_random_enabled
	recycle_random_enabled = false
	for _index: int in range(maxi(0, count)):
		on_launch_recycle(machine)
	recycle_random_enabled = was_random_enabled
	return last_recycle_record.duplicate(true)

func consume_machine_event_log() -> Array[String]:
	var drained: Array[String] = machine_event_log.duplicate()
	machine_event_log.clear()
	return drained

func _remember_gate_sequence(original_result: String, final_result: String) -> void:
	gate_result_sequence.append({
		"original_result": original_result,
		"final_result": final_result,
	})
	while gate_result_sequence.size() > 12:
		gate_result_sequence.pop_front()
