extends Unit
class_name Champion


@export var nametag : String


func _ready():
	super()
	has_mana = true
	healthbar.size = Vector2(100, 15)
	global_position = server_position
	

func die():
	super()
	var server_listener = $"../../ServerListener"
	server_listener.rpc_id(multiplayer.get_unique_id(), "respawn", self)


func _trigger_ability(index: int):
	if not can_cast(): return
	pass


@rpc("authority", "call_local")
func change_state(new, args):
	$StateMachine.change_state(new, args);
