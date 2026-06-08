class_name MachineComponentDefinition
extends Resource

@export var component_id: StringName = &""
@export_enum("Launch", "Tuning", "Unit") var warehouse: String = "Launch"
@export var display_name: String = ""
@export var component_kind: String = ""
@export_multiline var placeholder_note: String = ""
