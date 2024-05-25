extends Node

signal display_property_changed()
signal camera_property_changed()

@export var is_fullscreen: bool = false: set = set_fullscreen_mode

@export var edge_margin = 75: set = set_edge_margin
@export var cam_speed: float = 15.0: set = set_cam_speed

@export var min_zoom = 1.0: set = set_min_zoom
@export var max_zoom = 25.0: set = set_max_zoom

# Settings Keybinds
func _input(e):
	if Input.is_action_just_pressed("toggle_maximize"):
		toggle_fullscreen()


func set_fullscreen_mode(new_value):
	if new_value == is_fullscreen:
		return
	
	var window_mode: DisplayServer.WindowMode
	match new_value:
		true:
			window_mode = DisplayServer.WINDOW_MODE_FULLSCREEN
		false:
			window_mode = DisplayServer.WINDOW_MODE_WINDOWED
	
	DisplayServer.window_set_mode(window_mode)
	is_fullscreen = new_value
	
	display_property_changed.emit()
	
func toggle_fullscreen():
	set_fullscreen_mode(!is_fullscreen)

func set_edge_margin(new_value: int):
	edge_margin = new_value
	camera_property_changed.emit()
	
func set_cam_speed(new_value: float):
	cam_speed = new_value
	camera_property_changed.emit()

func set_min_zoom(new_value: float):
	min_zoom = new_value
	camera_property_changed.emit()

func set_max_zoom(new_value: float):
	max_zoom = new_value
	camera_property_changed.emit()

