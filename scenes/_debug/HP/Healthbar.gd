class_name Healthbar extends Node

var health: float = 0.0;
var max_health: float = 1.0;
@export var foreground: Control;
var _foreground_start_width: float;

func _ready() -> void:
	assert(foreground != null);
	_foreground_start_width = foreground.size.x;

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
