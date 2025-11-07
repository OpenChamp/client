extends Node
#
#signal player_connected(id)
#signal player_disconnected(id)
#
## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
#
#func _start_gameserver():
	## Connect Signals
	#multiplayer.peer_connected.connect(_on_player_connected)
	#multiplayer.peer_disconnected.connect(_on_player_disconnected)
	#multiplayer.connected_to_server.connect(_on_connected_to_server)
	#multiplayer.connection_failed.connect(_on_connection_failed)
	## Initial Config
	#Util.players[1] = PlayerObject.new("Server", true)
	## Start Server
	#var peer = ENetMultiplayerPeer.new()
	#var error = peer.create_server(Util.port, Util.max_players)
	#if error != OK:
		#print("Failed to create server on port ", Util.port)
		#get_tree().create_timer(1).timeout.connect(get_tree().quit)
	#multiplayer.multiplayer_peer = peer
	#print("Server Created, Waiting on for players...")
	#
#func _on_player_connected(id):
	#if not multiplayer.is_server():
		#return
	#print("Player connected with ID: %d" % id)
	#if Util.players.has(id):
		#Util.players[id].connected = true
	#elif Util.players.size() < Util.max_players + 1:
		#Util.players[id] = PlayerObject.new("Player", true)
		#rpc_id(id, "request_client_token")
	#emit_signal("player_connected", id)
#
#
#func _on_player_disconnected(id):
	#print("Player disconnected with ID: %d" % id)
	#emit_signal("player_disconnected", id)
#
#
#func _on_connected_to_server():
	#pass
#
#
#func _on_connection_failed():
	#pass
#
#@rpc("any_peer")
#func execute_move_command(pos):
	#if not multiplayer.is_server():
		#return
	#var id = multiplayer.get_remote_sender_id()
	#var player_node
	#if Util.players[id].has("nodepath"):
		#player_node = Util.players[id]["nodepath"]
	#if player_node:
		#player_node.set_move_target(pos)
	#else:
		#print("No player node found for move command")


#@rpc("any_peer")
#func request_client_username():
	#rpc_id(1, "receive_client_username", Util.username)
#
#
#@rpc("any_peer")
#func receive_client_username(new_name):
	#var id = multiplayer.get_remote_sender_id()
	#Util.players[id]["name"] = new_name
#
#
#@rpc("authority")
#func request_client_token():
	#rpc_id(1, "receive_client_token", Util.get_token())
#
#
#@rpc("any_peer")
#func receive_client_token(client_token):
	#Util.players[multiplayer.get_remote_sender_id()].token = client_token
#
#
#func send_move_command(pos):
	#pos.y = 0
	#rpc_id(1, "execute_move_command", pos)
