extends Node

var Players = {}
var Team1 = Array()
var Team2 = Array()

# ENV
@onready var Heroes = $"../Heroes"
@onready var Player = $"../Players"
@onready var Spawn1 = $"../Spawn1"
@onready var Spawn2 = $"../Spawn2"

# Called when the node enters the scene tree for the first time.
func _ready():
	if not multiplayer.is_server():
		return
		
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(del_player)
	
	for id in multiplayer.get_peers():
		add_player(id)
	
	if not OS.has_feature("dedicated_server"):
		add_player(1)


@rpc("any_peer", "call_local")
func MoveTo(pos):
	var peer_id = multiplayer.get_remote_sender_id()
	var Character = Players[peer_id]
	if !Character:
		print("Failed to find character")
		return;
	Character.isAttacking = false;
	Character.targetEntity = null;
	Character.navigation_agent.set_target_position(pos);

func add_player(clientId: int):
	print("Player Connected: " + str(clientId))
	var character = preload("res://Characters/Archer.tscn").instantiate()
	var Team = 0
	if Team1.size() > Team2.size():
		Team2.append(clientId)
		Team = 2
		character.position = Spawn2.position
	else:
		Team1.append(clientId)
		Team = 1
		character.position = Spawn1.position
	character.pid = clientId
	character.name = str(clientId)
	Players[clientId] = character
	Heroes.add_child(character)
	character.rpc_id(clientId, "setOwner", [clientId, Team])

func del_player(clientId: int):
	if not Heroes.has_node(str(clientId)):
		return
	Heroes.get_node(str(clientId)).queue_free()
	
func _exit_tree():
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(del_player)

