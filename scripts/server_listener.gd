extends Node

@export var connected_players:Array
var players = {}
var team1 = Array()
var team2 = Array()
var death_timers = []
var player_cooldowns = {}

# ENV
@onready var champions = $"../Champions"
@onready var spawn1 = $"../Spawn1"
@onready var spawn2 = $"../Spawn2"

var champion_scenes:Dictionary = {};

const PlayerScene = preload ("res://characters/champion.tscn")

signal server_ready

func _ready():
	# add all champions to spawner
	var champion_files = await get_champs();
	for file in champion_files:
		$"../".get_node("ChampionSpawner").add_spawnable_scene("res://characters/" + file)
	# Server Setup
	if not multiplayer.is_server():
		return
		# Preload all champions
	for player in connected_players:
		if !champion_scenes.has(player.champ):
			champion_scenes[player.champ] = await load("res://characters/" + player.champ + ".tscn")
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(del_player)
	$"../WorldNav/BlueNexus".game_over.connect(game_over)
	$"../WorldNav/RedNexus".game_over.connect(game_over)
	for player in connected_players:
		add_player(player)
	
	if not OS.has_feature("dedicated_server"):
		add_player({
			'id': '0', # Local user, no user in DB
			'peer_id': '0',
			'name': "Player",
			'champ': "archer",
			'team': 0
		})


func get_champs():
	var dir = await DirAccess.open("res://characters/")
	var files = dir.get_files();
	return files


@rpc("any_peer", "call_local")
func move_to(pos: Vector3):
	var champion = get_champion(multiplayer.get_remote_sender_id())
	champion.is_attacking = false
	champion.target_entity = null
	champion.update_target_location(champion.nav_agent, pos)

@rpc("any_peer", "call_local")
func target(target_name):
	var champion = get_champion(multiplayer.get_remote_sender_id())
	# Dont Kill Yourself
	if str(target_name) == str(champion.name):
		print_debug("That's you ya idjit") # :O
		return
	var target_entity = get_parent().find_child(str(target_name), true, false)
	champion.target_entity = target_entity
	if target_entity and not target_entity.team == champion.team:
		champion.is_attacking = true

@rpc("any_peer", "call_local")
func spawn_ability(ability_name, ability_type, ability_pos, ability_mana_cost, cooldown, ab_id):
	var peer_id = multiplayer.get_remote_sender_id()
	var champion = get_champion(peer_id)
	if champion.get_mana() < ability_mana_cost:
		print("Not enough mana!")
		return
	if player_cooldowns[peer_id][ab_id-1] != 0:
		print("This ability is on cooldown! Wait " + str(cooldown) + " seconds!")
		return
	player_cooldowns[peer_id][ab_id-1] = cooldown
	free_ability(cooldown, peer_id, ab_id-1)
	champion.rpc_id(peer_id, "use_mana", ability_mana_cost)
	rpc_id(peer_id, "spawn_local_effect", ability_name, ability_type, ability_pos, champion.position, champion.team)


@rpc("any_peer", "call_local")
func spawn_local_effect(ability_name, ability_type, ability_pos, player_pos, player_team) -> void:
	var ability_scene = load("res://effects/abilities/"+ability_name+".tscn").instantiate();
	if ability_type == 0:
		ability_scene.position = ability_pos
	if ability_type == 1:
		ability_scene.direction = ability_pos
		ability_scene.position = player_pos
	ability_scene.team = player_team
	$"../Abilities".add_child(ability_scene);
	

func free_ability(cooldown: float, peer_id: int, ab_id: int) -> void:
	await get_tree().create_timer(cooldown).timeout
	player_cooldowns[peer_id][ab_id] = 0


func game_over(team):
	print(str(team) + " Lost");
	get_tree().quit()


func add_player(player: Dictionary):
	print(player);
	print("Player Connected: " + str(player.peer_id))
	if str(player.peer_id) == "0":
		return
		
	var champion = champion_scenes[player.champ].instantiate()
	# If player is not registered
	if player.team == 0:
		if team1.size() > team2.size():
			player.team = 2
			team2.append(player)
		else:
			player.team = 1
			team1.append(player)
	# setup champion
	champion.team = player.team
	champion.name = str(player.peer_id)
	champion.nametag = player.name
	champion.pid = player.peer_id
	champion.is_dead = true
	champion.position = get_node("../Spawn"+str(player.team)).position
	player_cooldowns[player.peer_id] = [0, 0, 0, 0]
	champion.hide()
	players[player.peer_id] = champion;
	champions.add_child(champion)
	respawn(champion)

func del_player(client_id: int):
	if not champions.has_node(str(client_id)):
		return
	champions.get_node(str(client_id)).queue_free()

func respawn(champion:CharacterBody3D):
	var rand = RandomNumberGenerator.new()
	var x = rand.randf_range(0, 5)
	var z = rand.randf_range(0, 5)
	champion.position = get_node("../Spawn"+str(champion .team)).position + Vector3(x, 0, z)
	champion.show()

func get_champion(id:int):
	var champion = players.get(id)
	if not champion:
		print_debug("Failed to find character")
		return false
	return champion
	
func _exit_tree():
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(del_player)
