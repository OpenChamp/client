@tool
extends ggsSetting

func _init() -> void:
	value_type = TYPE_INT
	default = 75

func apply(value: int) -> void:
	Config.edge_margin = value
