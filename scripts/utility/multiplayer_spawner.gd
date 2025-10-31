extends MultiplayerSpawner

# Champions
var CHAMPION_MAGE_SCENE = load("res://scenes/champs/mage.tscn")
var CHAMPION_RANGER_SCENE = load("res://scenes/champs/ranger.tscn")

# Abilities
var ABILITY_METEOR_SCENE = load("res://scenes/abilities/meteor.tscn")

@export var max_spawn_timeout = 1.0
@export var max_wave_size = 5
var spawn_timeout = 0.0
var wave_size = 0
var current_minion_index = 0
# === Ingame Stats === #
var waves_spawned = 0

var t1_minion_spawns : Array = []
var t2_minion_spawns : Array = []

func _ready():
	add_scenes()
	setup_spawns()
	
func _physics_process(delta):
	if !Util.dedicated_server:return;
	if wave_size > 0:
		if spawn_timeout > 0:
			spawn_timeout -= delta
		else:
			spawn_timeout = max_spawn_timeout
			wave_size -= 1
			
			# Spawn one minion for each team at the current spawn index
			for team in range(1, 3):
				var minion = CHAMPION_MAGE_SCENE.instantiate()
				minion.team = team
				minion.name = str(waves_spawned, "_", team, "_", current_minion_index)
				get_node(spawn_path).call_deferred("add_child", minion, true)
				print("T", team)
				
				if team == 1:
					minion.ready.connect(func():
						minion.rpc("update_global_position", t1_minion_spawns[0])
						minion.rpc("update_target", t2_minion_spawns[0])
					)
				else:
					minion.ready.connect(func():
						minion.rpc("update_global_position", t2_minion_spawns[0])
						minion.rpc("update_target", t1_minion_spawns[0])
					)
			
			current_minion_index += 1
			# Reset for next wave if this wave is complete
			if wave_size == 0:
				current_minion_index = 0
		
	
func add_scenes():
	add_spawnable_scene(CHAMPION_MAGE_SCENE.resource_path)
	add_spawnable_scene(CHAMPION_RANGER_SCENE.resource_path)
	add_spawnable_scene(ABILITY_METEOR_SCENE.resource_path)

func setup_spawns():
	var minion_spawn_markers = get_tree().get_nodes_in_group("minion_spawn")
	for marker: Marker3D in minion_spawn_markers:
		if marker.is_in_group("team1"):
			t1_minion_spawns.append(marker.global_position)
		else:
			t2_minion_spawns.append(marker.global_position)

func spawn_ranger(name:String="Ranger"):
	if not multiplayer.is_server(): return;
	print("SPAWNING RANGER");
	var ranger:CharacterBody3D = CHAMPION_RANGER_SCENE.instantiate()
	ranger.name = name
	await get_node(spawn_path).call_deferred("add_child", ranger, true)
	if Util.players.has(name):
		Util.players[name]["Node"] = ranger
	
func spawn_mage(name:String="Mage"):
	if not multiplayer.is_server(): return;
	print("SPAWNING MAGE");
	var mage:CharacterBody3D = CHAMPION_MAGE_SCENE.instantiate()
	mage.name = name
	await get_node(spawn_path).call_deferred("add_child", mage, true)
	if Util.players.has(name):
		Util.players[name]["Node"] = mage
		
func spawn_ability(pos):
	if not multiplayer.is_server(): return;
	print("SPAWNING METEOR");
	var ability:Ability = ABILITY_METEOR_SCENE.instantiate()
	await get_node(spawn_path).call_deferred("add_child", ability, true)
	ability.position = pos

func _on_minion_wave_timer_timeout():
	print("SPAWNING WAVE")
	wave_size = max_wave_size
	waves_spawned += 1
	current_minion_index = 0
