extends Objective

@onready var range_collider_attack: Area3D = $AttackArea
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var healthbar_node: ProgressBar = $Healthbar

var target_attacked_player: bool = false

var target_priority: Dictionary = {
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
		healthbar_node
	)

func _process(delta):
	
	if is_dead:
		return ;
	_update_healthbar(healthbar)
	if health <= 0:
		$StateMachine.change_state("obj_dead");
