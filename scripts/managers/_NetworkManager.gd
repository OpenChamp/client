class_name GameNetworkManager
extends Node

signal player_connected(id)
signal player_disconnected(id)

signal connected_to_server
signal connection_failed
signal disconnected_from_server

var game_root:Node
const default_port = 7000
# === Updated from packet_validator.hpp in GameServer === #
enum PACKET_TYPE {
	PLAYER_READY,
	GAME_START,
	GAME_STATE,
	SPAWN_MAP,
	SPAWN_ENTITY,
	PLAYER_DISCONNECT,
	MINION_STATE
};

var connection: ENetConnection
var peer: ENetPacketPeer

func _process(_delta:float) -> void:
	if connection == null: return
	handle_packets()

func handle_packets():
	var packet_event = connection.service()
	var event_type = packet_event[0]
	
	while event_type != ENetConnection.EVENT_NONE:
		var peer = packet_event[1]
		
		match event_type:
			ENetConnection.EVENT_ERROR:
				push_warning("Packet Error")
				return
			ENetConnection.EVENT_CONNECT:
				on_connection_established()
			ENetConnection.EVENT_DISCONNECT:
				on_disconnect()
			ENetConnection.EVENT_RECEIVE:
				var packet_data : PackedByteArray = peer.get_packet()
				process_packet(packet_data)
		
		packet_event = connection.service()
		event_type = packet_event[0]
				

func on_connection_established():
	print("Connection Established");
	pass;

func on_disconnect():
	print("Disconnected from server");
	pass;

	
func _start():
	#_start_gameserver(ConfigManager.get_game_setting("network", "port"), ConfigManager.get_game_setting("game", "max_players"))
	_start_client(ConfigManager.get_game_setting("network", "server_ip"), ConfigManager.get_game_setting("network", "port"))

func _stop():
	multiplayer.multiplayer_peer = null
	print("Network stopped")

func _start_client(server_ip, port):
	if port == null:
		port = default_port
	# Connect Signals
	multiplayer.peer_packet.connect(process_packet)
	# Start Client
	connection = ENetConnection.new()
	var err : Error = connection.create_host(1)
	if err:
		print("Client failed to start connection")
		get_tree().quit()
	peer = connection.connect_to_host(server_ip, port)
	print("Client Created, Connecting to server at %s:%d..." % [server_ip, port])

func process_packet(packet:PackedByteArray):
	print(packet)
	match packet[0]:
		PACKET_TYPE.SPAWN_MAP:
			# Next 4 bytes are the length of the map name (little-endian)
			var name_length = packet[1] | packet[2] << 8 | packet[3] << 16 | packet[4] << 24
			var map_name = ""
			for i in range(5, 5 + name_length):
				map_name += char(packet[i])
			print("Spawning map: %s" % map_name)
			# Here you would call your map spawning logic
			var map = load("res://scenes/maps/%s.tscn" % map_name).instantiate()
			var player_controller = load("res://scenes/ui/game_controller.tscn").instantiate()
			UIManager.change_interface("InGame")
			get_tree().current_scene.add_child(map)
			get_tree().current_scene.add_child(player_controller)
			player_controller.rotate_y(deg_to_rad(-90))
			send_ready()
		PACKET_TYPE.MINION_STATE:
			handle_minion_packet(packet)

func handle_minion_packet(packet:PackedByteArray):
	# First byte is packet type
	# Next 4 bytes are number of minions (little-endian)
	# 21 bytes per minion:
	#   4 bytes: minion ID (little-endian)
	#   4 bytes: position x (float)
	#   4 bytes: position y (float)
	#   4 bytes: position z (float)
	#   4 bytes: health (float)
	#   1 byte: minion_state
	var num_minions = packet[1] | packet[2] << 8 | packet[3] << 16 | packet[4] << 24
	var offset = 5
	var minion_nodes = game_root.get_node("Entities/Minions").get_children()
	var alive_ids:Array = []
	for i in range(num_minions):
		var minion_id = packet[offset] | packet[offset + 1] << 8 | packet[offset + 2] << 16 | packet[offset + 3] << 24
		var pos_x = packet.decode_float(offset + 4)
		var pos_y = packet.decode_float(offset + 8)
		var pos_z = packet.decode_float(offset + 12)
		var health = packet.decode_float(offset + 16)
		var minion_state = packet[offset + 20]
		# Does minion already exist?
		var minion_node = game_root.get_node_or_null("Entities/Minions/%d" % minion_id)
		if minion_node == null:
			# Create new minion
			var minion_scene = load("res://scenes/entities/minions/minion_entity_mage.tscn")
			minion_node = minion_scene.instantiate()
			minion_node.name = str(minion_id)
			game_root.get_node("Entities/Minions").add_child(minion_node)
		# Update minion state
		alive_ids.push_back(minion_id)
		minion_node.global_position = Vector3(pos_z, pos_y, pos_x) # TODO: Will use Vect2 
		minion_node.health = health
		minion_node.minion_state = minion_state
		offset += 21
	
	for node in minion_nodes:
		var node_id = int(node.name)
		if not alive_ids.has(node_id):
			node.die()

func send_ready():
	var data = PackedByteArray()
	data.append(1) # 1 byte to indicate ready
	send_packet(PACKET_TYPE.PLAYER_READY, data);

func send_packet(type: PACKET_TYPE, data: PackedByteArray, reliable: bool = true):
	if peer == null:
		return
	var reliable_int = int(reliable)
	var packet = PackedByteArray()
	packet.append(type)
	for byte in data:
		packet.append(byte)
	if not reliable:
		reliable_int = 2 # ENetPacketPeer.FLAG_UNSEQUENCED
	peer.send(1, packet, reliable_int)
