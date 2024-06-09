extends CharacterBody3D

@export var team:int;
@export var health:float = 550.00
@export var mana = 300
@export var damage = 60
@export var attack_speed = .75 #APM
@export var armor = 20 
@export var resistance = 30
@export var speed = 5 # 330 
@export var range = 3
@export var target_pos:Vector3

@export var RangeCollider: Area3D;
@export var Projectile:PackedScene;

var isAttacking: bool = false;
var isDead: bool = false;
var targetEntity:CharacterBody3D;
var attackTimeout = 0;

func _ready():
	# Set Range
	RangeCollider.get_node("./CollisionShape3D").shape.radius = range
	RangeCollider.get_node("./MeshInstance3D").mesh.top_radius = range;
	target_pos = position
	$Healthbar.max_value = health
	$Healthbar.value = health

func _process(delta):
	$Healthbar.update_loc(position)
	if attackTimeout > 0:
		attackTimeout -= delta;
	if isAttacking:
		var bodies = RangeCollider.get_overlapping_bodies()
		var actionPerformed = false;
		if bodies:
			for body in bodies:
				if body == targetEntity:
					actionPerformed = true;
					if(targetEntity.isDead):
						isAttacking = false;
						targetEntity = null;
						target_pos = position;
					elif attackTimeout<=0:
						attackTimeout = attack_speed;
						auto_attack()
			if !actionPerformed:
				target_pos = targetEntity.position
				move(delta)
		else:
			target_pos = targetEntity.position
			move(delta)
			
	elif target_pos != position:
		move(delta)

func move(delta: float):
	if global_position.distance_to(target_pos) > 0.1:
		var dir = (target_pos - global_position).normalized();
		var dist = speed * delta
		global_position += dir * dist;
	else:
		global_position = target_pos;

func move_to(pos: Vector3):
	isAttacking = false;
	targetEntity = null;
	target_pos = pos;

func attack(entity:CharacterBody3D):
	isAttacking = true
	targetEntity = entity;
	target_pos = targetEntity.position	

func auto_attack():
	var Arrow = Projectile.instantiate()
	Arrow.position = position
	Arrow.target = targetEntity
	Arrow.damage = damage
	get_node("/root").add_child(Arrow)
	
# activate or ready ability 1
func ability1(pos: Vector3 = position, entity = null):
	print("ability1");
	
# activate or ready ability 2
func ability2(pos: Vector3 = position, entity = null):
	print("ability2");
	
# activate or ready ability 3
func ability3(pos: Vector3 = position, entity = null):
	print("ability3");
	
# activate or ready ability 4
func ability4(pos: Vector3 = position, entity = null):
	print("ability4");
	
# select or cast readied ability
func selected(pos: Vector3 = position, entity = null):
	print(pos);
	print(entity);
	
func take_damage(value):
	$Healthbar.value -= value / ((armor / 100) + 1)
	if $Healthbar.value <= 0: die()
		
func die():
	isDead = true;
	hide()
