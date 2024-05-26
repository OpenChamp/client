extends Node

var Players = {}
var DeathTimers = []
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
	$"../WorldNav/RedTower".GameOver.connect(GameOver)
	$"../WorldNav/BlueTower".GameOver.connect(GameOver)
	for id in multiplayer.get_peers():
		add_player(id)
	
	if not OS.has_feature("dedicated_server"):
		add_player(1)

func _process(delta):
	pass;

@rpc("any_peer", "call_local")
func center_cam():
	var peer_id = multiplayer.get_remote_sender_id()
	var Character = Players[peer_id]
	rpc_id(peer_id, "jump_cam_to", Character.position)

@rpc("any_peer", "call_local")
func jump_cam_to(pos):
	var player_node = $"../Player"
	player_node.position = pos
	

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

@rpc("any_peer", "call_local")
func Target(target_name, target_team):
	var peer_id = multiplayer.get_remote_sender_id()
	# Dont Kill Yourself
	if(str(target_name) == str(peer_id)):
		print("That's you ya idjit");
		return;
	print(str(peer_id) + " : " + str(target_name))
	var Character = Players[peer_id]
	if !Character:
		print("Failed to find character")
		return;
	
	if (Character.team == target_team):
		print("That's YOUR turret, dummy!")
		return;
	
	if target_name is int:
		if (Players[target_name].team == Character.team):
			print("Don't hurt your own team!")
			return;
		Character.targetEntity = Players[target_name]
	else: 
		Character.targetEntity = get_parent().get_node("./WorldNav/"+target_name)
	Character.isAttacking = true

func GameOver(team):
	get_tree().quit();

func player_died(pid):
	var Character = Players[pid]
	Character.Die()
	Character.PlayerDeath.rpc_id(pid)
	

func add_player(clientId: int):
	print("Player Connected: " + str(clientId))
	var character = preload("res://Characters/Archer.tscn").instantiate()
	if Team1.size() > Team2.size():
		Team2.append(clientId)
		character.team = 2
		character.position = Spawn2.position
	else:
		Team1.append(clientId)
		character.team = 1
		character.position = Spawn1.position
	character.pid = clientId
	character.name = str(clientId)
	character.died.connect(player_died)
	Players[clientId] = character
	Heroes.add_child(character)

func del_player(clientId: int):
	if not Heroes.has_node(str(clientId)):
		return
	Heroes.get_node(str(clientId)).queue_free()

func _exit_tree():
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(del_player)
