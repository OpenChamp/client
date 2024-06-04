extends State
class_name obj_scan

var range_collider:Area3D
var priorities = {
	"minion": 3,
	"champion": 1
}
var team
func enter(entity, _args):
	range_collider = entity.get_node("AttackArea");
	team = entity.team
	range_collider.body_entered.connect(check_entity)
	pass

func exit(entity):
	range_collider.body_entered.disconnect(check_entity)
	pass;

func update(entity, _delta):
	pass;

func update_tick(entity, _delta):
	super(entity, _delta);
	pass;
	
func check_entity(hostile):
	if not hostile is Unit :
		return;
	if hostile.team == team:
		return;
	change.emit("obj_attack");
