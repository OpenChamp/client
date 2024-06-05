extends State
class_name player_auto_attack

var target
var target_pos
var cast_timer:Timer
var cooldown_timer:Timer
var backup_entity
var is_in_range = false;
func enter(entity, target_entity=null):
	# Set the target
	target = target_entity
	backup_entity = entity
	# Configure Timers
	cast_timer = entity.get_node("Timers/Windup")
	cooldown_timer = entity.get_node("Timers/AACooldown")
	cast_timer.one_shot = true;
	cooldown_timer.one_shot = true;
	# Subscribe to timer timeout
	cast_timer.timeout.connect(finish_attack)
	# Subscribe to enter and exit 
	entity.range_collider.body_entered.connect(_on_body_entered)
	entity.range_collider.body_exited.connect(_on_body_exited)
	search_radius();
	pass

func exit(entity):
	entity.range_collider.body_entered.disconnect(entity, "_on_body_entered")
	entity.range_collider.body_exited.disconnect(entity, "_on_body_exited")
	pass;

func update(entity, delta):
	# Client only
	if entity.global_position != entity.server_position:
		entity.global_position = entity.server_position
		entity.global_position = entity.global_position.lerp(entity.server_position, delta * entity.move_speed)
	pass;

func update_tick(entity, delta):
	if is_in_range:
		if cast_timer.is_stopped() && cooldown_timer.is_stopped():
			print("Fire!");
			try_attack()
		else:
			print("Casting: " + str(cast_timer.is_stopped()))
			print(cooldown_timer.is_stopped())
	else:
		entity.nav_agent.target_position = target.global_position
	var current_location = entity.global_position
	var target_location = entity.nav_agent.get_next_path_position()
	# Check if target is looking at target
	
	if current_location.distance_to(target_location) <= .1:
		return
	var direction = target_location - current_location
	entity.velocity = direction.normalized() * entity.move_speed * delta
	entity.rotation.y = lerp_angle(entity.rotation.y, atan2(-direction.x, -direction.z), entity.turn_speed * delta)
	entity.move_and_slide()
	entity.server_position = entity.global_position;
	pass;
	
func modify(entity, new_target):
	# Update Target Position
	if new_target is CharacterBody3D || new_target is StaticBody3D:
		target = new_target

func _on_body_entered(body):
	if body == target:
		is_in_range = true;
	

	pass

func _on_body_exited(body):
	if body == target:
		is_in_range = false;
		cast_timer.stop()
	
	pass

func init_attack():
	# Start the cast timer
	cast_timer.set_wait_time(backup_entity.attack_windup)
	cast_timer.start()
	pass

func finish_attack():
	cooldown_timer.wait_time = backup_entity.attack_speed / 100;
	cooldown_timer.start();
	var projectile = backup_entity.projectile_scene.instantiate()
	projectile.global_position = backup_entity.global_position + Vector3.UP
	projectile.target = target
	backup_entity.get_node("Projectiles").add_child(projectile, true)

func try_attack():
	# Check if target is still in range
	if target == null:
		get_parent().change_state("Move");
		return
	if backup_entity.global_position.distance_to(target.global_position) > backup_entity.attack_range:
		return
	# Check if target is still alive
	if target.health <= 0:
		return
	# Attack the target
	init_attack()
	pass
	
func search_radius():
	var bodies = backup_entity.range_collider.get_overlapping_bodies()
	for body in bodies:
		if body == target:
			print(body);
			print(target);
			is_in_range = true;
