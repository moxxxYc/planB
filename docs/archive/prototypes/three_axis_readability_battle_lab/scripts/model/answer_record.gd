extends RefCounted

const REQUIRED_FIELDS := [
	"player_id",
	"battle_order",
	"hidden_preset",
	"answer_axis",
	"answer_counter",
	"answer_overdrive",
	"answer_frontline_cause",
	"confidence_axis_1_to_5",
	"confidence_counter_1_to_5",
	"confidence_overdrive_1_to_5",
	"confidence_frontline_1_to_5",
	"observer_notes",
	"correct_count_0_to_4",
	"unit_only_bias_flag",
	"overdrive_panic_flag",
]

const CONFIDENCE_FIELDS := [
	"confidence_axis_1_to_5",
	"confidence_counter_1_to_5",
	"confidence_overdrive_1_to_5",
	"confidence_frontline_1_to_5",
]

static func required_fields() -> Array:
	return REQUIRED_FIELDS.duplicate()

static func create(values: Dictionary) -> Dictionary:
	var record := {}
	for field in REQUIRED_FIELDS:
		record[field] = values.get(field, _default_value(field))
	return record

static func validate(record: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for field in REQUIRED_FIELDS:
		if not record.has(field):
			errors.append("missing:%s" % field)
	for field in CONFIDENCE_FIELDS:
		var value = record.get(field, null)
		if typeof(value) != TYPE_INT or value < 1 or value > 5:
			errors.append("invalid_confidence:%s" % field)
	var correct_count = record.get("correct_count_0_to_4", null)
	if typeof(correct_count) != TYPE_INT or correct_count < 0 or correct_count > 4:
		errors.append("invalid_correct_count")
	return errors

static func _default_value(field: String):
	if field.begins_with("confidence_"):
		return 1
	match field:
		"battle_order", "correct_count_0_to_4":
			return 0
		"unit_only_bias_flag", "overdrive_panic_flag":
			return false
		_:
			return ""
