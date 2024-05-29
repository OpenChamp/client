extends Node3D

@onready var particles: GPUParticles3D = $GPUParticles3D
var hasPlayed = false

func _ready():
	particles.one_shot = true
	$AnimationPlayer.current_animation = "shrink_ring"
	$AnimationPlayer.play()


func _process(delta):
	if !$AnimationPlayer.is_playing():
		queue_free();
	#if !$AnimationPlayer.is_playing() && !hasPlayed:
		#hasPlayed = true
		#particles.emitting = true
	#if not particles.emitting && hasPlayed:
		#queue_free()
