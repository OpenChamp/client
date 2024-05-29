extends Area3D

@export var team:int;
@export var direction:Vector3;

var lifetime = 3.0;
var damage = 45;
# Called when the node enters the scene tree for the first time.
func _ready():
	direction.y = 0;
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	lifetime -= delta;
	position = position + direction * delta
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body is CharacterBody3D && body.team != team:
			body.take_damage(damage)
			queue_free()
	if lifetime <0:
		queue_free();
