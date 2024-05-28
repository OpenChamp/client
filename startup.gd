# Set up network and determine if Client or Server
extends Control
enum Start {
	SERVER, 
	CLIENT,
	INTEGRATED,
}

@onready var args = Array(OS.get_cmdline_args())
# Network
@onready var address = "127.0.0.1"
@onready var port = 10000

@onready var status_text = $ConnectionUI/StatusText
@onready var attempts_text = $ConnectionUI/AttemptsText

@onready var reconnect_button = $ConnectionUI/ReconnectButton
@onready var exit_button = $ConnectionUI/ExitButton
@onready var host_button = $ConnectionUI/HostButton
# Retry
var max_attempts = 3
var attempts = 0
var timeout = 3


# Godot Default Listeners
func _ready():
	# UI
	_set_status("STARTUP:STATUS_CONNECTING")
	reconnect_button.hide()
	exit_button.hide()
	# Parse Args
	parse_args()
	# Start Relevant Process
	if args.has("-s") or DisplayServer.get_name() == "headless":
		call_deferred("start", Start.SERVER)
	else:
		call_deferred("start", Start.CLIENT)


# Client Connection Functionality
func setup_client(peer:ENetMultiplayerPeer):
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
	attempts +=1
	_update_attempts()
	if attempts <= max_attempts:
		$ReconnectTimer.wait_time = timeout
		$ReconnectTimer.start()
	else:
		_set_status("Could not connect to server")
		reconnect_button.show()
		exit_button.show()


# Server Connection Functionality
func setup_server(peer:ENetMultiplayerPeer):
	_set_status("STARTUP:STATUS_CREATE_SERVER")
	
	peer.create_server(port, 10)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("Server failed to start")
		return false
	return true


func server_fail():
	OS.alert("Server failed to start")
	get_tree().quit()


func server_success():
	print("Server Started, beginning initialization")
	$ConnectionUI.hide()
	change_map(load("res://maps/debug_map.tscn"))


# Custom Functions
func start(method: int):
	var peer = ENetMultiplayerPeer.new()
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


func change_map(scene: PackedScene):
	var map = $Map
	print(map)
	# Clean out everything
	for child in map.get_children():
		map.remove_child(child)
		child.queue_free()
	map.add_child(scene.instantiate())


func parse_args():
	for i in args.size():
		if args[i].begins_with("-"):
			# Process as command
			if args[i] == "-S":
				address = args[i] + 1
			if args[i] == "-P":
				port = args[i] + 1


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
func _set_status(message:String):
	status_text.text = "[center]" + tr(message) + "[/center]"


func _update_attempts():
	attempts_text.text = "[center]" + (tr("STARTUP:ATTEMPTS") % attempts) + "[/center]"
