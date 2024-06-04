extends Node
class_name Map

@export var connected_players: Array

var Players = {}

func _ready():
	if not multiplayer.is_server():
		client_setup()
		return ;
	# Spawn all the Champions
	for player in connected_players:
		#var champ = load("res://champions/" + player["champ"] + ".tscn").instanciate()
		#champ.name = player["peer_id"]
		#champ.nametag = player["name"]
		#champ.team = player["team"]
		pass ;
func _process_delta(_delta):
	pass ;

func client_setup():
	# Add the player into the world
	# The player rig will ask the server for their champion
	var player_rig = load("res://champions/_player.tscn").instantiate();
	add_child(player_rig);
	rpc_id(get_multiplayer_authority(), "client_ready")
	pass

@rpc("any_peer")
func client_ready():
	print(connected_players);
	print(multiplayer.get_remote_sender_id())

@rpc("any_peer")
func register_player():
	var peer_id = multiplayer.get_remote_sender_id()
	
