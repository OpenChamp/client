extends Unit
class_name Champion


@export var nametag : String

@export var max_mana: float = 100.0
@onready var current_mana: float = max_mana
@export var mana_regen: float = 5


func _ready():
	super()
	healthbar.size = Vector2(100, 15)
	global_position = server_position
	

func die():
	super()
	var server_listener = $"../../ServerListener"
	server_listener.rpc_id(multiplayer.get_unique_id(), "respawn", self)


@rpc("authority", "call_local")
func change_state(new, args):
	$StateMachine.change_state(new, args);
