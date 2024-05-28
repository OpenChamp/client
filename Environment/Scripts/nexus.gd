extends Objective

@onready var range_collider_attack: Area3D = $AttackArea
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var healthbar: ProgressBar = $Healthbar

signal game_over(team)


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

func take_damage(damage: float):
	health -= damage
	if health <= 0:
		is_dead = true
		emit_signal("game_over", team)
		die()

var target_attacked_player: bool = false

var target_priority:Dictionary = {
	"Character": 2,
	"Minion": 1
}

func die():
	is_dead = true
	mesh_instance.get_node("Crystal").hide()
