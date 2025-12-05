class_name Serializer
extends Node
	
func deserialize_combat_packet(packet:PackedByteArray) -> Dictionary:
	# type (1) + attacker_id (4) + target_id (4) + damage (4) + damage_type (1) + was_critical (1)
	var offset = 1
	var attacker_id = packet.decode_u32(offset)
	offset += 4
	var target_id = packet.decode_u32(offset)
	offset += 4
	var damage = packet.decode_float(offset)
	offset += 4
	var damage_type = packet.decode_u8(offset)
	offset += 1
	var was_critical = bool(packet.decode_u8(offset))
	return {
		"attacker_id": attacker_id,
		"target_id": target_id,
		"damage" : damage,
		"type": damage_type,
		"crit": was_critical
	}

func deserialize_entity_packet(packet: PackedByteArray) -> Dictionary:
	# (1) Type
	# (4) EntityID
	# (4) Float PosX
	# (4) Float PosY
	# (1) u8int Team
	# (4) u32 template_id length
	# (-) template_id (char[])
	var size = packet.decode_u32(14)
	var template_id = packet.slice(18, 18 + size).get_string_from_utf8()
	var data: = {
		"id": packet.decode_u32(1), # 4
		"pos": Vector2(packet.decode_float(5), packet.decode_float(9)),
		"team": packet.decode_u8(13),
		"template_id": template_id
	}
	return data;

func deserialize_map_packet(packet:PackedByteArray) -> String:
	if packet.size() < 3:
		push_error("MAP_LOAD packet too short: expected at least 3 bytes, got %d" % packet.size())
		return ""
	var name_length = packet[1] << 8 | packet[2]
	if packet.size() < 3 + name_length:
		push_error("MAP_LOAD packet truncated: expected %d bytes, got %d" % [3 + name_length, packet.size()])
		return ""
	var map_name = ""
	for i in range(3, 3 + name_length):
		map_name += char(packet[i])
	return map_name

func deserialize_position_packet(packet:PackedByteArray) -> Dictionary:
	# Type (1) + Entity ID (4) + Float PosX (4) + Float PosY (4)
	if packet.size() < 9:
		push_error("ENTITY_POSITION packet too short: expected 9 bytes, got %d" % packet.size())
		return {}
	var offset = 1
	var entity_id = packet.decode_u32(offset)
	offset += 4
	var pos_x = packet.decode_float(offset)
	offset += 4
	var pos_y = packet.decode_float(offset)
	return {
		"id": entity_id,
		"position": Vector2(pos_x, pos_y)
	}

func deserialize_stat_packet(packet:PackedByteArray) -> Dictionary:
	# Type (1) + Entity ID (4) + Key Length (4) + Key + Value Length (4) + Value
	var offset = 1
	var entity_id = packet.decode_u32(offset)
	print("Entity ID offset %d: %d" % [offset, entity_id])
	offset += 4
	var name_length = packet.decode_u32(offset)
	print("Name length offset %d: %d (0x%08X)" % [offset, name_length, name_length])
	offset += 4
	
	# Sanity check: name_length should be reasonable (< 100 chars)
	if name_length > 100 or name_length == 0:
		print("ERROR: Deserialize stat packet - invalid name_length: %d" % name_length)
		print("Packet size: %d, offset: %d" % [packet.size(), offset])
		print("Next bytes (hex): ", packet.slice(offset, min(offset + 16, packet.size())).hex_encode())
		return {}
	
	var stat_name = ""
	for i in range(offset, offset + name_length):
		stat_name += char(packet[i])
	offset += name_length
	var value_length = packet.decode_u32(offset)
	offset += 4
	
	# Sanity check: value_length should be reasonable (< 1000 chars)
	if value_length > 1000 or value_length == 0:
		print("ERROR: Deserialize stat packet - invalid value_length: %d" % value_length)
		print("Stat name: '%s', packet size: %d, offset: %d" % [stat_name, packet.size(), offset])
		print("Next bytes (hex): ", packet.slice(offset, min(offset + 16, packet.size())).hex_encode())
		return {}
	
	var stat_value = ""
	for i in range(offset, offset + value_length):
		stat_value += char(packet[i])
	
	return {
		"id": entity_id,
		"name": stat_name,
		"value": stat_value
	}

func deserialize_state_packet(packet:PackedByteArray) -> Dictionary:
	# Type (1) + Entity ID (4) + State (1)
	if packet.size() < 6:
		push_error("ENTITY_STATE packet too short: expected 6 bytes, got %d" % packet.size())
		return {}
	var offset = 1
	var entity_id = packet.decode_u32(offset)
	offset += 4
	var state = packet.decode_u8(offset)
	return {
		"id": entity_id,
		"state": state
	}