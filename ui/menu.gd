extends Node

var title_fadein : float = 0.0
var is_queued : bool = false

func _ready():
	# Fadein Logo
	$LogoLabel.add_theme_color_override("default_color", Color(255,0,0, 0))
	

func _process(_delta):
	# Fadein Title
	if(title_fadein < 255):
		title_fadein += 0.001
		$LogoLabel.add_theme_color_override("default_color", Color(255,0,0, title_fadein))

func _on_connection_button_button_up() -> void:
	$ConnectionButton.disabled = true
	$ConnectionButton.text = "Attempting Connection..."
	var isConnected = await NetworkManager.connect_to_server()
	if isConnected:
		open_main_menu()
	else:
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
