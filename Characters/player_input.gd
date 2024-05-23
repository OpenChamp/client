extends MultiplayerSynchronizer

#var MoveMarker = preload("res://Effects/MoveMarker.tscn")
@export var Camera:Camera3D;
@export var from:Vector3
@export var to:Vector3

func _ready():
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())
	pass

func _unhandled_input(event):
	#if event is InputEventMouseButton:
		## Right click to move
		#if event.button_index == MOUSE_BUTTON_RIGHT:
			#Action(event)
	pass
func Action(event):
	pass
	#var marker = MoveMarker.instantiate()
	#from = Camera.project_ray_origin(event.position)
	#to = from + Camera.project_ray_normal(event.position) * 1000
	
	#var space = get_world_3d().direct_space_state
	#var params = PhysicsRayQueryParameters3D.create(from, to)
	#var result = space.intersect_ray(params)
	#print_debug(result);
	# Move
	#if result and result.collider.is_in_group("ground"):
	#	result.position.y += 1;
	#	marker.position = result.position
	#	get_node("/root").add_child(marker);
	#	Player.MoveTo(result.position);
	# Attack
	#if result and result.collider is CharacterBody3D:
	#	print("FOUND YOU")
	#	if result.collider.team != Player.team:
	#		print("GONNA HURT YOU")
	#		Player.Attack(result.collider)
	#	print(result.collider.team)
	#	print(Player.team)
