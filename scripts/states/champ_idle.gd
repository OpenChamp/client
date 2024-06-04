extends State
class_name _champ_idle

func enter(entity, args):
	pass

func exit(entity):
	pass;

func update(entity, _delta):
	entity._update_healthbar(entity.healthbar);
	pass;

func update_tick(entity, _delta):
	super(entity, _delta);
	pass;
