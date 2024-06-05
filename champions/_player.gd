extends Node3D
class_name PlayerController

@export var cur_zoom: int

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
#@onready var attack_move_cast: ShapeCast3D = $AttackMoveCast

const MoveMarker: PackedScene = preload ("res://scenes/effects/move_marker.tscn")

@onready var server = get_parent()
@onready var champion
var initial_mouse_position := Vector2.ZERO
# Camera Settings
var camera_target_position := Vector3.ZERO
var is_middle_mouse_dragging : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the Server Listener
	while !server.is_in_group("Map"):
		server = server.get_parent()
	# Get your champion
	server.get_node("Champions").child_entered_tree.connect(champion_spawned)
	# Set our camera as main
	spring_arm.spring_length = Config.max_zoom
	camera.make_current()

func _process(delta):
	camera_movement_handler()
	# Update camera using lerp
	position = position.lerp(camera_target_position, 5 * delta)

func _input(event):
	$StateMachine.current_state.handle_input(event);

func champion_spawned(entity):
	if entity.id == multiplayer.get_unique_id():
		self.champion = entity
		server.get_node("Champions").child_entered_tree.disconnect(champion_spawned)
		server.rpc_id(get_multiplayer_authority(), "client_ready")
		$StateMachine.change_state("player_move")

func camera_movement_handler() -> void:
	# don't move the cam while changing the settings since that is annoying af
	if Config.in_focued_menu:
		return
	
	# If centered, blindly follow the champion
	if (Config.is_cam_centered):
		camera_target_position = get_target_position(multiplayer.get_unique_id())
	else:
		# Get Mouse Coords on screen
		var current_mouse_position = get_viewport().get_mouse_position()
		var size = get_viewport().get_visible_rect().size
		var cam_delta = Vector3(0, 0, 0)
		var edge_margin = Config.edge_margin
		
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
			cam_delta += Vector3(mouse_delta.x, 0, mouse_delta.y) * Config.cam_pan_sensitivity
		
		# Apply camera movement
		camera_target_position += cam_delta * get_process_delta_time() * Config.cam_speed
	
	# Zoom
	if Input.is_action_just_pressed("player_zoomin"):
		if spring_arm.spring_length > Config.min_zoom:
			spring_arm.spring_length -= 1
	if Input.is_action_just_pressed("player_zoomout"):
		if spring_arm.spring_length < Config.max_zoom:
			spring_arm.spring_length += 1
	
	# Recenter - Tap
	if Input.is_action_pressed("player_camera_recenter"):
		camera_target_position = get_target_position(multiplayer.get_unique_id())
	# Recenter - Toggle
	if Input.is_action_just_pressed("player_camera_recenter_toggle"):
		Config.set_cam_centered(!Config.is_cam_centered)

func get_champion(pid: int) -> Node:
	var champs = $"../Champions".get_children()
	for child in champs:
		if child.name == str(pid):
			return child
	return null
	
func get_target_position(pid: int) -> Vector3:
	var champ = get_champion(pid)
	if champ:
		return champ.position
	return Vector3.ZERO
