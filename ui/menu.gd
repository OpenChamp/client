extends Node

var title_fadein : float = 0.0
var is_queued : bool = false

func _ready():
	# If headless, go to Server Scene instead
	for argument in OS.get_cmdline_args():
		print(argument)
	if OS.get_cmdline_args().has("-s"):
		get_tree().change_scene_to_file("res://server/server.tscn")
		return
		
	# Make sure environment is defaulted correctly
	$LogoLabel.show()
	$PlayerCount.hide()
	$ConnectionButton.show()
	$MainMenu.hide()
	$Settings.hide()
	$CancelConnectionButton.hide()
	# Fadein Logo
	$LogoLabel.add_theme_color_override("default_color", Color(255,0,0, 0))
	

func _process(_delta):
	# Fadein Title
	if(title_fadein < 255):
		title_fadein += 0.001
		$LogoLabel.add_theme_color_override("default_color", Color(255,0,0, title_fadein))
	# Connection Timer
	if(NetworkManager.socket.get_ready_state() == WebSocketPeer.STATE_CONNECTING):
		$ConnectionButton.text = "Attempting Connection... [" + str(int(NetworkManager.connection_timeout)) + "]"

func _on_connection_button_button_up() -> void:
	$ConnectionButton.disabled = true
	$ConnectionButton.text = "Attempting Connection..."
	$CancelConnectionButton.show()
	NetworkManager.connect_to_server()
	var timer = Timer.new()
	timer.name = "ConnectionTimer"
	timer.set_wait_time(1)
	timer.set_one_shot(false)
	timer.autostart = true
	timer.connect("timeout", wait_for_connection)
	add_child(timer)


func wait_for_connection():
	var cur_state = NetworkManager.socket.get_ready_state()
	if cur_state == WebSocketPeer.STATE_OPEN:
		$ConnectionTimer.queue_free()
		$CancelConnectionButton.hide()
		open_main_menu()
	elif cur_state == WebSocketPeer.STATE_CLOSED:
		$ConnectionTimer.queue_free()
		$ConnectionButton.text = "Connect"
		$ConnectionButton.disabled = false


func open_main_menu():
	setup_player_count()
	$ConnectionButton.hide()
	$PlayerCount.show()
	$MainMenu.show()
	
func setup_player_count():
	# Create a timer to update the player count every 5 seconds
	var timer = Timer.new()
	timer.set_wait_time(5)
	timer.set_one_shot(false)
	timer.connect("timeout", update_player_count)
	add_child(timer)
	timer.start()

func update_player_count():
	NetworkManager.get_player_count()
	$PlayerCount.text = "[right]Players Online: [color=green]" + str(await NetworkManager.Store["PlayerCount"]) + "[/color][/right]"


func _on_start_queue_button_up() -> void:
	is_queued = !is_queued
	if is_queued:
		NetworkManager.start_queue()
		$MainMenu/StartQueue.text = "Stop"
	else:
		NetworkManager.stop_queue()
		$MainMenu/StartQueue.text = "Start Queue"

func _on_settings_button_up() -> void:
	$MainMenu.hide()
	$Settings.show()

func _on_quit_button_up() -> void:
	get_tree().quit()


func _on_back_button_button_up() -> void:
	$MainMenu.show()
	$Settings.hide()


func _on_cancel_connection_button_button_up() -> void:
	NetworkManager.disconnect_from_server()
	$ConnectionTimer.queue_free()
	$CancelConnectionButton.hide()
	$ConnectionButton.disabled = false
	$ConnectionButton.text = "Connect"
	pass # Replace with function body.
