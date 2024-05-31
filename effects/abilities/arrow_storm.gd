extends Area3D
@export var team:int
@onready var p = $GPUParticles3D

var lifetime = 3.0
var damage = 10
var ticktime = 0.2
var ticktime_left = 0.0
# Called when the node enters the scene tree for the first time.
func _ready():
	p.lifetime = lifetime
	p.amount = 80
	p.emitting = true
	ticktime_left = ticktime
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	ticktime_left -= delta;
	if ticktime_left <=0:
		ticktime_left = ticktime
		var bodies = get_overlapping_bodies()
		for body in bodies:
			if body is CharacterBody3D && body.team != team and !body.is_in_group("Objective"):
				body.take_damage(damage)
	if !p.emitting:
		queue_free()

