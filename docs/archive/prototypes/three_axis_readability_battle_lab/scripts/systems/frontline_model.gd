extends RefCounted

const SIGNATURES := ["sustained_flow", "repeated_heavy_hit", "batch_charge_release"]

static func available_signatures() -> Array[String]:
	return SIGNATURES.duplicate()

static func label_for(signature: String) -> String:
	match signature:
		"sustained_flow":
			return "Sustained flow"
		"repeated_heavy_hit":
			return "Repeated heavy hit"
		"batch_charge_release":
			return "Batch charge and release"
		_:
			return ""

