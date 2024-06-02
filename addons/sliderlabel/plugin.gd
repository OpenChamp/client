@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_custom_type("SliderLabel", "Label", preload("res://addons/sliderlabel/sliderlabel.gd"), preload("res://addons/sliderlabel/sliderlabel.svg"))

func _exit_tree() -> void:
	remove_custom_type("SliderLabel")
