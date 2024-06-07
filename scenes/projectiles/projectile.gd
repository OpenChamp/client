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
	var tmp_pos = target.global_position + Vector3.UP
	if global_position.distance_to(tmp_pos + Vector3.DOWN) > speed * delta:
		print(tmp_pos)
		print(global_position)
		print(global_position.distance_to(tmp_pos + Vector3.DOWN))
		var dir = (tmp_pos- global_position).normalized()
		var dist = speed * delta
		global_position += dir * dist
		look_at(tmp_pos)
	elif global_position.distance_to(tmp_pos + Vector3.DOWN) < speed * delta:
		global_position = tmp_pos
	if global_position == tmp_pos:
		if multiplayer.is_server():
			target.take_damage(damage)
		queue_free()
