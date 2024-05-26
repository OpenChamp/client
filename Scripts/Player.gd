extends Node3D

enum MovingState {
	NONE,
	MOVING,
	ATTACK_MOVING,
}


@export var cur_zoom: int;

@export var min_x: int;
@export var max_x: int;
@export var min_z: int;
@export var max_z: int;

@export var Spring_Arm: SpringArm3D;
@export var Camera: Camera3D;
@export var MoveMarker: PackedScene;
@export var ServerListener: Node;

var move_state : MovingState

var UI: Script;

#@export var player := 1:
	#set(id):
		#player = id
		#$MultiplayerSynchronizer.set_multiplayer_authority(id)

# Called when the node enters the scene tree for the first time.
func _ready():
	Spring_Arm.spring_length = Config.max_zoom
	Config.camera_property_changed.connect(_on_camera_setting_changed)
# Called every frame. 'delta' is the elapsed time since the previous frame.

func _input(event):
	if event is InputEventMouseMotion:
		try_move(event,false)
		return

	if Input.is_action_just_released("hero_attack_move") or Input.is_action_just_released("hero_move"):
		var raycast = camera_to_mouse_raycast(event.position)
		if not raycast.is_empty():
			place_move_marker(raycast.position)

	if not (Input.is_action_pressed("hero_attack_move") or Input.is_action_pressed("hero_move")):
		move_state = MovingState.NONE
		return

	if Input.is_action_just_pressed("hero_attack_move"):
		move_state = MovingState.ATTACK_MOVING
		try_move(event, true)
		return
	
	if Input.is_action_just_pressed("hero_move"):
		move_state = MovingState.MOVING
		try_move(event, true)



	pass
			
func _on_camera_setting_changed():
	Spring_Arm.spring_length = clamp(Spring_Arm.spring_length, Config.min_zoom, Config.max_zoom)


func try_move(event, show_particle_effect : bool):
	if move_state == MovingState.ATTACK_MOVING:
		attack_move_action(event, show_particle_effect)
		return
	
	if move_state == MovingState.MOVING:
		move_action(event, show_particle_effect)
		return

func move_action(event, show_particle_effect : bool):
	var result = camera_to_mouse_raycast(event.position)
	# Move
	if result and result.collider.is_in_group("ground"):
		result.position.y += 1;
		if show_particle_effect:
			place_move_marker(result.position)
		ServerListener.rpc_id(get_multiplayer_authority(), "MoveTo", result.position)
		#Player.MoveTo(result.position);
	# Attack
	if result and result.collider.is_in_group("Objective"):
		var group = 0
		if (result.collider.is_in_group("BlueObjective")):
			group = 1
		elif (result.collider.is_in_group("RedObjective")):
			group = 2
		ServerListener.rpc_id(get_multiplayer_authority(), "Target", result.collider.name, group)
	if result and result.collider is CharacterBody3D:
		var group = 0
		ServerListener.rpc_id(get_multiplayer_authority(), "Target", result.collider.pid, group)


func attack_move_action(event, show_particle_effect : bool):
	move_action(event, show_particle_effect)


func place_move_marker(location : Vector3):
	var marker = MoveMarker.instantiate()
	marker.position = location
	get_node("/root").add_child(marker);
	

func camera_to_mouse_raycast(target_position : Vector2) -> Dictionary:
	var from = Camera.project_ray_origin(target_position)
	var to = from + Camera.project_ray_normal(target_position) * 1000
	
	var space = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.create(from, to)
	return space.intersect_ray(params)


func _process(delta):
	# ignore all inputs when changing configs since that is annoying
	if Config.in_config_settings:
		return

	# Get Mouse Coords on screen
	var mouse_pos = get_viewport().get_mouse_position()
	var size = get_viewport().size
	var cam_delta = Vector3(0, 0, 0)
	var cam_moved = false
	var edge_margin = Config.edge_margin
	
	# Edge Panning
	if (mouse_pos.x <= edge_margin&&mouse_pos.x >= 0)||Input.is_action_pressed("player_left"):
		if !position.x <= min_x:
			cam_delta += Vector3( - 1, 0, 0)
			cam_moved = true
	if (mouse_pos.x >= size.x - edge_margin&&mouse_pos.x <= size.x)||Input.is_action_pressed("player_right"):
		if !position.x >= max_x:
			cam_delta += Vector3(1, 0, 0)
			cam_moved = true
	if (mouse_pos.y <= edge_margin&&mouse_pos.y >= 0)||Input.is_action_pressed("player_up"):
		if !position.z <= min_z:
			cam_delta += Vector3(0, 0, -1)
			cam_moved = true
	if (mouse_pos.y >= size.y - edge_margin&&mouse_pos.y <= size.y)||Input.is_action_pressed("player_down"):
		if !position.z >= max_z:
			cam_delta += Vector3(0, 0, 1)
			cam_moved = true
	
	if cam_moved:
		position += cam_delta.normalized() * delta * Config.cam_speed
	
	# Zoom
	if Input.is_action_just_pressed("player_zoomin"):
		if Spring_Arm.spring_length > Config.min_zoom:
			Spring_Arm.spring_length -= 1;
	if Input.is_action_just_pressed("player_zoomout"):
		if Spring_Arm.spring_length < Config.max_zoom:
			Spring_Arm.spring_length += 1;
	# Recenter
	if Input.is_action_just_pressed("player_cameraRecenter"):
		position = Vector3(0, 0, 0)
	
