extends CharacterBody3D

@export var team:int;
@export var health = 550
@export var mana = 300
@export var attack = 60
@export var attack_speed = .75 #APM
@export var armor = 20 
@export var resistance = 30
@export var speed = 5 # 330 
@export var range = 3
@export var target_pos:Vector3 = position

@export var RangeCollider: Area3D;
var isAttacking: bool = false;
var isDead: bool = false;
var targetEntity:CharacterBody3D;
var attackTimeout = 0;

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set Range
	RangeCollider.get_node("./CollisionShape3D").shape.radius = range
	RangeCollider.get_node("./MeshInstance3D").mesh.top_radius = range;
	
	$Healthbar.maxHealth = health
	$Healthbar.value = health
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Healthbar.update_loc(position)
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
						print("Attack!")
						attackTimeout = attack_speed;
						AutoAttack()
					else:
						attackTimeout -= delta;
			if !actionPerformed:
				target_pos = targetEntity.position
				move(delta)
		else:
			target_pos = targetEntity.position
			move(delta)
			
	elif target_pos != position:
		move(delta)

func move(delta):
	if global_position.distance_to(target_pos) > 0.1:
		var dir = (target_pos - global_position).normalized();
		var dist = speed * delta
		global_position += dir * dist;
	else:
		global_position = target_pos;


func MoveTo(pos:Vector3):
	target_pos = pos;

func Attack(entity:CharacterBody3D):
	targetEntity = entity;
	target_pos = targetEntity.position
	isAttacking = true

func AutoAttack():
	targetEntity.TakeDamage(attack)
	
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
