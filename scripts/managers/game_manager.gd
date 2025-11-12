class_name GameplayManager
extends Node

# == Signals == #
signal start
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
var server: ServerSettings = ServerSettings.new()

# === Player Reference === #
var players : Dictionary = {}
var player_ids: Array = []
# == Classes == #
class PlayerObject:
	var id: int
	var node: Node3D
	var name: String
	
class ServerSettings:
	var port: int = 7000
	var max_players := 2
	var players := {}
	var player_sessions
	var player_ids = []
	var tick_rate: int = 30
	var slow_tick_rate: float = 1.0
	
class MinionSettings:
	var wave_size = 2
	var wave_timeout = 10

func _ready():
	GameManager.server = ServerSettings.new()
	multiplayer.peer_connected.connect(_on_player_connected)
	# == Load Settings == #
	reload_settings()
	# == Slow Tick == #
	slow_tick_timer = Timer.new()
	slow_tick_timer.wait_time = 1
	slow_tick_timer.one_shot = false
	slow_tick_timer.timeout.connect(slow_tick_timeout)
	print("GameManager: Initialized")

func initialize():
	set_state(GAME_STATE.LOADING)
	Engine.max_fps = 30 # TICK RATE

func game_start():
	gamestate = GAME_STATE.ONGOING
	game_root = get_tree().get_first_node_in_group("game_root")
	slow_tick_timer.start()
	start.emit()
	print("GameManager: Game started")

func reload_settings() -> void:
	ConfigManager.load_settings()
	config = ConfigManager.get_ingame_configuration()
	print("GameManager: Settings reloaded")

func apply_settings() -> void:
	ConfigManager.apply_settings(config)
	print("GameManager: Settings applied")

func save_settings() -> void:
	ConfigManager.save_settings(config)
	print("GameManager: Settings saved")

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

func _on_player_connected(id):
	if not multiplayer.is_server(): return;
	if not id in server.player_ids:
		push_warning("Unauthorized player is connecting... allowing for alpha")
	var player = PlayerObject.new()
	player.id = id
	player.name = "Player%d" % id
	GameManager.players[id] = player
	lobby_check.call_deferred()

func lobby_check():
	if gamestate != GAME_STATE.LOADING: return
	var total_players = multiplayer.get_peers().size()
	if total_players == ConfigManager.game_config.max_players:
		game_start()

func set_player_node(node:Creature):
	if node.name in player_ids:
		players[node.name]["node"] = node
		print("Player node updated")
