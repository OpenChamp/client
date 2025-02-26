extends Node

var Settings = {
	"max_players": 0,
	"port": 10330,
	"map": "res://level/bridge.tscn",
}

var connected_clients = []

func _ready():
	for argument in OS.get_cmdline_args():
		if argument.begins_with("--port="):
			Settings.port = int(argument.replace("--port=", ""))
		elif argument.begins_with("--max_players="):
			Settings.max_players = int(argument.replace("--max_players=", ""))

	# var server = NetworkedMultiplayerENet.new()
	# server.create_server(Settings.port, Settings.max_players)
	# get_tree().network_peer = server
	
func _process(_delta: float) -> void:
	pass;
