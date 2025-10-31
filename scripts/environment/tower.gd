extends StaticBody3D

const TotalHP = 1000
@onready var CurrentHP : float = TotalHP

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.play("idle", -1, .5)
	pass # Replace with function body.

@rpc("authority")
func _take_damage(dmg:float):
	CurrentHP -= dmg
	if CurrentHP <= 0:
		die()
		
func die():
	queue_free()
