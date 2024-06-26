extends Node
class_name MapNode

enum EndCondition{
	TEAM_ELIMINATION,
	STRUCTURE_DESTRUCTION,
}

@export var connected_players: Array
@export var champion_container: Node

@export var player_spawns: Array = []
@export var unit_spawns: Array = []

@export var Spawns = {}

var Champions = {}
var player_cooldowns = {}
var end_conditions = []

func _ready():
	_setup_nodes()

	if not multiplayer.is_server():
		client_setup()
		return

	# Spawn all the Champions
	var champ_scene = load("res://champions/dummy.tscn")

	for player in connected_players:
		var champ = champ_scene.instantiate()

		champ.name = str(player["peer_id"])
		champ.id = player["peer_id"]
		champ.nametag = player["name"]
		champ.team = player["team"]
		champ.position = Spawns[str(champ.team)]
		champ.server_position = champ.position;
		champion_container.add_child(champ, true)
		champ.look_at(Vector3(0,0,0))

		Champions[player['peer_id']] = champ
		

func _process_delta(_delta):
	pass


func _setup_nodes():
	champion_container = Node.new()
	champion_container.name = "Champions"
	add_child(champion_container)
	champion_container = get_node("Champions")
	
	var champion_spawner = MultiplayerSpawner.new()
	champion_spawner.name = "ChampionSpawner"
	champion_spawner.spawn_path = champion_container.get_path()
	champion_spawner.spawn_limit = 50
	champion_spawner.add_spawnable_scene("res://champions/dummy.tscn")
	add_child(champion_spawner)
	
	var minions_node = Node.new()
	minions_node.name = "Minions"
	add_child(minions_node)
	
	var abilities_node = Node.new()
	abilities_node.name = "Abilities"
	add_child(abilities_node)
	


func load_config(map_config: Dictionary):
	if not map_config.has("end_conditions"):
		print("Map config is missing end conditions")
		return

	var raw_end_conditions = map_config["end_conditions"]
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

	if not map_config.has("features"):
		print("Map config is missing features")
		return

	var features = map_config["features"]
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
	
	if not data.has("position"):
		print("Spawn is missing position")
		return null
	
	if not data.has("name"):
		print("Spawn is missing name")
		return null

	if not data.has("spawn_behaviour"):
		print("Spawn is missing spawn_behaviour")
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
	
	var position = Vector3(x, y, z)

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
	var player_ui = load("res://ui/game_ui.tscn")
	add_child(player_ui.instantiate())


@rpc("any_peer")
func client_ready():
	print(connected_players);
	print(multiplayer.get_remote_sender_id())


@rpc("any_peer")
func register_player():
	var peer_id = multiplayer.get_remote_sender_id()


@rpc("any_peer", "call_local")
func move_to(pos: Vector3):
	var champion = get_champion(multiplayer.get_remote_sender_id())
	champion.change_state.rpc("Moving", pos)


@rpc("any_peer", "call_local")
func target(target_name):
	var champion = get_champion(multiplayer.get_remote_sender_id())
	# Dont Kill Yourself
	if target == champion:
		print_debug("That's you ya idjit") # :O
		return
	champion.change_state("Attacking", target)


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
