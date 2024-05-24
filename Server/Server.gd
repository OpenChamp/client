extends Node

@onready var peer = multiplayer.multiplayer_peer
# Called when the node enters the scene tree for the first time.
func _ready():
	if not multiplayer.is_server():
		OS.alert("Server Setup Failed...");
		get_tree().quit()
	
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	pass # Replace with function body.

func peer_connected(id):
	print("Connected: " + str(id));
func peer_disconnected(id):
	print("Disconnected: " + str(id));
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
