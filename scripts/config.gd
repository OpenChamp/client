extends Node

signal display_property_changed()
signal camera_property_changed()

# a helper value, to pause some things while in a menu
@export var in_focued_menu: bool = false
@export var is_dedicated_server:bool = false
# the settings groups
@export var camera_settings: CameraSettings
@export var graphics_settings: GraphicsSettings


# the internal config file object
var _config := ConfigFile.new()

func _ready() -> void:
	var load_error = _config.load("user://settings.cfg")
	if load_error != OK:
		print("Could not load file. (defaults will be used)")
	
	camera_settings = CameraSettings.new(_config)
	graphics_settings = GraphicsSettings.new(_config)

	_set_fullscreen_mode(graphics_settings.is_fullscreen)
	

# Settings Keybinds
func _input(e):
	if e.is_action("toggle_maximize"):
		toggle_fullscreen()


func toggle_fullscreen():
	var new_settings = graphics_settings.copy()
	new_settings.is_fullscreen = !new_settings.is_fullscreen
	change_graphics_settings(new_settings)


func change_camera_settings(new_settings: CameraSettings):
	if camera_settings.differs(new_settings):
		camera_settings = new_settings
		camera_property_changed.emit()
		
		camera_settings.save(_config)
		_config.save("user://settings.cfg")


func change_graphics_settings(new_settings: GraphicsSettings):
	if graphics_settings.differs(new_settings):

		if new_settings.is_fullscreen != graphics_settings.is_fullscreen:
			_set_fullscreen_mode(new_settings.is_fullscreen)

		graphics_settings = new_settings
		display_property_changed.emit()
		
		graphics_settings.save(_config)
		_config.save("user://settings.cfg")


func _set_fullscreen_mode(new_value):
	var window_mode: DisplayServer.WindowMode
	match new_value:
		true:
			window_mode = DisplayServer.WINDOW_MODE_FULLSCREEN
		false:
			window_mode = DisplayServer.WINDOW_MODE_WINDOWED
	
	DisplayServer.window_set_mode(window_mode)
