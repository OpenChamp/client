extends State
class_name player_idle


func update_tick_client(entity, delta):
	super(entity, delta)
	entity.global_position = entity.server_position
