class_name UnitTemplateDefinition
extends Resource

@export var unit_id: StringName = &""
@export var display_name: String = ""
@export_range(1, 4, 1) var slot_id: int = 1
@export var progress_required: int = 1
@export var hp: int = 1
@export var attack_damage: int = 1
@export var attack_interval: float = 1.0
@export var attack_range: float = 1.0
@export var move_speed: float = 1.0
@export_multiline var role_note: String = ""
@export_multiline var placeholder_note: String = ""
