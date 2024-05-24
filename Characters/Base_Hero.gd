extends CharacterBody3D

# Net  Vars
@export var team:int;
@export var pid:int; # Default to owned by the server

@export var Max_Health:float = 550.00
@export var Cur_Health:float = 550.00
@export var Max_Mana = 300
@export var CUR_MANA = 300
@export var attack = 60
@export var attack_speed:float = .75 #APM
@export var attack_timeout:float = 0.00

@export var speed = 5 # 330 
@export var range = 5

@export var Armor = 20;

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@export var RangeCollider: Area3D;
@export var Projectile:PackedScene;


var isAttacking: bool = false;
var isDead: bool = false;
@export var targetEntity:CharacterBody3D;
@export var targetId:int;
var attackTimeout = 0;

# Called when the node enters the scene tree for the first time.
func _ready():
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
	if attack_timeout >0 :
		attack_timeout -= delta;
	if isAttacking:
		var hasAction = true
		# Can Attack
		var bodies = RangeCollider.get_overlapping_bodies()
		for body in bodies:
			if body == targetEntity:
				AutoAttack()
				hasAction = false
		# Can't Attack
		if hasAction && targetEntity:
			navigation_agent.set_target_position(targetEntity.position)
			move(delta)
		
	else:
		move(delta)

func _update_health():
	$Healthbar.value = Cur_Health
	if(Cur_Health <=0):
		Die()
	
	
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
func SetTarget(pid):
	print(pid)
	var Champions = get_parent().get_children()
	for champ in Champions:
		if champ.pid == pid:
			targetEntity = champ
			isAttacking = true
		else:
			print(pid);
	
func move(delta):
	var target_pos = navigation_agent.get_next_path_position()
	var local_destination = target_pos - global_position
	var direction = local_destination.normalized();
	look_at(direction)
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

func AutoAttack():
	if attack_timeout > 0:
		return
	attack_timeout = attack_speed;
	var Arrow = Projectile.instantiate()
	Arrow.position = position
	Arrow.target = targetEntity
	Arrow.damage = attack
	get_node("/root").add_child(Arrow)
	pass
	
func TakeDamage(damage):
	print(damage);
	var taken:float = Armor
	taken /= 100
	taken = damage / (taken + 1)
	print(taken);
	Cur_Health -= taken;
	if(Cur_Health <= 0):
		Die()
		
func Die():
	isDead = true;
	hide()
