extends Node3D

@onready var debris = $Debris
@onready var smoke = $Smoke
@onready var fire = $Fire

func explode():
	debris.emitting = true
	smoke.emitting = true
	fire.emitting = true
	$AudioStreamPlayer.play()
