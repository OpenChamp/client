# === Clients Only === #
extends Node

var is_queued: bool = false
var chat_visible: bool = true
var chat_history: Array = []
var max_chat_messages: int = 100

func _ready():
	# Initialize UI
	set_ui("connect")
	$LogoLabel.add_theme_color_override("default_color", Color(255,0,0, 0))
	
	# Initialize settings UI
	_init_settings_ui()
	Util.apply_settings()
	
	# Set up match found overlay
	var match_overlay = ColorRect.new()
	match_overlay.name = "MatchFoundOverlay"
	match_overlay.color = Color(0, 0, 0, 0.8)  # Semi-transparent black
	match_overlay.hide()
	match_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)  # Fill entire screen
	
	var match_label = Label.new()
	match_label.name = "MatchFoundLabel"
	match_label.text = "MATCH FOUND"
	match_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	match_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	match_label.add_theme_font_size_override("font_size", 64)
	match_label.set_anchors_preset(Control.PRESET_CENTER)
	
	match_overlay.add_child(match_label)
	add_child(match_overlay)
	
	# Prepare for auth requirement before login
	NetworkManager.auth_required.connect(func():set_ui("register"))
	NetworkManager.auth_obtained.connect(func():print("Auth Obtained"); _setup_chat(); open_main_menu())
	NetworkManager.match_found.connect(func():_match_found())
	NetworkManager.ws_connecting.connect(func():$ConnectionButton.text = "Attempting Connection... [" + str(int(NetworkManager.connection_time)) + "]")
	NetworkManager.ws_connected.connect(func():
		print("Attmepting Auth")
		if Util.get_token():
			NetworkManager.auth_with_token()
		else:
			set_ui("register")
	)
	# Check Login
	_on_connection_button_button_up()

func _process(_delta):
	pass
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
	$Register.hide()
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
			$PlayerCount.show()
			$MainMenu.show()
			$ChatContainer.show()
		"register":
			$Register.show()
		"settings":
			$Settings.show()

func _init_settings_ui():
	$Settings/MasterVolumeSlider.value = Util.master_volume * 100
	$Settings/MusicVolumeSlider.value = Util.music_volume * 100
	$Settings/SFXVolumeSlider.value = Util.sfx_volume * 100
	$Settings/FullscreenCheckBox.button_pressed = Util.fullscreen
	$Settings/VSyncCheckBox.button_pressed = Util.vsync
	$Settings/ShowFPSCheckBox.button_pressed = Util.show_fps
	$Settings/UsernameInput.text = Util.username

# === Connection Management ===
func _on_connection_button_button_up() -> void:
	set_ui("connecting")
	NetworkManager.connect_to_server()

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
	add_chat_message("System", "Connected to server. Welcome, " + Util.username + "!")

func setup_player_count():
	var timer = Timer.new()
	timer.set_wait_time(5)
	timer.set_one_shot(false)
	timer.connect("timeout", update_player_count)
	add_child(timer)
	timer.start()

func update_player_count():
	NetworkManager.get_player_count()
	$PlayerCount.text = "[right]Players Online: [color=green]" + str(NetworkManager.player_count) + "[/color][/right]"

func _on_start_queue_button_up() -> void:
	is_queued = !is_queued
	if is_queued:
		NetworkManager.join_queue()
		$MainMenu/StartQueue.text = "Stop"
		add_chat_message("System", "You joined the queue.")
	else:
		NetworkManager.leave_queue()
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

# === Settings UI Signal Handlers ===

func _on_master_volume_slider_value_changed(value):
	Util.master_volume = value / 100.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(Util.master_volume))

func _on_music_volume_slider_value_changed(value):
	Util.music_volume = value / 100.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(Util.music_volume))

func _on_sfx_volume_slider_value_changed(value):
	Util.sfx_volume = value / 100.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(Util.sfx_volume))

func _on_fullscreen_check_box_toggled(button_pressed):
	Util.fullscreen = button_pressed
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if button_pressed else DisplayServer.WINDOW_MODE_WINDOWED)

func _on_vsync_check_box_toggled(button_pressed):
	Util.vsync = button_pressed
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if Util.vsync else DisplayServer.VSYNC_DISABLED)

func _on_show_fps_check_box_toggled(button_pressed):
	print(button_pressed)
	Util.toggle_fps_counter(button_pressed)

func _on_username_input_text_changed(new_text):
	Util.username = new_text

func _on_apply_settings_button_up():
	Util.apply_settings()
	Util.save_settings()

func _on_back_button_button_up() -> void:
	set_ui("mainmenu")
	Util.save_settings()

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
		if NetworkManager.is_ws_connected:
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
	Util.save_settings()


func _on_local_connect_button_up() -> void:
	pass # Replace with function body.


func _on_save_username_button_button_up() -> void:
	# Fast Registration
	NetworkManager.fast_registration($Register/VBoxContainer/UsernameInput.text)
	pass # Replace with function body.

func _match_found() -> void:
	var overlay = $MatchFoundOverlay
	var label = $MatchFoundOverlay/MatchFoundLabel
	
	# Show the overlay
	overlay.show()
	
	# Create a fade-in tween for the overlay
	var overlay_tween = create_tween()
	overlay_tween.tween_property(overlay, "modulate", Color(1, 1, 1, 1), 0.5)
	
	# Create a tween sequence for the label
	var label_tween = create_tween()
	label_tween.set_parallel(false)  # Make animations sequential
	
	# Fade in and scale up
	label_tween.tween_property(label, "modulate", Color(1, 1, 1, 1), 0.5)
	label_tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.3)
	
	# Pulse animation
	label_tween.tween_property(label, "scale", Vector2(1, 1), 0.3)
	label_tween.tween_property(label, "scale", Vector2(1.1, 1.1), 0.3)
	label_tween.tween_property(label, "scale", Vector2(1, 1), 0.3)
	
	# Wait a bit then transition to the game
	await get_tree().create_timer(3.0).timeout
	
	# Fade out everything
	var final_tween = create_tween()
	final_tween.tween_property(overlay, "modulate", Color(1, 1, 1, 0), 0.5)
	
	# Wait for fade out then change scene
	await final_tween.finished
	get_tree().change_scene_to_file("res://scenes/game.tscn")
