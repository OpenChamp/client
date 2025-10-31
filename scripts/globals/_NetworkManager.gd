extends Node
# === Websocket Settings === #
@export var websocket_url      := ""
@export var token              := ""
var is_ws_connected := false

var connection_time = 0.0
var WS := WebSocketPeer.new()

signal auth_required
signal auth_obtained
signal match_found(match:Dictionary)
signal chat_message_received(message)
signal ws_connecting
signal ws_disconnected
signal ws_connected
# === Game Server Settings === #
var in_queue := false
var player_count = 0;

signal player_connected(id)
signal player_disconnected(id)

class PlayerObject:
	var name : String = ""
	var connected: bool = false
	var node: Node
	var token: String = ""
	var ping: int = 0 #MS
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
	WS.poll()
	connection_time += delta
	var state = WS.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		if not is_ws_connected: 
			ws_connected.emit();
			is_ws_connected = true;
		while WS.get_available_packet_count():
			var data = WS.get_packet().get_string_from_utf8()
			var json = JSON.parse_string(data)
			process_packet(json)
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = WS.get_close_code()
		ws_disconnected.emit()
		is_ws_connected = false;
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		set_process(false)

# === Websocket Connection Management === #
func auth_with_token(auth_token: String = Util.get_token()):
	var packet = {
		"type": "token_auth",
		"payload": {
			"token" : auth_token
		}
	}
	WS.send_text(JSON.stringify(packet))

func connect_to_server():
	ws_connecting.emit()
	connection_time = 0.0
	var err = WS.connect_to_url(websocket_url)
	if err != OK:
		print("Unable to connect")
		return false
	else:
		set_process(true)
		return true

func disconnect_from_server():
	WS.close()
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
	WS.send_text(JSON.stringify(packet))

func process_registration(payload):
	print("Auth Obtained")
	Util.username = payload.username
	Util.set_token(payload.token)
	auth_obtained.emit()

# === Client Helper Functions === #
func get_player_count():
	WS.send_text("{\"type\": \"count\"}")

func set_username(username: String = Util.username):
	var packet = {
		"type": "set_username",
		"payload": username.replace("\"", "")
	}
	WS.send_text(JSON.stringify(packet))

func join_queue():
	WS.send_text("{\"type\": \"join_queue\"}")

func leave_queue():
	WS.send_text("{\"type\": \"leave_queue\"}")

func process_packet(packet: Dictionary):
	match packet["type"]:
		"global_chat":
			_handle_chat_message(packet["payload"])
		"player_count":
			player_count = int(packet["payload"])
		"queued":
			in_queue = true
		"match_found":
			match_found.emit(packet["payload"])
		"register_success", "auth_success":
			process_registration(packet["payload"])
		"user_assigned":
			Util.Username = packet["payload"]
		"error":
			_handle_server_error(packet["payload"])
		_:
			print("Unknown packet: ", JSON.stringify(packet))

# === Chat System === #

func send_global_chat_message(message_text):
	if WS.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var chat_packet = {
			"type": "global_chat",
			"payload": message_text,
		}
		WS.send_text(JSON.stringify(chat_packet))

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
	Util.players[1] = PlayerObject.new("Server", true)
	# Start Server
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(Util.port, Util.max_players)
	if error != OK:
		print("Failed to create server.")
		get_tree().quit(1001)
	multiplayer.multiplayer_peer = peer
	print("Server Created, Waiting on for players...")
	pass

func _on_player_connected(id):
	if not multiplayer.is_server(): return;
	print("Player connected with ID: %d" % id)
	if Util.players.has(id):
		Util.players[id].connected = true
	elif Util.players.size() < Util.max_players + 1:
		Util.players[id] = PlayerObject.new("Player", true)
		rpc_id(id, "request_client_token")
	emit_signal("player_connected", id)

func _on_player_disconnected(id):
	print("Player disconnected with ID: %d" % id)
	emit_signal("player_disconnected", id)
	pass
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
	if not multiplayer.is_server(): return;
	var id = multiplayer.get_remote_sender_id();
	var player_node
	if Util.players[id].has("nodepath"):
		player_node = Util.players[id]["nodepath"]
	if player_node:
		player_node.set_move_target(pos)
	else:
		print("No player node found for move command");

@rpc("any_peer")
func request_client_username():
	print("Name Request Received")
	rpc_id(1, "receive_client_username", Util.username)
	
@rpc("any_peer")
func receive_client_username(new_name):
	var id = multiplayer.get_remote_sender_id()
	Util.players[id]["name"] = new_name
	
@rpc("authority")
func request_client_token():
	rpc_id(1, "receive_client_token", Util.get_token())
	
@rpc("any_peer")
func receive_client_token(client_token):
	Util.players[multiplayer.get_remote_sender_id()].token = client_token

func send_move_command(pos):
	pos.y = 0;
	rpc_id(1, "execute_move_command", pos);
# === Sync Function (Client) === #
func sync_player_count():
	if multiplayer.is_server(): return;
	WS.send_text("{\"type\": \"count\"}")

# === Setup Functions (Server) === #
func setup_player_count():
	if not multiplayer.is_server(): return;
	var player_count_timer := Timer.new();
	player_count_timer.one_shot = false
	player_count_timer.wait_time = 1.0
	player_count_timer.timeout.connect(func():rpc("sync_player_count", player_count))
