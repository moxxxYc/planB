extends RefCounted

static func make(
	time: float,
	lane: String,
	event_type: String,
	preset_id: String,
	axis_id: String,
	counter_id: String,
	frontline_signature: String,
	readability_tag: String,
	component_id := ""
) -> Dictionary:
	return {
		"time": time,
		"lane": lane,
		"event_type": event_type,
		"preset_id": preset_id,
		"axis_id": axis_id,
		"counter_id": counter_id,
		"frontline_signature": frontline_signature,
		"readability_tag": readability_tag,
		"component_id": component_id,
	}

