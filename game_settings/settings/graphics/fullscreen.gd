@tool
extends ggsSetting

func _init() -> void:
	value_type = TYPE_BOOL
	default = false

func apply(value: bool) -> void:
	Config.set_fullscreen_mode(value)
