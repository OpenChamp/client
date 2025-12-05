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
	if connection == null:
		return
	handle_packets()
	
func conn():
	if config.host.is_empty():
		push_error("No host specified, unable to connect");
		get_tree().quit(1);
	if config.port == 0:
		push_warning("No port specified, defaulting to ", config.default_port)
		config.port = config.default_port
	# Connect Signals
	var signals_conn := multiplayer.peer_connected.get_connections()
	var setup = false
	for sig in signals_conn:
		if sig.callable == process_packet:
			setup = true;
	if not setup:
		multiplayer.peer_packet.connect(process_packet)
		multiplayer.peer_connected.connect(peer_connected)
		multiplayer.peer_disconnected.connect(peer_disconnected)
	# Start Client
	connection = ENetConnection.new()
	var err : Error = connection.create_host(1)
	if err:
		print("Client failed to start connection")
		connection_failed.emit()
		return
	peer = connection.connect_to_host(config.host, config.port)
	print("Client Created, Connecting to server at %s:%d..." % [config.host, config.port])
	
func _conn():
	print("Connection Established");
	connected_to_server.emit();

func disc():
	if connection != null:
		connection.destroy()
		peer = null
		connection = null
		disconnected_from_server.emit()
	
func peer_connected(id:int):
	print("Player Connected: ", id);
	player_connected.emit(id);
	pass
	
func peer_disconnected(id:int):
	print("Player Disconnected: ", id)
	player_disconnected.emit(id);
	pass
	
func handle_packets():
	var packet_event = connection.service()
	var event_type = packet_event[0]
	while (event_type != ENetConnection.EVENT_NONE) and (connection != null):
		var event_peer = packet_event[1]
		match event_type:
			ENetConnection.EVENT_ERROR:
				push_error("ENet Packet Error occurred")
				disc()
			ENetConnection.EVENT_CONNECT:
				_conn()
			ENetConnection.EVENT_DISCONNECT:
				push_warning("Server disconnected us")
				disc()
			ENetConnection.EVENT_RECEIVE:
				var packet_data : PackedByteArray = event_peer.get_packet()
				if not process_packet(packet_data):
					push_error("Packet processing failed")
					print(packet_data)
		if connection:
			packet_event = connection.service()
			event_type = packet_event[0]

func process_packet(packet:PackedByteArray) -> bool:
	if packet.size() == 0:
		push_error("Empty packet received")
		return false
	packets.append(packet)
	
	var packet_type = packet[0]
	print("Processing packet type: %d, size: %d bytes" % [packet_type, packet.size()])
	
	match packet_type:
		PACKET_TYPE.GAME_START:
			# Trigger: All players have sent ready packets (After Map Load)
			GameManager.start_game()
		PACKET_TYPE.MAP_LOAD:
			# Trigger: Connected to the Server, First Packet Received (usually)
			var err = GameManager.load_map(serializer.deserialize_map_packet(packet))
			if err != OK:
				push_error("Failed to load map from MAP_LOAD packet")
				return false
			send_ready()
		PACKET_TYPE.ENTITY_SPAWN:
			var entity = serializer.deserialize_entity_packet(packet)
			GameManager.spawn_entity(entity)
		PACKET_TYPE.ENTITY_STATS:
			var stat = serializer.deserialize_stat_packet(packet)
			EntityManager.update_entity_stat(stat)
		PACKET_TYPE.ENTITY_POSITION:
			var pos = serializer.deserialize_position_packet(packet)
			EntityManager.update_entity_pos(pos)
		PACKET_TYPE.ENTITY_STATE:
			var state = serializer.deserialize_state_packet(packet);
			EntityManager.update_entity_state(state);
		PACKET_TYPE.COMBAT_EVENT:
			var log = serializer.deserialize_combat_packet(packet);
			EntityManager.handle_combat(log)
		_:
			push_warning("Unknown packet type: %d, size: %d bytes" % [packet_type, packet.size()])
	
	return true

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
