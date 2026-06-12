class_name CounterState
extends RefCounted

enum Phase { INACTIVE, WARNING, ACTIVE, RESOLVED }

var definition: Resource = null
var phase: Phase = Phase.INACTIVE
var elapsed: float = 0.0
var active_elapsed: float = 0.0
var trigger_count: int = 0
var visible_effect: String = ""
var response_link: String = "无"

func configure(p_definition: Resource, p_response_link: String) -> void:
	definition = p_definition
	response_link = p_response_link
	phase = Phase.WARNING
	elapsed = 0.0
	active_elapsed = 0.0
	trigger_count = 0
	visible_effect = ""

func advance(delta: float) -> void:
	if definition == null or phase == Phase.RESOLVED:
		return
	elapsed += delta
	match phase:
		Phase.WARNING:
			if elapsed >= float(definition.get("warning_seconds")):
				phase = Phase.ACTIVE
				active_elapsed = 0.0
		Phase.ACTIVE:
			active_elapsed += delta
			if active_elapsed >= float(definition.get("active_seconds")):
				phase = Phase.RESOLVED

func is_warning() -> bool:
	return phase == Phase.WARNING

func is_active() -> bool:
	return phase == Phase.ACTIVE

func banner_text() -> String:
	if definition == null:
		return "反制：无"
	match phase:
		Phase.WARNING:
			return "%s 预警：正在攻击 %s，%.1fs 后生效。" % [
				String(definition.get("display_name")),
				String(definition.get("target_component")),
				maxf(0.0, float(definition.get("warning_seconds")) - elapsed),
			]
		Phase.ACTIVE:
			if visible_effect.is_empty():
				return "%s 生效中：等待 %s 的可见触发。" % [
					String(definition.get("display_name")),
					String(definition.get("target_component")),
				]
			return "%s 生效：%s" % [String(definition.get("display_name")), visible_effect]
		Phase.RESOLVED:
			return "%s 已结束：%s" % [String(definition.get("display_name")), visible_effect]
		_:
			return "%s 待命" % String(definition.get("display_name"))

func to_record() -> Dictionary:
	if definition == null:
		return {}
	return {
		"family": String(definition.get("id")),
		"target_component": String(definition.get("target_component")),
		"visible_effect": visible_effect,
		"response_link": response_link,
	}
