extends CharacterBody3D

var team := 1
var creature_id := 1

func _process(delta: float) -> void:
	if team == 1:
		position += Vector3(0,0,1) * delta
	else:
		position += Vector3(0, 0, -1) * delta
	pass
