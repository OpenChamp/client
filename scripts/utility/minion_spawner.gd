class_name MinionSpawner
extends MultiplayerSpawner

# Wave Configuration Class
class WaveConfig:
	var melee_count: int = 3
	var mage_count: int = 1
	var spawn_interval: float = 30.0
	
	func _init(melee: int = 3, mage: int = 1, interval: float = 30.0):
		melee_count = melee
		mage_count = mage
		spawn_interval = interval
	
	func get_description() -> String:
		return "WaveConfig(melee=%d, mage=%d, interval=%.1fs)" % [melee_count, mage_count, spawn_interval]

# ECS-based minion scenes
@export var melee_minion_scene := preload("res://scenes/entities/minions/minion_entity_melee.tscn")
@export var mage_minion_scene := preload("res://scenes/entities/minions/minion_entity_mage.tscn")

# Old minion scenes (kept for backwards compatibility)
@export var old_melee_minion_scene := preload("res://scenes/entities/minions/minion_melee.tscn")
@export var old_mage_minion_scene := preload("res://scenes/entities/minions/minion_mage.tscn")

# Wave configuration
var wave_config: WaveConfig

# Spawn points for different teams (team 1 spawns bottom, team 2 spawns top)
var team_spawn_points = {
	1: Vector3(0, 1, -28),
	2: Vector3(0, 1, 28)
}

# Target positions for enemy base (where minions walk to)
var team_target_points = {
	1: Vector3(0, 0.5, 28),
	2: Vector3(0, 0.5, -28)
}

var current_wave: int = 0
var spawned_minions: Array = []

# Use ECS-based entities
var use_ecs_minions: bool = true

func _ready():
	# Register both old and new minion scenes for spawning
	add_spawnable_scene(melee_minion_scene.resource_path)
	add_spawnable_scene(mage_minion_scene.resource_path)
	add_spawnable_scene(old_melee_minion_scene.resource_path)
	add_spawnable_scene(old_mage_minion_scene.resource_path)
	
	# Initialize wave configuration
	wave_config = WaveConfig.new()
	print("MinionSpawner: Initialized with configuration: %s" % wave_config.get_description())
	print("MinionSpawner: Using ECS-based minions: %s" % use_ecs_minions)


func _on_minion_wave_timer_timeout():
	"""Called when the minion wave timer fires"""
	if !multiplayer.is_server(): 
		return
	# Spawn waves for both teams
	spawn_wave(1, current_wave)
	spawn_wave(2, current_wave)
	current_wave += 1
	print("MinionSpawner: Wave %d completed" % current_wave)


func spawn_wave(team: int, wave_number: int) -> void:
	"""
	Spawn a complete minion wave for a team
	team: 1 or 2
	wave_number: Current wave number for tracking
	"""
	if !multiplayer.is_server():
		return
	
	print("MinionSpawner: Spawning wave %d for team %d (melee: %d, mage: %d)" % [wave_number, team, wave_config.melee_count, wave_config.mage_count])
	
	# Spawn melee minions
	for i in range(wave_config.melee_count):
		spawn_minion("melee", team)
	
	# Spawn mage minions
	for i in range(wave_config.mage_count):
		spawn_minion("mage", team)


func spawn_minion(minion_type: String, team: int) -> Node:
	"""
	Spawn a single minion
	minion_type: "melee" or "mage"
	team: 1 or 2
	Returns: The spawned minion node, or null on failure
	"""
	if !multiplayer.is_server():
		return null
	
	# Get the correct scene based on type
	var scene: PackedScene
	match minion_type.to_lower():
		"melee":
			scene = melee_minion_scene if use_ecs_minions else old_melee_minion_scene
		"mage":
			scene = mage_minion_scene if use_ecs_minions else old_mage_minion_scene
		_:
			push_error("MinionSpawner: Unknown minion type '%s'" % minion_type)
			return null
	
	# Instantiate the minion
	var minion = scene.instantiate()
	
	# Set minion properties
	minion.team = team
	minion.creature_id = randi()
	
	# Set spawn and target positions based on team
	#if team_spawn_points.has(team) and team_target_points.has(team):
		#minion.spawn_point = team_spawn_points[team]
		#minion.enemy_node_pos = team_target_points[team]
	#else:
		#push_error("MinionSpawner: Invalid team %d" % team)
		#minion.queue_free()
		#return null
	var spawn_point = team_spawn_points[team]
	# Add slight randomization to spawn position to avoid perfect stacking
	var spawn_offset = Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5))
	minion.position = spawn_point + spawn_offset
	
	# Add to the spawner's spawn path (should be root of ingame scene)
	var spawn_parent = get_node(spawn_path)
	spawn_parent.add_child(minion, true)
	spawned_minions.append(minion)
	
	# Hook up signals for minions that have them
	if minion.has_signal("died"):
		minion.died.connect(_on_minion_died.bindv([minion]))
	if minion.has_signal("attacked"):
		minion.attacked.connect(_on_minion_attacked.bindv([minion]))
	
	print("MinionSpawner: Spawned %s minion (team %d, ID: %d) at %s" % [minion_type, team, minion.creature_id, minion.position])
	return minion


func _on_minion_died(minion: Node) -> void:
	"""Called when a minion dies"""
	if minion in spawned_minions:
		spawned_minions.erase(minion)
	print("MinionSpawner: Minion died (team: %d, remaining: %d)" % [minion.team, spawned_minions.size()])


func _on_minion_attacked(target: Node, minion: Node) -> void:
	"""Called when a minion attacks"""
	print("MinionSpawner: Minion %d attacked %s" % [minion.creature_id, target.name])


func set_wave_config(config: WaveConfig) -> void:
	"""Update the wave configuration"""
	wave_config = config
	print("MinionSpawner: Wave configuration updated to: %s" % wave_config.get_description())


func set_use_ecs_minions(use_ecs: bool) -> void:
	"""Toggle between ECS and old minion system"""
	use_ecs_minions = use_ecs
	print("MinionSpawner: ECS minions toggled to: %s" % use_ecs_minions)


func get_current_wave() -> int:
	"""Get current wave number"""
	return current_wave


func get_spawned_minions() -> Array:
	"""Get array of all spawned minions"""
	return spawned_minions.duplicate()


func get_minion_count() -> int:
	"""Get count of currently spawned minions"""
	return spawned_minions.size()
	
