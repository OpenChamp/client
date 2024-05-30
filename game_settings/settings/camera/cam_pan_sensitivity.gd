@tool
extends ggsSetting

func _init() -> void:
	value_type = TYPE_FLOAT
	default = 0.1

func apply(value: float) -> void:
	Config.cam_pan_sensitivity = value
