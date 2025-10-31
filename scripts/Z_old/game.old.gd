extends Node3D

var Gamestate : int
enum State {
	MATCH_STARTING,
	MATCH_ONGOING,
	MATCH_PAUSED,
	MATCH_ENDING
}
@export var time_elapsed : float
@export var caster_minion : PackedScene

var PING_START:int = 0;
func _ready():
	# Load Arguments (allows for external clients to launch with args)
	Util.load_settings()
	Util.load_args()
	Util.show_debug_overlay()
	# Connect signals for server/client events
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	
	if Util.dedicated_server:
		setup_host()
	else:
		setup_client()

	NetworkManager.PlayerSpawner = $PlayerSpawner

func setup_host():
	Gamestate = State.MATCH_STARTING
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(Util.port, Util.max_players)
	if error != OK:
		print("Failed to create server.")
		get_tree().quit(1001)
	multiplayer.multiplayer_peer = peer
	$PingTimer.start();
	print("Server Created, Waiting on for players...")
	Util.players[1] = { "name": "Server", "connected": true, "nodepath": null }
	
func setup_client():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(Util.ip, Util.port)
	if error != OK:
		print("Failed to create client.")
		get_tree().quit(1002)
	multiplayer.multiplayer_peer = peer

func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		_server_tick(delta)
		$Timer.start()

	else:
		_client_tick(delta)

func _server_tick(delta: float) -> void:
	time_elapsed += delta


func _client_tick(_delta: float) -> void:
	$UI/Time.text = "[center] [color=red]" + sec_to_time(int(time_elapsed)) + "[/color] [/center]"

# Client Functions

func sec_to_time(sec: int) -> String:
	var minutes = int(sec / 60)
	var seconds = sec % 60
	return str(minutes) + ":" + str(seconds)
func setup_camera(playernode):
	print("Setting up camera");
	$game_controller.global_position = playernode.global_position
	$game_controller.global_rotation_degrees = Vector3(0, 90, 0);
	$game_controller._set_ui($UI);
	
# Server Functions
func start_game():
	$MapSpawner.spawn_map()
	rpc.call_deferred("start_champion_select")
	pass

func spawn_minion():
	add_child(caster_minion.instantiate())
	print("Minion Added")

func _on_player_connected(id):
	if not multiplayer.is_server():
		return;
	print("Player connected with ID: %d" % id)
	if Util.players.has(id):
		Util.players[id]["connected"] = true;
	elif Util.players.size() < Util.max_players + 1:
		Util.players[id] = { "name": "unknown_player", "connected:": true }
		rpc_id(id, "request_client_username")
	else:
		return;
		
	if Gamestate == State.MATCH_STARTING:
		var is_ready:bool = true;
		for pid in Util.player_ids:
			if !Util.players[pid]["connected"]:
				is_ready = false
		if is_ready:
			start_game();
		else:
			print("NOT READY")
			print(JSON.stringify(Util.players))
			print(JSON.stringify(Util.player_ids))
	pass
func _on_player_disconnected(id):
	print("Player disconnected with ID: %d" % id)
	pass
func _on_connected_to_server():
	pass
func _on_connection_failed():
	pass

@rpc("any_peer")
func request_client_username():
	print("Name Request Received")
	rpc_id(1, "receive_client_username", Util.username)

@rpc("any_peer")
func receive_client_username(client_uname):
	var id = multiplayer.get_remote_sender_id()
	print("OK")
	print("Got Name: " + str(id) + " _ " + client_uname)
	if Util.players.has(id):
		Util.players[id]["name"] = client_uname
	else:
		print("WEIRD PERSON HERE, NOT IN DB")

@rpc("authority")
func start_champion_select():
	# TODO: Add champ select
	NetworkManager.select_champion.call_deferred("ranger")
	pass;
