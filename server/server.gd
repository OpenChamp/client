extends Node

var Settings = {
	"max_players": 1, 
	"port": 10330, 
	"map": "res://level/rift.tscn", 
	"bots": false
}

var connected_clients = []

@export var player_scene: PackedScene

func _ready():
	for argument in OS.get_cmdline_args():
		if argument.begins_with("--port="):
			Settings.port = int(argument.replace("--port=", ""))
		elif argument.begins_with("--max_players="):
			Settings.max_players = int(argument.replace("--max_players=", ""))
		elif argument.begins_with("--map="):
			Settings.map = "res://level/"+argument.replace("--map=", "")+".tscn"
		elif argument.begins_with("--bots="):
			Settings.bots = bool(int(argument.replace("--bots=", "")))

	var peer = ENetMultiplayerPeer.new()
	peer.create_server(Settings.port, Settings.max_players)
	multiplayer.multiplayer_peer = peer

	# On connection
	multiplayer.peer_connected.connect(_on_peer_connected)
	# On disconnection
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	add_child(load("res://scene/game.tscn").instantiate())

func _process(_delta: float) -> void:
	pass;

func _on_peer_connected(id):
	print("Peer " + str(id) + " connected")
	add_player(id)
	connected_clients.append(id)
	
func _on_peer_disconnected(id):
	print("Peer " + str(id) + " disconnected")
	connected_clients.erase(id)

func add_player(id=1):
	var player = player_scene.instantiate()
	player.name = str(id)
	call_deferred("add_child", player)
