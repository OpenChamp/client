@tool
extends ggsSetting


func _init() -> void:
	value_type = TYPE_FLOAT
	default = 15.0


func apply(value: float) -> void:
	Config.cam_speed = value
