extends Unit

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var range_collider_activate: Area3D = $ActivationArea
@onready var range_collider_attack: Area3D = $ActivationArea
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var attack_timer: Timer = $AttackTimer

func _ready():
	name = "minion_%d_%d" % [team, id]
	attack_timer.timeout.connect(finish_auto_attack)
	range_collider_attack.get_node("./CollisionShape3D").shape.radius = attack_range
	range_collider_activate.get_node("./CollisionShape3D").shape.radius = activation_range
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.5
	call_deferred("actor_setup", nav_agent)
	$Healthbar.max_value = max_health
	_update_healthbar($Healthbar)
	if team == 1:
		mesh_instance.set_surface_override_material(0, load("res://Environment/Materials/Blue.material"))
	elif team == 2:
		mesh_instance.set_surface_override_material(0, load("res://Environment/Materials/Red.material"))
	if not multiplayer.is_server():
		set_physics_process(false)

func _physics_process(delta):
	var current_location = global_transform.origin
	var target_location = update_target_location(nav_agent)
	if current_location.distance_to(target_location) <= .1:
		return
	velocity = (target_location - current_location).normalized() * speed
	look_at(target_location)
	move_and_slide()

func _on_activation_area_body_entered(body):
	if target_entity == null:
		print_debug(body)
		target_entity = body

func _on_activation_area_body_exited(body):
	if target_entity == body:
		target_entity = null
