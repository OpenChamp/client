class_name Healthbar extends Node2D

@export var foreground: Control;
var _foreground_start_width: float;
var parent_ref : Node3D

func _ready() -> void:
	assert(foreground != null);
	_foreground_start_width = foreground.size.x;
	parent_ref = get_parent()
	
func _process(delta: float) -> void:
	position = get_viewport().get_camera_3d().unproject_position(parent_ref.position + Vector3(0, 1, 0)) + Vector2(-.5, 0.0);

func set_health(h: float) -> void:
	$ProgressBar.value = h
	
func set_max_health(mh: float) -> void:
	$ProgressBar.max_value = mh
