extends State
class_name player_move

func enter(entity, args=null):
	pass

func exit(entity):
	pass;

func update(entity, delta):
	super(entity, delta);
	# Client only
	if entity.global_position != entity.server_position:
		var lrp = delta * 8
		var lerp = entity.global_position.lerp(entity.server_position, lrp)
		entity.global_position = lerp
	pass;

func update_tick_server(entity, delta):
	# Server Only
	super(entity, delta);
	var current_location = entity.global_position
	entity.server_position = entity.global_position;
	var target_location = entity.nav_agent.get_next_path_position()
	# Check if target is looking at target
	
	if current_location.distance_to(target_location) <= .1:
		return
	var direction = target_location - current_location
	entity.velocity = direction.normalized() * entity.move_speed * delta
	entity.rotation.y = lerp_angle(entity.rotation.y, atan2(-direction.x, -direction.z), entity.turn_speed * delta)
	entity.move_and_slide()
	pass;
	
func modify(entity, args):
	# Update Target Position
	if args is Vector3:
		entity.nav_agent.target_position = args
