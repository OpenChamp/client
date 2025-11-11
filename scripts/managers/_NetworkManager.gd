class_name GameNetworkManager
extends Node

signal player_connected(id)
signal player_disconnected(id)

signal connected_to_server
signal connection_failed
signal disconnected_from_server

signal server_ready
signal quit

const default_port = 7000

func _start():
	if ConfigManager.client_mode == ConfigManager.CLIENTMODE.DEDICATED_SERVER:
		_start_gameserver(ConfigManager.get_game_setting("network", "port"), ConfigManager.get_game_setting("game", "max_players"))
	else:
		_start_client(ConfigManager.get_game_setting("network", "server_ip"), ConfigManager.get_game_setting("network", "port"))

func _stop():
	multiplayer.multiplayer_peer = null
	print("Network stopped")

func _start_gameserver(port, max_players):
	if port == null:
		port = default_port
	# Start Server
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, max_players)
	if error != OK:
		print("Failed to create server on port ", port)
		quit.emit()
	multiplayer.multiplayer_peer = peer
	# Connect Signals
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	print("Server Created, Waiting on for players...")
	server_ready.emit()

func _start_client(server_ip, port):
	if port == null:
		port = default_port
	# Connect Signals
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	# Start Client
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(server_ip, port)
	multiplayer.multiplayer_peer = peer
	print("Client Created, Connecting to server at %s:%d..." % [server_ip, port])

# === Networking Signals === #

func _on_connected_to_server():
	print("Successfully connected to server")
	emit_signal("connected_to_server")

func _on_connection_failed():
	print("Failed to connect to server")
	emit_signal("connection_failed")

func _on_server_disconnected():
	print("Disconnected from server")
	emit_signal("disconnected_from_server")
	
func _on_player_connected(id):
	if not multiplayer.is_server(): return
	print("Player connected with ID: %d" % id)
	emit_signal("player_connected", id)

func _on_player_disconnected(id):
	print("Player disconnected with ID: %d" % id)
	emit_signal("player_disconnected", id)

@rpc("any_peer")
func execute_move_command(pos):
	if not multiplayer.is_server():
		return
	var id = multiplayer.get_remote_sender_id()
	var player_node
	if player_node:
		player_node.set_move_target(pos)
	else:
		print("No player node found for move command")


# @rpc("any_peer")
# func request_client_username():
# 	rpc_id(1, "receive_client_username", Util.username)


# @rpc("any_peer")
# func receive_client_username(new_name):
# 	var id = multiplayer.get_remote_sender_id()
# 	Util.players[id]["name"] = new_name


# @rpc("authority")
# func request_client_token():
# 	rpc_id(1, "receive_client_token", Util.get_token())


# @rpc("any_peer")
# func receive_client_token(client_token):
# 	Util.players[multiplayer.get_remote_sender_id()].token = client_token


#func send_move_command(pos):
	#pos.y = 0
	#rpc_id(1, "execute_move_command", pos)
