class_name GameNetworkManager
extends Node

signal player_connected(id)
signal player_disconnected(id)

signal connected_to_server
signal connection_failed
signal disconnected_from_server

const default_port = 7000
# === Updated from packet_validator.hpp in GameServer === #
enum PACKET_TYPE {
	PLAYER_READY,
	GAME_START,
	GAME_STATE,
	SPAWN_MAP,
	SPAWN_ENTITY,
	PLAYER_DISCONNECT,
	HEARTBEAT_PING,
	HEARTBEAT_PONG,
	MINION_STATE,
};

var connection: ENetConnection
var peer: ENetPacketPeer

func _process(_delta:float) -> void:
	if connection == null: return
	check_connection()
	handle_packets()

func check_connection():
	if peer == null: return
	print(peer.get_statistic(ENetPacketPeer.PeerStatistic.PEER_LAST_ROUND_TRIP_TIME))

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
