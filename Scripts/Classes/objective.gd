class_name Objective extends Unit

@export var is_dead: bool = false

func setup(
	_nav_agent: NavigationAgent3D,
	_range_collider_activation: Area3D,
	range_collider_attack: Area3D,
	mesh_instance: MeshInstance3D,
	attack_timer: Timer,
	healthbar: ProgressBar
):
	speed = 0.0
	activation_range = 0.0
	attack_timer.timeout.connect(finish_auto_attack.bind(attack_timer, range_collider_attack))
	update_collision_radius(range_collider_attack, attack_range)
	healthbar.max_value = max_health
	health = max_health
	_update_healthbar(healthbar)
	if team == 1:
		mesh_instance.get_node("Crystal").set_surface_override_material(0, load("res://Environment/Materials/blue.material"))
	elif team == 2:
		mesh_instance.get_node("Crystal").set_surface_override_material(0, load("res://Environment/Materials/red.material"))
	if not multiplayer.is_server():
		set_physics_process(false)

func update_collision_radius(range_collider: Area3D, radius: float):
	var collision_shape = CylinderShape3D.new()
	collision_shape.radius = radius
	range_collider.get_node("CollisionShape3D").shape = collision_shape

func _update_healthbar(healthbar: ProgressBar):
	healthbar.value = health
	if health <= 0:
		health = 0
		die()

func target_in_attack_range(collider: Area3D):
	var bodies = collider.get_overlapping_bodies()
	for body in bodies:
		if body == target_entity:
			return true
	return false

func attack(entity: CharacterBody3D, _nav_agent: NavigationAgent3D):
	target_entity = entity
	is_attacking = true

func take_damage(damage: float):
	print_debug(damage)
	var taken: float = armor / 100
	taken = damage / (taken + 1)
	print_debug(taken)
	health -= taken
	if health <= 0:
		die()

func die():
	self.queue_free()

func init_auto_attack(attack_timer: Timer):
	if attack_timeout > 0:
		return
	attack_timer.wait_time = attack_time
	attack_timer.start()

func finish_auto_attack(attack_timer: Timer, collider: Area3D):
	attack_timer.stop()
	#Check if target is still in range
	if !target_in_attack_range(collider):
		return
	attack_timeout = attack_speed
	
	var arrow = projectile.instantiate()
	arrow.position = position
	arrow.target = target_entity
	arrow.damage = attack_damage
	get_node("/root").add_child(arrow)
