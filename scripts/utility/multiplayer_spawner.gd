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

func _ready():
	add_scenes()
	
func _physics_process(delta):
	if wave_size > 0:
		if spawn_timeout > 0:
			spawn_timeout -= delta
		else:
			spawn_timeout = max_spawn_timeout
			wave_size-=1
			for i in range(0,2):
				var minion = CHAMPION_MAGE_SCENE.instantiate()
				await get_node(spawn_path).call_deferred("add_child", minion, true)
				minion.team = i
				if i == 1:
					minion.position = Vector3(-5, 1, 0)
				else:
					minion.position = Vector3(5, 1, 0)
	
	
func add_scenes():
	add_spawnable_scene(CHAMPION_MAGE_SCENE.resource_path)
	add_spawnable_scene(CHAMPION_RANGER_SCENE.resource_path)
	add_spawnable_scene(ABILITY_METEOR_SCENE.resource_path)

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
