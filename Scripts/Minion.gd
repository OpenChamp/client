extends CharacterBody3D

@export var team:int
@export var speed = 5

func _ready():
	if team == 1:
		get_node("MeshInstance3D").set_surface_override_material(0, load("res://Environment/Materials/Blue.material"))
	elif team == 2:
		get_node("MeshInstance3D").set_surface_override_material(0, load("res://Environment/Materials/Red.material"))

func _process(delta):
	pass;
