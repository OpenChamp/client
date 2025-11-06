class_name GameTimer
extends Node

var time:float = 0.0

func _ready():
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	time += delta

func start():
	set_physics_process(true)

func stop():
	set_physics_process(false)
