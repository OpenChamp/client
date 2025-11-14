# OpenChamp In-Game Logic Script
# Orchestrates game startup and lifecycle management
class_name GameRoot
extends Node
"""
Gameplay Lifecycle
1. [LOADING] Load game config, find out if you're a server or client, and connect to the server (DONE)
2. [WAITING] Wait for the server to send the "start" signal (after all players have joined) (DONE)
3. [PREGAME] Initialize game state and spawn players
	- Creates a 15s timer for spawn lock
	- Start the Minion Timer (30s)
	- During this time, players can see the map and their champions, but can't move or interact
5. [MATCH_START] Game starts, spawn lock ends
	- Players can move and interact
	- Players gain 100% movement speed for 15s
	- Minions should start spawning after 15s of movement
	- Game state updates every tick
"""
# TODO: Reimplement SpawnManager
@onready var player_spawner := $Spawners/Player
@onready var map_spawner := $Spawners/Map
@onready var minion_spawner := $Spawners/Minion
@onready var jungle_spawner := $Spawners/Jungle

@onready var env := $WorldEnvironment
# === SETUP FUNCTIONS === #
func _ready() -> void:
	print("GameRoot: Initializing in-game scene")
	# == UI Setup == #
	UIManager.set_ui_root($"./UI/UIRoot")
	UIManager.change_interface("Loading")
	UIManager.preload_interface("InGame")
	# == Network Setup == #
	NetworkManager.player_connected.connect(GameManager._on_player_connected)
	NetworkManager.disconnected_from_server.connect(get_tree().quit)
	NetworkManager.game_root = self
	# == Load Config == #
	var config = ConfigManager.get_ingame_configuration()
	print("GameRoot: Loaded in-game configuration: %s" % str(config))
	# == Client Init == #
	NetworkManager._start.call_deferred()

func _on_game_start():
	"""
	1. Spawn in all players
	2. Start the pregame timer
	3. Transition to PREGAME state
	"""
	if not multiplayer.is_server():
		push_error("Only the server can start the game!")
		return
	# === 1 === #
	for id in GameManager.players.keys():
		player_spawner.spawn_player(id)
	
	# Wait 1s so all clients are loaded and ready 
	get_tree().create_timer(1).timeout.connect(rpc.bind("start_pregame"))
	# Connect minion wave timer to spawner and start it
	$Timers/MinionWave.start()


@rpc("any_peer", "call_local")
func start_pregame():
	"""
	Client-side pregame start logic
	1. Start the pregame timer
	2. Transition to PREGAME state
	3. Add Camera and UI
	"""
	var camera_scene := load("res://scenes/ui/game_controller.tscn")
	var camera_instance : Node3D = camera_scene.instantiate()
	add_child(camera_instance)
	camera_instance.rotate_y(deg_to_rad(-90))
	UIManager.change_interface("InGame")
