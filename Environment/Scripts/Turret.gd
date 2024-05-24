extends StaticBody3D

@export var team:int
@export var pid:int
var attackSpeed = 1.5; # 1.5/s
var attackTimeout = 0;
var Target:CharacterBody3D
var targetAttackedPlayer:bool = false;
var Health = 100

# Called when the node enters the scene tree for the first time.
func _ready():
	if team == 1:
		get_node("Crystal").set_surface_override_material(0, load("res://Environment/Materials/Blue.material"))
	elif team == 2:
		get_node("Crystal").set_surface_override_material(0, load("res://Environment/Materials/Red.material"))


func TakeDamage(dmg):
	Health -= dmg;
	print(Health)
	if(Health <=0):
		queue_free()
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#if attackTimeout > 0:
		#attackTimeout -= delta;
	#var bodies = $Range.get_overlapping_bodies();
	#for body in bodies:
		#if body is CharacterBody3D and body.team != team:
			#if attackTimeout <=0:
				##Attack(body)
				#print("Turret Attack!")
	#pass
