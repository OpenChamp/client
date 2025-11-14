extends Node3D

enum STATES {
	alive,
	dead
}
var state := STATES.alive
@export var movement_comp: MovementComponent
@export var speed: float = 5.0
@export var health:int = 0
# TODO: Create enum for minion states
@export var minion_state: int = 0

func die():
	if state == STATES.dead: return
	state = STATES.dead
	print("Minion Death")
	$Body.hide()
	$MoneyEmitter.emitting = true
	$AudioStreamPlayer3D.play()
	$AudioStreamPlayer3D.finished.connect(queue_free)
