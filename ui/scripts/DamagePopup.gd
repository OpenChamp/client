class_name DamagePopup
extends Node2D

@onready var label: Label = %Label
@onready var label_container: Node2D = %LabelNode
@onready var ap: AnimationPlayer = %AnimationPlayer

var camera: Camera3D

func _ready():
	camera = get_viewport().get_camera_3d()

func play(value: String):
	if not camera:
		return

	var start_pos = camera.unproject_position(get_parent().position)
	var length = ap.get_animation("pop_up").length
	var end_pos = start_pos + Vector2(0, -20)
	var tween = get_tree().create_tween()

	label.text = value
	ap.play("pop_up")
	
	tween.tween_property(label_container, "position", end_pos, length).from(start_pos)


func remove() -> void:
	ap.stop()
	get_parent().remove_child(self)
	self.queue_free()
