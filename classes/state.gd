extends Node
class_name State


signal change


func enter(entity, args=null):
	pass
	
	
func exit(entity):
	pass
	
	
func update(entity, _delta):
	# Client Tick, variable based on framerate
	if multiplayer.is_server(): return
	

func update_tick_client(entity, _delta):
	# Client tick, 60 Hz
	if multiplayer.is_server(): return


func update_tick_server(entity, _delta):
	# Server Tick, 60 Hz
	if not multiplayer.is_server(): return
