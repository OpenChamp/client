extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D

const SPEED = 5.0
@export var id:int
@export var team:int

func init(init_id:int, init_team:int):
	id = init_id
	team = init_team
	name = "minion_%d_%d" % [team, id]
	position = get_position()

func _ready():
	if team == 1:
		$MeshInstance3D.set_surface_override_material(0, load("res://Environment/Materials/Blue.material"))
	elif team == 2:
		$MeshInstance3D.set_surface_override_material(0, load("res://Environment/Materials/Red.material"))
	# Disable physics process for clients
	if not multiplayer.is_server():
		set_physics_process(false)

func _physics_process(delta):
	var current_location = global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	var new_velocity = (next_location - current_location).normalized() * SPEED
	
	velocity = new_velocity
	move_and_slide()

func update_target_location(target_location):
	nav_agent.target_position = target_location
