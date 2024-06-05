extends Node
class_name State

signal change

func enter(entity, args=null):
	pass
func exit(entity):
	pass;
func update(entity, _delta):
	# Client Tick, Server does not care
	if multiplayer.is_server():
		return;
	pass;
func update_tick(entity, _delta):
	# Server Tick, Clients do not care
	if not multiplayer.is_server():
		return;
	pass;
