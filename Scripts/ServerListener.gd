extends Node

var players = {}
var team1 = Array()
var team2 = Array()
var DeathTimers = []

# ENV
@onready var summoners = $"../Summoners"
@onready var player = $"../Players"
@onready var spawn1 = $"../Spawn1"
@onready var spawn2 = $"../Spawn2"

const PlayerScene = preload("res://Characters/Champion.tscn")


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
func move_to(pos: Vector3):
	var peer_id = multiplayer.get_remote_sender_id()
	var character = summoners.get_node("summoner_" + str(peer_id))
	if !character:
		print("Failed to find character")
		return
	character.is_attacking = false
	character.target_entity = null
	character.update_target_location(character.nav_agent, pos)

@rpc("any_peer", "call_local")
func Target(name):
	var peer_id = multiplayer.get_remote_sender_id()
	# Dont Kill Yourself

	if(str(name) == str(peer_id)):
		print("That's you ya idjit");
		return;
	print(str(peer_id) + " : " + str(name))
	var Character = Players[peer_id]
	if !Character:
		print("Failed to find character")
		return;
	if name is int:
		Character.targetEntity = Players[name]
	else: 
		Character.targetEntity = get_parent().get_node("./WorldNav/"+name)
	Character.isAttacking = true

func GameOver(team):
	get_tree().quit();

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

func del_player(client_id: int):
	if not summoners.has_node(str(client_id)):
		return
	Heroes.get_node(str(clientId)).queue_free()
	
func _exit_tree():
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(del_player)
