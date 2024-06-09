extends Node3D


@export var edge_margin = 20

@export var cam_speed = 10;
@export var min_zoom = 1;
@export var max_zoom = 20;
@export var cur_zoom:int;

@export var Spring_Arm: SpringArm3D;
@export var Camera:Camera3D;
@export var Player:CharacterBody3D;
@export var MoveMarker:PackedScene;

var isPlayer: bool = false;
var outOfBounds: bool = false;
var lockCamera: bool = false;

func _notification(event):
	match event:
		NOTIFICATION_WM_MOUSE_EXIT:
			outOfBounds = true;
		NOTIFICATION_WM_MOUSE_ENTER:
			outOfBounds = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	Spring_Arm.spring_length = max_zoom
	if Player:
		isPlayer = true;
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_process_pan(delta);
	_process_zoom();
	_process_snap();
	_process_actions();

# handle player move
func _process_actions():
	if !isPlayer: return;
			
	if Input.is_action_just_pressed("player_move"):
		var result = _target();
		
		if result && result.collider.is_in_group("ground"):
			_mark(result.position);
			Player.move_to(result.position + Vector3(0,1,0));
			
		elif result && result.collider.is_in_group("players"):
			if result.collider.team != Player.team:
				Player.attack(result.collider)
							
	if Input.is_action_just_pressed("player_select"):
		var result = _target();
		if result:
			Player.selected(result.position,result.collider);
		else:
			Player.selected();
			
	if Input.is_action_just_pressed("player_ability_1"):
		var result = _target();
		if result:
			Player.ability1(result.position,result.collider);
		else:
			Player.ability1();
		
	if Input.is_action_just_pressed("player_ability_2"):
		var result = _target();
		if result:
			Player.ability2(result.position,result.collider);
		else:
			Player.ability2();
		
	if Input.is_action_just_pressed("player_ability_3"):
		var result = _target();
		if result:
			Player.ability3(result.position,result.collider);
		else:
			Player.ability3();
		
	if Input.is_action_just_pressed("player_ability_4"):
		var result = _target();
		if result:
			Player.ability4(result.position,result.collider);
		else:
			Player.ability4();
		
# handle camera snapping behavior
func _process_snap():
	if Input.is_action_just_pressed("camera_recenter") && isPlayer:
		position = Player.position

# handle zoom behavior
func _process_zoom():
	var value = Spring_Arm.spring_length;
	
	if Input.is_action_just_pressed("camera_zoomin"):
		value -= 1;
			
	elif Input.is_action_just_pressed("camera_zoomout"):
		value += 1;

	Spring_Arm.spring_length = clampf(value,min_zoom,max_zoom);

# handle edge-based panning by the player
func _process_pan(delta):
	if outOfBounds: return
	
	var mouse_pos = get_viewport().get_mouse_position();
	var size = get_viewport().size;
	
	if Input.is_action_just_pressed("camera_lock") && isPlayer:
		lockCamera = !lockCamera;
	
	if lockCamera:
		position = Player.position
	else:
		if mouse_pos.x <= edge_margin:
			position += Vector3(-1,0,0) * delta * cam_speed
		if mouse_pos.x >= size.x - edge_margin:
			position += Vector3(1,0,0) * delta * cam_speed
		if mouse_pos.y <= edge_margin:
			position += Vector3(0,0,-1) * delta * cam_speed
		if mouse_pos.y >= size.y - edge_margin:
			position += Vector3(0,0,1) * delta * cam_speed

# get a target at the current mouse position
func _target() -> Dictionary:
	var pos = get_viewport().get_mouse_position();
	var from = Camera.project_ray_origin(pos)
	var to = from + Camera.project_ray_normal(pos) * 1000

	var space = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.create(from, to)
	return space.intersect_ray(params)

func _mark(pos):
	var marker = MoveMarker.instantiate();
	marker.position = pos;
	get_node("/root").add_child(marker);
