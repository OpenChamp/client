extends Node3D

@export var damage: int
var target: Node = null
var speed: int = 10


func _ready():
	if multiplayer.is_server() and not target:
		queue_free()


func _process(delta):
	if not multiplayer.is_server():
		return
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
