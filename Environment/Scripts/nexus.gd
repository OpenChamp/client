extends Objective

@onready var range_collider_attack: Area3D = $AttackArea
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var attack_timer: Timer = $AttackTimer
@onready var healthbar: ProgressBar = $Healthbar

signal game_over(team)

func _ready():
	setup(
		null,
		null,
		range_collider_attack,
		mesh_instance,
		attack_timer,
		healthbar
	)

func _physics_process(delta):
	_update_healthbar(healthbar)

func take_damage(damage: float):
	health -= damage
	if health <= 0:
		is_dead = true
		emit_signal("game_over", team)
		die()
