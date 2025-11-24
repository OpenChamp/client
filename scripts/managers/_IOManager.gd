## RELIES ON ECS SYSTEM
class_name InputOutputManager
extends Node

var game_root : Node = null
var nav_

func move_champion(to: Vector3):
	var packet := PackedByteArray([0,0,0,0,0,0,0,0])
	packet.encode_float(0, to.x)
	packet.encode_float(4, to.z)
	NetworkManager.send_packet(GameNetworkManager.PACKET_TYPE.PLAYER_MOVE, packet)
	pass;

func _find_champion_node(id) -> Node3D:
	var entities_node = game_root.get_node_or_null("Entities")
	if entities_node:
		var champ = entities_node.get_node_or_null(str(id))
		if champ:
			return champ
	return null

func _notify_user(message: String):
	# Placeholder for user notification (UI popup, log, etc.)
	print("[IOManager] ", message)
