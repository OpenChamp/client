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
	if Player:
		isPlayer = true;
# Called every frame. 'delta' is the elapsed time since the previous frame.

func _process(delta):
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
