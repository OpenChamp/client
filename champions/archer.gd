extends Champion
class_name TheArcher

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
	})
