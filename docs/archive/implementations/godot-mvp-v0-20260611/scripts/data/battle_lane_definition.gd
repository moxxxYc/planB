class_name BattleLaneDefinition
extends Resource

@export var lane_id: StringName = &""
@export var display_name: String = ""
@export var order_index: int = 0
@export var is_default_deploy_lane: bool = false
@export_range(0, 3, 1) var max_danger_tier: int = 3
@export_multiline var placeholder_note: String = ""
