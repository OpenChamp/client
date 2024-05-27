extends Node3D

@export var cur_zoom: int

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@export var server_listener: Node

const MoveMarker: PackedScene = preload("res://Effects/move_marker.tscn")

var is_cam_centered : bool = false

#@export var player := 1:
	#set(id):
		#player = id
		#$MultiplayerSynchronizer.set_multiplayer_authority(id)


func _ready():
	# For now close game when server dies
	multiplayer.server_disconnected.connect(get_tree().quit)
	spring_arm.spring_length = Config.max_zoom
	Config.camera_property_changed.connect(_on_camera_setting_changed)


func _input(event):
	if event is InputEventMouseButton:
		# Right click to move
		if event.button_index == MOUSE_BUTTON_RIGHT:
			action(event)


func center_cam():
	var champs = $"../Champions".get_children()
	for child in champs:
		if child.name == str(multiplayer.get_unique_id()):
			position = child.position


func action(event):
	var from = camera.project_ray_origin(event.position)
	var to = from + camera.project_ray_normal(event.position) * 1000
	
	var space = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.create(from, to)
	var result = space.intersect_ray(params)
	# Move
	if result and result.collider.is_in_group("ground"):
		result.position.y += 1
		var marker = MoveMarker.instantiate()
		marker.position = result.position
		get_node("/root").add_child(marker)
		server_listener.rpc_id(get_multiplayer_authority(), "move_to", result.position)
		#Player.MoveTo(result.position)
	# Attack
	if result and result.collider.is_in_group("Objective"):
		server_listener.rpc_id(get_multiplayer_authority(), "target", result.collider.name)
		return
	if result and result.collider.is_in_group("Minion"):
		server_listener.rpc_id(get_multiplayer_authority(), "target", result.collider.name)
		return
	if result and result.collider.is_in_group("Champion"):
		server_listener.rpc_id(get_multiplayer_authority(), "target", result.collider.name)
		return
	if result and result.collider is CharacterBody3D:
		server_listener.rpc_id(get_multiplayer_authority(), "target", result.collider.pid)


func _process(delta):
	# don't move the cam while changing the settings since that is annoying af
	if Config.in_config_settings:
		return
	
	# If centered, blindly follow the champion
	if (is_cam_centered):
		center_cam()
	else:
		# Get Mouse Coords on screen
		var mouse_pos = get_viewport().get_mouse_position()
		var size = get_viewport().size
		var cam_delta = Vector3(0, 0, 0)
		var cam_moved = false
		var edge_margin = Config.edge_margin
		
		# Edge Panning
		if (mouse_pos.x <= edge_margin and mouse_pos.x >= 0) or Input.is_action_pressed("player_left"):
			cam_delta += Vector3(-1,0,0)
			cam_moved = true
		if (mouse_pos.x >= size.x - edge_margin and mouse_pos.x <= size.x) or Input.is_action_pressed("player_right"):
			cam_delta += Vector3(1,0,0)
			cam_moved = true
		if (mouse_pos.y <= edge_margin and mouse_pos.y >= 0) or Input.is_action_pressed("player_up"):
			cam_delta += Vector3(0,0,-1)
			cam_moved = true
		if (mouse_pos.y >= size.y - edge_margin and mouse_pos.y <= size.y) or Input.is_action_pressed("player_down"):
			cam_delta += Vector3(0,0,1)
			cam_moved = true
		
		if cam_moved:
			position += cam_delta.normalized() * delta * Config.cam_speed
		
	# Zoom
	if Input.is_action_just_pressed("player_zoomin"):
		if spring_arm.spring_length > Config.min_zoom:
			spring_arm.spring_length -=1
	if Input.is_action_just_pressed("player_zoomout"):
		if spring_arm.spring_length < Config.max_zoom:
			spring_arm.spring_length +=1
	
	# Recenter - Tap
	if Input.is_action_pressed("player_camera_recenter"):
		center_cam()
	# Recenter - Toggle
	if Input.is_action_just_pressed("player_camera_recenter_toggle"):
		is_cam_centered = !is_cam_centered
	
	# toggle fullscreen
	if Input.is_action_just_pressed("toggle_maximize"):
		var window_mode = get_tree().root.mode
		if window_mode == Window.MODE_FULLSCREEN or window_mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
			get_tree().root.mode = Window.MODE_WINDOWED
		else:
			get_tree().root.mode = Window.MODE_FULLSCREEN


func _on_camera_setting_changed():
	spring_arm.spring_length = clamp(spring_arm.spring_length, Config.min_zoom, Config.max_zoom)
