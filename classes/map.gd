extends Node
class_name MapNode

enum EndCondition{
	TEAM_ELIMINATION,
	STRUCTURE_DESTRUCTION,
}

@export var map_configuration: Dictionary = {}

@export var connected_players: Array
@export var champion_container: Node

@export var player_spawns: Array = []
@export var unit_spawns: Array = []

@export var Spawns = {}

var Characters = {}
var player_cooldowns = {}
var end_conditions = []


const player_desktop_hud = preload("res://ui/game_ui.tscn")
const player_desktop_settings = preload("res://ui/settings_menu/settings_menu.tscn")

func _ready():
	_load_config()
	_setup_nodes()
	
	# TODO: make sure all clients have the map fully loaded before
	# continueing here. For now we just do a 1 seconds delay.
	await get_tree().create_timer(1).timeout
	
	
	if not multiplayer.is_server():
		client_setup()
		return
	# Check if Server is included as a player
	if multiplayer.get_peers().size() + 1 == connected_players.size():
		client_setup()
	
	for player in connected_players:
		var spawn_args = {}
		
		spawn_args["name"] = str(player["peer_id"])
		spawn_args["character"] = player["character"]
		spawn_args["id"] = player["peer_id"]
		spawn_args["nametag"] = player["name"]
		spawn_args["team"] = player["team"]
		spawn_args["position"] = Spawns[str(player["team"])]
		
		var new_char = $ChampionSpawner.spawn(spawn_args)
		new_char.look_at(Vector3(0,0,0))
		Characters[player['peer_id']] = new_char


func _process_delta(_delta):
	pass


func _setup_nodes():
	champion_container = Node.new()
	champion_container.name = "Characters"
	add_child(champion_container)
	champion_container = get_node("Characters")
	
	var champion_spawner = MultiplayerSpawner.new()
	champion_spawner.name = "ChampionSpawner"
	champion_spawner.spawn_path = champion_container.get_path()
	champion_spawner.spawn_limit = 50
	champion_spawner.spawn_function = _spawn_character
	
	add_child(champion_spawner)
	
	var minions_node = Node.new()
	minions_node.name = "Minions"
	add_child(minions_node)
	
	var abilities_node = Node.new()
	abilities_node.name = "Abilities"
	add_child(abilities_node)
	

func _spawn_character(args):
	var spawn_args = args as Dictionary
	
	if not spawn_args:
		print("Error character spawn args could now be parsed as dict!")
		return null
	
	print("loading character:" + spawn_args["character"])
	
	# TODO: implement the actual character loading
	# This requires the character registry to be implemented
	var new_char_scene = load("res://champions/dummy.tscn")
	var new_char = new_char_scene.instantiate()
	
	new_char.name = spawn_args["name"]
	new_char.id = spawn_args["id"]
	new_char.nametag = spawn_args["nametag"]
	new_char.team = spawn_args["team"]
	new_char.position = spawn_args["position"]
	new_char.server_position = new_char.position

	return new_char


func _load_config():
	if not map_configuration.has("end_conditions"):
		print("Map config is missing end conditions")
		return

	var raw_end_conditions = map_configuration["end_conditions"]
	for condition in raw_end_conditions:
		if not condition.has("type"):
			print("End condition is missing type")
			continue

		var type = condition["type"]
		match type:
			"team_elimination":
				if not condition.has("team"):
					print("Team elimination condition is missing team")
					continue
				end_conditions.append({
					"type": EndCondition.TEAM_ELIMINATION,
					"team": condition["team"]
				})
			"structure_destruction":
				if not condition.has("structure"):
					print("Structure destruction condition is missing structure")
					continue
				end_conditions.append({
					"type": EndCondition.STRUCTURE_DESTRUCTION,
					"structure_name": condition["structure_name"],
					"loosing_team": condition["loosing_team"]
				})
			_:
				print("Unknown end condition type: " + type)

	if not map_configuration.has("features"):
		print("Map config is missing features")
		return

	var features = map_configuration["features"]
	for feature in features:
		_load_feature(feature)


func _load_feature(data: Dictionary):
	if not data.has("type"):
		print("Feature is missing type")
		return
	
	match data["type"]:
		"player_spawn":
			var spawn = _decode_spawn_common(data)
			if spawn == null:
				return

			player_spawns.append(spawn)
			Spawns[str(spawn["team"])] = spawn["position"]

		"unit_spawn":
			var spawn = _decode_spawn_common(data)
			if spawn == null:
				return

			unit_spawns.append(spawn)
		_:
			print("Unknown feature type: " + data["type"])


func _decode_spawn_common(data: Dictionary):
	if not data.has("team"):
		print("Spawn is missing team")
		return null
	
	if not data.has("name"):
		print("Spawn is missing name")
		return null

	if not data.has("spawn_behaviour"):
		print("Spawn is missing spawn_behaviour")
		return null

	var feature_node: Node3D
	var feature_nodes = find_children(data["name"])
	for node in feature_nodes:
		if node.name == data["name"]:
			feature_node = node as Node3D
			if feature_node != null:
				break
	
	var position = Vector3(0,0,0)
	
	if feature_node == null:
		if not data.has("position"):
			print("Spawn is missing position")
			return null
			
		var x = 0
		var y = 0
		var z = 0

		if data["position"].has("x"):
			x = data["position"]["x"]

		if data["position"].has("y"):
			y = data["position"]["y"]

		if data["position"].has("z"):
			z = data["position"]["z"]
	
		position = Vector3(x, y, z)
		
	else:
		position = feature_node.position
	

	return {
		"team": int(data["team"]),
		"name": str(data["name"]),
		"position": position,
		"spawn_behaviour": data["spawn_behaviour"]
	}


func client_setup():
	# Add the player into the world
	# The player rig will ask the server for their champion
	var player_rig = load("res://champions/_player.tscn").instantiate()
	add_child(player_rig)
	
	# instantiate and add all the UI components
	add_child(player_desktop_hud.instantiate())
	add_child(player_desktop_settings.instantiate())
	


@rpc("any_peer")
func client_ready():
	print(connected_players);
	print(multiplayer.get_remote_sender_id())


@rpc("any_peer")
func register_player():
	var peer_id = multiplayer.get_remote_sender_id()


@rpc("any_peer", "call_local")
func move_to(pos: Vector3):
	var character = get_champion(multiplayer.get_remote_sender_id())
	character.change_state.rpc("Moving", pos)


@rpc("any_peer", "call_local")
func target(target_name):
	var character = get_champion(multiplayer.get_remote_sender_id())
	# Dont Kill Yourself
	if target_name == character.name:
		print_debug("That's you ya idjit") # :O
		return
	character.change_state("Attacking", target_name)


@rpc("any_peer", "call_local")
func spawn_ability(ability_name, ability_type, ability_pos, ability_mana_cost, cooldown, ab_id):
	var peer_id = multiplayer.get_remote_sender_id()
	var character = get_champion(peer_id)
	if character.mana < ability_mana_cost:
		print("Not enough mana!")
		return
	if player_cooldowns[peer_id][ab_id-1] != 0:
		print("This ability is on cooldown! Wait " + str(cooldown) + " seconds!")
		return
	player_cooldowns[peer_id][ab_id-1] = cooldown
	free_ability(cooldown, peer_id, ab_id-1)
	character.mana -= ability_mana_cost
	print(character.mana)
	rpc_id(peer_id, "spawn_local_effect", ability_name, ability_type, ability_pos, character.position, character.team)


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
func respawn(character:CharacterBody3D):
	var rand = RandomNumberGenerator.new()
	var x = rand.randf_range(0, 5)
	var z = rand.randf_range(0, 5)
	character.position = get_node("../Spawn"+str(character .team)).position + Vector3(x, 0, z)
	character.set_health(character.get_health_max())
	character.is_dead = false
	character.show()
	character.rpc_id(character.pid, "respawn")


func free_ability(cooldown: float, peer_id: int, ab_id: int) -> void:
	await get_tree().create_timer(cooldown).timeout
	player_cooldowns[peer_id][ab_id] = 0


func get_champion(id:int):
	var character = Characters.get(id)
	if not character:
		print_debug("Failed to find character")
		return false
	return character
