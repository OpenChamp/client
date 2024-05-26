extends CharacterBody3D

# Net  Vars
@export var team: int
@export var pid: int

@export var health: float = 550.00
@export var mana = 300
@export var attack_damage = 60
@export var attack_speed = .75 #APM
@export var armor = 20 
@export var resistance = 30
@export var speed = 5 # 330 
@export var range = 3

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@export var range_collider: Area3D
@export var projectile: PackedScene


var is_attacking: bool = false
var is_dead: bool = false
var target_entity: CharacterBody3D
var attack_timeout = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set Range
	range_collider.get_node("./CollisionShape3D").shape.radius = range
	range_collider.get_node("./MeshInstance3D").mesh.top_radius = float(range)
	# Set Nav
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5
	# Set Health
	call_deferred("actor_setup")
	$Healthbar.max_value = health
	$Healthbar.value = health
	pass # Replace with function body.

func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame
	var pos
	if target_entity:
		pos = target_entity.position
	else:
		pos = position
	navigation_agent.set_target_position(pos)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Healthbar.update_loc(position)
	if attack_timeout > 0:
		attack_timeout -= delta
	if is_attacking:
		var bodies = range_collider.get_overlapping_bodies()
		var action_performed = false
		if bodies:
			for body in bodies:
				if body == target_entity:
					action_performed = true
					if target_entity.is_dead:
						is_attacking = false
						target_entity = null
					elif attack_timeout <= 0:
						print("Attack!")
						attack_timeout = attack_speed
						auto_attack()
			if !action_performed:
				navigation_agent.set_target_position(target_entity.position)
				move(delta)
		else:
			navigation_agent.set_target_position(target_entity.position)
			move(delta)
			
	elif !navigation_agent.is_navigation_finished():
		move(delta)

func move(delta):
	var target_pos = navigation_agent.get_next_path_position()
	var local_destination = target_pos - global_position
	var direction = local_destination.normalized()
	look_at(direction)
	if global_position.distance_to(target_pos) > 0.1:
		var dir = (target_pos - global_position).normalized()
		var dist = speed * delta
		global_position += dir * dist
	else:
		global_position = target_pos

func move_to(pos: Vector3):
	is_attacking = false
	target_entity = null
	navigation_agent.set_target_position(pos)

func attack(entity: CharacterBody3D):
	target_entity = entity
	navigation_agent.set_target_position(target_entity.position)
	is_attacking = true

func auto_attack():
	var arrow = projectile.instantiate()
	arrow.position = position
	arrow.target = target_entity
	arrow.damage = attack
	get_node("/root").add_child(arrow)
	pass
	
func take_damage(damage):
	print(damage)
	var taken: float = armor
	taken /= 100
	taken = damage / (taken + 1)
	print(taken)
	$Healthbar.value -= taken
	if $Healthbar.value <= 0:
		die()
		
func die():
	is_dead = true
	hide()
	print("RIP")
