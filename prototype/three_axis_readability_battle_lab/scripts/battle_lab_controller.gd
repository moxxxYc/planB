extends Control

func _ready() -> void:
	if has_node("CausalChain"):
		$CausalChain.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func axis_order() -> Array[String]:
	return ["launch", "tuning", "unit"]

func debug_label_is_primary() -> bool:
	return false

