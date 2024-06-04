extends Node3D

@export var ability_name:String

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the Server Listener
	var map = get_parent()
	while !map.is_in_group("Map"):
		map = map.get_parent();
	var listener = map.get_node("ServerListener");
	listener.rpc_id(get_multiplayer_authority(), "spawn_ability", ability_name, 3, position, 1, 5, id)
