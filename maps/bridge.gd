extends Node3D

@export var countdown = 10
@export var wave_timeout = 30
@export var wave_size = 3
var GameStartTimer = Timer.new()
# Called when the node enters the scene tree for the first time.
func _ready():
	if not multiplayer.is_server():
		return;
	GameStartTimer.wait_time = 1;
	GameStartTimer.one_shot = true
	GameStartTimer.timeout.connect(start);
	add_child(GameStartTimer)
	GameStartTimer.start()

func start():
	GameStartTimer.timeout.disconnect(start);
	GameStartTimer.queue_free();
	spawn_waves(wave_size)
	$MinionSpawnTimer.wait_time = wave_timeout;
	$MinionSpawnTimer.timeout.connect(spawn_waves)
	$MinionSpawnTimer.autostart = true;
	$MinionSpawnTimer.start();

func spawn_waves(wave_size = 0):
	$BlueMinionSpawnerMid.spawn_wave(wave_size)
	$RedMinionSpawnerMid.spawn_wave(wave_size)
