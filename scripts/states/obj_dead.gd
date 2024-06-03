extends State
class_name obj_dead


func enter(entity):
	entity.is_dead = true;
	$"../../MeshInstance3D/Crystal".hide();
	$"../../MeshInstance3D/CrystalExplode".explode();
	pass

func exit(entity):
	pass;

func update(entity, _delta):
	pass;

func update_tick(entity, _delta):
	super(entity, _delta);
	pass;
