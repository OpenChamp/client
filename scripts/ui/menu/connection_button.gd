extends Button

func _ready() -> void:
	WSManager.ws_connected.connect(_connected)
	WSManager.ws_disconnected.connect(_disconnected)
	pressed.connect(try_connect)
	
func try_connect():
	
	var connecting = WSManager.connect_to_server()
	if not connecting: return;
	disabled = true
	text = "Connecting..."
	
func _connected():
	UIManager.change_menu("MainMenu")
	
func _disconnected():
	text = "Connect"
	disabled = false
	
