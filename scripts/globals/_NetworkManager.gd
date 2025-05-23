extends Node

# Network Constants
const SETTINGS_PATH = "user://settings.cfg"

# Network Settings
var websocket_url: String = ""
var token = ""
# Network State
var socket = WebSocketPeer.new()
var connection_timeout: float = 0

# Store - Application State
var Store = {
	"InQueue": false,
	"PlayerCount": 0,
}

# Signals
signal chat_message_received(sender, message)

func _ready():
	set_process(false)
	print("NetworkManager Loaded")

func _process(delta):
	socket.poll()
	connection_timeout += delta
	var state = socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			var data = socket.get_packet().get_string_from_utf8()
			var json = JSON.parse_string(data)
			process_packet(json)
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		set_process(false)

# === Connection Management ===

func connect_to_server():
	connection_timeout = 0.0
	var err = socket.connect_to_url(websocket_url)
	if err != OK:
		print("Unable to connect")
		return false
	else:
		set_process(true)
		return true

func disconnect_from_server():
	socket.close()
	set_process(false)

func set_username(username: String = Util.username):
	var packet = {
		"type": "set_username",
		"payload": username.replace("\"", "")
	}
	socket.send_text(JSON.stringify(packet))
# === Server Communication ===

func get_player_count():
	socket.send_text("{\"type\": \"count\"}")

func start_queue():
	socket.send_text("{\"type\": \"queue\"}")

func stop_queue():
	socket.send_text("{\"type\": \"stop_queue\"}")

func process_packet(packet: Dictionary):
	match packet["type"]:
		"global_chat":
			_handle_chat_message(packet["payload"])
		"player_count":
			Store.PlayerCount = int(packet["payload"])
		"queued":
			Store.InQueue = true
		"user_assigned":
			Util.Username = packet["payload"]
		_:
			print("Unknown packet: ", JSON.stringify(packet))

# === Chat System ===

func send_global_chat_message(message_text):
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var chat_packet = {
			"type": "global_chat",
			"payload": message_text,
		}
		socket.send_text(JSON.stringify(chat_packet))

func _handle_chat_message(packet):
	if packet.has("username") and packet.has("message"):
		emit_signal("chat_message_received", packet.username, packet.message)
