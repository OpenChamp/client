class_name ConfigurationManager
extends Node

signal settings_changed

# Config file handling
const SETTINGS_PATH := "user://settings.cfg"
const AUTH_TOKEN_PATH := "user://auth.dat"

var config_file := ConfigFile.new()
var game_config: GameConfiguration = GameConfiguration.new()

var client_mode: CLIENTMODE = CLIENTMODE.CLIENT

var debug = false

var username := "Player" # Possibly temporary

enum CLIENTMODE {
	OFFLINE,
	CLIENT,
	DEDICATED_SERVER,
}

func _ready() -> void:
	load_settings()


##===== Settings File =====##

func load_settings() -> void:
	"""Load settings from disk into ConfigFile."""
	var err := config_file.load(SETTINGS_PATH)
	if err != OK:
		push_warning("ConfigManager: No settings file found, using defaults")
	settings_changed.emit()

func save_settings(settings: Dictionary) -> void:
	"""Update ConfigFile from settings dictionary."""
	for section in settings:
		if settings[section] is Dictionary:
			for key in settings[section]:
				config_file.set_value(section, key, settings[section][key])
	
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

func _get_settings_from_file() -> Dictionary:
	"""Convert ConfigFile to a dictionary for easier access."""
	var settings := {}
	for section in config_file.get_sections():
		settings[section] = {}
		for key in config_file.get_section_keys(section):
			settings[section][key] = config_file.get_value(section, key)
	return settings

##===== Auth Token Handling =====##
func save_auth_token(token: String) -> void:
	"""Save authentication token to disk."""
	set_game_setting("network", "player_auth_token", token)
	
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

##===== In-Game Configuration =====##
class GameConfiguration:
	"""Holds in-game configuration settings."""
	var server_id: String = ""
	var server_ip: String = ""
	var player_name: String = ""
	var player_auth_token: String = ""
	var map_name: String = ""
	var game_mode: String = ""
	var max_players: int = 10
	
	# Dictionary mapping for cleaner access
	var _config_map := {
		"network": {
			"server_id": &"server_id",
			"server_ip": &"server_ip",
			"player_name": &"player_name",
			"player_auth_token": &"player_auth_token",
		},
		"game": {
			"map_name": &"map_name",
			"game_mode": &"game_mode",
			"max_players": &"max_players",
		}
	}
	
	func set_value(section: String, key: String, value) -> void:
		if _config_map.has(section) and _config_map[section].has(key):
			set(_config_map[section][key], value)
	
	func get_value(section: String, key: String):
		if _config_map.has(section) and _config_map[section].has(key):
			return get(_config_map[section][key])
		return null

func set_game_setting(section: String, key: String, value) -> void:
	"""Set an in-game configuration value."""
	game_config.set_value(section, key, value)
	settings_changed.emit()
	print("ConfigManager: In-game setting updated: [%s] %s = %s" % [section, key, str(value)])

func get_game_setting(section: String, key: String):
	"""Get an in-game configuration value."""
	return game_config.get_value(section, key)

func get_in_game_configuration() -> GameConfiguration:
	"""Get the entire game configuration object."""
	return game_config
