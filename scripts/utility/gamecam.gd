# === CAMERA IS ROTATED 90deg AT LAUNCH === #
extends Camera3D

@export_category("Camera movement")
@export var camera_speed: float = 20.0
@export var camera_pan_speed: float = 1
@export var camera_close_speed: float = 0.2
@export var camera_zoom_speed: float = .2
@export var camera_zoom_min: float = 4.0
@export var camera_zoom_max: float = 8.0

var camera_zoom = camera_zoom_max
var camera_close = -5
@export_category("Edge scrolling")
@export var edge_scroll_margin: float = 20.0
@export var edge_scroll_speed: float = 15.0 

var orbit_center: Vector3 = Vector3.ZERO
var _is_mmb_pressed := false

var mmb_origin: Vector2 = Vector2.ZERO
var state: CameraMode = CameraMode.FREE
enum CameraMode {
	FREE,
	FOLLOW
}

signal use_ability(ability_id:int, loc)
signal move_player(pos:Vector3)
var target_node: Node3D = null

func _ready() -> void:
	_update_camera_position()
	pass
func _enter_tree() -> void:
	state = CameraMode.FREE
	set_process_unhandled_input(true)

func _process(_delta: float) -> void:
	_update_camera_position()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_zoom -= camera_zoom_speed
			if camera_zoom < camera_zoom_min: camera_zoom = camera_zoom_min
			else:
				camera_close += camera_close_speed
			_update_camera_position()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_zoom += camera_zoom_speed
			if camera_zoom > camera_zoom_max: camera_zoom = camera_zoom_max
			else:
				camera_close -= camera_close_speed
			_update_camera_position()

		if event.button_index == MOUSE_BUTTON_RIGHT:
			_is_mmb_pressed = event.pressed
			mmb_origin = get_viewport().get_mouse_position()
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN if _is_mmb_pressed else Input.MOUSE_MODE_VISIBLE)

		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var result := Util.get_mouse_vector3()
			if result:
				move_player.emit(result)
			
	elif event is InputEventMouseMotion and _is_mmb_pressed:
		var dt := get_process_delta_time()
		var mouse_pos = get_viewport().get_mouse_position()
		var new_movement = Vector3(mmb_origin.y - mouse_pos.y, 0, mouse_pos.x- mmb_origin.x) * camera_pan_speed * dt
		mmb_origin = mouse_pos
		orbit_center -= new_movement
		_update_camera_position()
		
	elif event is InputEventKey:
		if event.is_action("ability_1"):
			use_ability.emit(1, Util.get_mouse_vector3())
		elif event.is_action("ability_2"):
			use_ability.emit(2, Util.get_mouse_vector3())
		elif event.is_action("ability_3"):
			use_ability.emit(3, Util.get_mouse_vector3())
		elif event.is_action("ability_4"):
			use_ability.emit(4, Util.get_mouse_vector3())
func set_follow_target(new_node: Node3D) -> void:
	state = CameraMode.FOLLOW
	target_node = new_node
	_update_camera_position()

func _update_camera_position() -> void:
	var dir := Vector3(
		camera_close,
		camera_zoom,
		0
	)

	if state == CameraMode.FOLLOW and target_node != null:
		orbit_center = target_node.global_transform.origin

	position = orbit_center + dir
	look_at(orbit_center, Vector3.UP)
