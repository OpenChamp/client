@tool
extends ggsSetting


func _init() -> void:
	value_type = TYPE_FLOAT
	default = 25.0


func apply(value: float) -> void:
	Config.max_zoom = value
