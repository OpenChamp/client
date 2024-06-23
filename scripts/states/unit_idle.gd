extends State
class_name unit_idle


func update_tick_client(entity: Unit, delta):
	super(entity, delta)
	entity.global_position = entity.server_position
