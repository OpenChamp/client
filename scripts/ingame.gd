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
@onready var NetworkManager = $Systems/Network
@onready var LifecycleManager = $Systems/Lifecycle

# === SETUP FUNCTIONS === #
func _ready() -> void:
	print("GameRoot: Initializing in-game scene")
	# == Network Setup == #
	NetworkManager.server_ready.connect(self._on_server_ready)
	NetworkManager.player_connected.connect(GameManager._on_player_connected)
	NetworkManager.quit.connect(get_tree().quit)
	# == Load Config == #
	var config = ConfigManager.get_ingame_configuration()
	print("GameRoot: Loaded in-game configuration: %s" % str(config))
	# == Server Init == #
	if ConfigManager.is_server():
		GameManager.slow_tick_timer = $Timers/Second
		GameManager.initialize()
	# == Client Init == #
	NetworkManager._start.call_deferred()

func _on_server_ready():
	"""
	1. Spawn in the map
	2. Wait for all players to connect
	3. Trigger gameManager start
	"""
	# === 1 === #
	SpawnManager.spawn_map(ConfigManager.get_game_setting("game","map_name"))
	# === 2 === #
	# NetworkManager.lobby_full.connect(GameManager.game_start)
