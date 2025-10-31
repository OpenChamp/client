extends StaticBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.play("idle", -1, .5)
	pass # Replace with function body.
