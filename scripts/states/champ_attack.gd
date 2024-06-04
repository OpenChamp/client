extends State
class_name champ_attack

var target_entity
var timer;
var idle_ticks = 20;

func enter(entity, target):
	print(target);
	print("Attacking");
	if target and not target.team == entity.team:
		target_entity = target
		target_entity.died.connect(go_idle)
		timer = entity.get_node("AttackTimer");
		timer.one_shot = true;
	else:
		print(target)
		get_parent().change_state("Idle");

func exit(entity):
	target_entity.died.disconnect(go_idle)
	pass ;

func update(entity, _delta):
	entity._update_healthbar(entity.healthbar);
	if idle_ticks == 0:
		get_parent().get_node("Move").update(entity, _delta);
	pass ;

func update_tick(entity, delta):
	super(entity, delta);
	if not timer.is_stopped():
		print("A");
		# You can pursue the target
		entity.nav_agent.target_position = target_entity.position;
	elif idle_ticks > 0:
		print("B");
		# You must finish your auto idle time
		idle_ticks -= 1;
	else:
		print("C");
		# Try to auto
		try_auto(entity, target_entity, delta);
	pass ;

func go_idle():
	get_parent().change_state("Idle");

func try_auto(entity, target, delta):
	if target == null:
		return;
	if target_in_range(entity, target):
		auto_attack(entity, target);
		timer.set_wait_time(100 / entity.attack_speed);
		print(100/entity.attack_speed)
		idle_ticks = 20
		timer.start();
	else:
		entity.nav_agent.target_position = target.position;
		get_parent().get_node("Move").update_tick(entity, delta);
		
func target_in_range(entity, target):
	var bodies = entity.get_node("AttackArea").get_overlapping_bodies()
	if bodies.has(target):
		return true
	return false

func auto_attack(entity, target):
	if entity.projectile:
		var scene = entity.projectile.instantiate()
		scene.position = entity.position
		scene.target = target
		scene.damage = entity.attack_damage
		entity.get_node("Projectiles").add_child(scene, true)
	else:
		target.take_damage(entity.attack_damage)
