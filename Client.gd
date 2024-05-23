extends Control

@export var CountDown = 30
# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().paused = true
	var args = Array(OS.get_cmdline_args())
	if args.has("-s") || DisplayServer.get_name() == "headless":
		call_deferred("StartServer")
	else: 
		call_deferred("StartClient")

func ChangeMap(scene: PackedScene):
	var map = $Map
	# Clean out everything
	for child in map.get_children():
		map.remove_child(child)
		child.queue_free()
	map.add_child(scene.instantiate())

func StartClient():
	print("Starting Client")
	var peer = ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", 10000)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client.")
		return
		
	print(peer.get_connection_status())
	multiplayer.multiplayer_peer = peer
	StartGame()

func StartGame():
	print("Starting Game")
	$ConnectionUI.hide()
	get_tree().paused = false;
	if multiplayer.is_server():
		ChangeMap.call_deferred(load("res://Maps/DebugMap.tscn"))
		
func StartServer():
	print("Starting Server")
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(10000, 10)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to Start Server.")
		return
	multiplayer.multiplayer_peer = peer
	StartGame()


