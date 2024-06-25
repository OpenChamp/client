extends Node

# This script is explicitly used for setting up the network connection between the client and the server

enum Start {
	SERVER,
	CLIENT,
	INTEGRATED,
}

const map_base_script := preload("res://classes/map.gd")

@onready var args := Array(OS.get_cmdline_args())

# Network
@onready var api_server := "https://api.open-champ.com"
@onready var address := "127.0.0.1"
@onready var port := 10000
@onready var max_players := 2
@onready var tickrate := 30
@onready var game_mode := "openchamp:onslaught"
@onready var server_map_id := Identifier.for_resource("map://openchamp:onslaught")
var jwt: String

# UI
@onready var status_text := $ConnectionUI/Background/ConnectionStatus
@onready var reconnect_button := $ConnectionUI/Background/ReconnectButton
@onready var exit_button := $ConnectionUI/Background/ExitButton
@onready var host_button := $ConnectionUI/Background/HostButton

# Server Vars
var Players: Array = []
var mode_manifest_data: Dictionary = {}
var server_map_config: Dictionary = {} 
var server_pid: int = 0

# Used for when the API fails
var last_team = 1
var team_count = 1


func _ready():
	_set_status("STARTUP:STATUS_CONNECTING")
	
	# Parse Args and launch the startup deferred
	var start_type = parse_args()
	call_deferred("start", start_type)

	$MapSpawner.spawn_function = map_spawn_function


func start(method: Start):
	var peer = ENetMultiplayerPeer.new()
	
	# Integrated
	if method == Start.INTEGRATED:
		host_button.button_down.connect(host_click)
		host_button.show()
	
	# Init client stuff when not starting dedicated server
	if method != Start.SERVER:
		$ConnectionUI.show()
		setup_client(peer)
		multiplayer.multiplayer_peer = peer
	
	# Start the server
	if method == Start.SERVER:
		if not setup_server(peer):
			server_fail()
			return
		
		multiplayer.multiplayer_peer = peer
		server_success()
	

# Client Connection Functionality
func setup_client(peer: ENetMultiplayerPeer):
	_set_status("STARTUP:STATUS_CONNECT_CLIENT")
	print("Attempting connection to:" + address + ":" + str(port))
	
	peer.create_client(address, port)
	_set_status("STARTUP:STATUS_CONNECTING")
	
	var timer = Timer.new()
	timer.name="CheckConnectionTimer"
	timer.wait_time = 1
	timer.autostart = true
	timer.timeout.connect(check_client_connection)
	
	add_child(timer)


func check_client_connection():
	var connection_status := multiplayer.multiplayer_peer.get_connection_status()
	if connection_status == MultiplayerPeer.CONNECTION_CONNECTING:
		return
	
	var timer = get_node("CheckConnectionTimer")
	timer.stop()
	timer.timeout.disconnect(check_client_connection)
	timer.queue_free()
	
	if connection_status == MultiplayerPeer.CONNECTION_CONNECTED:
		client_success()
	else:
		client_fail()


func client_success():
	_set_status("STARTUP:STATUS_CLIENT_CONNECTED")

	# Todo: get the correct game mode from the server
	var manifest_json = load("gamemode://" + game_mode)
	mode_manifest_data = manifest_json.data

	server_map_config = RegistryManager.load_manifest(
		mode_manifest_data,
		game_mode
	)

	#server_map_id = Identifier.for_resource("map://" + server_map_config["id"])

	# Add map to mapspawner
	#$MapSpawner.add_spawnable_scene(AssetIndexer.get_asset_path(server_map_id))


func client_fail():
	_set_status("STARTUP:STATUS_CLIENT_FAILED")
	multiplayer.multiplayer_peer.close()
	
	reconnect_button.show()
	exit_button.show()


# Server Connection Functionality
func setup_server(peer: ENetMultiplayerPeer):
	_set_status("STARTUP:STATUS_CREATE_SERVER")
	
	# Get the manifest data for the game mode
	var manifest_json = load("gamemode://" + game_mode)

	mode_manifest_data = manifest_json.data

	# Load the manifest data and get the map config
	server_map_config = RegistryManager.load_manifest(
		mode_manifest_data,
		game_mode
	)

	# load some of the config values
	#server_map_id = Identifier.for_resource("map://" + server_map_config["id"])
	#$MapSpawner.add_spawnable_scene(AssetIndexer.get_asset_path(server_map_id))

	max_players = server_map_config["max_players"]

	# Hook up signals
	peer.connect("peer_connected", server_add_player)
	peer.connect("peer_disconnected", server_remove_player)
	
	var err = peer.create_server(port, max_players)
	if err != Error.OK:
		if err == Error.ERR_ALREADY_IN_USE:
			print("already has a server part")
		else:
			print("Server failed to start")
			return false
	
	return true


func server_success():
	print("Server Started, beginning initialization")
	
	# Set FPS to 30
	Engine.set_max_fps(30)
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
	
	if connected_players == 0:
		print("No players connected")
		timer.start()
		return
	
	if server_map_config['require_all_players'] and connected_players != max_players:
		print("Still Waiting...")
		timer.start()
		return
	
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
	change_map(Players)


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


# JWTs
@rpc("authority", "call_local")
func get_jwt():
	if jwt == null:
		rpc("set_jwt", "")
	else:
		rpc("set_jwt", jwt)


@rpc("any_peer", "call_local")
func set_jwt(token: String):
	var user = {}
	
	if token == "":
		# Create a default user in case not token is given
		user = fetch_default_user()
	else:
		# Fetch from the api server
		user = await fetch_user(token)
	
	Players.append(user)


func fetch_user(token: String):
	var headers = {}
	var response = HTTPRequest.new()
	var message:String = api_server + "/user"
	
	headers["Authorization"] = "Bearer " + token
	response.request("GET", message.split(), headers)
	
	while response.get_status() == 0:
		await response.request_completed
	
	if response.get_status() == 200:
		return response.get_response_body_as_string()
	
	return null


func fetch_default_user():
	var user = {}
	
	var team = last_team + 1
	if team > team_count:
		team = 1

	last_team = team
	
	# Give the user random data
	var peer_id = multiplayer.get_remote_sender_id()
	user = {
		'id': '0', # Local user, no user in DB
		'peer_id': peer_id,
		'name': "Player",
		'champ': "archer",
		'team': team
	}
	
	return user


func server_fail():
	OS.alert("Server failed to start")
	get_tree().quit()


# Custom Functions
func change_map(players):
	var map = $Map
	
	# Clean out everything
	for child in map.get_children():
		map.remove_child(child)
		child.queue_free()

	server_map_config["players"] = players
	var new_map = $MapSpawner.spawn(server_map_config)
	
	map.add_child(new_map)

	rpc("map_loaded")


func map_spawn_function(data: Variant) -> Node:
	var map_id = Identifier.for_resource("map://" + data["id"])

	# Load the new map
	var scene = load(AssetIndexer.get_asset_path(map_id))
	var new_map = scene.instantiate()

	# Add the map script and load the config
	new_map.set_script(map_base_script)
	new_map.load_config(server_map_config)
	new_map.add_to_group("Map")
	new_map.connected_players = data["players"]
	
	return new_map


func parse_args() -> Start:
	var start_type = Start.CLIENT
	if DisplayServer.get_name() == "headless":
		start_type = Start.SERVER
	
	for i in args.size():
		match args[i]:
			"-S": # Server
				address = args[i + 1]
				i += 1
			"-P": # Port
				port = args[i + 1]
				i += 1
			"-M": # Gamemode
				game_mode = args[i + 1]
				i += 1
			"-T": # Tickrate
				Engine.physics_ticks_per_second = args[i + 1]
				i += 1
			"-PL": # Players (Max)
				max_players = args[i + 1]
				i += 1
			"-t": # token
				jwt = args[i + 1]
				i += 1
			"-s": # start as server
				start_type = Start.SERVER
			"-i": # start as integrated server
				start_type = Start.INTEGRATED
	
	return start_type


# Event Listeners
func host_click():
	server_pid = OS.create_process(
		OS.get_executable_path(),
		[OS.get_cmdline_args(), '-s']
	)

	host_button.hide()


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if server_pid != 0:
			OS.kill(server_pid)
		
		get_tree().quit()


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
