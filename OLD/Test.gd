extends Node3D

@export var ADDR:String
@export var PORT:int

var DEFAULT_SERVER_IP = "127.0.0.1"

var players = {}

var player_info = {
	"name": "Name",
	"agent": "Agent",
}

var players_loaded = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	pass # Replace with function body.

func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_connected(peer_id, player_info)


func _on_connected_fail():
	multiplayer.multiplayer_peer = null


func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	players.clear()
	#server_disconnected.emit()


func _on_button_pressed():
	player_info.name = $Control/Input_Username.text
	player_info.agent = $Control/OptionButton.get_item_text($Control/OptionButton.selected)
	if player_info.name.length() < 1:
		return
	if player_info.agent.length() < 1:
		return
	print(player_info)
	join_game()

	
	
func join_game(address = ""):
	if address.is_empty():
		address = DEFAULT_SERVER_IP
	if !PORT:
		PORT = 10000
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, PORT)
	if error:
		print(error)
		return error
	multiplayer.multiplayer_peer = peer
	print("Connected!")
	
func player_connected(id, info):
	$Control/RichTextLabel.text += info.name + " Has connected"
