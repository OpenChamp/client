extends Objective

@onready var range_collider_attack: Area3D = $AttackArea
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var healthbar: ProgressBar = $Healthbar
@onready var target_ray:MeshInstance3D = $TargetRay

var target_attacked_player: bool = false

var target_priority:Dictionary = {
	"Character": 2,
	"Minion": 1
}

func _ready():
	setup(
		null,
		$AttackArea,
		range_collider_attack,
		mesh_instance,
		attack_timer,
		healthbar
	)


func _process(delta):
	_update_healthbar(healthbar)
	set_target()
	if attack_timeout > 0:
		attack_timeout -= delta;
	if not multiplayer.is_server():
		pass
	if target_entity && attack_timer.is_stopped():
		init_auto_attack()

func set_target():
	var bodies = $AttackArea.get_overlapping_bodies()
	var target_found = false;
	for body in bodies:
		if body is CharacterBody3D and body.is_in_group("Champion"):
			target_entity = body
			target_found = true;
			#if body == target_entity:
				#target_found = true;
				#return;
			#elif body.team:
				#target_entity = body
				#target_found = true;
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
	

func die():
	is_dead = true
	mesh_instance.get_node("Crystal").hide()
