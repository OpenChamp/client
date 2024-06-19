class_name NPC_Unit
extends Unit

enum AggroType {
	PASSIVE, # Doesn't attack.
	NEUTRAL, # Attacks when attacked.
	AGGRESSIVE, # Attacks anything not on its team.
}

var aggro_type : AggroType
var aggro_distance : float = 1.0
var deaggro_distance: float = 3.0

@onready var aggro_collider: Area3D = $AggroCollider

func _ready():
	aggro_collider.body_entered.connect(_enter_aggro_range)




func _enter_aggro_range(body: PhysicsBody3D):
	if aggro_type != AggroType.AGGRESSIVE: return
	if target_entity: return
	change_state("Attacking", null)

