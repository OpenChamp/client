class_name GameNetworkManager
extends Node

signal player_connected(id)
signal player_disconnected(id)

signal connected_to_server
signal connection_failed
signal game_start
signal disconnected_from_server

var game_root:Node
const default_port = 7000
var packets : Array = [];
# ======================================================= #
# === Updated from packet_validator.hpp in GameServer === # 
# ===      Last Updated: 18/11/2025 - CMKRIST         === #
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
	# Player related packets
	PLAYER_READY,
	PLAYER_DISCONNECT,
	# Player Actions
	PLAYER_MOVE
};

const ENTITY_SCENES = {
	"champion" : preload("res://scenes/champs/ranger.tscn"),
	"melee_minion" : preload("res://scenes/entities/minions/minion_entity_melee.tscn"),
	"ranged_minion" : preload("res://scenes/entities/minions/minion_entity_ranged.tscn"),
	"magic_minion" : preload("res://scenes/entities/minions/minion_entity_mage.tscn"),
	"cannon_minion" : preload("res://scenes/entities/minions/minion_entity_cannon.tscn"),
}

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
	disconnected_from_server.emit()
	pass;

	
func _start():
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
		_:
			push_error(packet)

func handle_entity_spawn_packet(packet:PackedByteArray):
	# (1) Type
	# (4) EntityID
	# (4) Float PosX
	# (4) Float PosY
	# (1) u8int Team
	# (4) u32 template_id length
	# (-) template_id (char[])
	var offset = 1
	var entity_id = packet.decode_u32(offset)
	offset += 4
	var pos_x = packet.decode_float(offset)
	offset += 4
	var pos_y = packet.decode_float(offset)
	offset += 4
	var entity_pos = Vector3(pos_x, 1, pos_y)
	var entity_team = packet.decode_u8(offset)
	offset += 1
	var size = packet.decode_u32(offset)
	offset += 4
	var template_id = packet.slice(offset, offset + size).get_string_from_utf8()
	var entity : Entity = ENTITY_SCENES[template_id].instantiate()
	var entity_template = EntityTemplates.get_entity_template(template_id)
	var components = entity_template.get("_children")
	if not components:
		push_warning("Entity: ", entity.name , " Template: ", template_id, " Error: Failed to initialize XML Components")
		return
	for key in components:
		match key:
			"stats":
				print(components["stats"]);
				for stat_name in components["stats"]:
					if entity[stat_name]:
						# Typecast everything to string for consistency -- cmkrist 19/11/2025
						var value : String = str(components["stats"][stat_name])
						entity.set_stat(stat_name, value)
			_:
				print(key, components[key])
		pass;
	
	entity.name = str(entity_id)
	game_root.get_node("Entities").add_child(entity)
	entity.global_position = entity_pos
	print("Spawned entity %d (%s) at (%.1f, %.1f)" % [entity_id, template_id, pos_x, pos_y])
	
func handle_entity_stats_packet(packet:PackedByteArray):
	# Type (1 byte) + Entity ID (4) + Name Length (4) + Name + Value Length (4) + Value
	var offset = 1
	var entity_id = packet.decode_u32(offset)
	offset += 4
	var name_length = packet.decode_u32(offset)
	offset += 4
	var stat_name = ""
	for i in range(offset, offset + name_length):
		stat_name += char(packet[i])
	offset += name_length
	var value_length = packet.decode_u32(offset)
	offset += 4
	var stat_value = ""
	for i in range(offset, offset + value_length):
		stat_value += char(packet[i])
	# Verify Existence
	var entity_node = game_root.get_node_or_null("Entities/%d" % entity_id)
	if entity_node == null:
		push_error("Entity with ID %d not found!" % entity_id)
		return;
	# Update Stat
	if not entity_node.has_method("set_stat"):
		push_error("Entity with ID %d has no set_stat method!" % entity_id)
		return;
	entity_node.set_stat(stat_name, stat_value)
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
