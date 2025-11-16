extends Panel

@onready var username_input := $VBoxContainer/UsernameInput
@onready var save_button := $VBoxContainer/SaveUsernameButton

func _ready():
	WSManager.auth_obtained.connect(_auth_obtained)
	save_button.pressed.connect(_register)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		_register()

func _auth_obtained(auth_credentials: Dictionary):
	ConfigManager.username = auth_credentials.username
	ConfigManager.save_auth_token(auth_credentials.token)
	UIManager.change_menu("MainMenu")

func _register():
	WSManager.fast_registration(username_input.text)
