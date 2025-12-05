class_name GameplayManager
extends Node

# == Signals == #
signal game_started
#signal finish(teamid)
#signal paused
#signal resumed

signal slow_tick

# === Game State === #
var gamestate = GAME_STATE.LOADING
enum GAME_STATE {LOADING, ONGOING, PAUSED, DONE}

# == Timers == #
var slow_tick_timer: Timer

# == Game State == #
var game_root: Node

# == Settings (Source of Truth) == #
var config: Dictionary = {}

# === Player Reference === #
var players : Dictionary = {}
var player_ids: Array = []
# == Classes == #
class PlayerObject:
	var id: int
	var node: Node3D
	var name: String

class MinionSettings:
	var wave_size = 2
	var wave_timeout = 10

func _ready():
	# == Load Settings == #
	reload_settings()
	# == Slow Tick == #
	slow_tick_timer = Timer.new()
	slow_tick_timer.wait_time = 1
	slow_tick_timer.one_shot = false
	slow_tick_timer.timeout.connect(slow_tick_timeout)
	print("GameManager: Initialized")

func initialize(root:Node):
	game_root = root;
	set_state(GAME_STATE.LOADING)

	UIManager.set_ui_root(root.get_tree().get_first_node_in_group("ui_root"))
	UIManager.change_interface("Loading")
	UIManager.preload_interface("InGame")

	SpawnManager.initialize(root)
	

func start_game():
	print("GameplayManager: Starting game...")
	game_started.emit()
	# Update required Systems
	UIManager.change_interface("Ingame")
	# Add Player Controller to game
	SpawnManager.spawn_player_controller()
	# 
	gamestate = GAME_STATE.ONGOING
	game_root = get_tree().get_first_node_in_group("game_root")
	slow_tick_timer.start()
	print("GameManager: Game started")

func load_map(map_name:String) -> Error:
	if map_name.is_empty():
		return Error.ERR_FILE_BAD_PATH
	var map = load("res://scenes/maps/%s.tscn" % map_name)
	if map == null:
		return Error.ERR_FILE_NOT_FOUND
	var map_instance = map.instantiate()
	game_root.add_child(map_instance)
	return Error.OK
	
func spawn_entity(entity_data: Dictionary):
	EntityManager.create_entity(entity_data)
	
func reload_settings() -> void:
	ConfigManager.load_settings()
	print("GameManager: Settings reloaded")

func apply_settings() -> void:
	ConfigManager.apply_settings(config)
	print("GameManager: Settings applied")

func slow_tick_timeout():
	emit_signal("slow_tick")
	
func set_state(new_state: GAME_STATE):
	gamestate = new_state
	match new_state:
		GAME_STATE.LOADING:
			pass;
		GAME_STATE.ONGOING:
			pass
		GAME_STATE.PAUSED:
			pass
		GAME_STATE.DONE:
			pass

func get_state() -> GAME_STATE:
	return gamestate
