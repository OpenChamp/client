class_name Unit extends CharacterBody3D

# General Stats:
@export var id: int
@export var team: int
@export var speed: float = 3.0

# Defensive Stats:
@export var max_health: float = 400.0
@export var health: float = max_health
@export var armor: float = 20.0

# Offensive Stats:
@export var attack_damage: float = 60.0
@export var attack_speed: float = .75
@export var attack_timeout: float = 0.0
@export var attack_range: float = 3.0
@export var attack_time: float = 0.1
@export var projectile:NodePath = ""

# Targeting
@export var activation_range: float = 5.0
var target_entity 

# States:
var is_attacking: bool = false

func _ready():
	add_user_signal("unit_died")

func actor_setup(nav_agent: NavigationAgent3D):
	# Wait for first physics frame so the NavigationServer can sync
	await get_tree().physics_frame
	if target_entity:
		nav_agent.target_position = target_entity.position
	else:
		nav_agent.target_position = position

func _update_healthbar(healthbar: ProgressBar):
	healthbar.value = health
	if(health <= 0):
		health = 0
		die()

func update_target_location(nav_agent: NavigationAgent3D) -> Vector3:
	if target_entity != null: 
		nav_agent.target_position = target_entity.global_transform.origin
	else:
		nav_agent.target_position = global_transform.origin
	return nav_agent.target_position

func target_in_range(collider: Area3D):
	var bodies = collider.get_overlapping_bodies()
	for body in bodies:
		if body == target_entity:
			return true
	return false

func attack(entity: CharacterBody3D, nav_agent: NavigationAgent3D):
	target_entity = entity
	nav_agent.set_target_position(target_entity.position)
	is_attacking = true

func take_damage(damage: float):
	print_debug(damage)
	var taken: float = armor / 100
	taken = damage / (taken + 1)
	print_debug(taken)
	health -= taken
	if(health <= 0):
		die()

func die():
	self.queue_free()

func init_auto_attack(attack_timer: Timer):
	if attack_timeout > 0:
		return
	attack_timer.wait_time = attack_time
	attack_timer.start()

func finish_auto_attack(attack_timer: Timer, collider: Area3D):
	print("Attacking")
	attack_timer.stop()
	#Check if target is still in range
	if !target_in_range(collider):
		return
	attack_timeout = attack_speed
	
	var arrow = load(projectile).instantiate()
	arrow.position = position
	arrow.target = target_entity
	arrow.damage = attack
	get_node("/root").add_child(arrow)
