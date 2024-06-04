extends Node
class_name State

signal change

func enter(entity, _args):
	pass
func exit(entity):
	pass ;
func manipulate(entity, _args):
	pass ;
func update(entity, _delta):
	pass ;
func update_tick(entity, _delta):
	# Server Tick, Clients do not care
	if not multiplayer.is_server():
		return ;
	pass ;
