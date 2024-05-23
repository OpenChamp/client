extends Control

@export var CountDown = 30
# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().paused = true
	var args = Array(OS.get_cmdline_args())
	if args.has("-s") || DisplayServer.get_name() == "headless":
		call_deferred("StartServer")
	else:
		if args.has("-i"):
			call_deferred("StartIntegrated")
		else:
			call_deferred("StartClient")

func ChangeMap(scene: PackedScene):
	var map = $Map
	# Clean out everything
	for child in map.get_children():
		map.remove_child(child)
		child.queue_free()
	map.add_child(scene.instantiate())

func PrepareClient(peer):
	print("Preparing Client")
	
	peer.create_client("127.0.0.1", 10000)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client.")
		return
		
	print(peer.get_connection_status())

func PrepareServer(peer):
	print("Preparing Server")
	peer.create_server(10000, 10)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to Start Server.")
		return

func StartClient():
	var peer = ENetMultiplayerPeer.new()
	PrepareClient(peer)
	StartGame(peer)

func StartServer():
	var peer = ENetMultiplayerPeer.new()
	PrepareServer(peer)
	StartGame(peer)
	
func StartIntegrated():
	var peer = ENetMultiplayerPeer.new()
	PrepareServer(peer)
	PrepareClient(peer)
	StartGame(peer)

func StartGame(peer):
	print("Starting Game")
	multiplayer.multiplayer_peer = peer
	$ConnectionUI.hide()
	get_tree().paused = false;
	if multiplayer.is_server():
		ChangeMap.call_deferred(load("res://Maps/DebugMap.tscn"))
		
