extends Button

func _ready() -> void:
	self.pressed.connect(func():get_tree().quit(0))
