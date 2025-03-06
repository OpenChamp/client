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
			print("Got data from server: ", json)
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
		socket.send_text("{\"type\": \"set_username\", \"payload\": \"" + Settings.username + "\"}")
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
	print("Processing packet: ", packet)
	match packet["type"]:
		"player_count":
			Store.PlayerCount = int(packet["payload"])
		"queued":
			Store.InQueue = true
		"user_assigned":
			Store.Username = packet["payload"]
		_:
			print("Unknown packet: ", JSON.stringify(packet))
		
