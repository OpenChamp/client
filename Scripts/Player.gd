extends Node3D

@export var edge_margin = 75

@export var cam_speed = 15;
@export var min_zoom = 1;
@export var max_zoom = 25;
@export var cur_zoom:int;

@export var Spring_Arm: SpringArm3D;
@export var Camera:Camera3D;
@export var Player:CharacterBody3D;
@export var MoveMarker:PackedScene;

#@export var player := 1:
	#set(id):
		#player = id
		#$MultiplayerSynchronizer.set_multiplayer_authority(id)

var isPlayer: bool = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	Spring_Arm.spring_length = max_zoom
# Called every frame. 'delta' is the elapsed time since the previous frame.

func _input(event):
	if event is InputEventMouseButton:
		# Right click to move
		if event.button_index == MOUSE_BUTTON_RIGHT && isPlayer:
			Action(event)
		elif event.button_index == MOUSE_BUTTON_RIGHT && isPlayer:
			print("Not yet bud");
			
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
		multiplayer.rpc(get_multiplayer_authority(), Player, "MoveTo", [result.position])
		#Player.MoveTo(result.position);
	# Attack
	if result and result.collider is CharacterBody3D:
		print("FOUND YOU")
		if result.collider.team != Player.team:
			print("GONNA HURT YOU")
			#Player.Attack(result.collider)

func set_player(p:CharacterBody3D):
	print("Player Set")
	Player = p
	isPlayer = true

func _process(delta):
	# Handle the escape key (for now just close the game)
	if Input.is_action_just_pressed("player_pause"):
		get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
		get_tree().quit()

	# Get Mouse Coords on screen
	var mouse_pos = get_viewport().get_mouse_position();
	var size = get_viewport().size;
	
	# Edge Panning
	if (mouse_pos.x <= edge_margin && mouse_pos.x >= 0) || Input.is_action_pressed("player_left"):
		position += Vector3(-1,0,0) * delta * cam_speed
	if (mouse_pos.x >= size.x - edge_margin && mouse_pos.x <= size.x) || Input.is_action_pressed("player_right"):
		position += Vector3(1,0,0) * delta * cam_speed
	if (mouse_pos.y <= edge_margin && mouse_pos.y >= 0) || Input.is_action_pressed("player_up"):
		position += Vector3(0,0,-1) * delta * cam_speed
	if( mouse_pos.y >= size.y - edge_margin && mouse_pos.y <= size.y) || Input.is_action_pressed("player_down"):
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
		
	# toggle fullscreen	
	if Input.is_action_just_pressed("toggle_maximize"):
		var window_mode = get_tree().root.mode
		if window_mode == Window.MODE_FULLSCREEN or window_mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
			get_tree().root.mode = Window.MODE_WINDOWED
		else:
			get_tree().root.mode = Window.MODE_FULLSCREEN
	
