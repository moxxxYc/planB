class_name GuardianDefinition
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var axis: String = ""
@export_multiline var tactical_read: String = ""
@export_multiline var strategic_read: String = ""
@export_multiline var risk_read: String = ""

func to_card_text() -> String:
	return "%s\n契约倾向：%s\n战术防守：%s\n机器契约：%s\n风险：%s" % [
		display_name,
		axis,
		tactical_read,
		strategic_read,
		risk_read,
	]
