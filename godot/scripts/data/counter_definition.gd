class_name CounterDefinition
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var target_component: String = ""
@export var warning_seconds: float = 4.0
@export var active_seconds: float = 16.0
@export var visible_effect: String = ""
@export var patch_ids: Array[String] = []

func to_scout_text() -> String:
	return "%s 侦测：目标 %s。进入战斗 3 后会先预警 %.0fs，再触发：%s。" % [
		display_name,
		target_component,
		warning_seconds,
		visible_effect,
	]
