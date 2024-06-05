extends Node3D

@export var damage: int
var target: Node = null
var speed: int = 80


func _ready():
	if multiplayer.is_server() and not target:
		queue_free()


func _process(delta):
	if not multiplayer.is_server():
		return
	if target == null:
		queue_free()
		return
	var tmp_pos = target.position + Vector3.UP
	if global_position.distance_to(tmp_pos) > 0.5:
		var dir = (tmp_pos- global_position).normalized()
		var dist = speed * delta
		global_position += dir * dist
		look_at(tmp_pos)
	else:
		target.take_damage(damage)
		queue_free()
