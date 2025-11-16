## ECS-Based Minion Entity
## Replaces the inheritance-based Minion_Base with a composition-based approach
## Integrates with CombatManager for unified combat handling
class_name MinionEntity
extends CharacterBody3D

# === Identification === #
@export var creature_id: int
@export var team: int = -1
@export var minion_type: String = "melee"  # "melee" or "mage"

# === Spawning === #
@export var spawn_point: Vector3
@export var enemy_node_pos: Vector3

# === Movement === #
@export var move_speed: float = 5.0
@export var follow_distance: float = 2.0
@export var max_follow_time: float = 8.0

# === Combat === #
@export var attack_cooldown: float = 1.0
@export var attack_range: float = 1.0
@export var max_health: float = 150.0
@export var physical_power: float = 15.0
@export var vision_range: float = 5.0

# === Audio === #
@export var death_sound: AudioStream

# === State === #
var state: STATE = STATE.IDLE
enum STATE {
	IDLE,
	MOVING,
	FOLLOWING,
	ATTACKING,
	DEAD
}

# === Internal === #
var health: float
var can_attack_now: bool = true
var attack_timer: float = 0.0
var target_node: Node3D = null
var target_pos: Vector3 = Vector3.ZERO

# === Nodes === #
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var vision_area: Area3D = $Vision
@onready var attack_timeout: Timer = $AttackTimeout
@onready var follow_timer: Timer = $FollowTimer

# === CombatManager Integration === #
var combat_manager: Node
var is_registered_with_combat: bool = false

# === Signals === #
signal died
signal health_changed(new_health: float, max_health: float)
signal attacked(target: Node)

func _ready():
	# Initialize health
	health = max_health
	
	# Set up team
	if team != -1:
		add_to_group(str("team", team))
	
	# Set starting position
	if spawn_point:
		global_position = spawn_point
	
	# Physics settings
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	
	# Timer connections
	attack_timeout.timeout.connect(func(): can_attack_now = true)
	attack_timeout.wait_time = attack_cooldown
	follow_timer.timeout.connect(_on_follow_timer_timeout)
	
	# Navigation setup
	if multiplayer.is_server():
		call_deferred("_setup_navigation")
		_setup_vision_range()
		
		# Register with CombatManager if available
		if has_node("/root/Main/CombatManager"):
			combat_manager = get_node("/root/Main/CombatManager")
		else:
			combat_manager = CombatManager
		
		if combat_manager and combat_manager.has_method("register_creature"):
			combat_manager.register_creature(self)
			is_registered_with_combat = true
			print("MinionEntity: Registered with CombatManager")
		
		# Set target if provided
		if enemy_node_pos != Vector3.ZERO:
			_set_target(enemy_node_pos)

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	
	if state == STATE.DEAD:
		return
	
	if health <= 0:
		_die()
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

func _process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	
	# Health regeneration
	if health < max_health and health < 100:
		health = min(health + delta, max_health)
		health_changed.emit(health, max_health)

## === State Handlers === ##

func _handle_idle_state(_delta: float) -> void:
	if enemy_node_pos != Vector3.ZERO and not target_node:
		_set_target(enemy_node_pos)
		state = STATE.MOVING

func _handle_moving_state(delta: float) -> void:
	if not nav_agent or not _is_navigation_ready():
		move_and_slide()
		return
	
	if not nav_agent.is_target_reachable() or nav_agent.is_target_reached():
		if target_node:
			_reset()
		else:
			state = STATE.IDLE
		return
	
	var next_path_pos := nav_agent.get_next_path_position()
	if next_path_pos == Vector3.ZERO or next_path_pos.distance_to(global_position) < 0.1:
		return
	
	var dir := global_position.direction_to(next_path_pos)
	velocity = dir * move_speed
	
	var rot_speed = 60
	var target_rotation := dir.signed_angle_to(Vector3.MODEL_FRONT, Vector3.DOWN)
	if abs(target_rotation - rotation.y) > deg_to_rad(30):
		rot_speed = 80
	rotation.y = move_toward(rotation.y, target_rotation, delta * rot_speed)
	
	move_and_slide()

func _handle_following_state(_delta: float) -> void:
	if not _target_check():
		return
	
	if not nav_agent or not _is_navigation_ready():
		move_and_slide()
		return
	
	var distance_to_target = global_position.distance_to(target_node.global_position)
	
	if distance_to_target <= attack_range:
		state = STATE.ATTACKING
		return
	
	# Update target position for following
	target_pos = target_node.global_position
	nav_agent.target_position = target_pos
	
	if not nav_agent.is_target_reachable():
		_reset()
		return
	
	var next_path_pos := nav_agent.get_next_path_position()
	if next_path_pos.distance_to(global_position) < 0.1:
		return
	
	var dir := global_position.direction_to(next_path_pos)
	velocity = dir * move_speed
	rotation.y = dir.signed_angle_to(Vector3.MODEL_FRONT, Vector3.DOWN)
	
	move_and_slide()

func _handle_attacking_state(_delta: float) -> void:
	if not _target_check():
		return
	
	var distance = global_position.distance_to(target_node.global_position)
	
	if distance > attack_range * 1.5:
		state = STATE.FOLLOWING
		return
	
	# Face target
	var dir = global_position.direction_to(target_node.global_position)
	rotation.y = dir.signed_angle_to(Vector3.MODEL_FRONT, Vector3.DOWN)
	
	# Attack if cooldown is ready
	if can_attack_now:
		_attack(target_node)
		can_attack_now = false
		attack_timeout.start()

## === Action Methods === ##

func _attack(target: Node) -> void:
	if not multiplayer.is_server():
		return
	
	# Use CombatManager if available
	if combat_manager and combat_manager.has_method("apply_damage"):
		var damage = int(physical_power)
		combat_manager.apply_damage(self, target, damage, OC.DAMAGE_TYPE.PHYSICAL)
		print("MinionEntity: Attacked %s for %d damage" % [target.name, damage])
	
	attacked.emit(target)

@rpc("authority", "call_local")
func take_damage(damage: int, damage_type: OC.DAMAGE_TYPE = OC.DAMAGE_TYPE.PHYSICAL) -> void:
	# Apply damage reduction
	var reduced_damage = damage
	match damage_type:
		OC.DAMAGE_TYPE.PHYSICAL:
			reduced_damage = int(damage * 0.95)  # Minions have 5% armor
		OC.DAMAGE_TYPE.MAGICAL:
			reduced_damage = int(damage * 0.90)  # Minions have 10% magic resist
		OC.DAMAGE_TYPE.TRUE:
			reduced_damage = damage
	
	health -= reduced_damage
	health_changed.emit(health, max_health)
	
	if health <= 0:
		_die()

func _die() -> void:
	state = STATE.DEAD
	rpc("_on_death_visual")
	died.emit()
	
	# Unregister from combat manager
	if combat_manager and is_registered_with_combat:
		if combat_manager.has_method("unregister_creature"):
			combat_manager.unregister_creature(self)

@rpc("authority", "call_local")
func _on_death_visual() -> void:
	if death_sound:
		AudioManager.play_sound(death_sound, global_position)
	queue_free()

## === Navigation and Targeting === ##

func _setup_navigation() -> void:
	if nav_agent:
		nav_agent.path_max_distance = 20.0
		nav_agent.target_desired_distance = 0.5

func _setup_vision_range() -> void:
	if vision_area:
		var shape = SphereShape3D.new()
		shape.radius = vision_range
		var collision = vision_area.get_child(0) as CollisionShape3D
		if collision:
			collision.shape = shape

func _is_navigation_ready() -> bool:
	if not is_node_ready():
		return false
	return true

func _set_target(target: Vector3) -> void:
	target_pos = target
	if nav_agent:
		nav_agent.target_position = target_pos
	state = STATE.MOVING

func _target_check() -> bool:
	if not target_node or not is_instance_valid(target_node):
		_reset()
		return false
	if target_node.health <= 0 if target_node.has_meta("health") else false:
		_reset()
		return false
	return true

func _reset() -> void:
	target_node = null
	target_pos = Vector3.ZERO
	state = STATE.IDLE
	follow_timer.stop()

func _on_follow_timer_timeout() -> void:
	if target_node:
		_reset()

## === Utility === ##

func is_alive() -> bool:
	return health > 0 and state != STATE.DEAD

func get_team() -> int:
	return team

func get_creature_id() -> int:
	return creature_id

func get_entity_position() -> Vector3:
	return global_position
