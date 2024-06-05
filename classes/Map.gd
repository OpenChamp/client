extends Node
class_name Open_Map


@export var connected_players: Array

@export var champion_container: Node

var Players = {}
var Spawns = []

func _ready():
	if not multiplayer.is_server():
		client_setup()
		return ;
	# Get both team spawns
	Spawns.append(get_node("Spawn1").position)
	Spawns.append(get_node("Spawn2").position)
	# Spawn all the Champions
	for player in connected_players:
		var champ = load("res://champions/" + player["champ"].to_lower() + ".tscn").instantiate()
		champ.name = str(player["peer_id"])
		champ.id = player["peer_id"]
		champ.nametag = player["name"]
		champ.team = player["team"]
		champ.position = Spawns[champ.team-1]
		champion_container.add_child(champ)
		pass ;
		
func _process_delta(_delta):
	pass ;

func client_setup():
	# Add the player into the world
	# The player rig will ask the server for their champion
	var player_rig = load("res://champions/_player.tscn").instantiate();
	add_child(player_rig);
	pass

@rpc("any_peer")
func client_ready():
	print(connected_players);
	print(multiplayer.get_remote_sender_id())

@rpc("any_peer")
func register_player():
	var peer_id = multiplayer.get_remote_sender_id()
