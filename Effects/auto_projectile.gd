extends Node3D

var target
@export var damage: int
var speed = 10

func _ready():
	if not target:
		queue_free()

func _process(delta):
	if target == null or target.is_dead:
		queue_free()
		return
	if global_position.distance_to(target.position) > 0.1:
		var dir = (target.position - global_position).normalized()
		var dist = speed * delta
		global_position += dir * dist
		look_at(target.position)
	else:
		target.take_damage(damage)
		queue_free()
