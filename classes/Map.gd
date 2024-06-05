extends Node
class_name MapNode

@export var connected_players: Array

@export var champion_container: Node

var Champions = {}
var Spawns = []

var player_cooldowns = {}

func _ready():
	if not multiplayer.is_server():
		client_setup()
		return ;
	# Get both team spawns
	Spawns.append(get_node("Spawn1").global_position)
	Spawns.append(get_node("Spawn2").global_position)
	# Spawn all the Champions
	for player in connected_players:
		var champ = load("res://champions/" + player["champ"].to_lower() + ".tscn").instantiate()
		champ.name = str(player["peer_id"])
		champ.id = player["peer_id"]
		champ.nametag = player["name"]
		champ.team = player["team"]
		champ.position = Spawns[champ.team-1]
		champ.server_position = champ.position
		champion_container.add_child(champ)
		Champions[player['peer_id']] = champ
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


@rpc("any_peer", "call_local")
func move_to(pos: Vector3):
	print("Trying to move");
	print(pos);
	var champion = get_champion(multiplayer.get_remote_sender_id())
	champion.update_target_location(pos);

@rpc("any_peer", "call_local")
func target(target_name):
	var champion = get_champion(multiplayer.get_remote_sender_id())
	# Dont Kill Yourself
	if str(target_name) == str(champion.name):
		print_debug("That's you ya idjit") # :O
		return
	var target_entity = get_parent().find_child(str(target_name), true, false)
	champion.change_state("Attack", target_entity)

@rpc("any_peer", "call_local")
func spawn_ability(ability_name, ability_type, ability_pos, ability_mana_cost, cooldown, ab_id):
	var peer_id = multiplayer.get_remote_sender_id()
	var champion = get_champion(peer_id)
	if champion.mana < ability_mana_cost:
		print("Not enough mana!")
		return
	if player_cooldowns[peer_id][ab_id-1] != 0:
		print("This ability is on cooldown! Wait " + str(cooldown) + " seconds!")
		return
	player_cooldowns[peer_id][ab_id-1] = cooldown
	free_ability(cooldown, peer_id, ab_id-1)
	champion.mana -= ability_mana_cost
	print(champion.mana)
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
	
@rpc("any_peer", "call_local")
func respawn(champion:CharacterBody3D):
	var rand = RandomNumberGenerator.new()
	var x = rand.randf_range(0, 5)
	var z = rand.randf_range(0, 5)
	champion.position = get_node("../Spawn"+str(champion .team)).position + Vector3(x, 0, z)
	champion.set_health(champion.get_health_max())
	champion.is_dead = false
	champion.show()
	champion.rpc_id(champion.pid, "respawn")

func free_ability(cooldown: float, peer_id: int, ab_id: int) -> void:
	await get_tree().create_timer(cooldown).timeout
	player_cooldowns[peer_id][ab_id] = 0

func get_champion(id:int):
	var champion = Champions.get(id)
	if not champion:
		print_debug("Failed to find character")
		return false
	return champion
