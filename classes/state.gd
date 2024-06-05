extends Node
class_name State

signal change

func enter(entity):
	pass
func exit(entity):
	pass;
func update(entity, _delta):
	pass;
func update_tick(entity, _delta):
	# Server Tick, Clients do not care
	if not multiplayer.is_server():
		return;
	pass;
