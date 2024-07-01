extends State
class_name unit_auto_attack

var windup_timer: Timer
var cooldown_timer: Timer
var this_entity: Unit


func enter(entity: Unit, _args = null):
	this_entity = entity
	# Configure Timers
	windup_timer = entity.get_node("Timers/AAWindup")
	cooldown_timer = entity.get_node("Timers/AACooldown")
	# Subscribe to timer timeout
	windup_timer.timeout.connect(do_attack)


func exit(entity: Unit):
	windup_timer.timeout.disconnect


func update(entity: Unit, delta):
	# Client only
	if entity.global_position != entity.server_position:
		entity.global_position = entity.server_position
		entity.global_position = entity.global_position.lerp(entity.server_position, delta * entity.current_stats.movement_speed)


func update_tick_server(entity: Unit, delta):
	if not entity.target_entity: 
		entity.change_state("Idle", null)
		return
	if entity.target_entity.health <= 0: 
		entity.change_state("Idle", null)
		return
	if entity.distance_to(entity.target_entity) <= entity.attack_range:
		start_windup()
		return
	entity.nav_agent.target_position = entity.target_entity.global_position
	entity.move_on_path(delta)


func start_windup():
	if not this_entity.can_attack(): return
	if not windup_timer.is_stopped(): return
	if not cooldown_timer.is_stopped(): return
	windup_timer.start()


func do_attack():
	if not this_entity.can_attack(): return
	cooldown_timer.start()
