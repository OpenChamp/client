extends Node

# Settings variables
var master_volume : float = 1.0
var music_volume : float = 1.0
var sfx_volume : float = 1.0
var fullscreen : bool = false
var vsync : bool = true
var username : String = "Player"
var show_fps : bool = false
# Config file handling
const SETTINGS_PATH = "user://settings.cfg"
var config = ConfigFile.new()

func _process(_d:float):
	if show_fps:
		get_node("FPSCounter").text = "FPS: " + str(Engine.get_frames_per_second())

func load_settings():
	var err = config.load(SETTINGS_PATH)
	if err != OK:
		print("No settings file found, using defaults")
	
	master_volume = config.get_value("audio", "master_volume", 1.0)
	music_volume = config.get_value("audio", "music_volume", 1.0)
	sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
	fullscreen = config.get_value("video", "fullscreen", false)
	vsync = config.get_value("video", "vsync", true)
	show_fps = config.get_value("video", "show_fps", false)
	username = config.get_value("player", "username", "Player")
	NetworkManager.websocket_url = config.get_value("network", "websocket_url", "ws://localhost:8080/ws")
	NetworkManager.token = config.get_value("network", "token", "")
	
func save_settings():
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volumen", music_volume)
	config.set_value("audio", "sfx_volume", 1.0)
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("video", "vsync", vsync)
	config.set_value("video", "show_fps", show_fps)
	config.set_value("player", "username", username)
	config.set_value("network", "token", NetworkManager.token)
	config.set_value("network", "websocket_url", NetworkManager.websocket_url)
	config.save(SETTINGS_PATH)
	print("Configuration Saved")
	
func apply_settings():
	# Apply audio settings
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))
	
	# Apply video settings
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN != fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	
	# Apply FPS counter
	toggle_fps_counter(show_fps)
	
	# Apply username
	if NetworkManager and NetworkManager.Store.has("Username"):
		NetworkManager.Store["Username"] = username

func toggle_fps_counter(on:bool = false):
	print(on)
	show_fps = on
	if on:
		if not has_node("FPSCounter"):
			var fps_label = Label.new()
			fps_label.name = "FPSCounter"
			fps_label.text = "FPS: 0"
			fps_label.add_theme_color_override("font_color", Color(0, 1, 0))
			fps_label.position = Vector2(10, 10)
			add_child(fps_label)
	else:
		if has_node("FPSCounter"):
			get_node("FPSCounter").queue_free()
