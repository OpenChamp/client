class_name Objective extends StaticBody3D

# General Stats:
@export var id: int
@export var team: int
@export var speed: float = 500.0
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
@export var projectile: PackedScene = null
# Targeting:
@export var activation_range: float = 5.0
var target_entity: Node = null
# Timers:
@onready var attack_timer: Timer = $AttackTimer
# States:
var is_attacking: bool = false
var is_dead: bool = false
# Signals:
signal objective_died
# UI:
@onready var healthbar: ProgressBar = $Healthbar
@onready var dmg_popup_template = preload("res://ui/DamagePopup.tscn")

@onready var target_ray: MeshInstance3D = $TargetRay
@export var cast_time: float = 0.1


func setup(
	_nav_agent: NavigationAgent3D,
	_range_collider_activation: Area3D,
	range_collider_attack: Area3D,
	mesh_instance: MeshInstance3D,
	attack_timer_node: Timer,
	healthbar_node: ProgressBar
):
	healthbar = healthbar_node
	attack_timer = attack_timer_node
	attack_range = 10;
	attack_speed = 1.0
	speed = 0.0
	activation_range = 1.0
	attack_timer.timeout.connect(finish_auto_attack.bind(attack_timer, range_collider_attack))
	update_collision_radius(range_collider_attack, attack_range)
	healthbar.max_value = max_health
	health = max_health
	_update_healthbar(healthbar)
	if multiplayer.is_server():
		return;
	if team == 1:
		mesh_instance.get_node("Crystal").set_surface_override_material(0, load("res://environment/materials/blue.material"))
	elif team == 2:
		mesh_instance.get_node("Crystal").set_surface_override_material(0, load("res://environment/materials/red.material"))

func _process(delta):
	if is_dead:
		return
	if attack_timeout > 0:
		attack_timeout -= delta;

func update_collision_radius(range_collider: Area3D, radius: float):
	var collision_shape = CylinderShape3D.new()
	collision_shape.radius = radius
	range_collider.get_node("CollisionShape3D").shape = collision_shape

func _update_healthbar(node: ProgressBar):
	node.value = health

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
	var taken: float = armor / 100
	taken = damage / (taken + 1)

	if taken > 0:
		var popup = dmg_popup_template.instantiate()
		add_child(popup, true)
		popup.play(str(int(taken)))

	health -= taken

func init_auto_attack():
	if !multiplayer.is_server():
		pass ;
	if attack_timeout > 0 and attack_timer.is_stopped():
		return
	attack_timer.wait_time = cast_time
	attack_timer.start()

func finish_auto_attack(attack_timer: Timer, collider: Area3D):
	attack_timer.stop()
	#Check if target is still in range
	if not target_in_attack_range(collider):
		return
	attack_timeout = attack_speed
	
	var shot = projectile.instantiate()
	shot.position = position
	shot.target = target_entity
	if !shot.target.is_in_group("Champion"):
		shot.damage = attack_damage/10  # Reduced damage to non-champs
	else:
		shot.damage = attack_damage
	get_node("Projectiles").add_child(shot, true)
	init_auto_attack()

func set_target():
	var bodies = $AttackArea.get_overlapping_bodies()
	var target_found = false;
	for body in bodies:
		if body is CharacterBody3D and body.team != team:
			target_entity = body
			target_found = true
	if !target_found:
		target_entity = null;
		target_ray.hide()
	else:
		show_target_ray()

func show_target_ray():
	target_ray.show()
	var mid = (target_entity.position + position) / 2
	var dis = position.distance_to(target_entity.position);
	var dir = (target_entity.position - position).normalized()
	target_ray.global_position = mid;
	
	var basis = Basis()
	basis = basis.looking_at(dir, Vector3.UP)
	target_ray.global_transform = Transform3D(basis, mid)

	# Set the mesh's scale to match the distance
	var scale = Vector3(1, dis / 2, 1) # Assuming the cylinder's height is 2 units
	target_ray.scale = scale
