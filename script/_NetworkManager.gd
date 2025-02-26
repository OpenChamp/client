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

func _ready():
	set_process(false)
	print("Global Script Loaded")
	load_settings()
	pass
	
func _process(_delta):
	socket.poll()

	# get_ready_state() tells you what state the socket is in.
	var state = socket.get_ready_state()

	# WebSocketPeer.STATE_OPEN means the socket is connected and ready
	# to send and receive data.
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			var data = socket.get_packet().get_string_from_utf8()
			var json = JSON.parse_string(data)
			print("Got data from server: ", json)
			processPacket(json)
	
	if state == WebSocketPeer.STATE_CONNECTING:
		print("WebSocket connecting...")
		pass
	# WebSocketPeer.STATE_CLOSING means the socket is closing.
	# It is important to keep polling for a clean close.
	elif state == WebSocketPeer.STATE_CLOSING:
		print("WebSocket closing...")
		pass

	# WebSocketPeer.STATE_CLOSED means the connection has fully closed.
	# It is now safe to stop polling.
	elif state == WebSocketPeer.STATE_CLOSED:
		# The code will be -1 if the disconnection was not properly notified by the remote peer.
		var code = socket.get_close_code()
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		set_process(false) # Stop processing.
# Setup
func connect_to_server():
	var err = socket.connect_to_url(Settings.websocket_url)
	if err != OK:
		print("Unable to connect")
		return false
	else:
		set_process(true)
		return true
		
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
		
