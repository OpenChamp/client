class_name WebsocketManager
extends Node

# === Websocket Settings === #
@export var websocket_url := "ws://localhost:8080/ws"
@export var token := ""
@export var connection_timeout := 10.0
var connection_time := 0.0
var is_ws_connected := false
var ws := WebSocketPeer.new()
var _packet_buffer: String = ""
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
var in_queue: bool = false
var player_count: int = 0

func _ready() -> void:
	set_process(false)
	# Initialize chat manager integration
	if chat_manager:
		chat_manager.set_socket(ws)
		print("WebsocketManager: Chat manager connected.")

func _process(delta) -> void:
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
		while ws.get_available_packet_count():
			var data = ws.get_packet().get_string_from_utf8()
			_packet_buffer += data
			_parse_buffered_packets()
	elif state == WebSocketPeer.STATE_CONNECTING:
		# Check for connection timeout
		if connection_time > connection_timeout:
			push_error("WebSocket connection timeout after %.1f seconds" % connection_timeout)
			ws.close()
			ws_disconnected.emit()
			set_process(false)
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = ws.get_close_code()
		ws_disconnected.emit()
		is_ws_connected = false
		push_warning("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		set_process(false)

## Handles incomplete packets that may arrive across multiple frames.
func _parse_buffered_packets() -> void:
	var brace_count := 0
	var current_packet_end := -1
	
	for i in range(_packet_buffer.length()):
		var c = _packet_buffer[i]
		if c == "{":
			brace_count += 1
		elif c == "}":
			brace_count -= 1
			if brace_count == 0:
				current_packet_end = i
				var packet_str = _packet_buffer.substr(0, current_packet_end + 1)
				var json = JSON.parse_string(packet_str)
				if json == null:
					push_error("Bad Packet (malformed json): %s" % packet_str)
				else:
					process_packet(json)
				_packet_buffer = _packet_buffer.substr(current_packet_end + 1).strip_edges()
				if _packet_buffer.is_empty():
					return
				return


# === Websocket Connection Management === #

func auth_with_token(auth_token: String = token) -> void:
	if auth_token.is_empty():
		push_error("No auth token provided for authentication")
		return
	var packet = {
		"type": "token_auth",
		"payload": {
			"token": auth_token
		}
	}
	_send_packet(packet)

func connect_to_server(ws_url: String = websocket_url) -> bool:
	ws_connecting.emit()
	connection_time = 0.0
	var err: int = ws.connect_to_url(ws_url)
	if err != OK:
		push_error("Unable to connect")
		return false
	else:
		set_process(true)
		return true

func disconnect_from_server() -> void:
	ws.close()
	ws_disconnected.emit()
	set_process(false)

func _send_packet(packet_data: Dictionary) -> bool:
	var json_str := JSON.stringify(packet_data)
	var err := ws.send_text(json_str)
	
	if err != OK:
		push_error("Failed to send packet: %s (Error: %d)" % [json_str, err])
		return false
	
	packet_sent.emit()
	return true


### DEBUG ONLY ###
func fast_registration(username: String) -> void:
	push_warning("Using fast registration for user: %s" % username)
	var packet = {
		"type": "register",
		"payload": {
			"username": username,
			"password": "password123",
			"email": username + "@open-champ.com"
		}
	}
	_send_packet(packet)

# === Client Helper Functions === #

func get_player_count() -> void:
	_send_packet({"type": "count"})


func set_username(username: String) -> void:
	if username.is_empty():
		push_error("Username cannot be empty")
		return
	var packet = {
		"type": "set_username",
		"payload": username.replace("\"", "")
	}
	_send_packet(packet)


func join_queue() -> void:
	_send_packet({"type": "join_queue"})


func leave_queue() -> void:
	_send_packet({"type": "leave_queue"})

func process_packet(packet: Dictionary) -> void:
	if not packet.has("type"):
		push_error("Invalid packet: missing 'type' field - %s" % JSON.stringify(packet))
		return
	
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
			if packet["payload"].has("token"):
				token = packet["payload"]["token"]
			auth_obtained.emit(packet["payload"])
		"error":
			_handle_server_error(packet["payload"])
		_:
			if packet["type"] in ["global_chat", "party_chat", "private_chat", "match_chat", "error"] and chat_manager:
				chat_manager.process_packet(packet)
			else:
				print("Unknown packet type: %s" % packet["type"])

func _handle_server_error(payload: Dictionary) -> void:
	if payload.has("code"):
		match payload["code"]:
			"AUTH_REQUIRED":
				auth_required.emit()
			"REGISTRATION_FAILED":
				push_error("Registration failed: %s" % JSON.stringify(payload))
			_:
				push_error("Server Error: " + JSON.stringify(payload))
	else:
		push_error("Malformed Error packet: %s" % JSON.stringify(payload))

# === Sync Function (Client) === #
func sync_player_count() -> void:
	if multiplayer.is_server():
		return
	_send_packet({"type": "count"})
