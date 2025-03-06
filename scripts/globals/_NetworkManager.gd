extends Node

# Network Constants
const SETTINGS_PATH = "user://settings.cfg"

# Network Settings
var websocket_url: String = "ws://localhost:8080/ws"

# Network State
var socket = WebSocketPeer.new()
var connection_timeout: float = 0

# Store - Application State
var Store = {
	"InQueue": false,
	"PlayerCount": 0,
	"Username": ""
}

# Signals
signal chat_message_received(sender, message)

func _ready():
	set_process(false)
	print("NetworkManager Loaded")
	load_settings()

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

func connect_to_server(username: String = ""):
	Store["Username"] = username
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

func set_username(username: String = Store["Username"]):
	var packet = {
		"type": "set_username",
		"payload": username.replace("\"", "")
	}
	socket.send_text(JSON.stringify(packet))

# === Settings Management ===

func load_settings():
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)
	
	if err != OK:
		print("No settings file found, using defaults for network")
		return
	
	# Load network settings from the same config file
	websocket_url = config.get_value("network", "websocket_url", "ws://localhost:8080/ws")
	Store["Username"] = config.get_value("player", "username", "Player")

func save_settings_to_config(config):
	# Save network settings to the provided config
	config.set_value("network", "websocket_url", websocket_url)

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
			Store.Username = packet["payload"]
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
