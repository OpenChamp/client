extends Node3D
class_name PlayerController

@export var cur_zoom: int

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var attack_move_cast: ShapeCast3D = $AttackMoveCast

const MoveMarker: PackedScene = preload ("res://scenes/effects/move_marker.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
