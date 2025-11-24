extends Button


# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	pressed.connect(_on_pressed)

func _on_pressed():
	push_warning("PRESSED")
	UIManager.hide_overlay_interface(self.get_parent())
