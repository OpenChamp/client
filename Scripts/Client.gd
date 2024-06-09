extends Node

var server_ws = "ws://localhost:9999"
var socket = WebSocketPeer.new();
var gamesocket = WebSocketPeer.new()
var connecting = false;
var map_requested = false;
@export var DEBUG:bool = true;

# Called when the node enters the scene tree for the first time.
func _ready():
	# Attempt to connect to the Websocket
	socket.connect_to_url(server_ws)
	if DEBUG:
		$Play_Button.disabled = false;
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if(connecting):
		gamesocket.poll();
		var gs_state = gamesocket.get_ready_state()
		if gs_state == WebSocketPeer.STATE_OPEN:
			var count:int = gamesocket.get_available_packet_count();
			if count > 0:
				var packet = gamesocket.get_packet()
				var map = packet.get_string_from_ascii();
				load_game(map);
				
	socket.poll();
	var state = socket.get_ready_state();
	if state == WebSocketPeer.STATE_OPEN:
		$Connection_Status.text = "Connected"
		$Play_Button.disabled = false
		var count:int = socket.get_available_packet_count();
		if count > 0:
			var packet = socket.get_packet()
			var r = packet.get_string_from_ascii();
			if r == "queued":
				print("Waiting In Queue")
				$Play_Button.text = "Queued..."
			if r.contains("CON: "):
				$Play_Button.text = "Connecting To Server"
				var try_url = r.replace("CON: ", "");
				gamesocket.connect_to_url(try_url)
				connecting = true;
		
	elif state == WebSocketPeer.STATE_CLOSING || state == WebSocketPeer.STATE_CLOSED:
		$Connection_Status.text = "Disconnected"
	else:
		$Connection_Status.text = "Disconnected"
	pass


func load_game(mapName:String):
	# Load the map
	var map = load("res://Maps/" + mapName + ".tscn");
	var mapScene = map.instantiate()
	get_node("/root").add_child(mapScene)
	$".".visible = false;

func _on_play_button_pressed():
	socket.send_text("Play")
	if DEBUG:
		# Swap to the map
		load_game("DebugMap")
