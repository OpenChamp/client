extends Control

func _ready() -> void:
	UIManager.set_ui_root(self)
	UIManager.change_menu("Connect")
