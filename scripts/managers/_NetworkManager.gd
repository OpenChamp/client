extends Node


# === Signals === #
signal auth_required
signal auth_obtained
signal match_found(match: Dictionary)
signal chat_message_received(message)
signal player_connected(id)
signal player_disconnected(id)
signal ws_connecting
signal ws_disconnected
signal ws_connected

# === WS Client === #
var in_queue := false
var token := ""
var websocket_url := ""
var ws := WebSocketPeer.new()

# === Timers === #
var connection_time = 0.0

# === Game Server Settings === #
var online_player_count = 1 # Yourself
var connections: Dictionary
class PlayerConnection:
	var name: String = ""
	var connected: bool = false
	var node: Node
	var token: String = ""
	var ping: int = 0  # MS

	func _init(
		new_name = "",
		new_connected = false,
		new_node: Node = null,
		new_token = ""
	) -> void:
		self.name = new_name
		self.connected = new_connected
		self.node = new_node
		self.token = new_token

func _ready():
	set_process(false)
	print("NetworkManager Loaded")

func _process(delta):
	ws.poll()
	connection_time += delta
	var state = ws.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		ws_connected.emit()
		while ws.get_available_packet_count():
			var data = ws.get_packet().get_string_from_utf8()
			var json = JSON.parse_string(data)
			process_packet(json)
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = ws.get_close_code()
		ws_disconnected.emit()
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		set_process(false)

# === Websocket === #
func auth_with_credentials(_username:String, _password:String):
	# TODO: Implement login logic with uname and password
	pass;

func auth_with_token(auth_token: String = Util.get_token()):
	var packet = {
		"type": "token_auth",
		"payload": {
			"token": auth_token
		}
	}
	ws.send_text(JSON.stringify(packet))

func connect_to_server():
	ws_connecting.emit()
	connection_time = 0.0
	var err = ws.connect_to_url(GameManager.config['network']['websocket_url'])
	if err != OK:
		print("Unable to connect")
		return false
	else:
		set_process(true)
		return true

func disconnect_from_server():
	ws.close()
	ws_disconnected.emit()
	set_process(false)

func fast_registration(username):
	var packet = {
		"type": "register",
		"payload": {
			"username": username,
			"password": "password123",
			"email": username + "@techeron.com"
		}
	}
	ws.send_text(JSON.stringify(packet))

func process_registration(payload):
	print("Auth Obtained")
	Util.username = payload.username
	Util.set_token(payload.token)
	auth_obtained.emit()

func get_player_count():
	ws.send_text("{\"type\": \"count\"}")

func set_username(username: String = Util.username):
	var packet = {
		"type": "set_username",
		"payload": username.replace("\"", "")
	}
	ws.send_text(JSON.stringify(packet))

func join_queue():
	ws.send_text("{\"type\": \"join_queue\"}")

func leave_queue():
	ws.send_text("{\"type\": \"leave_queue\"}")

func process_packet(packet: Dictionary):
	match packet["type"]:
		"global_chat":
			_handle_chat_message(packet["payload"])
		"player_count":
			online_player_count = int(packet["payload"])
		"queued":
			in_queue = true
		"match_found":
			match_found.emit(packet["payload"])
		"register_success", "auth_success":
			process_registration(packet["payload"])
		"user_assigned":
			Util.username = packet["payload"]
		"error":
			_handle_server_error(packet["payload"])
		_:
			print("Unknown packet: ", JSON.stringify(packet))

# === Chat System === #
func send_global_chat_message(message_text):
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var chat_packet = {
			"type": "global_chat",
			"payload": message_text,
		}
		ws.send_text(JSON.stringify(chat_packet))

func _handle_chat_message(packet):
	if packet.has("username") and packet.has("message"):
		emit_signal("chat_message_received", packet.username, packet.message)

func _handle_server_error(packet):
	if packet.has("code"):
		match packet["code"]:
			"AUTH_REQUIRED":
				emit_signal("auth_required")
			_:
				print("Server Error: " + JSON.stringify(packet))

# === Game Functions === #

func _start_gameserver():
	# Connect Signals
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	# Initial Config
	connections[1] = PlayerConnection.new("Server", true)
	# Start Server
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(GameManager.server.port ,GameManager.server.max_players)
	if error != OK:
		print("Failed to create server on port ", Util.port)
		get_tree().create_timer(1).timeout.connect(get_tree().quit)
	multiplayer.multiplayer_peer = peer
	print("Server Created, Waiting on for players...")


func _on_player_connected(id):
	# TODO: Implement max lobby size based on max_connections variable
	if not multiplayer.is_server():
		return
	print("Player connected with ID: %d" % id)
	if connections.has(id):
		connections[id].connected = true
	elif connections.size() < Util.max_players + 1:
		connections[id] = PlayerConnection.new("Player", true)
		rpc_id(id, "request_client_token")
	emit_signal("player_connected", id)


func _on_player_disconnected(id):
	print("Player disconnected with ID: %d" % id)
	emit_signal("player_disconnected", id)


func _on_connected_to_server():
	pass


func _on_connection_failed():
	pass

# === Champion Select ===
#@rpc("any_peer")
#func select_champion(champion:String):
	#print("Selecting Champion")
	#if multiplayer.is_server():
		#print("ON SERVER")
		#var id = multiplayer.get_remote_sender_id()
		#if not PlayerSpawner:
			#rpc_id(id, "failed_select_champion", "missing_player_spawner")
			#return
		#PlayerSpawner.spawn_player(id, champion)
		#return;
	#rpc_id(1, "select_champion", champion)

#@rpc("authority")
#func failed_select_champion(reason:String):
	#print("Champion selection failed: %s" % reason)
	## Wait 3s, then try again
	#get_tree().create_timer(3.0).timeout.connect(func():
		#select_champion("ranger")
	#)	


# === Movement ===

@rpc("any_peer")
func execute_move_command(pos):
	if not multiplayer.is_server():
		return
	var id = multiplayer.get_remote_sender_id()
	var player_node
	if connections[id].has("nodepath"):
		player_node = connections[id]["nodepath"]
	if player_node:
		player_node.set_move_target(pos)
	else:
		print("No player node found for move command")


@rpc("any_peer")
func request_client_username():
	print("Name Request Received")
	rpc_id(1, "receive_client_username", Util.username)


@rpc("any_peer")
func receive_client_username(new_name):
	var id = multiplayer.get_remote_sender_id()
	connections[id]["name"] = new_name


@rpc("authority")
func request_client_token():
	rpc_id(1, "receive_client_token", Util.get_token())


@rpc("any_peer")
func receive_client_token(client_token):
	connections[multiplayer.get_remote_sender_id()].token = client_token


func send_move_command(pos):
	pos.y = 0
	rpc_id(1, "execute_move_command", pos)


# === Sync Function (Client) === #

func sync_player_count():
	if multiplayer.is_server():
		return
	ws.send_text("{\"type\": \"count\"}")


# === Setup Functions (Server) === #

func setup_player_count():
	if not multiplayer.is_server():
		return
	var player_count_timer := Timer.new()
	player_count_timer.one_shot = false
	player_count_timer.wait_time = 1.0
	player_count_timer.timeout.connect(func():rpc("sync_player_count", online_player_count))


func set_player_whitelist(_players: Array):
	if not multiplayer.is_server(): return;
	# TODO: Implement server whitelisting
	pass


func setup_client_network():
	multiplayer.connected_to_server.connect(_on_client_connected_to_server)
	multiplayer.server_disconnected.connect(_on_client_disconnected_from_server)
	multiplayer.connection_failed.connect(_on_client_disconnected_from_server)
