extends Decal

@onready var particle_system = $GPUParticles3D
var tween
# Called when the node enters the scene tree for the first time.
func move_to(pos):
	if tween:
		tween.kill()
	self.scale = Vector3.ONE
	global_position = pos
	particle_system.emitting = true
	tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, $Timer.wait_time)
	show()
	$Timer.start()

func _on_timer_timeout() -> void:
	hide()
