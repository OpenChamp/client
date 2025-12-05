class_name StatusBar
extends Node2D

@export var foreground: Control;
var _foreground_start_width: float;
var parent_ref : Node3D
var camera_ref : Camera3D

@onready var healthbar: ProgressBar = $Panel/HBoxContainer/VBoxContainer/Health
@onready var manabar: ProgressBar = $Panel/HBoxContainer/VBoxContainer/Mana
var size:Vector2
func _ready() -> void:
	assert(foreground != null);
	_foreground_start_width = foreground.size.x;
	parent_ref = get_parent()
	size = $Panel.get_size()
	
func _process(delta: float) -> void:
	if camera_ref:
		position = camera_ref.unproject_position(parent_ref.position + Vector3(0, 1, 0)) + Vector2(-size.x / 2, -50);
		print(position)
	else:
		camera_ref = get_viewport().get_camera_3d()

func set_stat(stat: String, value: float)-> void:
	var bar = get_bar(stat)
	if bar == null:
		push_error("Failed to set stat ", stat, " on statbar")
		return;
	bar.value = value
	if value <= 0:
		hide()
	else:
		show()
	
func set_max(stat:String ,value: float) -> void:
	var bar = get_bar(stat)
	if bar == null:
		push_error("Failed to set stat ", stat, " on statbar")
		return;
	bar.max_value = value

func get_bar(statname) -> Node:
	const health_whitelist = ["health", "hp", "h"]
	const mana_whitelist = ["mana", "mp", "m"]
	if health_whitelist.has(statname):
		return healthbar
	elif mana_whitelist.has(statname):
		return manabar
	return null
