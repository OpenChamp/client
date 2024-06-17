extends CharacterBody3D
class_name Unit

# General Stats:
@export var id: int
@export var team: int
@export var move_speed: float = 100.0
# Defensive Stats:
@export var max_health: float = 100.0
@onready var current_health: float = max_health
@export var health_regen: float = 5
var overheal: float = 0;
@export var armor: float = 20.0
@export var magic_resist:float = 20.0
# Offensive Stats:
@export var attack_damage: float = 60.0
@export var attack_speed: float = 0.75
@export var attack_windup: float = 0.2
@export var attack_range: float = 3.0: set = _set_attack_range
@export var attack_time: float = 0.1
@export var critical_chance: float = 0.0
@export var critical_damage: float = 100
# Targeting:
@export var activation_range: float = 5.0
# Rotation:
@export var turn_speed: float = 15.0
# AI:
var target_entity: Node = null
var is_aggressive: bool = false
var is_patrolling: bool = false
@export var can_respawn: bool = false;
@onready var nav_agent :NavigationAgent3D = $NavigationAgent3D
# Signals
signal died
# UI
@export var projectile_scene: PackedScene = null
@onready var range_collider = $RangeCollider
@onready var healthbar = $Healthbar

func _ready():
	# Set Range
	if !range_collider == null:
		_set_attack_range(attack_range)


func _process(delta):
	_update_healthbar(healthbar)

func _physics_process(delta: float):
	move(delta);

# Setters
func _set_attack_range(new_range=null):
	if new_range < 0: return
	if not range_collider: return
	range_collider.get_child(0).shape.radius = new_range
#func setup(
	#nav_agent: NavigationAgent3D,
	#range_collider_activate: Area3D,
	#range_collider_attack: Area3D,
	#mesh_instance: MeshInstance3D,
	#attack_timer_node: Timer,
	#healthbar_node: ProgressBar
#):
	#healthbar = healthbar_node
	#attack_timer = attack_timer_node
	#attack_timer.timeout.connect(finish_auto_attack.bind(attack_timer, range_collider_attack))
	#update_collision_radius(range_collider_activate, activation_range)
	#update_collision_radius(range_collider_attack, attack_range)
	#nav_agent.path_desired_distance = 0.5
	#nav_agent.target_desired_distance = 0.5
	#healthbar.max_value = max_health
	#health = max_health
	#_update_healthbar(healthbar)
	#if multiplayer.is_server():
		#return;
	#if team == 1:
		#mesh_instance.set_surface_override_material(0, load("res://environment/materials/blue.material"))
	#elif team == 2:
		#mesh_instance.set_surface_override_material(0, load("res://environment/materials/red.material"))
	#if not multiplayer.is_server():
		#set_physics_process(false)
#
#func update_collision_radius(range_collider: Area3D, radius: float):
	#var collision_shape = CylinderShape3D.new()
	#collision_shape.radius = radius
	#range_collider.get_node("CollisionShape3D").shape = collision_shape
#
#func actor_setup(nav_agent: NavigationAgent3D):
	## Wait for first physics frame so the NavigationServer can sync
	#await get_tree().physics_frame
	#if target_entity:
		#nav_agent.target_position = target_entity.position
	#else:
		#nav_agent.target_position = position
#
#

# Movement
func update_target_location(target_location: Vector3):
	print("Target Location Updated");
	is_aggressive = false
	target_entity = null
	nav_agent.target_position = target_location
#
#func target_in_attack_range(collider: Area3D):
	#var bodies = collider.get_overlapping_bodies()
	#if bodies.has(target_entity):
		#return true
	#return false
#
#
#func search_for_target(collider: Area3D):
	#var bodies = collider.get_overlapping_bodies()
	#for body in bodies:
		#if body.team != team:
			#target_entity = body
			#return;
#
#
#func attack(entity: CharacterBody3D, nav_agent: NavigationAgent3D):
	#target_entity = entity
	#nav_agent.set_target_position(target_entity.position)
	#is_attacking = true
#
#func die():
	#is_dead = true
#
	#if !can_respawn:
		#self.queue_free()
#
#
#func init_auto_attack():
	#if attack_timeout > 0:
		#return
	#if !attack_timer.is_stopped():
		#return;
	#attack_timer.wait_time = attack_time
	#attack_timer.start()
#
#
#func finish_auto_attack(timer: Timer, collider: Area3D):
	#timer.stop()
	##Check if target is still in range
	#if not target_in_attack_range(collider):
		#return
	#attack_timeout = attack_speed
	#
	#if projectile:
		#var arrow = projectile.instantiate()
		#arrow.position = position
		#arrow.target = target_entity
		#arrow.damage = attack_damage
		#get_node("Projectiles").add_child(arrow, true)
	#else:
		## Melee Attack
		#target_entity.take_damage(attack_damage)
#
func move(delta: float):
	var target_location = nav_agent.get_next_path_position()
	if global_position.distance_to(target_location) <= .1:
		return
	var current_location = global_position
	var direction = target_location - current_location
	velocity = direction.normalized() * move_speed * delta
	rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), turn_speed * delta)
	move_and_slide()

## Combat
func take_damage(damage: float):
	var taken: float = armor / 100
	taken = damage / (taken + 1)
	current_health -= taken
	if current_health <= 0:
		current_health = 0
		die()

func heal(amount:float, keep_extra:bool = false):
	current_health += amount
	if current_health > max_health and not keep_extra:
		current_health = max_health
	else:
		overheal = current_health - max_health
		current_health = max_health

func die():
	get_tree().quit()

# UI
func _update_healthbar(node: ProgressBar):
	node.value = current_health


@rpc("authority", "call_local")
func change_state(new, args):
	$StateMachine.change_state(new, args);
