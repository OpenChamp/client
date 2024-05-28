extends Objective

@onready var range_collider_attack: Area3D = $AttackArea
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var attack_timer: Timer = $AttackTimer
@onready var healthbar: ProgressBar = $Healthbar

#var target: CharacterBody3D
#var target_attacked_player: bool = false


func _ready():
	setup(
		null,
		null,
		range_collider_attack,
		mesh_instance,
		attack_timer,
		healthbar
	)


func _process(delta):
	_update_healthbar(healthbar)


func die():
	is_dead = true
	mesh_instance.get_node("Crystal").hide()
	#$GPUParticles3D.one_shot = true
	#$GPUParticles3D.emitting = true


#func _process(delta):
#	if attackTimeout > 0:
#		attackTimeout -= delta
#	var bodies = $Range.get_overlapping_bodies()
#	for body in bodies:
#		if body is CharacterBody3D and not body.team == team:
#			if attackTimeout <=0:
#				#Attack(body)
#				print("Turret Attack!")
#	pass
