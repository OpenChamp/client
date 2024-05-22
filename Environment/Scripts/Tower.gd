extends Node3D

@export var team:int


# Called when the node enters the scene tree for the first time.
func _ready():
	if team == 1:
		get_node("Towercrystal").set_surface_override_material(0, load("res://Environment/Materials/Blue.material"))
	elif team == 2:
		get_node("Towercrystal").set_surface_override_material(0, load("res://Environment/Materials/Red.material"))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
