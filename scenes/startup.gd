extends Node
# This script is explicitly used for setting up the network connection between the client and the server

enum Start {
	SERVER,
	CLIENT,
	INTEGRATED,
}

@onready var args = Array(OS.get_cmdline_args())
# Network
@onready var api_server = "https://api.open-champ.com"
@onready var address = "127.0.0.1"
@onready var port = 10000
@onready var max_players = 2
@onready var tickrate = 30
@onready var server_map = "bridge"
var jwt: String
# UI
@onready var status_text = $ConnectionUI/Background/ConnectionStatus
@onready var reconnect_button = $ConnectionUI/Background/ReconnectButton
@onready var exit_button = $ConnectionUI/Background/ExitButton
@onready var host_button = $ConnectionUI/Background/HostButton
# Server Vars
var Players: Array = [];
# Used for when the API fails
var isTeamOne = true;

func _ready():
	# UI
	_set_status("STARTUP:STATUS_CONNECTING")
	# Parse Args
	parse_args()
	# Start Relevant Process
	if args.has("-s") or DisplayServer.get_name() == "headless":
		call_deferred("start", Start.SERVER)
	else:
		$ConnectionUI.show();
		# Setup button signals
		host_button.button_down.connect(host_click)
		if args.has("-i"):
			call_deferred("start", Start.INTEGRATED)
		else:
			call_deferred("start", Start.CLIENT)

func start(method: int):
	var peer = ENetMultiplayerPeer.new()
	host_button.hide()
	reconnect_button.hide()
	exit_button.hide()
	# Integrated
	if method == Start.INTEGRATED:
		host_button.show()
		method = Start.CLIENT
	# Client Side
	if method == Start.CLIENT:
		setup_client(peer)
	# Server Side
	elif method == Start.SERVER:
		if not setup_server(peer):
			server_fail()
		else:
			multiplayer.multiplayer_peer = peer
			server_success()
			return

# Client Connection Functionality
func setup_client(peer: ENetMultiplayerPeer):
	_set_status("STARTUP:STATUS_CONNECT_CLIENT")
	print("Attempting connection to:" + address + ":" + str(port))
	
	peer.create_client(address, port)
	multiplayer.multiplayer_peer = peer;
	_set_status("STARTUP:STATUS_CONNECTING")
	var timer = Timer.new()
	timer.name="CheckConnectionTimer"
	timer.wait_time = 1
	timer.autostart = true;
	timer.timeout.connect(check_client_connection)
	add_child(timer)

func check_client_connection():
	var timer = get_node("CheckConnectionTimer");
	timer.stop();
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTING:
		timer.start()
		return;
	timer.timeout.disconnect(check_client_connection)
	timer.queue_free()
	
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		client_fail();
	elif multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		client_success();
	return;

func client_success():
	_set_status("Ready!")

func client_fail():
	_set_status("STARTUP:STATUS_CLIENT_FAILED")
	multiplayer.multiplayer_peer.close()
	_set_status("Could not connect to server")
	reconnect_button.show()
	exit_button.show()

# Server Connection Functionality
func setup_server(peer: ENetMultiplayerPeer):
	_set_status("STARTUP:STATUS_CREATE_SERVER")
	
	# Hook up signals
	peer.connect("peer_connected", server_add_player)
	peer.connect("peer_disconnected", server_remove_player)
	var err = peer.create_server(port, max_players)
	if err != Error.OK:
		print("Server failed to start")
		return false
	return true

func server_success():
	print("Server Started, beginning initialization")
	# Set FPS to 30
	Engine.set_max_fps(30);
	# Set Timer to wait until all players are connected
	var WaitTimer = Timer.new()
	WaitTimer.name = "WaitTimer"
	WaitTimer.wait_time = 1
	WaitTimer.autostart = true
	WaitTimer.timeout.connect(server_update)
	add_child(WaitTimer)

func server_update():
	var timer = get_node("WaitTimer")
	# Check how many players are connected
	var connected_players = multiplayer.get_peers().size()
	print(str(connected_players) + "/" + str(max_players) + " Connected")
	if connected_players != max_players:
		print("Still Waiting...")
		timer.start();
	else:
		print("Ready!")
		# Clean up our timer
		timer.stop()
		timer.timeout.disconnect(server_update)
		timer.queue_free()
		# prevent new users from joining
		multiplayer.multiplayer_peer.refuse_new_connections = true
		# disconnect the signals
		multiplayer.multiplayer_peer.disconnect("peer_connected", server_add_player)
		multiplayer.multiplayer_peer.disconnect("peer_disconnected", server_remove_player)
		#Change Map
		print(Players)
		change_map(load("res://scenes/maps/" + server_map + ".tscn"), Players)

func server_add_player(id: int):
	print("Player connected: " + str(id))
	# ask for jwt
	rpc_id.call_deferred(id, "get_jwt")
	
func server_remove_player(id: int):
	print("Player disconnected: " + str(id))
	# Remove from Players
	for i in range(Players.size()):
		if Players[i].peer_id == id:
			Players.remove_at(i)
			break
	pass ;
	
# JWTs
@rpc("authority", "call_local")
func get_jwt():
	if jwt != null:
		rpc ("set_jwt", jwt)
	else:
		rpc ("set_jwt", "")

@rpc("any_peer", "call_local")
func set_jwt(token: String):
	var user = {};
	if token == "":
		var team = 1
		if !isTeamOne:
			team = 2
		isTeamOne = !isTeamOne
		# Give the user random data
		var peer_id = multiplayer.get_remote_sender_id()
		user = {
			'id': '0', # Local user, no user in DB
			'peer_id': peer_id,
			'name': "Player",
			'champ': "archer",
			'team': team
		}
	else:
		# Fetch from the api server
		user = await fetch_user(token)
	Players.append(user);

func fetch_user(token: String):
	var headers = {}
	headers["Authorization"] = "Bearer " + token
	var response = HTTPRequest.new()
	response.request("GET", api_server + "/user", headers)
	while response.get_status() == 0:
		await response.request_completed
	if response.get_status() == 200:
		return response.get_response_body_as_string()
	else:
		return null

func server_fail():
	OS.alert("Server failed to start")
	get_tree().quit()

# Custom Functions
func change_map(scene: PackedScene, players):
	var map = $Map
	# Clean out everything
	for child in map.get_children():
		map.remove_child(child)
		child.queue_free()
	var new_map = scene.instantiate()
	new_map.add_to_group("Map")
	new_map.connected_players = players
	map.add_child(new_map)
	rpc("map_loaded")

func parse_args():
	for i in args.size():
		if args[i].begins_with("-"):
			# Process as command
			# Server
			if args[i] == "-S":
				address = args[i + 1]
			# Port
			if args[i] == "-P":
				port = args[i + 1]
			# Map
			if args[i] == "-M":
				server_map = args[i + 1]
			# Tickrate
			if args[i] == "-T":
				Engine.physics_ticks_per_second = args[i + 1]
			# Players (Max)
			if args[i] == "-PL":
				max_players = args[i + 1]
				pass
			# token
			if args[i] == "-t":
				jwt = args[i + 1]

# Event Listeners
func host_click():
	client_fail();
	start(Start.SERVER)
	
func reconnect_click():
	start(Start.CLIENT)

func exit_click():
	get_tree().quit()

# Setters
func _set_status(message: String):
	status_text.text = "[center]" + tr(message) + "[/center]"

@rpc("authority")
func map_loaded():
	$ConnectionUI.hide();
