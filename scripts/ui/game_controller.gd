class_name GameController
extends Node3D

# Public state
var is_panning: bool = false
var is_mmb_panning: bool = false
var movement_vector: Vector3 = Vector3.ZERO
var mmb_relative_vector: Vector2 = Vector2.ZERO

var target: Vector3 = Vector3.ZERO

@export var speed: float = 20.0
@export var mmb_sensitivity: float = .05
@export var camera_path: NodePath = NodePath("")
@export var lerp_speed: float = 8.0 # higher -> snappier follow
@export var mmb_lerp_speed : int = 20

# Decals
@export var movement_decal_scene : PackedScene
@export var attack_move_decal_scene : PackedScene

var camera: Camera3D = null

@onready var game_root:Node = get_tree().get_first_node_in_group("game_root")
var movement_decal: Decal
var attack_move_decal: Decal

# MMB Movement Origins
var mmb_origin : Vector2 = Vector2.ZERO

func _ready() -> void:
	if game_root == null:
		get_tree().quit(-1)
	# Decal Config
	if movement_decal_scene == null or attack_move_decal_scene == null:
		push_error("Player Controller Decal was left Unset")
		get_tree().quit(-1)
	movement_decal = movement_decal_scene.instantiate()
	attack_move_decal = attack_move_decal_scene.instantiate()
	movement_decal.hide()
	attack_move_decal.hide()
	game_root.add_child(movement_decal)
	game_root.add_child(attack_move_decal)
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
		if !camera:
			return
		# MMB Panning
		if event.button_index == MouseButton.MOUSE_BUTTON_MIDDLE:
			is_mmb_panning = event.pressed
			if is_mmb_panning:
				mmb_origin = event.global_position
				Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
				mmb_relative_vector = Vector2.ZERO
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				mmb_relative_vector = Vector2.ZERO
				
		# LMB Move Command
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_pos = event.position
			var from = camera.project_ray_origin(mouse_pos)
			var to = from + camera.project_ray_normal(mouse_pos) * 1000.0
			var space_state = get_world_3d().direct_space_state
			var params = PhysicsRayQueryParameters3D.new()
			params.from = from
			params.to = to
			params.collide_with_areas = false
			params.collide_with_bodies = true
			var result = space_state.intersect_ray(params)
			if result.size() > 0:
				movement_decal.move_to(result.position)
				IOManager.move_champion.rpc_id(1, result.position)
				
	if event is InputEventMouseMotion and is_mmb_panning:
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
	var mouse_pos = get_viewport().get_mouse_position()
	
	#var out = Vector3.ZERO
	#if mmb_relative_vector != Vector2.ZERO:
		#mmb_relative_vector = mmb_relative_vector.normalized() * mmb_sensitivity
		#var dir: Vector3 =  Vector3(-mmb_relative_vector.y, 0, mmb_relative_vector.x)
		#out = dir * speed
	return out

func stop_panning() -> void:
	movement_vector = Vector3.ZERO
	is_panning = false
	is_mmb_panning = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	target = global_transform.origin
