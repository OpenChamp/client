extends Champion
class_name Dummy 

func _ready():
	super()
	healthbar.size = Vector2(100, 15)
	global_position = server_position
	

func die():
	super()
	var server_listener = $"../../ServerListener"
	server_listener.rpc_id(multiplayer.get_unique_id(), "respawn", self)
