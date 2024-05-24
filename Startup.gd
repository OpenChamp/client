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
# Retry
var max_attempts = 3
var attempts = 0
var timeout = 3
 
func _ready():
	# UI
	_set_status("Connecting...")
	$Panel/ReconnectButton.hide()
	$Panel/ExitButton.hide()
	# Parse Args
	var args = Array(OS.get_cmdline_args())
	ParseArgs(args)
	# Start Relevant Process
	if args.has("-s") || DisplayServer.get_name() == "headless":
		call_deferred("Start", START.SERVER)
	else:
		call_deferred("Start", START.CLIENT)

func ParseArgs(args:Array):
	for i in args.size():
		if(args[i].begins_with("-")):
			# Process as command
			if(args[i] == "-S"):
				address = args[i] + 1
			if(args[i] == "-P"):
				port = args[i] + 1

# Client Peer Connection
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
	get_tree().change_scene_to_file("res://Client/Client.tscn")

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
		$Panel/ReconnectButton.show()
		$Panel/ExitButton.show()
		
# Server Peer Connection
func SetupServer(peer:ENetMultiplayerPeer):
	_set_status("Creating Server...")
	
	peer.create_server(port, 10)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("Server failed to start")
		return false;
	return true

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
			OS.alert("Server failed to start")
			get_tree().quit()
			return
		else:
			multiplayer.multiplayer_peer = peer
			print("Server Started, beginning initialization")
			get_tree().change_scene_to_file("res://Server/Server.tscn")
			return;
			

		
func _set_status(message:String):
	var text = "[center]" + message + "[/center]"
	$Panel/StatusText.text = text;
	
func _update_attempts():
	$Panel/AttemptsText.text = "[center]Attempts: " + str(attempts) + "[/center]";
	
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
