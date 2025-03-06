extends Node

# Variables
var title_fadein : float = 0.0
var is_queued : bool = false

# Settings variables
var master_volume : float = 1.0
var music_volume : float = 1.0
var sfx_volume : float = 1.0
var fullscreen : bool = false
var vsync : bool = true
var username : String = "Player"
var show_fps : bool = false

# Chat variables
var chat_visible : bool = true
var chat_history : Array = []
var max_chat_messages : int = 100

# Config file handling
const SETTINGS_PATH = "user://settings.cfg"
var config = ConfigFile.new()

func _ready():
	load_settings()
	
	# Check for headless server mode
	for argument in OS.get_cmdline_args():
		print(argument)
	if OS.get_cmdline_args().has("-s"):
		get_tree().change_scene_to_file("res://server/server.tscn")
		return
	
	# Initialize UI
	set_ui("connect")
	$LogoLabel.add_theme_color_override("default_color", Color(255,0,0, 0))
	
	# Initialize settings UI
	_init_settings_ui()
	apply_settings()

func _process(_delta):
	# Handle logo fade-in animation
	if(title_fadein < 255):
		title_fadein += 0.001
		$LogoLabel.add_theme_color_override("default_color", Color(255,0,0, title_fadein))
	
	# Update connection status
	if(NetworkManager.socket.get_ready_state() == WebSocketPeer.STATE_CONNECTING):
		$ConnectionButton.text = "Attempting Connection... [" + str(int(NetworkManager.connection_timeout)) + "]"
	
	# Update FPS counter if enabled
	if show_fps and has_node("FPSCounter"):
		$FPSCounter.text = "FPS: " + str(Engine.get_frames_per_second())

# === UI Management ===

func set_ui(layout: String):
	# Hide all UI elements first
	$ConnectionButton.hide()
	$CancelConnectionButton.hide()
	$Quit.hide()
	$MainMenu.hide()
	$Settings.hide()
	$Credits.hide()
	$ChatContainer.hide()
	
	# Show only the elements needed for the current layout
	match layout:
		"connect":
			$LogoLabel.show()
			$ConnectionButton.show()
			$Quit.show()
		"connecting":
			$ConnectionButton.disabled = true
			$ConnectionButton.text = "Attempting Connection..."
			$ConnectionButton.show()
			$CancelConnectionButton.show()
		"mainmenu":
			$ConnectionButton.hide()
			$PlayerCount.show()
			$MainMenu.show()
			$ChatContainer.show()
		"settings":
			$Settings.show()

func _init_settings_ui():
	$Settings/MasterVolumeSlider.value = master_volume * 100
	$Settings/MusicVolumeSlider.value = music_volume * 100
	$Settings/SFXVolumeSlider.value = sfx_volume * 100
	$Settings/FullscreenCheckBox.button_pressed = fullscreen
	$Settings/VSyncCheckBox.button_pressed = vsync
	$Settings/ShowFPSCheckBox.button_pressed = show_fps
	$Settings/UsernameInput.text = username

# === Connection Management ===

func _on_connection_button_button_up() -> void:
	set_ui("connecting")
	
	NetworkManager.connect_to_server(username)
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
		NetworkManager.set_username()
		_setup_chat()
		open_main_menu()
	elif cur_state == WebSocketPeer.STATE_CLOSED:
		$ConnectionTimer.queue_free()
		set_ui("connect")

func _on_cancel_connection_button_button_up() -> void:
	NetworkManager.disconnect_from_server()
	$ConnectionTimer.queue_free()
	$CancelConnectionButton.hide()
	$ConnectionButton.disabled = false
	$ConnectionButton.text = "Connect"
	$Quit.show()

# === Main Menu and Player Count ===

func open_main_menu():
	set_ui("mainmenu")
	setup_player_count()
	add_chat_message("System", "Connected to server. Welcome, " + username + "!")

func setup_player_count():
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
		add_chat_message("System", "You joined the queue.")
	else:
		NetworkManager.stop_queue()
		$MainMenu/StartQueue.text = "Start Queue"
		add_chat_message("System", "You left the queue.")

func _on_practice_button_up() -> void:
	$MainMenu/Practice.text = "Please Wait..."
	$MainMenu/Practice.disabled = true

	var peer = ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", 10330)
	multiplayer.multiplayer_peer = peer
	
	await get_tree().create_timer(2).timeout
	if(multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED):
		get_tree().change_scene_to_file("res://scene/game.tscn")
	else:
		print("Failed to connect to server")
		$MainMenu/Practice.text = "Practice"
		$MainMenu/Practice.disabled = false

# === Settings Management ===

func load_settings():
	var err = config.load(SETTINGS_PATH)
	if err != OK:
		print("No settings file found, using defaults")
		return
	
	master_volume = config.get_value("audio", "master_volume", 1.0)
	music_volume = config.get_value("audio", "music_volume", 1.0)
	sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
	fullscreen = config.get_value("video", "fullscreen", false)
	vsync = config.get_value("video", "vsync", true)
	show_fps = config.get_value("video", "show_fps", false)
	username = config.get_value("player", "username", "Player")
	chat_visible = config.get_value("ui", "chat_visible", true)

func save_settings():
	NetworkManager.save_settings_to_config(config)


func apply_settings():
	# Apply audio settings
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))
	
	# Apply video settings
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN != fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	
	# Apply FPS counter
	_update_fps_counter()
	
	# Apply username
	if NetworkManager and NetworkManager.Store.has("Username"):
		NetworkManager.Store["Username"] = username

func _update_fps_counter():
	if show_fps:
		if not has_node("FPSCounter"):
			var fps_label = Label.new()
			fps_label.name = "FPSCounter"
			fps_label.text = "FPS: 0"
			fps_label.add_theme_color_override("font_color", Color(0, 1, 0))
			fps_label.position = Vector2(10, 10)
			add_child(fps_label)
	else:
		if has_node("FPSCounter"):
			$FPSCounter.queue_free()

# === Settings UI Signal Handlers ===

func _on_master_volume_slider_value_changed(value):
	master_volume = value / 100.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))

func _on_music_volume_slider_value_changed(value):
	music_volume = value / 100.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_volume))

func _on_sfx_volume_slider_value_changed(value):
	sfx_volume = value / 100.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_volume))

func _on_fullscreen_check_box_toggled(button_pressed):
	fullscreen = button_pressed
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if button_pressed else DisplayServer.WINDOW_MODE_WINDOWED)

func _on_vsync_check_box_toggled(button_pressed):
	vsync = button_pressed
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)

func _on_show_fps_check_box_toggled(button_pressed):
	show_fps = button_pressed
	_update_fps_counter()

func _on_username_input_text_changed(new_text):
	username = new_text

func _on_apply_settings_button_up():
	apply_settings()
	save_settings()

func _on_back_button_button_up() -> void:
	set_ui("mainmenu")
	save_settings()

# === Navigation Buttons ===

func _on_settings_button_up() -> void:
	set_ui("settings")

func _on_credits_button_up() -> void:
	$MainMenu.hide()
	$Credits.show()

func _on_quit_button_up() -> void:
	get_tree().quit()

# === Chat System ===

func _setup_chat():
	$ChatContainer/SendButton.connect("button_up", _send_chat_message)
	$ChatContainer/ChatInput.connect("text_submitted", _send_chat_message)
	$ChatContainer/ToggleButton.connect("button_up", _on_chat_toggle_button_pressed)
	
	NetworkManager.chat_message_received.connect(add_chat_message)

func _send_chat_message(_e = null):
	var message_text = $ChatContainer/ChatInput.text.strip_edges()
	if message_text.length() > 0:
		if NetworkManager.socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
			NetworkManager.send_global_chat_message(message_text)
			$ChatContainer/ChatInput.text = ""

func add_chat_message(sender, message):
	# Create message with timestamp
	var timestamp = Time.get_datetime_string_from_system(false, true).split(" ")[1].substr(0, 5)
	var formatted_message = "[" + timestamp + "] " + sender + ": " + message
	
	# Add to history with size limit
	chat_history.append(formatted_message)
	if chat_history.size() > max_chat_messages:
		chat_history.pop_front()
	
	_update_chat_display()

func _update_chat_display():
	var display_text = ""
	for message in chat_history:
		display_text += message + "\n"
	
	$ChatContainer/ChatDisplay.text = display_text
	$ChatContainer/ChatDisplay.scroll_vertical = $ChatContainer/ChatDisplay.get_v_scroll_bar().max_value

func _on_chat_toggle_button_pressed():
	chat_visible = !chat_visible
	$ChatContainer.visible = chat_visible
	save_settings()
