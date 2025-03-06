extends "res://addons/delta_rollback/NetworkAdaptor.gd"

var my_peer_id: int

func _init(_my_peer_id: int = 1) -> void:
	my_peer_id = _my_peer_id

func send_ping(peer_id: int, msg: Dictionary) -> void:
	pass

func send_ping_back(peer_id: int, msg: Dictionary) -> void:
	pass

func send_remote_start(peer_id: int) -> void:
	pass

func send_remote_stop(peer_id: int) -> void:
	pass

func send_input_tick(peer_id: int, msg: PackedByteArray) -> void:
	pass

func is_network_host() -> bool:
	return my_peer_id == 1

func is_network_master_for_node(node: Node) -> bool:
	return node.get_network_master() == my_peer_id

func get_network_unique_id() -> int:
	return my_peer_id
