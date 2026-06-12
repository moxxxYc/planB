class_name CounterState
extends RefCounted

enum Phase { INACTIVE, WARNING, ACTIVE, RESOLVED }

var definition: Resource = null
var phase: Phase = Phase.INACTIVE
var elapsed: float = 0.0
var warning_elapsed: float = 0.0
var active_elapsed: float = 0.0
var trigger_count: int = 0
var visible_effect: String = ""
var response_link: String = "无"

func configure(p_definition: Resource, p_response_link: String) -> void:
	definition = p_definition
	response_link = p_response_link
	phase = Phase.INACTIVE
	elapsed = 0.0
	warning_elapsed = 0.0
	active_elapsed = 0.0
	trigger_count = 0
	visible_effect = ""

func advance(delta: float) -> void:
	if definition == null or phase == Phase.RESOLVED:
		return
	elapsed += delta
	match phase:
		Phase.INACTIVE:
			_advance_inactive_phase()
		Phase.WARNING:
			warning_elapsed += delta
			_resolve_warning_phase()
		Phase.ACTIVE:
			active_elapsed += delta
			_resolve_active_phase()

func is_warning() -> bool:
	return phase == Phase.WARNING

func is_active() -> bool:
	return phase == Phase.ACTIVE

func is_resolved() -> bool:
	return phase == Phase.RESOLVED

func banner_text() -> String:
	if definition == null:
		return "反制：无"
	match phase:
		Phase.WARNING:
			return "%s 预警：正在攻击 %s，准备触发 %s，%.1fs 后生效。" % [
				String(definition.get("display_name")),
				String(definition.get("target_component")),
				String(definition.get("visible_effect")),
				maxf(0.0, float(definition.get("warning_seconds")) - warning_elapsed),
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
			return "%s 待命：%.1fs 后预警，目标 %s。" % [
				String(definition.get("display_name")),
				maxf(0.0, _first_warning_start_seconds() - elapsed),
				String(definition.get("target_component")),
			]

func to_record() -> Dictionary:
	if definition == null:
		return {}
	return {
		"family": String(definition.get("id")),
		"target_component": String(definition.get("target_component")),
		"visible_effect": visible_effect,
		"response_link": response_link,
		"phase": _phase_label(),
		"first_warning_start_seconds": _first_warning_start_seconds(),
	}

func _advance_inactive_phase() -> void:
	var first_warning_start_seconds: float = _first_warning_start_seconds()
	if elapsed < first_warning_start_seconds:
		return
	phase = Phase.WARNING
	warning_elapsed = elapsed - first_warning_start_seconds
	_resolve_warning_phase()

func _resolve_warning_phase() -> void:
	var warning_seconds: float = float(definition.get("warning_seconds"))
	if warning_elapsed < warning_seconds:
		return
	phase = Phase.ACTIVE
	active_elapsed = warning_elapsed - warning_seconds
	_resolve_active_phase()

func _resolve_active_phase() -> void:
	if active_elapsed >= float(definition.get("active_seconds")):
		phase = Phase.RESOLVED

func _first_warning_start_seconds() -> float:
	if definition == null:
		return 0.0
	if not _has_property(definition, "first_warning_start_seconds"):
		return 0.0
	return maxf(0.0, float(definition.get("first_warning_start_seconds")))

func _phase_label() -> String:
	match phase:
		Phase.INACTIVE:
			return "inactive"
		Phase.WARNING:
			return "warning"
		Phase.ACTIVE:
			return "active"
		Phase.RESOLVED:
			return "resolved"
		_:
			return "unknown"

func _has_property(object: Object, property_name: String) -> bool:
	for property_info: Dictionary in object.get_property_list():
		if String(property_info.get("name", "")) == property_name:
			return true
	return false
