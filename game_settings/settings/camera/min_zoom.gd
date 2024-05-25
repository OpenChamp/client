@tool
extends ggsSetting


func _init() -> void:
	value_type = TYPE_FLOAT
	default = 1.0

func apply(value: float) -> void:
	Config.min_zoom = value
