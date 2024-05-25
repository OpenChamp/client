extends CharacterBody3D

# Net  Vars
@export var team:int;
@export var pid:int; # Default to owned by the server

@export var Max_Health:float = 550.00
@export var Health:float = 550.00
@export var Max_Mana = 300
@export var Mana = 300
@export var attack = 60
@export var attack_speed:float = .75 #APM
@export var attack_timeout:float = 0.00

@export var Casttime:float = 0.1

@export var speed = 5 # 330 
@export var range = 8

@export var Armor = 20;

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@export var RangeCollider: Area3D;
@export var Projectile:PackedScene;

signal died(pid)

var isAttacking: bool = false;
var isDead: bool = false;
var targetEntity; 
@export var targetId:int;
var attackTimeout = 0;

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set Signals
	$CastTimer.timeout.connect(FinishAutoAttack)
	# Set Range
	RangeCollider.get_node("./CollisionShape3D").shape.radius = range
	RangeCollider.get_node("./MeshInstance3D").mesh.top_radius = float(range);
	# Set Nav
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5
	# Set Health
	call_deferred("actor_setup")
	$Healthbar.max_value = Max_Health;
	_update_health();

func _process(delta):
	_update_health()
	if not multiplayer.is_server():
		return;
	if !$CastTimer.is_stopped():
		return
	if attack_timeout >0 :
		attack_timeout -= delta;
	if isAttacking:
		if targetEntity.Health <=0:
			targetEntity = null
			isAttacking = false
			return;
		var hasAction = true
		if target_in_range():
			InitAutoAttack()
		else:
			if(targetEntity != null):
				navigation_agent.set_target_position(targetEntity.position)
			else:
				targetEntity = null
				isAttacking = false
			move(delta)
		
	else:
		move(delta)

func _update_health():
	$Healthbar.value = Health
	if(Health <=0):
		Die()
		
func target_in_range():
	var bodies = RangeCollider.get_overlapping_bodies()
	for body in bodies:
		if body == targetEntity:
			return true;
	return false;
	
func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame
	var pos
	if targetEntity:
		pos = targetEntity.position
	else:
		pos = position
	navigation_agent.set_target_position(pos)
	
@rpc("authority", "call_local")
func SetTarget(target_pid):
	print(target_pid)
	var Champions = get_parent().get_children()
	for champ in Champions:
		if champ.pid == target_pid:
			targetEntity = champ
			isAttacking = true
		else:
			print(target_pid);
	
func move(delta):
	var target_pos = navigation_agent.get_next_path_position()
	if(position == target_pos):
		return;
	var local_destination = target_pos - global_position
	var direction = local_destination.normalized();
	look_at(target_pos)
	if global_position.distance_to(target_pos) > 0.1:
		var dir = (target_pos - global_position).normalized();
		var dist = speed * delta
		global_position += dir * dist;
	else:
		global_position = target_pos;

func Attack(entity:CharacterBody3D):
	targetEntity = entity;
	navigation_agent.set_target_position(targetEntity.position)
	isAttacking = true

func InitAutoAttack():
	if attack_timeout > 0:
		return
	look_at(targetEntity.position)
	$CastTimer.wait_time = Casttime
	$CastTimer.start()

func FinishAutoAttack():
	print("Attacking")
	$CastTimer.stop()
	#Check if target is still in range
	if !target_in_range():
		return;
	attack_timeout = attack_speed;
	
	var Arrow = Projectile.instantiate()
	Arrow.position = position
	Arrow.target = targetEntity
	Arrow.damage = attack
	get_parent().get_parent().get_node("Projectiles").add_child(Arrow, true)

func TakeDamage(damage):
	print(damage);
	var taken:float = Armor
	taken /= 100
	taken = damage / (taken + 1)
	print(taken);
	Health -= taken;
	if(Health <= 0):
		died.emit(pid)
		
func Die():
	isDead = true;
	$Body.hide()
	$PlayerCollider.hide()
	
@rpc("authority","call_local")
func PlayerDeath():
	$Dead.show()

func _on_respawn_timer_timeout():
	$RespawnTimer.stop()
	print("ReAlive");
	$Dead.hide()
	$Body.show()
	$PlayerCollider.show()
	Health = Max_Health
	position = get_parent().get_parent().get_node("Spawn" + str(team)).position
	isDead = false
	show()
