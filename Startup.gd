# Set up network and determine if Client or Server
extends Control
enum START {
	SERVER, 
	CLIENT,
	INTEGRATED
}

@onready var args = Array(OS.get_cmdline_args())
# Network
@onready var address = "127.0.0.1"
@onready var port = 10000

@onready var StatusText = $ConnectionUI/StatusText
@onready var AttemptsText = $ConnectionUI/AttemptsText

@onready var ReconnectButton = $ConnectionUI/ReconnectButton
@onready var ExitButton = $ConnectionUI/ExitButton
@onready var HostButton = $ConnectionUI/HostButton
# Retry
var max_attempts = 3
var attempts = 0
var timeout = 3

# Godot Default Listeners
func _ready():
	# UI
	_set_status("Connecting...")
	ReconnectButton.hide()
	ExitButton.hide()
	# Parse Args
	var args = Array(OS.get_cmdline_args())
	ParseArgs(args)
	# Start Relevant Process
	if args.has("-s") || DisplayServer.get_name() == "headless":
		call_deferred("Start", START.SERVER)
	else:
		call_deferred("Start", START.CLIENT)

# Client Connection Functionality
func SetupClient(peer:ENetMultiplayerPeer):
	_set_status("Connecting as Client...")
	_update_attempts()
	print("Attempting connection to:" + address + ":" + str(port))
	
	peer.create_client(address, port)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		return false
	elif peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTING:
		_set_status("Connecting...");
		multiplayer.multiplayer_peer = peer
		$CheckupTimer.wait_time = 1
		$CheckupTimer.start()
		return false
	return true

func ClientSuccess():
	print("Connected!");
	$ConnectionUI.hide()

func ClientFail():
	_set_status("Failed To Connect...")
	multiplayer.multiplayer_peer.close()
	attempts +=1
	_update_attempts()
	if attempts <= max_attempts:
		$ReconnectTimer.wait_time = timeout
		$ReconnectTimer.start()
	else:
		_set_status("Could not connect to server")
		ReconnectButton.show()
		ExitButton.show()

# Server Connection Functionality
func SetupServer(peer:ENetMultiplayerPeer):
	_set_status("Creating Server...")
	
	peer.create_server(port, 10)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("Server failed to start")
		return false;
	return true

func ServerFail():
	OS.alert("Server failed to start")
	get_tree().quit()

func ServerSuccess():
	print("Server Started, beginning initialization")
	$ConnectionUI.hide()
	ChangeMap(load("res://Maps/DebugMap.tscn"))

# Custom Functions
func Start(method:int):
	var peer = ENetMultiplayerPeer.new()
	# Client Side
	if method == START.CLIENT:
		if not SetupClient(peer):
			if !$CheckupTimer.is_stopped():
				_set_status("Connecting...")
			else:
				ClientFail()
		else:
			ClientSuccess()
	# Server Side
	elif method == START.SERVER:
		if not SetupServer(peer):
			ServerFail()
		else:
			multiplayer.multiplayer_peer = peer
			ServerSuccess()
			return;

func ChangeMap(scene: PackedScene):
	var map = $Map
	print(map)
	# Clean out everything
	for child in map.get_children():
		map.remove_child(child)
		child.queue_free()
	map.add_child(scene.instantiate())

func ParseArgs(args:Array):
	for i in args.size():
		if(args[i].begins_with("-")):
			# Process as command
			if(args[i] == "-S"):
				address = args[i] + 1
			if(args[i] == "-P"):
				port = args[i] + 1

# Event Listeners
func _on_reconnect_timer_timeout():
	$ReconnectTimer.stop()
	Start(START.CLIENT)

func _on_reconnect_button_pressed():
	Start(START.CLIENT)

func _on_exit_button_pressed():
	get_tree().quit()

func _on_host_pressed():
	Start(START.SERVER)
	$ReconnectTimer.stop()

func _on_checkup_timer_timeout():
	# Is Connected?
	print("A")
	$CheckupTimer.stop()
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		print("D")
		ClientSuccess()
	elif multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("C")
		ClientFail()
	elif multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTING:
		print("B")
		$CheckupTimer.wait_time = 1
		$CheckupTimer.start()
	pass # Replace with function body.

# Setters
func _set_status(message:String):
	var text = "[center]" + message + "[/center]"
	StatusText.text = text;
	
func _update_attempts():
	AttemptsText.text = "[center]Attempts: " + str(attempts) + "[/center]";
	
