class_name CounterDefinition
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var source: String = "Enemy.Counter"
@export var warehouse: String = ""
@export var target_component: String = ""
@export var operation: String = ""
@export var first_warning_start_seconds: float = 30.0
@export var warning_seconds: float = 4.0
@export var active_seconds: float = 16.0
@export var visible_effect: String = ""
@export var patch_ids: Array[String] = []
@export var scope: String = "单场反制窗口"
@export_multiline var player_read: String = ""
@export_multiline var failure_risk: String = ""
@export_multiline var guardrail: String = ""

func to_scout_text() -> String:
	return "%s 侦测：目标 %s。进入战斗约 %.0fs 后预警 %.0fs，再触发：%s。" % [
		display_name,
		target_component,
		first_warning_start_seconds,
		warning_seconds,
		visible_effect,
	]
