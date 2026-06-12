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
	return "%s%s\n影响：%s\n定位：%s\n%s" % [
		cost_text,
		display_name,
		_effect_text(),
		role,
		player_read,
	]

func _effect_text() -> String:
	match id:
		"pool_pocket":
			return "Launch / Pool 容量 +1"
		"prime_charge":
			return "Tuning / Prime 数值 +1 提升到 +2"
		"slot_primer":
			return "Unit / S1 保留 1 点底线进度"
		"front_recycle":
			return "Launch 前段回收，让球更容易回到 Pool"
		"surge_buffer":
			return "Tuning / Surge 暂存 1 次冲刺，下次同槽 Unit 更快出队"
		"queue_brace":
			return "Queue 空档超过 3 秒时，补强最低进度 Unit 槽"
		"junk_sieve":
			return "Launch 头球是 Junk 时过滤，降低 Pool 污染"
		"muster_pair":
			return "Unit 同槽短时间连续成型时，合并成 2 个单位"
		"echo_latch":
			return "Tuning / Echo 复制保留一次重复命中"
		_:
			var axis_text: String = warehouse
			var target_text: String = target_component
			if not operation.is_empty():
				return "%s / %s：%s" % [axis_text, target_text, operation]
			if not target_text.is_empty():
				return "%s / %s" % [axis_text, target_text]
			return axis_text
