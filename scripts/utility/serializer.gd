class_name Serializer
extends Node

func serialize_entity(entity):
	pass;
	
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
	
	
	
func deserialize_entity_packet(packet: PackedByteArray) -> Dictionary: # Creation handled by EntityManager -- cmkrist 24/11/25
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

func deserialize_stat_packet(packet:PackedByteArray) -> Dictionary:
	# Type (1) + Entity ID (4) + Key Length (4) + Key + Value Length (4) + Value
	print("=== STAT PACKET DEBUG ===")
	print("Packet size: %d bytes" % packet.size())
	print("Packet hex: %s" % packet.hex_encode())
	print("Packet bytes: ", packet)
	
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
	print("Stat name offset %d, length %d: '%s'" % [offset, name_length, stat_name])
	offset += name_length
	var value_length = packet.decode_u32(offset)
	print("Value length offset %d: %d (0x%08X)" % [offset, value_length, value_length])
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
	
	print("Stat value offset %d, length %d: '%s'" % [offset, value_length, stat_value])
	print("======================")
	
	return {
		"id": entity_id,
		"name": stat_name,
		"value": stat_value
	}
