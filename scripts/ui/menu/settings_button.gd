extends Button

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	UIManager.change_menu("Settings", true)
