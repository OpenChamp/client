extends State
class_name player_idle

func enter(entity, args=null):
	super(entity);
	# Client only
	if entity.global_position != entity.server_position:
		var lerp = entity.global_position.lerp(entity.server_position, 1)
		entity.global_position = lerp

func exit(entity):
	pass;

func update(entity, delta):
	pass;

func update_tick(entity, delta):
	pass;
	
func modify(entity, args):
	pass
