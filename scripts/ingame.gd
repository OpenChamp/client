# OpenChamp In-Game Logic Script
# Orchestrates game startup and lifecycle management
# 
# Architecture: Thin orchestration layer that delegates to specialized managers
# Core Managers:
# - WSManager: Manages WebSocket connections and network events
# - GameManager: Maintains game state and timing loops
# - CombatManager: Processes all combat and ability interactions
# - UIManager: Manages all UI updates and state display
# - IOManager: Handles player input and movement commands

class_name GameRoot
extends Node

# === Node References === #
@onready var PlayerSpawner: MultiplayerSpawner = $Spawners/Player
@onready var MapSpawner: MultiplayerSpawner = $Spawners/Map
@onready var MinionSpawner: MultiplayerSpawner = $Spawners/Minion
@onready var JungleSpawner: MultiplayerSpawner = $Spawners/Jungle

@onready var PingTimer: Timer = $Timers/Ping
@onready var SecondTimer: Timer = $Timers/Second
@onready var MinionWaveTimer: Timer = $Timers/MinionWave

@onready var GameTime: Node = $Timers/GameTime

# === Initialization === #
func _ready() -> void:
	GameManager.set_state(GameManager.GAME_STATE.LOADING)

	if Util.dedicated_server:
		_initialize_server()
	else:
		_initialize_client()
	
	_connect_signals()
	print("GameRoot: Initialization complete (dedicated_server: %s)" % Util.dedicated_server)

# ============================================================================
# INITIALIZATION LAYER - Sets up managers and connects core systems
# ============================================================================

## Initialize server-side game state and network listeners
func _initialize_server() -> void:
	# Configure engine timing
	Engine.max_fps = GameManager.server.tick_rate
	
	# Start network listener (NetworkManager handles player connections)
	NetworkManager._start_gameserver()
	
	# Hide loading screen
	_update_loading_ui(false)
	
	print("GameRoot: Server initialized")

## Initialize client-side network connection and input handlers
func _initialize_client() -> void:
	# Setup local input handlers
	_setup_client_input()
	
	# Setup multiplayer connection callbacks
	NetworkManager._setup_client_network()
	
	# Delegate server connection to NetworkManager
	NetworkManager.connect_to_server()

## Configure local player input signals
func _setup_client_input() -> void:
	if not has_node("PlayerRig"):
		return
	
	var player_rig = $PlayerRig
	if player_rig.has_signal("use_ability"):
		player_rig.use_ability.connect(_on_client_ability_requested)
	if player_rig.has_signal("move_player"):
		player_rig.move_player.connect(_on_client_movement_requested)

## Configure multiplayer connection state signals (delegated to NetworkManager)
func _setup_client_network() -> void:
	# NetworkManager handles multiplayer signal connections
	NetworkManager.ws_connected.connect(_on_client_connected_to_server)
	NetworkManager.ws_disconnected.connect(_on_client_disconnected_from_server)

## Connect all signal handlers
func _connect_signals() -> void:
	# Network events - delegated to NetworkManager in managers folder
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	
	# Game state changes
	GameManager.start.connect(_on_game_start)
	
	# Timer events for periodic updates
	if PingTimer:
		PingTimer.timeout.connect(_on_ping_tick)
	if SecondTimer:
		SecondTimer.timeout.connect(_on_second_tick)
	if MinionWaveTimer:
		MinionWaveTimer.timeout.connect(_on_minion_wave_tick)

# ============================================================================
# GAME LIFECYCLE - Manages transitions between game states
# ============================================================================

## Called when game transitions to ONGOING state
func _on_game_start() -> void:
	GameManager.set_state(GameManager.GAME_STATE.ONGOING)
	_update_loading_ui(false)
	print("GameRoot: Game started")

## Called when all players are connected and game should begin
func start_game() -> void:
	GameManager.set_state(GameManager.GAME_STATE.ONGOING)
	
	# Server: Start game timers
	if Util.dedicated_server:
		if SecondTimer:
			SecondTimer.start()
		if MinionWaveTimer:
			MinionWaveTimer.start()
		GameManager.on_game_start()
	
	# Notify all clients via NetworkManager
	NetworkManager.rpc("_client_on_game_start")

# ============================================================================
# NETWORK EVENT HANDLERS - Delegated to managers when appropriate
# ============================================================================

## Server: Handle player connection (NetworkManager tracks connection state)
func _on_player_connected(id: int) -> void:
	if not Util.dedicated_server:
		return
	
	print("GameRoot: Player %d connected" % id)
	
	# Check if all players have connected and game should start
	var connected_count = Util.players.size()
	if connected_count >= GameManager.server.max_players:
		print("GameRoot: All players connected (%d/%d)" % [connected_count, GameManager.server.max_players])
		start_game()
	else:
		print("GameRoot: Waiting for players (%d/%d)" % [connected_count, GameManager.server.max_players])

## Server: Handle player disconnection
func _on_player_disconnected(id: int) -> void:
	print("GameRoot: Player %d disconnected" % id)
	
	# TODO: Implement reconnection grace period or team elimination
	# This could delegate to a SessionManager or similar

## Client: Handle successful connection to server
func _on_client_connected_to_server() -> void:
	_update_loading_ui_text("Waiting for other players...")
	print("GameRoot: Connected to server")

## Client: Handle disconnection from server
func _on_client_disconnected_from_server() -> void:
	_update_loading_ui_text("Server connection lost - shutting down")
	_update_loading_ui(true)
	get_tree().create_timer(3.0).timeout.connect(get_tree().quit)
	print("GameRoot: Disconnected from server")

## RPC: Called on all clients when server starts the game
@rpc("authority")
func _client_on_game_start() -> void:
	_update_loading_ui(false)
	print("GameRoot: Client received game start signal")

# ============================================================================
# PLAYER ACTION HANDLERS - Routes input through appropriate managers
# ============================================================================

## Client: Player requested ability usage (from input system)
func _on_client_ability_requested(ability_id: int, location: Vector3) -> void:
	# TODO: Create execute_ability method in NetworkManager
	# For now, delegate movement portion to NetworkManager
	print("GameRoot: Ability %d requested at %s (pending CombatManager integration)" % [ability_id, location])

## Client: Player requested movement (from input system)
func _on_client_movement_requested(target: Vector3) -> void:
	# Delegate to NetworkManager's existing movement RPC system
	NetworkManager.send_move_command(target)

# ============================================================================
# PERIODIC TICK HANDLERS - Process recurring game events
# ============================================================================

## Called every network ping interval
func _on_ping_tick() -> void:
	# TODO: Update player latency in UIManager
	pass

## Called once per second - for periodic updates
func _on_second_tick() -> void:
	# Timer-based effects, cooldown updates, etc could go here
	# Delegate specialized logic to appropriate managers
	pass

## Called when minion wave should spawn
func _on_minion_wave_tick() -> void:
	# TODO: Delegate to minion spawning system
	# This could be a separate MinionManager or handled by CombatManager
	pass

# ============================================================================
# HELPER FUNCTIONS - Utility methods for common operations
# ============================================================================

## Get player node by network peer ID
func _get_player_node(player_id: int) -> Node:
	# Search spawned player nodes for matching ID
	if PlayerSpawner and PlayerSpawner.is_node_ready():
		for child in PlayerSpawner.get_children():
			if child.name == str(player_id):
				return child
	return null

## Update loading screen visibility
func _update_loading_ui(visible: bool) -> void:
	if has_node("Loading"):
		if visible:
			$Loading.show()
		else:
			$Loading.hide()

## Update loading screen text
func _update_loading_ui_text(text: String) -> void:
	if has_node("Loading") and $Loading.has_method("update_header"):
		$Loading.update_header(text)
