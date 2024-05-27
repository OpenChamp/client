extends Node3D


@export var edge_margin = 10

@export var cam_speed = 10;
@export var min_zoom = 1;
@export var max_zoom = 10;
@export var cur_zoom:int;

@export var Spring_Arm: SpringArm3D;
@export var Camera:Camera3D;
@export var Player:CharacterBody3D;
@export var MoveMarker:PackedScene;
var isPlayer: bool = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	Spring_Arm.spring_length = max_zoom
	if Player:
		isPlayer = true;
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Get Mouse Coords on screen
	var mouse_pos = get_viewport().get_mouse_position();
	var size = get_viewport().size;
	# Edge Panning
	if mouse_pos.x <= edge_margin || Input.is_action_pressed("player_left"):
		position += Vector3(-1,0,0) * delta * cam_speed
	if mouse_pos.x >= size.x - edge_margin || Input.is_action_pressed("player_right"):
		position += Vector3(1,0,0) * delta * cam_speed
	if mouse_pos.y <= edge_margin || Input.is_action_pressed("player_up"):
		position += Vector3(0,0,-1) * delta * cam_speed
	if mouse_pos.y >= size.y - edge_margin || Input.is_action_pressed("player_down"):
		position += Vector3(0,0,1) * delta * cam_speed
	# Zoom
	if Input.is_action_just_pressed("player_zoomin"):
		if Spring_Arm.spring_length > min_zoom:
			Spring_Arm.spring_length -=1;
	if Input.is_action_just_pressed("player_zoomout"):
		if Spring_Arm.spring_length < max_zoom:
			Spring_Arm.spring_length +=1;
	# Recenter
	if Input.is_action_just_pressed("player_cameraRecenter") && isPlayer:
		position = Player.position
	if Input.is_action_just_pressed("toggle_window_mode"):
		var is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		if is_fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED) 
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN) 

func _unhandled_input(event):
	if event is InputEventMouseButton:
		# Right click to move
		if event.button_index == MOUSE_BUTTON_RIGHT && isPlayer:
			Action(event)
			
func Action(event):
	var marker = MoveMarker.instantiate()
	var from = Camera.project_ray_origin(event.position)
	var to = from + Camera.project_ray_normal(event.position) * 1000
	
	var space = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.create(from, to)
	var result = space.intersect_ray(params)
	print_debug(result);
	# Move
	if result and result.collider.is_in_group("ground"):
		result.position.y += 1;
		marker.position = result.position
		get_node("/root").add_child(marker);
		Player.MoveTo(result.position);
	# Attack
	if result and result.collider is CharacterBody3D:
		print("FOUND YOU")
		if result.collider.team != Player.team:
			print("GONNA HURT YOU")
			Player.Attack(result.collider)
		print(result.collider.team)
		print(Player.team)
