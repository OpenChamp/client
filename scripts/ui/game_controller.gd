class_name GameController
extends Node3D

# Public state
var is_panning: bool = false
var is_mmb_panning: bool = false
var movement_vector: Vector3 = Vector3.ZERO
var mmb_relative_vector: Vector2 = Vector2.ZERO

var target: Vector3 = Vector3.ZERO

@export var speed: float = 20.0
@export var mmb_sensitivity: float = 0.100
@export var camera_path: NodePath = NodePath("")
@export var lerp_speed: float = 8.0 # higher -> snappier follow
@export var mmb_lerp_speed : int = 20

# Decals
@export var movement_decal : Decal
@export var attack_move_decal: Decal

var camera: Camera3D = null

func _ready() -> void:
	# Cache camera
	if camera_path != NodePath(""):
		camera = get_node_or_null(camera_path) as Camera3D
	if camera == null:
		camera = get_viewport().get_camera_3d()
	# Target init
	target = global_transform.origin
	print("GameController: Initialized (camera=", camera, ")")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MouseButton.MOUSE_BUTTON_MIDDLE:
			is_mmb_panning = event.pressed
			if is_mmb_panning:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				target = global_transform.origin
				mmb_relative_vector = Vector2.ZERO
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				mmb_relative_vector = Vector2.ZERO
				
	if event is InputEventMouseMotion and is_mmb_panning:
		mmb_relative_vector = event.get_relative()
		get_viewport().set_input_as_handled()

# --- Process Movement ---
func _process(delta: float) -> void:
	var delta_move: Vector3 = Vector3.ZERO
	# Input
	if is_mmb_panning:
		delta_move = get_mmb_pan()
	else:
		var dir = get_keyboard_pan()
		dir += get_edge_pan()
		if dir != Vector3.ZERO:
			dir = dir.normalized()
			var cam = camera
			if cam == null:
				cam = get_viewport().get_camera_3d()
			var right = cam.global_transform.basis.x
			var forward = cam.global_transform.basis.z
			delta_move = (right * dir.x + forward * dir.z)
			delta_move.y = 0
			delta_move = delta_move.normalized() * speed * delta
	# Movement
	if delta_move != Vector3.ZERO:
		movement_vector = delta_move
		is_panning = true
		target += delta_move
	else:
		movement_vector = Vector3.ZERO
		is_panning = false
	do_lerp(delta)
	
func do_lerp(delta:float):
	var current_pos = global_transform.origin
	var t
	if is_mmb_panning:
		t = clamp(delta * mmb_lerp_speed, 0.0, 1.0)
	else:
		t = clamp(delta * lerp_speed, 0.0, 1.0)
	var new_pos = current_pos.lerp(target, t)
	var gt = global_transform
	gt.origin = new_pos
	global_transform = gt
# --- Input Getters ---

func get_keyboard_pan() -> Vector3:
	var dir := Vector3.ZERO
	if Input.is_action_pressed("camera_pan_up"):
		dir.z -= 1
	if Input.is_action_pressed("camera_pan_down"):
		dir.z += 1
	if Input.is_action_pressed("camera_pan_left"):
		dir.x -= 1
	if Input.is_action_pressed("camera_pan_right"):
		dir.x += 1
	return dir

func get_edge_pan() -> Vector3:
	var dir := Vector3.ZERO
	var viewport := get_viewport()
	var mouse_pos := viewport.get_mouse_position()
	var edge_threshold := 10
	
	if mouse_pos.x <= edge_threshold:
		dir.x -= 1
	elif mouse_pos.x >= viewport.size.x - edge_threshold:
		dir.x += 1
	if mouse_pos.y <= edge_threshold:
		dir.z -= 1 
	elif mouse_pos.y >= viewport.size.y - edge_threshold:
		dir.z += 1
	return dir

func get_mmb_pan() -> Vector3:
	var out = Vector3.ZERO
	if mmb_relative_vector != Vector2.ZERO:
		var cam = camera
		if cam == null:
			cam = get_viewport().get_camera_3d()
		var x_amount = mmb_relative_vector.x * mmb_sensitivity
		var z_amount = mmb_relative_vector.y * mmb_sensitivity
		var right = cam.global_transform.basis.x
		var forward = cam.global_transform.basis.z
		out = (right * x_amount) + (forward * z_amount)
		out.y = 0
		mmb_relative_vector = Vector2.ZERO
	return out

func stop_panning() -> void:
	movement_vector = Vector3.ZERO
	is_panning = false
	is_mmb_panning = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	target = global_transform.origin
