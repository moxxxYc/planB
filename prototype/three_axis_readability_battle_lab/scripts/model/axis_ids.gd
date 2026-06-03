extends RefCounted

const LAUNCH := "launch"
const TUNING := "tuning"
const UNIT := "unit"

const PRIME := "prime"
const ECHO := "echo"
const SURGE := "surge"

static func all_axis_ids() -> Array[String]:
	return [LAUNCH, TUNING, UNIT]

static func all_tuning_slot_ids() -> Array[String]:
	return [PRIME, ECHO, SURGE]

static func axis_label(axis_id: String) -> String:
	match axis_id:
		LAUNCH:
			return "Launch"
		TUNING:
			return "Tuning"
		UNIT:
			return "Unit"
		_:
			return ""

static func tuning_slot_label(slot_id: String) -> String:
	match slot_id:
		PRIME:
			return "Prime"
		ECHO:
			return "Echo"
		SURGE:
			return "Surge"
		_:
			return ""

