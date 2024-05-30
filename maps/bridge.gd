extends Node3D

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
	spawn_waves()
	$MinionSpawnTimer.wait_time = 10;
	$MinionSpawnTimer.timeout.connect(spawn_waves)
	$MinionSpawnTimer.autostart = true;
	$MinionSpawnTimer.start();

func spawn_waves():
	$BlueMinionSpawnerMid.spawn_wave()
	$RedMinionSpawnerMid.spawn_wave()
