extends Node
# Network Manager for Client -> Main Server
var Settings = {
	"websocket_url": "ws://localhost:8080/ws",
	"username": ""
}
var Store = {
	"InQueue": false,
	"PlayerCount": 0,
	"Username": ""
}
var socket = WebSocketPeer.new()
var connection_timeout : float = 0

signal chat_message_received(sender, message)

func _ready():
	set_process(false)
	print("Global Script Loaded")
	load_settings()
	pass
	
func _process(delta):
	socket.poll()
	connection_timeout += delta
	var state = socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		
		while socket.get_available_packet_count():
			var data = socket.get_packet().get_string_from_utf8()
			var json = JSON.parse_string(data)
			processPacket(json)
	
	if state == WebSocketPeer.STATE_CONNECTING:
		pass

	elif state == WebSocketPeer.STATE_CLOSING:
		pass

	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		set_process(false)

# Setup
func connect_to_server(username : String = ""):
	Settings.username = username
	connection_timeout  = 0.0
	var err = socket.connect_to_url(Settings.websocket_url)
	if err != OK:
		print("Unable to connect")
		return false
	else:
		set_process(true)
		return true

func disconnect_from_server():
	socket.close()
	set_process(false)
		
func load_settings():
	var file = FileAccess.open("user://settings.json", FileAccess.READ)
	if file == null:
		var newFile = FileAccess.open("user://settings.json", FileAccess.WRITE)
		newFile.store_string(JSON.stringify(Settings))
	else:
		Settings = JSON.parse_string(file.get_as_text())
	pass

# Basic Networking
func get_player_count():
	socket.send_text("{\"type\": \"count\"}")
func start_queue():
	socket.send_text("{\"type\": \"queue\"}")
func stop_queue():
	socket.send_text("{\"type\": \"stop_queue\"}")
	
func processPacket(packet : Dictionary):
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
		
## Chat
func send_global_chat_message(message_text):
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var chat_packet = {
			"type": "global_chat",
			"payload": message_text,
		}
		var json_string = JSON.stringify(chat_packet)
		socket.send_text(json_string)

# Handle incoming chat messages from server
# This would be called from your _process function that processes incoming messages
func _handle_chat_message(packet):
	print("HANDLING MESSAGE")
	if packet.has("username") and packet.has("message"):
		# Emit the signal for any listeners
		emit_signal("chat_message_received", packet.username, packet.message)

func set_username(username:String = Settings.username):
	var packet = {
		"type": "set_username",
		"payload": Settings.username.replace("\"", "")
	}
	NetworkManager.socket.send_text(JSON.stringify(packet))
