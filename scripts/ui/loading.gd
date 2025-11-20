extends Control

func _ready() -> void:
	NetworkManager.connection_failed.connect(connection_fail)
	NetworkManager.disconnected_from_server.connect(connection_fail)
	$Panel/Disconnected/ReQueue.pressed.connect(func():
		change_interface(true)
	)
	
func connection_fail():
	change_interface(false)
	
func change_interface(toggle: bool, err:String = ""):
	if toggle:
		$Panel/Joining.show()
		$Panel/Disconnected.hide()
	else:
		$Panel/Joining.hide()
		$Panel/Disconnected.show()
		if err != "":
			$Panel/Disconnected/ErrorBox.text = err
		
func _exit_tree() -> void:
	NetworkManager.connection_failed.disconnect(change_interface)
	NetworkManager.disconnected_from_server.disconnect(change_interface)
