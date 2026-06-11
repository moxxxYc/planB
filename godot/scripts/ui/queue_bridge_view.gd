class_name QueueBridgeView
extends VBoxContainer

const PREVIEW_COUNT: int = 3

@onready var lane_label: Label = %LaneLabel
@onready var queue_label: Label = %QueueLabel
@onready var queue_preview_label: Label = %QueuePreviewLabel
@onready var bridge_label: Label = %BridgeLabel
@onready var spawn_port_label: Label = %SpawnPortLabel

var transfer_text: String = ""

func _ready() -> void:
	_ensure_nodes()
	add_theme_constant_override("separation", 12)
	lane_label.add_theme_color_override("font_color", Color("#56b4e9"))
	spawn_port_label.add_theme_color_override("font_color", Color("#56b4e9"))

func render(machine, deploy) -> void:
	_ensure_nodes()
	var lane_name := _lane_name(deploy.current_lane)
	lane_label.text = "部署路线：%s" % lane_name
	queue_label.text = "Queue 条目：%d" % machine.queue.size()
	queue_preview_label.text = transfer_text if not transfer_text.is_empty() else _queue_preview_text(machine.queue, deploy.current_lane)
	bridge_label.text = "Queue Bridge -> %s出兵口" % lane_name
	spawn_port_label.text = "连线：Queue 队首 ===> %s玩家侧出兵口" % lane_name

func show_deploy_transfer(lane: String, entry: Dictionary) -> void:
	_ensure_nodes()
	transfer_text = "转移确认：%s x%d 已沿 Queue Bridge 抵达%s出兵口" % [
		_unit_name(String(entry.get("unit_id", "unknown_unit"))),
		int(entry.get("count", 1)),
		_lane_name(lane),
	]
	queue_preview_label.text = transfer_text

func clear_deploy_transfer() -> void:
	transfer_text = ""

func get_transfer_text() -> String:
	return transfer_text

func get_lane_label_text() -> String:
	_ensure_nodes()
	return lane_label.text

func get_spawn_port_text() -> String:
	_ensure_nodes()
	return spawn_port_label.text

func get_bridge_route_text() -> String:
	_ensure_nodes()
	return bridge_label.text

func _queue_preview_text(queue: Array[Dictionary], current_lane: String) -> String:
	if queue.is_empty():
		return "预览：等待 Unit 槽满后生成 Queue 条目。"

	var lines := PackedStringArray()
	var limit: int = mini(PREVIEW_COUNT, queue.size())
	for index: int in range(limit):
		var entry: Dictionary = queue[index]
		lines.append("%d. %s x%d -> %s" % [
			index + 1,
			_unit_name(String(entry.get("unit_id", "unknown_unit"))),
			int(entry.get("count", 1)),
			_lane_name(current_lane),
		])
	return "\n".join(lines)

func _lane_name(lane: String) -> String:
	match lane:
		"Left":
			return "左路"
		"Mid":
			return "中路"
		"Right":
			return "右路"
		_:
			return lane

func _unit_name(unit_id: String) -> String:
	match unit_id:
		"hive_short_fang":
			return "短牙"
		"hive_shield_shell":
			return "盾壳"
		"hive_acid_sac":
			return "酸囊"
		"hive_crush_shell_beast":
			return "碾壳兽"
		_:
			return "未知单位"

func _ensure_nodes() -> void:
	if lane_label == null:
		lane_label = get_node("LaneLabel") as Label
	if queue_label == null:
		queue_label = get_node("QueueLabel") as Label
	if queue_preview_label == null:
		queue_preview_label = get_node("QueuePreviewLabel") as Label
	if bridge_label == null:
		bridge_label = get_node("BridgeLabel") as Label
	if spawn_port_label == null:
		spawn_port_label = get_node("SpawnPortLabel") as Label
