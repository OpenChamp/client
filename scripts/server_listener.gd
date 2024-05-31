extends Node

var players = {}
var team1 = Array()
var team2 = Array()
var death_timers = []
var player_cooldowns = {}

# ENV
@onready var champions = $"../Champions"
@onready var spawn1 = $"../Spawn1"
@onready var spawn2 = $"../Spawn2"

const PlayerScene = preload ("res://characters/champion.tscn")


func _ready():
	if not multiplayer.is_server():
		return
		
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(del_player)
	$"../WorldNav/BlueNexus".game_over.connect(game_over)
	$"../WorldNav/RedNexus".game_over.connect(game_over)
	for id in multiplayer.get_peers():
		add_player(id)
	
	if not OS.has_feature("dedicated_server"):
		add_player(1)


@rpc("any_peer", "call_local")
func move_to(pos: Vector3):
	var peer_id = multiplayer.get_remote_sender_id()
	var character = champions.get_node(str(peer_id))
	if not character:
		print("Failed to find character")
		return
	character.is_attacking = false
	character.target_entity = null
	character.update_target_location(character.nav_agent, pos)


@rpc("any_peer", "call_local")
func target(name):
	var peer_id = multiplayer.get_remote_sender_id()
	var player = players[peer_id]
	var character = champions.get_node(str(peer_id))
	if not player:
		print_debug("Failed to find character")
		return
	# Dont Kill Yourself
	if str(name) == str(player.name):
		print_debug("That's you ya idjit") # :O
		return
	var target_entity = get_parent().find_child(str(name), true, false)
	player.target_entity = target_entity
	if target_entity and not target_entity.team == player.team:
		character.update_target_location(character.nav_agent, character.position)
		player.is_attacking = true


@rpc("any_peer", "call_local")
func spawn_ability(ability_name, ability_type, ability_pos, ability_mana_cost, cooldown, ab_id):
	var peer_id = multiplayer.get_remote_sender_id()
	var player = players[peer_id]
	if not player:
		print_debug("Failed to find character")
		return
	if player.get_mana() < ability_mana_cost:
		print("Not enough mana!")
		return
	if player_cooldowns[peer_id][ab_id-1] != 0:
		print("This ability is on cooldown! Wait " + str(cooldown) + " seconds!")
		return
	player_cooldowns[peer_id][ab_id-1] = cooldown
	free_ability(cooldown, peer_id, ab_id-1)
	player.rpc_id(peer_id, "set_mana", ability_mana_cost)
	rpc_id(peer_id, "spawn_local_effect", ability_name, ability_type, ability_pos, player.position, player.team)


@rpc("any_peer", "call_local")
func spawn_local_effect(ability_name, ability_type, ability_pos, player_pos, player_team) -> void:
	var ability = load("res://effects/abilities/"+ability_name+".tscn").instantiate();
	if ability_type == 0:
		ability.position = ability_pos
	if ability_type == 1:
		ability.direction = ability_pos
		ability.position = player_pos
	ability.team = player_team
	$"../Abilities".add_child(ability);
	

func free_ability(cooldown: float, peer_id: int, ab_id: int) -> void:
	await get_tree().create_timer(cooldown).timeout
	player_cooldowns[peer_id][ab_id] = 0


func game_over(team):
	get_tree().quit()


func add_player(client_id: int):
	print("Player Connected: " + str(client_id))
	var character = PlayerScene.instantiate()
	if team1.size() > team2.size():
		team2.append(client_id)
		character.position = spawn2.position
		character.team = 2
	else:
		team1.append(client_id)
		character.position = spawn1.position
		character.team = 1
	character.pid = client_id
	character.name = str(client_id)
	players[client_id] = character
	var cooldowns = [0, 0, 0, 0]
	player_cooldowns[client_id] = cooldowns
	champions.add_child(character)


func del_player(client_id: int):
	if not champions.has_node(str(client_id)):
		return
	champions.get_node(str(client_id)).queue_free()


func _exit_tree():
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(del_player)
