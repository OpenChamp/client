extends Node

# === Websocket Settings === #
@export var websocket_url := ""
@export var token := ""
var is_ws_connected := false

var connection_time = 0.0
var ws := WebSocketPeer.new()

# === Chat Manager Integration === #
var chat_manager: Node = null

signal auth_required
signal auth_obtained
signal match_found(match: Dictionary)
signal ws_connecting
signal ws_disconnected
signal ws_connected

signal packet_received
signal packet_sent
# === Game Server Settings === #
var in_queue := false
var player_count = 0

class PlayerObject:
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
	# Share the WebSocketPeer with the chat manager
	if chat_manager:
		chat_manager.set_socket(ws)
		# Connect chat signals to WS_Manager signals
		chat_manager.connect("chat_message_received", Callable(self, "_on_chat_message_received"))
		chat_manager.connect("auth_required", Callable(self, "_on_chat_auth_required"))
		chat_manager.connect("server_error", Callable(self, "_on_chat_server_error"))

func _process(delta):
	ws.poll()
	connection_time += delta
	var state = ws.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		if not is_ws_connected:
			ws_connected.emit()
			is_ws_connected = true
			if chat_manager:
				chat_manager.packet_sent.connect(func(): emit_signal("packet_sent"))
				chat_manager.packet_received.connect(func(_packet): emit_signal("packet_received"))
				chat_manager.set_socket(ws)
		while ws.get_available_packet_count():
			var data = ws.get_packet().get_string_from_utf8()
			var packets = data.split('}{', false)
			for i in packets.size():
				var packet_str = packets[i]
				if i == 0 and packets.size() > 1:
					packet_str += "}"
				elif i == packets.size() - 1 and packets.size() > 1:
					packet_str = "{" + packet_str
				elif packets.size() > 1:
					packet_str = "{" + packet_str + "}"
				var json = JSON.parse_string(packet_str)
				if json == null:
					print("Bad Packet: ", packet_str)
					continue
				process_packet(json)
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = ws.get_close_code()
		ws_disconnected.emit()
		is_ws_connected = false
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		set_process(false)


# === Websocket Connection Management === #

func auth_with_token(auth_token: String = Util.get_token()):
	var packet = {
		"type": "token_auth",
		"payload": {
			"token": auth_token
		}
	}
	ws.send_text(JSON.stringify(packet))
	packet_sent.emit()


func connect_to_server(ws_url:String = websocket_url):
	ws_connecting.emit()
	connection_time = 0.0
	var err = ws.connect_to_url(ws_url)
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
	packet_sent.emit()


func process_registration(payload):
	Util.username = payload.username
	Util.set_token(payload.token)
	auth_obtained.emit()


# === Client Helper Functions === #

func get_player_count():
	ws.send_text("{\"type\": \"count\"}")
	packet_sent.emit()


func set_username(username: String = Util.username):
	var packet = {
		"type": "set_username",
		"payload": username.replace("\"", "")
	}
	ws.send_text(JSON.stringify(packet))
	packet_sent.emit()


func join_queue():
	ws.send_text("{\"type\": \"join_queue\"}")
	packet_sent.emit()


func leave_queue():
	ws.send_text("{\"type\": \"leave_queue\"}")
	packet_sent.emit()


func process_packet(packet: Dictionary):
	packet_received.emit()
	match packet["type"]:
		# Chat packets are now handled by chat_manager in _process
		"player_count":
			player_count = int(packet["payload"])
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
			if packet["type"] in ["global_chat", "party_chat", "private_chat", "match_chat", "error"]:
				chat_manager.process_packet(packet)
			else:
				print("Unknown packet: ", JSON.stringify(packet))

# === Chat System === #

## Handles server error packets.
func _handle_server_error(payload: Dictionary):
	if payload.has("code"):
		match payload["code"]:
			"AUTH_REQUIRED":
				emit_signal("auth_required")
			"REGISTRATION_FAILED":
				print(payload)
			_:
				print("Server Error: " + JSON.stringify(payload))
				emit_signal("server_error", payload)
	else:
		print("Malformed Errror packet was sent")
		print(payload)
# === Game Functions === #





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
func request_client_username():
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
	pos.y = 0
	rpc_id(1, "execute_move_command", pos)


# === Sync Function (Client) === #

func sync_player_count():
	if multiplayer.is_server():
		return
	ws.send_text("{\"type\": \"count\"}")
	packet_sent.emit()


# === Setup Functions (Server) === #

func setup_player_count():
	if not multiplayer.is_server():
		return
	var player_count_timer := Timer.new()
	player_count_timer.one_shot = false
	player_count_timer.wait_time = 1.0
	player_count_timer.timeout.connect(func():rpc("sync_player_count", player_count))
