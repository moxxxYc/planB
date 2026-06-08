class_name ModifierDefinition
extends Resource

@export var modifier_id: StringName = &""
@export var display_name: String = ""
@export_enum("Reward", "Shop", "Reward / Shop", "Second Reward") var source_pool: String = "Reward"
@export_enum("Launch", "Tuning", "Unit") var warehouse: String = "Launch"
@export var target_component: String = ""
@export var operation: String = ""
@export_enum("Anchor", "Patch", "Pivot", "Deepen", "Rest") var role_tag: String = "Anchor"
@export_multiline var player_read: String = ""
@export_multiline var placeholder_note: String = ""
