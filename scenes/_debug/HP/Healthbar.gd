class_name Healthbar extends Node2D

var health: float = 0.0;
var max_health: float = 1.0;
@export var foreground: Control;
var _foreground_start_width: float;
var parent_ref : Node3D

func _ready() -> void:
	assert(foreground != null);
	_foreground_start_width = foreground.size.x;
	parent_ref = get_parent()
	
func _process(delta: float) -> void:
	position = get_viewport().get_camera_3d().unproject_position(parent_ref.position + Vector3(0, 1, 0)) + Vector2(.5, 0.0);

func set_health(h: float) -> void:
	health = h;
	if(max_health != 0.0):
		foreground.size.x = (health / max_health) * _foreground_start_width;
	else:
		foreground.size.x = _foreground_start_width;
	
func set_max_health(mh: float) -> void:
	max_health = mh;
	if(max_health != 0.0):
		foreground.size.x = (health / max_health) * _foreground_start_width;
	else:
		foreground.size.x = _foreground_start_width;
