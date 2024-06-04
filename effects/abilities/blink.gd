extends Area3D

@onready var p = $Smoke

func _ready():
	p.emitting = true

func _process(delta):
	if !p.emitting:
		queue_free()
