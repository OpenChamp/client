extends Minion_Base
class_name Minion_Mage

# === Ranged New Vars === #
@export var Projectile_Scene : PackedScene = load("res://scenes/abilities/MageProjectile.tscn")

func setup_stats():
	AttackRange = 5.0
	MaxHealth = 100
	MagicalPower = 25
	super()
	
func attack(body: Node3D = target_node):
	if state == STATE.DEAD: return;
	if !can_attack: return
	if !body or !body is OC_Entity: return
	
	var distance_to_target = body.global_position.distance_to(global_position)
	
	if distance_to_target > AttackRange:
		state = STATE.FOLLOWING
		return
	
	can_attack = false
	$AttackTimeout.start()
	$FollowTimer.stop()
	$FollowTimer.start(max_follow_time)
	
	print("Minion team ", Team, " attacking ", body.name, " with magical power ", MagicalPower)
	var spawner = get_tree().get_first_node_in_group("game_root")
	if not spawner:
		print("Error: Could not find game_root node")
		return
		
	var mp_spawner = spawner.get_node("MultiplayerSpawner")
	if not mp_spawner:
		print("Error: Could not find MultiplayerSpawner")
		return
		
	spawn_projectile.rpc(
		target_node.name
	)
	
@rpc("authority", "call_local")
func spawn_projectile(target_name:String):
	var target = get_parent().get_node(target_name)
	if not target:
		print("Projectile Sync Error: Invalid Target Name")
		return;
	var new_projectile = Projectile_Scene.instantiate()
	var direction = (target.global_position - global_position).normalized()
	new_projectile.spawn_pos = global_position + direction
	new_projectile.direction = direction
	new_projectile.team = Team
	new_projectile.creator = self
	new_projectile.target_node = target
	new_projectile.damage = MagicalPower
	new_projectile.speed = ProjectileSpeed
	get_parent().add_child(new_projectile)
