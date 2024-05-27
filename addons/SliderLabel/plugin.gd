@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_custom_type("SliderLabel", "Label", preload("res://addons/SliderLabel/SliderLabel.gd"), preload("res://addons/SliderLabel/SliderLabel.svg"))

func _exit_tree() -> void:
	remove_custom_type("SliderLabel")
