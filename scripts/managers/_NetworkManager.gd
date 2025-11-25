class_name GameNetworkManager
extends Node

signal player_connected(id)
signal player_disconnected(id)

signal connected_to_server
signal connection_failed
signal game_start
signal disconnected_from_server

var game_root:Node

var config = {
	"host": "",
	"port": 0,
	"default_port": 7000
}
var packets : Array = [];
# ======================================================= #
# === Updated from packet_validator.hpp in GameServer === # 
# ===      Last Updated: 24/11/2025 - CMKRIST         === #
# ======================================================= #
enum PACKET_TYPE {
	# Engine reserved packet types
	GAME_START,
	GAME_STATE,
	GAME_TIME,
	LOBBY_FULL,
	MAP_SPAWN,
	MAP_LOAD,
	# Spawn packets
	ENTITY_SPAWN,
	# Update packets
	ENTITY_POSITION,
	ENTITY_STATS,
	ENTITY_STATE,
	# Combat packets
	COMBAT_EVENT,
	# Player related packets
	PLAYER_READY,
	PLAYER_DISCONNECT,
	# Player Actions
	PLAYER_MOVE
};

var connection: ENetConnection
var peer: ENetPacketPeer

@onready var serializer:Serializer = Serializer.new()
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
	disconnected_from_server.emit()
	pass;

	
func _start():
	if config.host.is_empty():
		push_error("No host specified, unable to connect");
		get_tree().quit(1);
	if config.port == 0:
		push_warning("No port specified, defaulting to ", config.default_port)
		config.port = config.default_port
	# Connect Signals
	multiplayer.peer_packet.connect(process_packet)
	# Start Client
	connection = ENetConnection.new()
	var err : Error = connection.create_host(1)
	if err:
		print("Client failed to start connection")
		get_tree().quit()
	peer = connection.connect_to_host(config.host, config.port)
	print("Client Created, Connecting to server at %s:%d..." % [config.host, config.port])


func _stop():
	multiplayer.multiplayer_peer = null
	print("Network stopped")

func process_packet(packet:PackedByteArray):
	packets.append(packet)
	match packet[0]:
		PACKET_TYPE.GAME_START:
			game_start.emit()
			UIManager.change_interface("Ingame")
			var player_controller = load("res://scenes/ui/game_controller.tscn").instantiate()
			get_tree().current_scene.add_child(player_controller)
			player_controller.rotate_y(deg_to_rad(-90))
		PACKET_TYPE.MAP_LOAD:
			# Next 2 bytes are the length of the map name (Big-endian)
			var name_length = packet[1] << 8 | packet[2]
			var map_name = ""
			for i in range(3, 3 + name_length):
				map_name += char(packet[i])
			print("Spawning map: %s" % map_name)
			# Here you would call your map spawning logic
			var map = load("res://scenes/maps/%s.tscn" % map_name).instantiate()
			get_tree().current_scene.add_child(map)
			send_ready()
		PACKET_TYPE.ENTITY_SPAWN:
			handle_entity_spawn_packet(packet)
		PACKET_TYPE.ENTITY_STATS:
			handle_entity_stats_packet(packet)
		PACKET_TYPE.ENTITY_POSITION:
			handle_entity_position_packet(packet)
		PACKET_TYPE.ENTITY_STATE:
			handle_entity_state_packet(packet)
		PACKET_TYPE.COMBAT_EVENT:
			EntityManager.handle_combat(serializer.deserialize_combat_packet(packet))
		_:
			push_error(packet)

func handle_entity_spawn_packet(packet:PackedByteArray):
	var entity_data: Dictionary = serializer.deserialize_entity_packet(packet)
	EntityManager.create_entity(entity_data)
	
func handle_entity_state_packet(packet:PackedByteArray):
	# Type (1) + Entity ID (4) + State (1)
	EntityManager.state_change(packet.decode_u32(1), packet.decode_u8(5))
	pass
	
func handle_entity_stats_packet(packet:PackedByteArray):
	var stat = serializer.deserialize_stat_packet(packet)
	print("Received stat update: Entity %d, Stat '%s' = '%s'" % [stat.id, stat.name, stat.value])
	EntityManager.update_entity_stat(stat)
	# First byte is packet type

func handle_entity_position_packet(packet:PackedByteArray):
	# First byte is packet type
	# Next 4 bytes are entity id (little-endian)
	# Next 4 bytes are x coord (little-endian)
	# Next 4 bytes are Z coord (little-endian)
	var offset = 1
	var entity_id = packet.decode_u32(offset)
	offset += 4
	var pos_x = packet.decode_float(offset)
	offset += 4
	var pos_y = packet.decode_float(offset)
	# Verify Existence
	var entity_node = game_root.get_node_or_null("Entities/%d" % entity_id)
	if entity_node == null:
		push_error("Entity with ID %d not found!" % entity_id)
		return;
	# Update Position
	entity_node.server_position = Vector3(pos_x, entity_node.global_position.y, pos_y)

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
