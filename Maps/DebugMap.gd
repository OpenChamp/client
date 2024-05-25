extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	$Player.min_x = -30
	$Player.max_x = 30
	$Player.min_z = -10
	$Player.max_z = 10
	print("Level Loaded")
