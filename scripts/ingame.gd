extends Node

const MAX_PLAYERS = 2

var Gamestate = GAME_STATE.LOADING
enum GAME_STATE {
	LOADING,
	ONGOING,
	PAUSED,
	DONE
}

@export var Game_Time: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(true)
	Util.set_up();
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	if Util.dedicated_server:
		_setup_server()
	else:
		get_tree().create_timer(randi_range(0,3)).timeout.connect(setup_client)
	pass # Replace with function body.

func _physics_process(delta: float) -> void:
	if Util.dedicated_server:
		Game_Time += delta

func _setup_server():
	Gamestate = GAME_STATE.LOADING
	$Loading.hide()
	NetworkManager._start_gameserver()
	# $PingTimer.start();
	print("Server Created, Waiting on for players...")
	
func setup_client():
	$PlayerRig.use_ability.connect(_on_player_use_ability)
	$PlayerRig.move_player.connect(_on_player_requests_movement)
	multiplayer.connected_to_server.connect(_client_on_connected)
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(Util.ip, Util.port)
	if error != OK:
		print("Failed to create client.")
		get_tree().quit(1002)
	multiplayer.multiplayer_peer = peer

func start_game():
	Gamestate = GAME_STATE.ONGOING
	Game_Time = 0.0
	rpc("_client_on_game_start")
	$MinionWaveTimer.start()
	for pid in Util.players.keys():
		if pid == 1: continue;
		$MultiplayerSpawner.spawn_ranger(str(pid))
	print("Game Started!")
	pass

func _on_player_connected(id):
	if not Util.dedicated_server: return;
	if not Util.players.has(id):
		Util.players[id] = NetworkManager.PlayerObject.new("DEBUG",true)
	if Gamestate == GAME_STATE.LOADING:
		# Check if we have reached the maximum number of players
		var connected_players = Util.players.size() - 1
		if connected_players >= MAX_PLAYERS:
			print("All %d players connected, ready to start game" % MAX_PLAYERS)
			start_game()
		else:
			print("Waiting for more players: %d/%d connected" % [connected_players, MAX_PLAYERS])
			print("Connected players: %s" % JSON.stringify(Util.players.keys()))
	pass
func _on_player_disconnected(id):
	print("Player disconnected with ID: %d" % id)
	pass
func _on_connected_to_server():
	pass
func _on_connection_failed():
	pass
func _client_on_connected():
	$Loading.update_header("Waiting On Players...")
@rpc("authority")
func _client_on_game_start():
	$Loading.hide()
# === Abilities === #
@rpc("any_peer")
func _rpc_player_use_ability(ability_id:int, loc):
	_on_player_use_ability(ability_id, loc, multiplayer.get_remote_sender_id())
func _on_player_use_ability(ability_id:int, loc, pid=-1):
	if not Util.dedicated_server:
		print(loc)
		rpc_id(1, "_rpc_player_use_ability", ability_id, loc)
	else:
		print("Player %d used ability %d at location %s" % [pid, ability_id, str(loc)])
		$MultiplayerSpawner.spawn_ability(loc)
# === Movement === #

@rpc("any_peer")
func _rpc_player_requests_movement(target:Vector3):
	_on_player_requests_movement(target, multiplayer.get_remote_sender_id())
func _on_player_requests_movement(target:Vector3, pid=-1):
	if not Util.dedicated_server:
		rpc_id(1, "_rpc_player_requests_movement", target)
	else:
		var player = get_node(str(pid))
		if player:
			player.update_target.rpc(target)
			print("Player %d requested movement to %s" % [pid, str(target)])
		
