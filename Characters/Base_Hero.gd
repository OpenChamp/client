extends CharacterBody3D

# Net  Vars
@export var team:int;
@export var pid:int

@export var health:float = 550.00
@export var mana = 300
@export var attack = 60
@export var attack_speed = .75 #APM
@export var armor = 20 
@export var resistance = 30
@export var speed = 5 # 330 
@export var range = 3

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@export var RangeCollider: Area3D;
@export var Projectile:PackedScene;


var isAttacking: bool = false;
var isDead: bool = false;
var targetEntity:CharacterBody3D;
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
	$Healthbar.max_value = health
	$Healthbar.value = health

func _process(delta):
	move(delta)


func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame
	var pos
	if targetEntity:
		pos = targetEntity.position
	else:
		pos = position
	navigation_agent.set_target_position(pos)

@rpc("authority")
func setOwner(team):
	self.team = team;
	get_parent().get_parent().get_node("Player").set_player(self)
	
@rpc("any_peer")
func MoveTo(coords):
	print(coords);
	isAttacking = false;
	targetEntity = null;
	navigation_agent.set_target_position(coords);
	pass

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
	var Arrow = Projectile.instantiate()
	Arrow.position = position
	Arrow.target = targetEntity
	Arrow.damage = attack
	get_node("/root").add_child(Arrow)
	pass
	
func TakeDamage(damage):
	print(damage);
	var taken:float = armor
	taken /= 100
	taken = damage / (taken + 1)
	print(taken);
	$Healthbar.value -= taken
	if $Healthbar.value <= 0:
		Die()
		
func Die():
	isDead = true;
	hide()
	print("RIP");
