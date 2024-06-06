extends Champion
class_name Dummy 

func _ready():
	setup({
		'health': 640,
		'mana': 280,
		'health_regen': 3.5,
		'mana_regen': 7,
		'magic_resist': 30,
		'critical_chance': 15,
		'critical_damage': 100,
		'attack_damage': 59,
		'attack_windup': 21, 
		'attack_range': 300,
		'move_speed': 210
	})
	healthbar.size = Vector2(100, 15)
	global_position = server_position
	
func _process(delta):
	pass;

func _physics_process(delta: float):
	pass;

func die():
	super()
	var server_listener = $"../../ServerListener"
	server_listener.rpc_id(multiplayer.get_unique_id(), "respawn", self)
