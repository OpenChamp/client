extends MultiplayerSpawner

@onready var spawn_timer: Timer = $SpawnTimer

@export var team: int
@export var spawn_position: Vector3 = Vector3(0, 0, 0)
@export var wave_size: int = 6
@export var spawn_delay: float = .5
@export var auto_spawn: bool = false

const MinionScene: PackedScene = preload("res://Characters/minion.tscn")
var max_ids: Dictionary
var timeout: float = 1.0

func _ready():
	if timeout < 1.0:
		timeout = 1.0
	spawn_timer.wait_time = timeout
	spawn_timer.timeout.connect(spawn_wave.bind())
	set_auto_spawn(auto_spawn)

func set_auto_spawn(enabled: bool = true):
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
	minion.position = spawn_position
	get_parent().find_child("Minions").add_child(minion)
	max_ids[team] += 1
	
func spawn_wave():
	for i in wave_size:
		spawn_minion()
		await get_tree().create_timer(spawn_delay).timeout
