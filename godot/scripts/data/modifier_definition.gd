class_name ModifierDefinition
extends Resource

enum SourceType { REWARD, SHOP, REST }

@export var id: String = ""
@export var display_name: String = ""
@export var source_type: SourceType = SourceType.REWARD
@export var warehouse: String = ""
@export var target_component: String = ""
@export var operation: String = ""
@export var role: String = ""
@export var gold_cost: int = 0
@export_multiline var player_read: String = ""

func to_card_text() -> String:
	var cost_text: String = "" if gold_cost <= 0 else "%d Gold\n" % gold_cost
	return "%s%s\n%s -> %s -> %s\n定位：%s\n%s" % [
		cost_text,
		display_name,
		warehouse,
		target_component,
		operation,
		role,
		player_read,
	]
