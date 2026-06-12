class_name MachineSlotExposureState
extends RefCounted

const EXPOSURE_START_SECONDS: Dictionary = {1: 0.0, 2: 12.0, 3: 36.0, 4: 72.0}
const EXPOSURE_FULL_SECONDS: Dictionary = {1: 0.0, 2: 24.0, 3: 54.0, 4: 96.0}
const SLOT_REQUIREMENTS: Dictionary = {1: 3, 2: 5, 3: 8, 4: 12}
const SLOT_IDS: Array[int] = [1, 2, 3, 4]

func get_exposure_ratio(slot_id: int, battle_elapsed: float) -> float:
	if not EXPOSURE_START_SECONDS.has(slot_id):
		return 0.0
	var start_seconds: float = float(EXPOSURE_START_SECONDS[slot_id])
	var full_seconds: float = float(EXPOSURE_FULL_SECONDS.get(slot_id, start_seconds))
	if battle_elapsed < start_seconds:
		return 0.0
	if full_seconds <= start_seconds:
		return 1.0
	if battle_elapsed >= full_seconds:
		return 1.0
	return clampf((battle_elapsed - start_seconds) / (full_seconds - start_seconds), 0.0, 1.0)

func is_slot_open_for_progress(slot_id: int, battle_elapsed: float) -> bool:
	if not EXPOSURE_START_SECONDS.has(slot_id):
		return false
	return battle_elapsed >= float(EXPOSURE_START_SECONDS[slot_id])

func is_slot_fully_exposed(slot_id: int, battle_elapsed: float) -> bool:
	return get_exposure_ratio(slot_id, battle_elapsed) >= 1.0

func snapshot(battle_elapsed: float) -> Dictionary:
	var slots: Dictionary = {}
	for slot_id: int in SLOT_IDS:
		var ratio: float = get_exposure_ratio(slot_id, battle_elapsed)
		slots[slot_id] = {
			"slot_id": slot_id,
			"start_seconds": float(EXPOSURE_START_SECONDS[slot_id]),
			"full_seconds": float(EXPOSURE_FULL_SECONDS[slot_id]),
			"ratio": ratio,
			"open": is_slot_open_for_progress(slot_id, battle_elapsed),
			"fully_exposed": ratio >= 1.0,
			"progress_required": int(SLOT_REQUIREMENTS[slot_id]),
		}
	return {
		"battle_elapsed": battle_elapsed,
		"slot_order": SLOT_IDS.duplicate(),
		"slots": slots,
	}

func lowest_progress_legal_slot(slot_progress: Dictionary, battle_elapsed: float) -> int:
	var best_slot_id: int = 0
	var best_progress: int = 0
	for slot_id: int in SLOT_IDS:
		if not is_slot_open_for_progress(slot_id, battle_elapsed):
			continue
		var progress: int = int(slot_progress.get(slot_id, 0))
		if best_slot_id == 0 or progress < best_progress:
			best_slot_id = slot_id
			best_progress = progress
	return best_slot_id
