extends Node
class_name CameraSettings

@export var is_cam_centered: bool = false
@export var cam_pan_sensitivity: float = 0.01
@export var cam_speed: float = 15.0
@export var edge_margin: int = 75

@export var min_zoom = 1.0
@export var max_zoom = 15.0


func _init(_config: ConfigFile = null) -> void:
	if _config == null:
		return

	is_cam_centered = _config.get_value("camera", "cam_centered", false)
	cam_pan_sensitivity = _config.get_value("camera", "cam_pan_sensitivity", 0.01)
	cam_speed = _config.get_value("camera", "cam_speed", 15.0)
	edge_margin = _config.get_value("camera", "edge_margin", 75)
	
	min_zoom = _config.get_value("camera", "min_zoom", 1)
	max_zoom = _config.get_value("camera", "max_zoom", 15.0)


func save(_config: ConfigFile) -> void:
	_config.set_value("camera", "cam_centered", is_cam_centered)
	_config.set_value("camera", "cam_pan_sensitivity", cam_pan_sensitivity)
	_config.set_value("camera", "cam_speed", cam_speed)
	_config.set_value("camera", "edge_margin", edge_margin)
	
	_config.set_value("camera", "min_zoom", min_zoom)
	_config.set_value("camera", "max_zoom", max_zoom)


func copy() -> CameraSettings:
	var copied_group = CameraSettings.new()
	copied_group.is_cam_centered = is_cam_centered
	copied_group.cam_pan_sensitivity = cam_pan_sensitivity
	copied_group.cam_speed = cam_speed
	copied_group.edge_margin = edge_margin

	copied_group.min_zoom = min_zoom
	copied_group.max_zoom = max_zoom

	return copied_group
	

func differs(other: CameraSettings) -> bool:
	if other == null:
		return true
	
	return (
		is_cam_centered != other.is_cam_centered or
		cam_pan_sensitivity != other.cam_pan_sensitivity or
		cam_speed != other.cam_speed or
		edge_margin != other.edge_margin or
		min_zoom != other.min_zoom or
		max_zoom != other.max_zoom
	)
