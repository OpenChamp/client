extends State
class_name unit_move

func enter(entity: Unit, args=null):
	pass


func exit(entity: Unit):
	pass


func update(entity: Unit, delta):
	super(entity, delta);
	# Client only
	if entity.global_position != entity.server_position:
		var lrp = delta * 8
		var lerp = entity.global_position.lerp(entity.server_position, lrp)
		entity.global_position = lerp


func update_tick_server(entity: Unit, delta):
	# Server Only
	super(entity, delta);
	entity.move_on_path(delta)


func modify(entity: Unit, args):
	# Update Target Position
	if args is Vector3:
		entity.nav_agent.target_position = args
