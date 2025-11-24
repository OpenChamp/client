class_name ConfigurationManager
extends Node

signal settings_changed

# Config file handling
const SETTINGS_PATH := "user://settings.cfg"
const AUTH_TOKEN_PATH := "user://auth.dat"

var config_file := ConfigFile.new()
var debug = false

func _ready() -> void:
	load_settings()

##===== Settings File =====##

func load_settings() -> void:
	var err := config_file.load(SETTINGS_PATH)
	if err != OK:
		push_warning("ConfigManager: No settings file found, using defaults")
	
	for section in config_file.get_sections():
		match section:
			"Hotkeys":
				load_hotkeys()
			"Video":
				load_video()

func save_settings() -> void:
	var err := config_file.save(SETTINGS_PATH)
	if err != OK:
		push_error("ConfigManager: Failed to save settings to disk")
	else:
		settings_changed.emit()
		print("ConfigManager: Settings saved to disk")

func apply_settings(settings: Dictionary) -> void:
	"""Apply settings to engine immediately."""
	# Audio settings
	if settings.has("audio") and settings["audio"].has("master_volume"):
		AudioServer.set_bus_volume_db(0, linear_to_db(settings["audio"]["master_volume"]))
	
	# Video settings
	if settings.has("video"):
		var video = settings["video"]
		if video.has("fullscreen"):
			var target_mode := DisplayServer.WINDOW_MODE_FULLSCREEN if video["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
			DisplayServer.window_set_mode(target_mode)
		
		if video.has("vsync"):
			var vsync_mode := DisplayServer.VSYNC_ENABLED if video["vsync"] else DisplayServer.VSYNC_DISABLED
			DisplayServer.window_set_vsync_mode(vsync_mode)
	
	settings_changed.emit()

func set_setting(section: String, key: String, value) -> void:
	"""Set a setting and apply it immediately. Does not save to disk."""
	config_file.set_value(section, key, value)
	var settings := _get_settings_from_file()
	apply_settings(settings)

func get_hotkey_overrides() -> PackedStringArray:
	return config_file.get_section_keys("Hotkeys")

func get_value(section, key):
	return config_file.get_value(section, key)

func _get_settings_from_file() -> Dictionary:
	"""Convert ConfigFile to a dictionary for easier access."""
	var settings := {}
	for section in config_file.get_sections():
		settings[section] = {}
		for key in config_file.get_section_keys(section):
			settings[section][key] = config_file.get_value(section, key)
	return settings

func load_hotkeys():
	for key in config_file.get_section_keys("Hotkeys"):
		set_keybind(key, config_file.get_value("Hotkeys", key) as InputEvent)
func load_video():
	push_error("Video settings not implemented");
	pass;
##===== Auth Token Handling =====##
func save_auth_token(token: String) -> void:
	"""Save authentication token to disk."""
	var file := FileAccess.open(AUTH_TOKEN_PATH, FileAccess.WRITE)
	if file:
		file.store_string(token)
		print("ConfigManager: Auth token saved")
	else:
		push_error("ConfigManager: Failed to save auth token")

func load_auth_token() -> String:
	"""Load authentication token from disk."""
	var file := FileAccess.open(AUTH_TOKEN_PATH, FileAccess.READ)
	if file:
		var token := file.get_as_text()
		return token
	
	push_warning("ConfigManager: No auth token found")
	return ""

##==== KeyBinding ====##
func reset_keybinds():
	InputMap.load_from_project_settings()

func set_keybind(key:String, value:InputEvent) -> bool:
	if !InputMap.has_action(key):
		push_error("Attempted to set unknown keybind:" + key)
		return false
	var events = InputMap.action_get_events(key)
	for event in events:
		InputMap.action_erase_event(key, event)
	
	InputMap.action_add_event(key, value)
	set_setting("Hotkeys", key, value)
	save_settings()
	return true;
	
