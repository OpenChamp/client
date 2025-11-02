extends Creature
class_name Minion_Base

# === Minion Specific Stats === #
@export var spawn_point: Vector3
@export var enemy_node_pos: Vector3
# === Attack Stats === #
@onready var vision_area: Area3D = $Vision
@onready var vision_collision: CollisionShape3D = $Vision/CollisionShape3D
# === Navigation Optimization === #
var _last_nav_update: float = 0.0
const NAV_UPDATE_INTERVAL: float = 0.1

func _ready():
	super()
	if spawn_point:
		global_position = spawn_point
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	setup_stats()
	if Util.dedicated_server:
		call_deferred("_setup_navigation")
		_setup_vision_range()
		$AttackTimeout.timeout.connect(func(): can_attack_now = true)
		$FollowTimer.timeout.connect(_on_follow_timer_timeout)
		if enemy_node_pos != Vector3.ZERO:
			_set_target(enemy_node_pos)

func _physics_process(delta: float) -> void:
	if not Util.dedicated_server: return
	if state == STATE.DEAD: return
	if not nav_agent: return

	if health <= 0:
		print("SERVER IS ASKING FOR DEATH")
		state = STATE.DEAD
		die.rpc()
		return
	
	match state:
		STATE.IDLE:
			_handle_idle_state(delta)
		STATE.MOVING:
			_handle_moving_state(delta)
		STATE.FOLLOWING:
			_handle_following_state(delta)
		STATE.ATTACKING:
			_handle_attacking_state(delta)
		STATE.DEAD:
			return
			
## === State Handlers === ##
func _handle_idle_state(_delta: float) -> void:
	if enemy_node_pos != Vector3.ZERO and not target_node:
		_set_target(enemy_node_pos)
		state = STATE.MOVING

func _handle_moving_state(delta: float) -> void:
	# Throttle navigation updates to prevent hangs
	_last_nav_update += delta
	if _last_nav_update < NAV_UPDATE_INTERVAL:
		move_and_slide()
		return
	
	_last_nav_update = 0.0
	
	if not _is_navigation_ready():
		return
	
	if not nav_agent.is_target_reachable() or nav_agent.is_target_reached():
		if target_node:
			reset()
	
	var next_path_pos := nav_agent.get_next_path_position()
	
	if next_path_pos == Vector3.ZERO or next_path_pos.distance_to(global_position) < 0.1:
		return
	
	var dir := global_position.direction_to(next_path_pos)
	velocity = dir * move_speed
	
	var ROT_SPEED = 4
	var target_rotation := dir.signed_angle_to(Vector3.MODEL_FRONT, Vector3.DOWN)
	if abs(target_rotation - rotation.y) > deg_to_rad(60):
		ROT_SPEED = 20
	rotation.y = move_toward(rotation.y, target_rotation, delta * ROT_SPEED)
	
	move_and_slide()

func _handle_following_state(delta: float) -> void:
	if not target_check(): return
	
	_last_nav_update += delta
	if _last_nav_update < NAV_UPDATE_INTERVAL:
		move_and_slide()
		return
	
	_last_nav_update = 0.0
	
	if not _is_navigation_ready():
		return
	
	_set_target(target_node.global_position)
	
	if not nav_agent.is_target_reachable():
		reset()
		return
	
	var next_path_pos := nav_agent.get_next_path_position()
	
	if next_path_pos == Vector3.ZERO or next_path_pos.distance_to(global_position) < 0.1:
		return
	
	var dir := global_position.direction_to(next_path_pos)
	velocity = dir * move_speed
	
	var ROT_SPEED = 6
	var target_rotation := dir.signed_angle_to(Vector3.MODEL_FRONT, Vector3.DOWN)
	if abs(target_rotation - rotation.y) > deg_to_rad(45):
		ROT_SPEED = 25
	rotation.y = move_toward(rotation.y, target_rotation, delta * ROT_SPEED)
	
	move_and_slide()

func _handle_attacking_state(_delta: float) -> void:
	if not target_check(): return
	attack(target_node)
	velocity = Vector3.ZERO
	move_and_slide()

## == Setup Functions == ##
func setup_stats():
	super()
func _setup_navigation():
	await get_tree().process_frame
	
	if target_node:
		_set_target(target_node.position)

func _setup_vision_range():
	vision_area.get_node("CollisionShape3D").shape.radius = vision_range
	vision_area.body_entered.connect(_on_body_entered_vision)

@rpc("authority", "call_local")
func die():
	print(str(multiplayer.get_unique_id(), ": Death Called"))
	if Util.dedicated_server:
		_distribute_experience()
		died.emit()
		$MoneyEmitter.finished.connect(cleanup)
		$AudioStreamPlayer3D.finished.connect(cleanup)
	$Body.hide()
	$CollisionShape3D.disabled = true
	$AudioStreamPlayer3D.play()
	$MoneyEmitter.emitting = true
	
func cleanup():
	if !$MoneyEmitter.emitting and !$AudioStreamPlayer3D.playing:
		queue_free()

func reset():
	if state == STATE.DEAD: return
	super()
	if enemy_node_pos != Vector3.ZERO:
		_set_target(enemy_node_pos)
		state = STATE.MOVING

func _distribute_experience():
	# TODO: get all bodies in range on death
	pass
	#for body in bodies:
		#if body.is_in_group("player") and body.has_method("get_team"):
			## Give experience to players on the OPPOSITE team (enemy players who killed this minion)
			#if body.get_team() != team:
				#players_in_range.append(body)
	#
	#if players_in_range.size() > 0:
		#var exp_per_player = float(TotalExp) / players_in_range.size()
		#for player in players_in_range:
			#if player.has_method("gain_experience"):
				#player.gain_experience(int(exp_per_player))
	#

func _is_navigation_ready() -> bool:
	if not nav_agent:
		return false
	
	if not NavigationServer3D.get_maps().size() > 0:
		return false
		
	if not nav_agent.is_inside_tree():
		return false
		
	return true

func target_check() -> TARGET_STATUS:
	if state == STATE.DEAD: return TARGET_STATUS.INVALID
	# Verify node exists and is valid
	if not target_node or not is_instance_valid(target_node):
		reset()
		return TARGET_STATUS.INVALID
	# Verify node hasn't left target max_range
	var distance_to_target = global_position.distance_to(target_node.global_position)
	if distance_to_target > vision_range * 1.5:
		reset()
		return TARGET_STATUS.INVALID
	# Attack target if in range
	if distance_to_target <= vision_range:
		state = STATE.ATTACKING
		return TARGET_STATUS.IN_RANGE
	else:
		return TARGET_STATUS.OUT_OF_RANGE

func _on_body_entered_vision(body: Node3D):
	var eid
	if team != 1:
		eid = 1
	else:
		eid = 2
	if body.is_in_group(str("team", eid)):
		print("Enemy Spotted")
		set_attack_target(body)

func set_attack_target(body: Node3D):
	target_node = body
	target_node.died.connect(reset)
	state = STATE.FOLLOWING
	$FollowTimer.start(max_follow_time)

func _on_follow_timer_timeout():
	print("Follow timer timeout - returning to path")
	reset()
	if enemy_node_pos != Vector3.ZERO:
		_set_target(enemy_node_pos)
		state = STATE.MOVING

func move_towards_target(target: Node3D) -> void:
	if not target or not is_instance_valid(target):
		reset()
		return
	
	var distance_to_target = global_position.distance_to(target.global_position)
	
	if distance_to_target > vision_range * 1.5:
		reset()
		return
	
	_set_target(target.global_position)
	
	if distance_to_target > attack_range:
		state = STATE.FOLLOWING
	else:
		state = STATE.ATTACKING

func attack(body: Node3D = target_node):
	if !can_attack_now: return
	if !body or !body is Node3D: return
	
	var distance_to_target = body.global_position.distance_to(global_position)
	
	if distance_to_target > attack_range:
		state = STATE.FOLLOWING
		return
	
	can_attack_now = false
	$AttackTimeout.start()
	$FollowTimer.stop()
	$FollowTimer.start(max_follow_time)
	
	print("Minion team ", team, " attacking ", body.name, " with magical power ", magic_power)
	var spawner = get_tree().get_first_node_in_group("game_root")
	if not spawner:
		print("Error: Could not find game_root node")
		return
		
	var mp_spawner = spawner.get_node("MultiplayerSpawner")
	if not mp_spawner:
		print("Error: Could not find MultiplayerSpawner")
		return
		
	var direction = (body.global_position - global_position).normalized()
	var spawn_pos = global_position + direction
	
	print("Spawning projectile at ", spawn_pos, " towards ", direction)
