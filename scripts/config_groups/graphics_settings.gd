extends Node
class_name GraphicsSettings

@export var is_fullscreen: bool = true

func _init(_config: ConfigFile = null) -> void:
	if _config == null:
		return

	is_fullscreen = _config.get_value("graphics", "fullscreen", true)


func save(_config: ConfigFile) -> void:
	_config.set_value("graphics", "fullscreen", is_fullscreen)


func copy() -> GraphicsSettings:
	var copied_group = GraphicsSettings.new()

	copied_group.is_fullscreen = is_fullscreen

	return copied_group
	

func differs(other: GraphicsSettings) -> bool:
	if other == null:
		return true
	
	return (
		is_fullscreen != other.is_fullscreen
	)
