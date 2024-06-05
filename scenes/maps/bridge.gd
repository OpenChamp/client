extends MapNode
class_name MapBridge

var GameStartTimer = Timer.new()
@export var waveTimes = 10
@export var waveSize = 6
# Called when the node enters the scene tree for the first time.
func _ready():
	super();
	GameStartTimer.wait_time = 10;
	GameStartTimer.one_shot = true
	#GameStartTimer.timeout.connect(start);
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
