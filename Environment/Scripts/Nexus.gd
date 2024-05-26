extends Unit

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var range_collider_activate: Area3D = $ActivationArea
@onready var range_collider_attack: Area3D = $AttackArea
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var attack_timer: Timer = $AttackTimer
@onready var healthbar: ProgressBar = $Healthbar

signal game_over(team)

func _ready():
	speed = 0.0
	max_health = 800
	setup(
		nav_agent,
		range_collider_activate,
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
		emit_signal("game_over", team)
		die()
