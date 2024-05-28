extends Unit

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var range_collider_activate: Area3D = $ActivationArea
@onready var range_collider_attack: Area3D = $AttackArea
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var healthbar: ProgressBar = $Healthbar

var patrol_path: Node3D = null
var path_array: Array[Marker3D] = []


func _ready():
	name = "minion_%d_%d" % [team, id]
	activation_range = 10.0
	speed = 3.0
	max_health = 100.0
	
	for point in patrol_path.get_children():
		path_array.append(point)
	
	setup(
		nav_agent,
		range_collider_activate,
		range_collider_attack,
		mesh_instance,
		attack_timer,
		healthbar
	)


func _process(delta):
	_update_healthbar(healthbar)
	if not multiplayer.is_server():
		return
	if target_entity == null:
		if not patrol_path == null:
			update_target_location(nav_agent, get_closest_patrol_point())
	else:
		update_target_location(nav_agent, target_entity.global_transform.origin)
	var current_location = global_transform.origin
	var target_location = nav_agent.get_next_path_position()
	if current_location.distance_to(target_location) <= .1:
		return
	velocity = (target_location - current_location).normalized() * speed
	look_at(target_location)
	move_and_slide()


func get_closest_patrol_point() -> Vector3:
	if path_array.size() == 0:
		return global_position
	var closest_point: Vector3 = path_array[0].global_position
	var distance: float
	for point in path_array:
		distance = global_position.distance_to(point.global_position)
		if distance < 1:
			path_array.remove_at(path_array.bsearch(point))
			continue
		if distance < global_position.distance_to(closest_point):
			closest_point = point.global_position
	return closest_point


func _on_activation_area_body_entered(body):
	if not target_entity == null:
		return
	elif target_entity == self:
		return
	elif body.team == team:
		return
	else:
		target_entity = body


func _on_activation_area_body_exited(body):
	if target_entity == body:
		target_entity = null
