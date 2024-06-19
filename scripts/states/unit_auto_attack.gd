extends State
class_name player_auto_attack

var windup_timer: Timer
var cooldown_timer: Timer
func enter(entity, _args = null):
	# Set the target
	
	# Configure Timers
	windup_timer = entity.get_node("Timers/AAWindup")
	cooldown_timer = entity.get_node("Timers/AACooldown")
	# Subscribe to timer timeout


func update(entity, delta):
	# Client only
	if entity.global_position != entity.server_position:
		entity.global_position = entity.server_position
		entity.global_position = entity.global_position.lerp(entity.server_position, delta * entity.move_speed)
	pass;

func update_tick_server(entity, delta):
	if not entity.target_entity: 
		entity.change_state("Idle")
		return
	if entity.target_entity.health <= 0: 
		entity.change_state("Idle")
		return
	if entity.distance_to(entity.target_entity) <= entity.attack_range:
		init_attack()
		return
	entity.nav_agent.target_position = entity.target_entity.global_position
	entity.move_on_path(delta)

func init_attack():
	pass
