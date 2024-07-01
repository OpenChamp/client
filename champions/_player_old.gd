extends Node3D

@export var cur_zoom: int

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
#@onready var attack_move_cast: ShapeCast3D = $AttackMoveCast
@export var server_listener: Node

@export var MoveMarker: PackedScene

var camera_target_position := Vector3.ZERO
var initial_mouse_position := Vector2.ZERO
var is_middle_mouse_dragging := false
var is_right_mouse_dragging := false
var is_left_mouse_dragging := false
var character : CharacterBody3D

@onready var marker = MoveMarker.instantiate();
#@export var player := 1:
	#set(id):
		#player = id
		#$MultiplayerSynchronizer.set_multiplayer_authority(id)

func _ready():
	add_child(marker);
	# For now close game when server dies
	multiplayer.server_disconnected.connect(get_tree().quit)
	spring_arm.spring_length = Config.camera_settings.max_zoom
	Config.camera_property_changed.connect(_on_camera_setting_changed)
	
	center_camera.call_deferred(multiplayer.get_unique_id())
	
	if server_listener == null:
		server_listener = get_parent()
		while !server_listener.is_in_group("Map"):
			server_listener = server_listener.get_parent()

func _input(event):
	if Config.is_dedicated_server: return;
	
	if event is InputEventMouseButton:
		
		# if event.button_index == MOUSE_BUTTON_LEFT and not is_right_mouse_dragging:
		# 	player_action(event, not is_left_mouse_dragging, true)
		# 	if event.is_pressed and not is_left_mouse_dragging:
		# 		is_left_mouse_dragging = true
		# 	else:
		# 		is_left_mouse_dragging = false
		# Right click to move
		if event.button_index == MOUSE_BUTTON_RIGHT and not is_left_mouse_dragging:
			# Start dragging
			player_action(event, not is_right_mouse_dragging) # For single clicks
			if event.is_pressed and not is_right_mouse_dragging:
				is_right_mouse_dragging = true
			else:
				is_right_mouse_dragging = false

		# if event.button_index == MOUSE_BUTTON_MIDDLE:
		# 	if event.pressed:
		# 		initial_mouse_position = event.position
		# 		is_middle_mouse_dragging = true
		# 	else:
		# 		is_middle_mouse_dragging = false
		
		# Stop dragging if mouse is released
	
	if event is InputEventMouseMotion:
		if is_left_mouse_dragging:
			player_action(event, false, true)
			return
		if is_right_mouse_dragging:
			player_action(event, false)
			return

func get_target_position(pid: int) -> Vector3:
	var champ = get_champion(pid)
	if champ:
		return champ.position
	return Vector3.ZERO

func player_action(event, play_marker: bool=false, attack_move: bool=false):
	var from = camera.project_ray_origin(event.position)
	var to = from + camera.project_ray_normal(event.position) * 1000
	
	var space = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.create(from, to)
	var result = space.intersect_ray(params)
	if !result: return

	# Move
	if result.collider.is_in_group("Ground"):
		
		if attack_move:
			#if _try_attack_move(result.position, play_marker):
				#return
			pass
		_player_action_move(result, play_marker, attack_move)
	# Attack
	_player_action_attack(result.collider)

func _player_action_attack(collider):
	if not collider is Unit: return
	if collider.team == get_champion(multiplayer.get_unique_id()).team: return
	server_listener.rpc_id(get_multiplayer_authority(), "target", collider.name)


func _player_action_move(result, play_marker: bool, attack_move: bool):
		result.position.y += 1
		if play_marker:
			_play_move_marker(result.position, attack_move)
		server_listener.rpc_id(get_multiplayer_authority(), "move_to", result.position)


#func _try_attack_move(target_position: Vector3, play_marker : bool = false):
	#attack_move_cast.global_position = target_position
	#attack_move_cast.force_shapecast_update()
	#if attack_move_cast.is_colliding():
		#var closest_enemy = null
		#for i in attack_move_cast.get_collision_count():
			#var collider = attack_move_cast.get_collider(i)
			#if collider == null: continue
			#if not "health" in collider: continue
			#if collider.team == get_champion(multiplayer.get_unique_id()).team: continue
			#if closest_enemy == null:
				#closest_enemy = collider
				#continue
			#if target_position.distance_to(collider.position) < target_position.distance_to(closest_enemy.position):
				#closest_enemy = collider
		#if closest_enemy != null:
			#_player_action_attack(closest_enemy)
			#if play_marker:
				#_play_move_marker(target_position, true)
			#return true
	#return false

func _play_move_marker(marker_position : Vector3, attack_move: bool = false):
	marker.global_position = marker_position
	marker.attack_move = attack_move
	marker.play()

func center_camera(playerid):
	camera_target_position = get_target_position(playerid)

func _process(delta):
	if Config.is_dedicated_server : return ;
	# handle all the camera-related input
	camera_movement_handler()
	
	# check input for ability uses
	detect_ability_use()
	
	# update the camera position using lerp
	position = position.lerp(camera_target_position, delta * Config.camera_settings.cam_speed)

func detect_ability_use() -> void:
	var pid = multiplayer.get_unique_id()
	if Input.is_action_just_pressed("player_ability1"):
		get_champion(pid).trigger_ability(1)
		return
	if Input.is_action_just_pressed("player_ability2"):
		get_champion(pid).trigger_ability(2)
		return
	if Input.is_action_just_pressed("player_ability3"):
		get_champion(pid).trigger_ability(3)
		return
	if Input.is_action_just_pressed("player_ability4"):
		get_champion(pid).trigger_ability(4)
		return

func camera_movement_handler() -> void:
	# don't move the cam while changing the settings since that is annoying af
	if Config.in_focued_menu:
		return
	
	# If centered, blindly follow the champion
	if (Config.camera_settings.is_cam_centered):
		camera_target_position = get_target_position(multiplayer.get_unique_id())
	else:
		#ignore the input if this window is not even focused
		if not get_window().has_focus():
			return
		
		# Get Mouse Coords on screen
		var current_mouse_position = get_viewport().get_mouse_position()
		var size = get_viewport().get_visible_rect().size
		var cam_delta = Vector3(0, 0, 0)
		var edge_margin = Config.camera_settings.edge_margin
		
		# Check if there is a collision at the mouse position
		if not get_viewport().get_visible_rect().has_point(
			get_viewport().get_final_transform() * current_mouse_position
		):
			return
			
		# Edge Panning
		if current_mouse_position.x <= edge_margin:
			cam_delta.x -= 1
		elif current_mouse_position.x >= size.x - edge_margin:
			cam_delta.x += 1

		if current_mouse_position.y <= edge_margin:
			cam_delta.z -= 1
		elif current_mouse_position.y >= size.y - edge_margin:
			cam_delta.z += 1
		
		# Keyboard input
		cam_delta.x += Input.get_action_strength("player_right") - Input.get_action_strength("player_left")
		cam_delta.z += Input.get_action_strength("player_down") - Input.get_action_strength("player_up")
		
		# Middle mouse dragging
		if is_middle_mouse_dragging:
			var mouse_delta = current_mouse_position - initial_mouse_position
			cam_delta += Vector3(mouse_delta.x, 0, mouse_delta.y) * Config.camera_settings.cam_pan_sensitivity
		
		# Apply camera movement
		if cam_delta != Vector3.ZERO:
			camera_target_position += cam_delta
	
	# Zoom
	if Input.is_action_just_pressed("player_zoomin"):
		if spring_arm.spring_length > Config.camera_settings.min_zoom:
			spring_arm.spring_length -= 1
	if Input.is_action_just_pressed("player_zoomout"):
		if spring_arm.spring_length < Config.camera_settings.max_zoom:
			spring_arm.spring_length += 1
	
	# Recenter - Tap
	if Input.is_action_pressed("player_camera_recenter"):
		camera_target_position = get_target_position(multiplayer.get_unique_id())
	# Recenter - Toggle
	if Input.is_action_just_pressed("player_camera_recenter_toggle"):
		Config.camera_settings.is_cam_centered = (!Config.camera_settings.is_cam_centered)

func get_champion(pid: int) -> Node:
	if character == null:
		var champs = $"../Characters".get_children()
		for child in champs:
			if child.name == str(pid):
				character = child
				return child
		return null
	else:
		return character

func _on_camera_setting_changed():
	spring_arm.spring_length = clamp(
		spring_arm.spring_length,
		Config.camera_settings.min_zoom,
		Config.camera_settings.max_zoom
	)
