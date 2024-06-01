# Set up network and determine if Client or Server
extends Control

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
@onready var status_text = $ConnectionUI/StatusText
@onready var attempts_text = $ConnectionUI/AttemptsText
@onready var reconnect_button = $ConnectionUI/ReconnectButton
@onready var exit_button = $ConnectionUI/ExitButton
@onready var host_button = $ConnectionUI/HostButton
# Retry
var max_attempts = 3
var attempts = 0
var timeout = 3
# Server Vars
var Players: Array = [];
func _ready():
	# UI
	_set_status("STARTUP:STATUS_CONNECTING")
	host_button.hide()
	reconnect_button.hide()
	exit_button.hide()
	# Parse Args
	parse_args()
	# Start Relevant Process
	if args.has("-s") or DisplayServer.get_name() == "headless":
		call_deferred("start", Start.SERVER)
	elif args.has("-i"):
		call_deferred("start", Start.INTEGRATED)
	else:
		call_deferred("start", Start.CLIENT)

func start(method: int):
	var peer = ENetMultiplayerPeer.new()
	# Integrated
	if method == Start.INTEGRATED:
		host_button.show()
		method = Start.CLIENT
	# Client Side
	if method == Start.CLIENT:
		if not setup_client(peer):
			if not $CheckupTimer.is_stopped():
				_set_status("STARTUP:STATUS_CONNECTING")
			else:
				client_fail()
		else:
			client_success()
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
	_update_attempts()
	print("Attempting connection to:" + address + ":" + str(port))
	
	peer.create_client(address, port)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		return false
	elif peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTING:
		_set_status("STARTUP:STATUS_CONNECTING")
		multiplayer.multiplayer_peer = peer
		$CheckupTimer.wait_time = 1
		$CheckupTimer.start()
		return false
	return true

func client_success():
	print("Connected!")
	$ConnectionUI.hide()

func client_fail():
	_set_status("STARTUP:STATUS_CLIENT_FAILED")
	multiplayer.multiplayer_peer.close()
	attempts += 1
	_update_attempts()
	if attempts <= max_attempts:
		$ReconnectTimer.wait_time = timeout
		$ReconnectTimer.start()
	else:
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
	$ConnectionUI.hide()
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
		change_map(load("res://maps/" + server_map + ".tscn"), Players)

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
		# Give the user random data
		var peer_id = multiplayer.get_remote_sender_id()
		user = {
			'id': '0', # Local user, no user in DB
			'peer_id': peer_id,
			'name': "Player",
			'champ': "archer",
			'team': 0
		}
	else:
		# Fetch from the api server
		user = await fetch_user(token)
	Players.append(user);

func fetch_user(token: String):
	var headers
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
func change_map(scene: PackedScene, Players):
	var map = $Map
	print(map)
	# Clean out everything
	for child in map.get_children():
		map.remove_child(child)
		child.queue_free()
	var new_map = scene.instantiate()
	new_map.add_to_group("Map")
	new_map.get_node("ServerListener").connected_players = Players
	map.add_child(new_map)

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
func _on_reconnect_timer_timeout():
	$ReconnectTimer.stop()
	start(Start.CLIENT)

func _on_reconnect_button_pressed():
	start(Start.CLIENT)

func _on_exit_button_pressed():
	get_tree().quit()

func _on_host_pressed():
	start(Start.SERVER)
	$ReconnectTimer.stop()

func _on_checkup_timer_timeout():
	# Is Connected?
	print("A")
	$CheckupTimer.stop()
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		print("D")
		client_success()
	elif multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("C")
		client_fail()
	elif multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTING:
		print("B")
		$CheckupTimer.wait_time = 1
		$CheckupTimer.start()

# Setters
func _set_status(message: String):
	status_text.text = "[center]" + tr(message) + "[/center]"

func _update_attempts():
	attempts_text.text = "[center]" + tr("STARTUP:ATTEMPTS") % attempts + "[/center]"
