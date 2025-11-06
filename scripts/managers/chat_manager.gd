# === Chat Manager === #
#----------------------#
# To use as global, remove from the ChatWidget scene
# To use as instance, use like normal

class_name ChatManager
extends Node
var ws : WebSocketPeer

# === Signals === #
signal connecting
signal connected
signal disconnected

signal chat_message_received(username, message)
signal server_error(payload: Dictionary)

signal packet_sent
signal packet_received

signal error(message: String)

var last_state := WebSocketPeer.STATE_CLOSED

var chat_container : RichTextLabel 

# Could be easily moved to a settings file
enum CHANNELS { GLOBAL_CHAT, PARTY_CHAT, PRIVATE_CHAT, MATCH_CHAT }

const CHAT_COLORS = {
	CHANNELS.GLOBAL_CHAT: "#FF6666",
	CHANNELS.PARTY_CHAT: "#99CCFF",
	CHANNELS.PRIVATE_CHAT: "#CC99FF",
	CHANNELS.MATCH_CHAT: "#66FF99"
}

func _ready():
	set_process(false)
	print("Chat Manager Loaded")

# === Setup Functions === #
func connect_to_ws(websocket_url: String):
	ws = WebSocketPeer.new()
	var err = ws.connect_to_url(websocket_url)
	if err != OK:
		print("Failed to connect to WebSocket: ", err)
		emit_signal("disconnected")
		return
	set_process(true)
	emit_signal("connecting")

## Sets an existing WebSocketPeer instance. Call only if you manage the socket externally.
func set_socket(socket: WebSocketPeer):
	ws = socket
	last_state = socket.get_ready_state()
	if last_state == WebSocketPeer.STATE_OPEN:
		emit_signal("connected")

func _process(_delta):
	ws.poll()
	var state = ws.get_ready_state()
	if state != last_state:
		match state:
			WebSocketPeer.STATE_OPEN:
				emit_signal("connected")
			WebSocketPeer.STATE_CLOSED:
				emit_signal("disconnected")
				set_process(false)
		last_state = state
	if state == WebSocketPeer.STATE_OPEN:
		while ws.get_available_packet_count():
			var data = ws.get_packet().get_string_from_utf8()
			var json = JSON.parse_string(data)
			process_packet(json)

func process_packet(packet: Dictionary):
	match packet["type"]:
		"global_chat", "party_chat", "private_chat", "match_chat":
			_handle_chat_message(packet["payload"], CHAT_COLORS[packet["type"]])
		"error":
			emit_signal("server_error", packet["payload"])
		_:
			print("Unknown packet: ", JSON.stringify(packet))

# === Chat Functions === #

func send_chat_message(chat_type: CHANNELS, message: String, target: String = "") -> bool:
	if ws == null or ws.get_ready_state() != WebSocketPeer.STATE_OPEN: return false
	var chat_packet := {"type": chat_type, "payload": null}
	match chat_type:
		CHANNELS.GLOBAL_CHAT:
			chat_packet.payload = message
		CHANNELS.MATCH_CHAT:
			chat_packet.payload = message
		CHANNELS.PRIVATE_CHAT, CHANNELS.PARTY_CHAT:
			if target.is_empty():
				emit_signal("error", "send_chat_message: no target provided for %s" % chat_type)
				return false
			chat_packet.payload = {"target": target, "message": message}
		_:
			emit_signal("error", "send_chat_message: unknown chat type: %s" % chat_type)
			return false
	ws.send_text(JSON.stringify(chat_packet))
	packet_sent.emit()
	return true

## Handles incoming chat messages and emits the chat_message_received signal.
func _handle_chat_message(payload: Dictionary, color:String):
	packet_received.emit(payload)
	if payload.has("username") and payload.has("message"):
		emit_signal("chat_message_received", payload.username, payload.message)
		var message: String = str("[color=",color, "]",payload.username, "[/color]", payload.message, "\n")
		chat_container.append_text(message)
