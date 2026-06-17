class_name GuardianDefinition
extends Resource

@export var guardian_id: StringName = &""
@export var display_name: String = ""
@export var race: String = "Hive"
@export_enum("Launch", "Tuning", "Unit") var axis_lean: String = "Launch"
@export var tactical_skill: String = ""
@export var strategic_target: String = ""
@export_multiline var placeholder_note: String = ""
