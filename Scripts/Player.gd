extends Node3D

@export var cur_zoom:int;

@export var min_x:int;
@export var max_x:int;
@export var min_z:int;
@export var max_z:int;

@export var Spring_Arm: SpringArm3D;
@export var Camera:Camera3D;
@export var MoveMarker:PackedScene;
@export var ServerListener:Node;

var UI: Script;

#@export var player := 1:
	#set(id):
		#player = id
		#$MultiplayerSynchronizer.set_multiplayer_authority(id)


# Called when the node enters the scene tree for the first time.
func _ready():
	Spring_Arm.spring_length = Config.max_zoom
# Called every frame. 'delta' is the elapsed time since the previous frame.

func _input(event):
	if event is InputEventMouseButton:
		# Right click to move
		if event.button_index == MOUSE_BUTTON_RIGHT:
			Action(event)

func Action(event):
	var from = Camera.project_ray_origin(event.position)
	var to = from + Camera.project_ray_normal(event.position) * 1000
	
	var space = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.create(from, to)
	var result = space.intersect_ray(params)
	# Move
	if result and result.collider.is_in_group("ground"):
		result.position.y += 1;
		var marker = MoveMarker.instantiate()
		marker.position = result.position
		get_node("/root").add_child(marker);
		ServerListener.rpc_id(get_multiplayer_authority(),"MoveTo", result.position)
		#Player.MoveTo(result.position);
	# Attack
	if result and result.collider.is_in_group("Objective"):
		ServerListener.rpc_id(get_multiplayer_authority(), "Target", result.collider.name)
	if result and result.collider is CharacterBody3D:
		ServerListener.rpc_id(get_multiplayer_authority(), "Target", result.collider.pid)
		

func _process(delta):

	# Get Mouse Coords on screen
	var mouse_pos = get_viewport().get_mouse_position()
	var size = get_viewport().size
	var cam_delta = Vector3(0, 0, 0)
	var cam_moved = false
	var edge_margin = Config.edge_margin
	
	# Edge Panning
	if (mouse_pos.x <= edge_margin && mouse_pos.x >= 0) || Input.is_action_pressed("player_left"):
		if !position.x <= min_x:
			cam_delta += Vector3(-1,0,0)
			cam_moved = true
	if (mouse_pos.x >= size.x - edge_margin && mouse_pos.x <= size.x) || Input.is_action_pressed("player_right"):
		if !position.x >= max_x:
			cam_delta += Vector3(1,0,0)
			cam_moved = true
	if (mouse_pos.y <= edge_margin && mouse_pos.y >= 0) || Input.is_action_pressed("player_up"):
		if !position.z <= min_z:
			cam_delta += Vector3(0,0,-1)
			cam_moved = true
	if( mouse_pos.y >= size.y - edge_margin && mouse_pos.y <= size.y) || Input.is_action_pressed("player_down"):
		if !position.z >= max_z:
			cam_delta += Vector3(0,0,1)
			cam_moved = true
	
	if cam_moved:
		position += cam_delta.normalized() * delta * Config.cam_speed
	
	# Zoom
	if Input.is_action_just_pressed("player_zoomin"):
		if Spring_Arm.spring_length > Config.min_zoom:
			Spring_Arm.spring_length -=1;
	if Input.is_action_just_pressed("player_zoomout"):
		if Spring_Arm.spring_length < Config.max_zoom:
			Spring_Arm.spring_length +=1;
	# Recenter
	if Input.is_action_just_pressed("player_cameraRecenter"):
		position = Vector3(0,0,0)
	
	# toggle fullscreen	
	if Input.is_action_just_pressed("toggle_maximize"):
		Config.toggle_fullscreen()
	
