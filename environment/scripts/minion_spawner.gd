extends Node3D

@onready var spawn_timer: Timer = $SpawnTimer
@onready var spawner: MultiplayerSpawner = $MinionSpawner

@export var team: int
@export var wave_size: int = 6
@export var spawn_delay: float = .5
@export var auto_spawn: bool = false
@export var spawn_path: Node = null
@export var patrol_path: Node3D = null

# For some reason setting the _spawnable_scenes on MultiplayerSpawner during
# runtime doesn't work properly so we are stuck with this constant for now
const MinionScene: PackedScene = preload ("res://characters/minion.tscn")

var max_ids: Dictionary
var timeout: float = 1.0

func _ready():
	# Timers must have a minimum wait_time of 1 sec, otherwise they throw an error
	if timeout < 1.0:
		timeout = 1.0
	spawn_timer.wait_time = timeout
	spawn_timer.timeout.connect(spawn_wave)
	
	# Searches for "Minions" node in parent if spawn_path isn't set
	if spawner.spawn_path.is_empty() and spawn_path == null:
		spawner.spawn_path = get_parent().find_child("Minions").get_path()
	else:
		spawner.spawn_path = spawn_path.get_path()
	
	set_auto_spawn(auto_spawn)

func set_auto_spawn(enabled: bool=true):
	if enabled:
		spawn_timer.start()
	else:
		spawn_timer.stop()

func spawn_minion():
	if not max_ids.has(team):
		max_ids[team] = 0
	var id: int = max_ids.get(team)
	var minion = MinionScene.instantiate()
	minion.id = id
	minion.team = team
	minion.position = position
	minion.patrol_path = patrol_path
	get_node(spawner.spawn_path).add_child(minion)
	max_ids[team] += 1

func spawn_wave():
	for i in wave_size:
		spawn_minion()
		await get_tree().create_timer(spawn_delay).timeout
