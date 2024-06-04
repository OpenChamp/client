extends Node
class_name Map

@export var connected_players : Array

func _ready():
	if not multiplayer.is_server():
		client_setup()
		return;
	pass;
func _process(_delta):
	pass;
func _process_delta(_delta):
	pass;


func client_setup():
	# Add the player into the world
	# The player rig will ask the server for their champion
	var player_rig = load("res://champions/_player.tscn").instanciate()
	add_child(player_rig);
	rpc_id(get_multiplayer_authority(), "client_ready")
	pass

@rpc("any_peer")
func client_ready():
	print(connected_players);
	print(multiplayer.get_remote_sender_id())
