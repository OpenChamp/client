extends Button

func _ready() -> void:
	WSManager.ws_connected.connect(_connected)
	WSManager.ws_disconnected.connect(_disconnected)
	WSManager.auth_required.connect(_on_auth_required)
	WSManager.auth_obtained.connect(_on_auth_obtained)
	pressed.connect(connect_to_server)
	
func connect_to_server():
	var connecting = WSManager.connect_to_server()
	if not connecting: return;
	disabled = true
	text = "Connecting..."

func _connected():
	if not WSManager.auth_with_token():
		# Assume the user needs to register
		await UIManager.change_menu("Registration")

func _disconnected():
	text = "Connect"
	disabled = false

func _on_auth_required():
	await UIManager.change_menu("Register")

func _on_auth_obtained(auth_credentials: Dictionary):
	ConfigManager.username = auth_credentials.username
	ConfigManager.save_auth_token(auth_credentials.token)
	await UIManager.change_menu("MainMenu")
	

	
