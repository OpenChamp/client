extends Node3D

@export var Particles:GPUParticles3D
# Called when the node enters the scene tree for the first time.
func _ready():
	Particles.one_shot = true
	Particles.emitting = true

func _process(delta):
	if(!Particles.emitting):
		queue_free()
