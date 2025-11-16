extends Node

const MAX_PLAYERS = 2
const SERVER_TICKRATE = 30

var gamestate = GAME_STATE.LOADING

enum GAME_STATE {
	LOADING,
	ONGOING,
	PAUSED,
	DONE,
}

@export var game_time: float = 0.0


func _ready() -> void:
	set_process(true)
	await Util.set_up()
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	if Util.dedicated_server:
		call_deferred("_setup_server")
	else:
		# Simulate different player's loading times
		get_tree().create_timer(randi_range(0, 3)).timeout.connect(setup_client)


func _physics_process(delta: float) -> void:
	if Util.dedicated_server:
		game_time += delta


func _setup_server():
	# 30s Server
	if Util.debug:
		get_tree().create_timer(30).timeout.connect(get_tree().quit)
	Engine.max_fps = SERVER_TICKRATE
	gamestate = GAME_STATE.LOADING
	$Loading.hide()
	NetworkManager._start_gameserver()
	print("Server Created, Waiting on for players...")

func setup_client():
	$PlayerRig.use_ability.connect(_on_player_use_ability)
	$PlayerRig.move_player.connect(_on_player_requests_movement)
	multiplayer.connected_to_server.connect(_client_on_connected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connection_failed.connect(_on_server_disconnected)
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(Util.ip, Util.port)
	if error != OK:
		print("Failed to create client.")
		get_tree().quit(1002)
	multiplayer.multiplayer_peer = peer


func start_game():
	gamestate = GAME_STATE.ONGOING
	game_time = 0.0
	rpc("_client_on_game_start")
	$MinionWaveTimer.start()
	## === UNCOMMENT BEFORE PROD === ##
	#for pid in Util.players.keys():
	#	if pid == 1:
	#		continue
	#	$MultiplayerSpawner.spawn_ranger(str(pid))
	## === DEBUGGING === ##
	$MultiplayerSpawner.spawn_minion_test()
	print("Game Started!")


func _on_player_connected(id):
	if not Util.dedicated_server:
		return
	if not Util.players.has(id):
		Util.players[id] = NetworkManager.PlayerObject.new("DEBUG", true)
	if gamestate == GAME_STATE.LOADING:
		# Check if we have reached the maximum number of players
		var connected_players = Util.players.size() - 1
		if connected_players >= MAX_PLAYERS:
			print("All %d players connected, ready to start game" % MAX_PLAYERS)
			start_game()
		else:
			print("Waiting for more players: %d/%d connected" % [connected_players, MAX_PLAYERS])
			print("Connected players: %s" % JSON.stringify(Util.players.keys()))


func _on_player_disconnected(id):
	print("Player disconnected with ID: %d" % id)


func _on_connected_to_server():
	pass


func _on_connection_failed():
	pass


func _on_server_disconnected():
	$Loading.update_header("Server Lost... Shutting Down.")
	$Loading.show()
	get_tree().create_timer(3).timeout.connect(get_tree().quit)


func _client_on_connected():
	$Loading.update_header("Waiting On Players...")


@rpc("authority")
func _client_on_game_start():
	$Loading.hide()

# === Abilities === #

@rpc("any_peer")
func _rpc_player_use_ability(ability_id: int, loc):
	_on_player_use_ability(ability_id, loc, multiplayer.get_remote_sender_id())


func _on_player_use_ability(ability_id: int, loc, pid: int = -1):
	if not Util.dedicated_server:
		print(loc)
		rpc_id(1, "_rpc_player_use_ability", ability_id, loc)
	else:
		print("Player %d used ability %d at location %s" % [pid, ability_id, str(loc)])
		$MultiplayerSpawner.spawn_ability(loc)


# === Movement === #

@rpc("any_peer")
func _rpc_player_requests_movement(target: Vector3):
	_on_player_requests_movement(target, multiplayer.get_remote_sender_id())


func _on_player_requests_movement(target: Vector3, pid: int = -1):
	if not Util.dedicated_server:
		rpc_id(1, "_rpc_player_requests_movement", target)
	else:
		var player = get_node(str(pid))
		if player:
			player.update_target.rpc(target)
			print("Player %d requested movement to %s" % [pid, str(target)])
