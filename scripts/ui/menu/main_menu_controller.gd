extends Control

func _ready() -> void:
	UIManager.set_ui_root($MenuOverlay)
	UIManager.change_interface("Connect")
