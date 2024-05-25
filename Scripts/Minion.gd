class_name Minion extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
@onready var mesh_instance = $MeshInstance3D

var speed:float = 5.0
var id:int
var team:int
var range:float = 10.0
var target_player

func _init(init_id:int, init_team:int):
	id = init_id
	team = init_team
	name = "minion_%d_%d" % [team, id]
	position = get_position()

func _ready():
	if not multiplayer.is_server():
		set_physics_process(false)
