extends Node3D

var SPAWN_RANDOM:float = 5.0
var Team1 = Array()
var Team2 = Array()
# Called when the node enters the scene tree for the first time.
func _ready():
	print("Level Loaded")
	if not multiplayer.is_server():
		return
		
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(del_player)
	
	# Not Needed, but may save headache if Servers have Map Rollovers
	for id in multiplayer.get_peers():
		add_player(id)
		
	if not OS.has_feature("dedicated_server"):
		add_player(1)
		
func add_player(clientId: int):
	print("Player Connected: " + str(clientId))
	var character = preload("res://Characters/Archer.tscn").instantiate()
	var Team = 0
	if Team1.size() > Team2.size():
		Team2.append(clientId)
		Team = 2
		character.position = $Spawn2.position
	else:
		Team1.append(clientId)
		Team = 1
		character.position = $Spawn1.position
	character.pid = clientId
	character.name = str(clientId)
	$Heroes.add_child(character)
	multiplayer.rpc(clientId, character, "setOwner", [clientId, Team])
	
	
func del_player(clientId: int):
	if not $Heroes.has_node(str(clientId)):
		return
	$Heroes.get_node(str(clientId)).queue_free()
	
func _exit_tree():
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(del_player)
