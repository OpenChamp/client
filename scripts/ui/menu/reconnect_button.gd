class_name ReconnectButton
extends Button

func _ready() -> void:
	self.pressed.connect(_try_reconnect)
	
func _try_reconnect():
	if not NetworkManager:
		push_error("No Network Manager Available to reconnect")
		
	NetworkManager.conn()
