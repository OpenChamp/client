extends Node3D

var target
@export var damage: int
var speed=10


# Called when the node enters the scene tree for the first time.
func _ready():
	pass;
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not multiplayer.is_server(): return
	if global_position.distance_to(target.position) > 0.1:
		var dir = (target.position - global_position).normalized();
		var dist = speed * delta
		global_position += dir * dist;
		look_at(target.position);
	else:
		target.TakeDamage(damage)
		queue_free()
