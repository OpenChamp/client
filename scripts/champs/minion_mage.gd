extends OC_Entity
class_name Minion_Mage

@export var team := 1
@export var spawn_point : Vector3
@onready var vision_area : Area3D = $Vision
@onready var vision_collision : CollisionShape3D = $Vision/CollisionShape3D
@onready var experience_area : Area3D = $ExperienceZone
@onready var experience_collision : CollisionShape3D = $ExperienceZone/CollisionShape3D

func _ready():
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	if Util.dedicated_server:
		_setup_vision_range()
		_setup_experience_range()
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

func die():
	_distribute_experience()
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
		var exp_per_player = TotalExp / players_in_range.size()
		for player in players_in_range:
			if player.has_method("gain_experience"):
				player.gain_experience(exp_per_player)
	

	
func _physics_process(delta: float) -> void:
	if not Util.dedicated_server: return;
	take_damage(1)
	# Check if minion is dead
	if Health <= 0:
		die()
		return
		
	if not NavAgent.is_target_reachable() or NavAgent.is_target_reached():
		target_node = null
		return;
	var next_path_pos := NavAgent.get_next_path_position()
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

func _on_body_entered_vision(body:Node3D):
	print("BODY");
	var eid
	if team != 1:
		eid=1;
	else:
		eid=0
	if body.is_in_group(str("team", eid)):
		
		set_target_node(body)
	
