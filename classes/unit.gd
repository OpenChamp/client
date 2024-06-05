extends CharacterBody3D
class_name Unit

# General Stats:
@export var id: int
@export var team: int
@export var move_speed: float = 100.0
# Defensive Stats:
@export var max_health: float = 100.0
@export var health: float = max_health
@export var max_mana: float = 100.0
@export var mana:float = max_mana
@export var armor: float = 20.0
@export var magic_resist:float = 20.0
@export var overheal: float = 0;
# Offensive Stats:
@export var attack_damage: float = 60.0
@export var attack_speed: float = .75
@export var attack_windup: float = attack_speed/100;
@export var attack_range: float = 3.0
@export var attack_time: float = 0.1
@export var critical_chance: float = 0.0
@export var critical_damage: float = 100
@export var projectile: PackedScene = null
# Targeting:
@export var activation_range: float = 5.0
# Rotation:
@export var turn_speed: float = 15.0
var target_entity: Node = null

signal died
# Timers:
#@onready var attack_timer: Timer = $AttackTimer
## States:
#var is_attacking: bool = false
#var is_dead: bool = false
## Signals:
#var can_respawn: bool = false # Only players or super special units
#signal unit_died
## UI:
#@onready var healthbar: ProgressBar = $Healthbar
#
#
#func _process(delta):
	#if multiplayer.is_server():
		#return;
	#_update_healthbar(healthbar)
#
func setup(default_stats:Dictionary):
	for key in default_stats.keys():
		self[key] = default_stats[key]
	
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
#func _update_healthbar(node: ProgressBar):
	#node.value = health
#
#
#func update_target_location(nav_agent: NavigationAgent3D, target_location: Vector3):
	#nav_agent.target_position = target_location
	#
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
#func move(nav_agent: NavigationAgent3D, delta: float):
	#var current_location = global_transform.origin
	#var target_location = nav_agent.get_next_path_position()
	## Check if target is looking at target
	#
	#if current_location.distance_to(target_location) <= .1:
		#return
	#var direction = target_location - current_location
	#velocity = direction.normalized() * speed * delta
	#rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), turn_speed * delta)
	#move_and_slide()
#
## Combat
#
#func take_damage(damage: float):
	#var taken: float = armor / 100
	#taken = damage / (taken + 1)
	#health -= taken
	#if health <= 0:
		#health = 0
		#die()
#
#func heal(amount:float, keep_extra:bool = false):
	#health += amount
	#if health > max_health and not keep_extra:
		#health = max_health
	#else:
		#overheal = health - max_health
		#health = max_health
#
## Setters
#
#func set_health(total):
	#health = total;
#
## Getters
#
#func get_health_max() -> int:
	#return max_health
#
#func get_health() -> int:
	#return health
