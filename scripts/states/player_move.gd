extends State
class_name player_move

func enter(entity):
	pass

func exit(entity):
	pass;

func update(entity, _delta):
	pass;

func update_tick(entity, _delta):
	super(entity, _delta);
	pass;
	
func process_input():
	if Input.is_action_pressed("player_ability1"):
		get_parent().change_state("player_ability", 1)
		pass;
	elif Input.is_action_pressed("player_ability2"):
		get_parent().change_state("player_ability", 2)
		pass;
	elif Input.is_action_pressed("player_ability3"):
		get_parent().change_state("player_ability", 3)
		pass;
	elif Input.is_action_pressed("player_ability4"):
		get_parent().change_state("player_ability", )
		pass;
