extends State
class_name obj_attack

var range_collider: Area3D
var max_range: float
var priorities = {
	"Minion": 3,
	"Champion": 1
}
var target_entity: CharacterBody3D = null;
var ticks_per_attack: int = 20;
var ticks_since_attack: int = 0;

func enter(entity):
	range_collider = entity.get_node("AttackArea");
	max_range = range_collider.get_node("CollisionShape3D").shape.radius
	set_target(entity)
	pass

func exit(entity):
	pass ;

func update(entity, _delta):
	pass ;

func update_tick(entity, _delta):
	super(entity, _delta);
	# Only Attack Characterbodies
	if ticks_since_attack <= 0:
		try_attack(entity, target_entity)
	ticks_since_attack -= 1

func set_target(entity):
	var bodies = range_collider.get_overlapping_bodies()
	var highest_priority = 0;
	for body in bodies:
		if body is CharacterBody3D and body.team != entity.team:
			if priorities[body.get_groups()[0]]:
				if priorities[body.get_groups()[0]] > highest_priority:
					target_entity = body;
					target_entity.free
	if !target_entity:
		change.emit("obj_scan");
	else:
		# Subscribe to their death
		# target_entity.unit_died.connect(set_target(entity))
		return ;

func try_attack(entity, target):
	# Check if target is still in range
	if target.global_position.distance_to(range_collider.global_position) <= max_range:
		# Attack
		var shot = entity.projectile.instantiate()
		shot.position = entity.position
		shot.target = target
		if !shot.target.is_in_group("Champion"):
			shot.damage = entity.attack_damage/10  # Reduced damage to non-champs
		else:
			shot.damage = entity.attack_damage
		entity.get_node("Projectiles").add_child(shot, true)
		ticks_since_attack = ticks_per_attack
	else:
		set_target(entity)
