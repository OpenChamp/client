extends OC_Entity
class_name Minion_Mage

@export var team := 1
@export var spawn_point : Vector3
@onready var vision_area : Area3D = $Vision
@onready var vision_collision : CollisionShape3D = $Vision/CollisionShape3D
@onready var experience_area : Area3D = $ExperienceZone
@onready var experience_collision : CollisionShape3D = $ExperienceZone/CollisionShape3D
# Syncing State instead of Health as micro-optimization
@export var State: minion_state = minion_state.IDLE

enum minion_state {
	IDLE,
	MOVING,
	ATTACKING,
	DEAD
}

# Navigation timeout protection
var _last_nav_update: float = 0.0
const NAV_UPDATE_INTERVAL: float = 0.1 

func _ready():
	Health = 250
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	if Util.dedicated_server:
		# Defer navigation setup to avoid race conditions
		call_deferred("_setup_navigation")
		_setup_vision_range()
		_setup_experience_range()

func _setup_navigation():
	# Wait for navigation server to be ready
	await get_tree().process_frame
	
	if spawn_point:
		global_position = spawn_point + Vector3(0, .5, 0) # Adjust for unit height
	if target_node:
		_set_target(target_node.position)

func _setup_vision_range():
	vision_area.get_node("CollisionShape3D").shape.radius = VisionRange
	vision_area.body_entered.connect(_on_body_entered_vision)

func _setup_experience_range():
	if experience_collision and experience_collision.shape is SphereShape3D:
		var sphere_shape = experience_collision.shape as SphereShape3D
		sphere_shape.radius = 5.0  # Default experience range
@rpc("authority","call_local")
func die():
	_distribute_experience()
	State = minion_state.DEAD
	died.emit()
	$Body.hide()
	$CollisionShape3D.disabled = true
	$MoneyEmitter.emitting = true
	$AudioStreamPlayer3D.stream = death_sound
	$AudioStreamPlayer3D.play()
	get_tree().create_timer(2.0).timeout.connect(queue_free)

func _distribute_experience():
	if not experience_area:
		return
		
	var players_in_range = []
	var bodies = experience_area.get_overlapping_bodies()
	
	for body in bodies:
		if body.is_in_group("player") and body.has_method("get_team"):
			# Give experience to players on the OPPOSITE team (enemy players who killed this minion)
			if body.get_team() != team:
				players_in_range.append(body)
	
	if players_in_range.size() > 0:
		var exp_per_player = float(TotalExp) / players_in_range.size()
		for player in players_in_range:
			if player.has_method("gain_experience"):
				player.gain_experience(int(exp_per_player))
	

	
func _physics_process(delta: float) -> void:
	if not Util.dedicated_server: return;
	if State == minion_state.DEAD: return;
	if not NavAgent: return;
	if Util.debug:
		take_damage(1)
	if Health <= 0:
		die.rpc()
		return
	
	# Throttle navigation updates to prevent hangs
	_last_nav_update += delta
	if _last_nav_update < NAV_UPDATE_INTERVAL:
		move_and_slide()
		return
	
	_last_nav_update = 0.0
	if not _is_navigation_ready():
		return
		
	if not NavAgent.is_target_reachable() or NavAgent.is_target_reached():
		target_node = null
		return;
		
	var next_path_pos := NavAgent.get_next_path_position()
	# Add validation for next_path_pos
	if next_path_pos == Vector3.ZERO or next_path_pos.distance_to(global_position) < 0.1:
		return
		
	var dir := global_position.direction_to(next_path_pos)
	velocity = dir * MoveSpeed
	if NavAgent.is_navigation_finished():
		velocity = Vector3.ZERO
		die()
	var ROT_SPEED = 4
	var target_rotation := dir.signed_angle_to(Vector3.MODEL_FRONT, Vector3.DOWN)
	if abs(target_rotation - rotation.y) > deg_to_rad(60):
		ROT_SPEED = 20
	rotation.y = move_toward(rotation.y, target_rotation, delta*ROT_SPEED)
	move_and_slide()

# Helper function to check if navigation is ready and avoid hangs
func _is_navigation_ready() -> bool:
	if not NavAgent:
		return false
	
	# Check if navigation server is ready
	if not NavigationServer3D.get_maps().size() > 0:
		return false
		
	# Ensure navigation agent is properly configured
	if not NavAgent.is_inside_tree():
		return false
		
	return true

func _on_body_entered_vision(body:Node3D):
	print("BODY");
	var eid
	if team != 1:
		eid=1;
	else:
		eid=0
	if body.is_in_group(str("team", eid)):
		
		set_target_node(body)
	
