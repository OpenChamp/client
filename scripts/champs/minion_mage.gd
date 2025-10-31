extends OC_Entity
class_name Minion_Mage

@export var team := 1
@export var target_node : Node3D
@export var spawn_point : Vector3
var has_target:bool = false

func _ready():
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	if spawn_point:
		global_position = spawn_point + Vector3(0, .5, 0) # Adjust for unit height
	if target_node:
		_set_target(target_node.position)
	
func _set_target(pos:Vector3):
	has_target = true
	NavAgent.set_target_position(pos)
	
func _physics_process(delta: float) -> void:
	if not Util.dedicated_server: return;
	if has_target:
		if not NavAgent.is_target_reachable():
			has_target = false;
			return;
		var next_path_pos := NavAgent.get_next_path_position()
		var dir := global_position.direction_to(next_path_pos)
		velocity = dir * MoveSpeed
		if NavAgent.is_navigation_finished():
			has_target = false
			velocity = Vector3.ZERO
		var ROT_SPEED = 4
		var target_rotation := dir.signed_angle_to(Vector3.MODEL_FRONT, Vector3.DOWN)
		if abs(target_rotation - rotation.y) > deg_to_rad(60):
			ROT_SPEED = 20
		rotation.y = move_toward(rotation.y, target_rotation, delta*ROT_SPEED)
	move_and_slide()
