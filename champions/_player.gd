extends Node3D
class_name PlayerController

@export var cur_zoom: int

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
#@onready var attack_move_cast: ShapeCast3D = $AttackMoveCast

const MoveMarker: PackedScene = preload ("res://scenes/effects/move_marker.tscn")

@onready var Server = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the Server Listener
	while !Server.is_in_group("Map"):
		Server = Server.get_parent()
	# Set our camera as main
	$SpringArm3D/Camera3D.make_current()

func _unhandled_input(event):
	if event.is_action("player_zoomin"):
		if spring_arm.spring_length > Config.min_zoom:
			spring_arm.spring_length -= 1
	if event.is_action("player_zoomout"):
		if spring_arm.spring_length < Config.max_zoom:
			spring_arm.spring_length += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
