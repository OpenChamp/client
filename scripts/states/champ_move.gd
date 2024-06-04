extends State
class_name champ_idle

func enter(entity, loc=Vector3(0, 0, 0)):
	entity.nav_agent.target_position = loc
	pass

func exit(entity):
	entity.nav_agent.target_position = entity.position;
	pass ;

func manipulate(entity, loc=Vector3(0, 0, 0)):
	entity.nav_agent.target_position = loc
	pass ;

func update(entity, delta):
	entity._update_healthbar(entity.healthbar);
	var current_location = entity.global_transform.origin
	var target_location = entity.server_pos
	# Check if target is looking at target
	if current_location.distance_to(target_location) <= .1:
		return
	var direction = target_location - current_location
	entity.velocity = direction.normalized() * entity.speed * delta
	entity.rotation.y = lerp_angle(entity.rotation.y, atan2( - direction.x, -direction.z), entity.turn_speed * delta)
	entity.move_and_slide()
	pass ;

func update_tick(entity, _delta):
	super(entity, _delta);
	entity.server_pos = entity.nav_agent.get_next_path_position();
	pass ;
