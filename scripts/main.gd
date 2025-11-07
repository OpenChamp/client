## === Main Script === ##
class_name OpenChamp
extends Node

var external_client_used: bool = false

func _ready():
	# Load initial settings and args
	load_args()

	if ConfigManager.debug:
		ConfigManager.show_debug_overlay()

	if ConfigManager.client_mode == ConfigManager.CLIENTMODE.DEDICATED_SERVER || external_client_used:
		get_tree().call_deferred("change_scene_to_file", "res://scenes/game/ingame.tscn")
	else:
		get_tree().call_deferred("change_scene_to_file", "res://scenes/ui/menu_controller.tscn")

func load_args():
	# Args should only modify Global/ConfigManager variables, as values will change between scenes otherwise.
	var args = OS.get_cmdline_args()
	for i in range(args.size()):
		match args[i]:
			# === Auth === #
			"-t", "--token":
				if i + 1 < args.size():
					WSManager.auth_token = args[i + 1]
			"-ws", "--websocket":
				if i + 1 < args.size():
					WSManager.websocket_url = args[i + 1]
			# === Config === #
			"--fullscreen":
				ConfigManager.update_in_game_setting("video", "fullscreen", true)
			"--windowed":
				ConfigManager.update_in_game_setting("video", "fullscreen", false)
			"--vsync":
				ConfigManager.update_in_game_setting("video", "vsync", true)
			"--novsync":
				ConfigManager.update_in_game_setting("video", "vsync", false)
			"--showfps":
				ConfigManager.update_in_game_setting("video", "show_fps", true)
			"--hidefps":
				ConfigManager.update_in_game_setting("video", "show_fps", false)
			# === Audio === #
			"-mv", "--mastervolume":
				if i + 1 < args.size():
					ConfigManager.update_in_game_setting("audio", "master_volume", float(args[i + 1]))
			"-muv", "--musicvolume":
				if i + 1 < args.size():
					ConfigManager.update_in_game_setting("audio", "music_volume", float(args[i + 1]))
			"-sfxv", "--sfxvolume":
				if i + 1 < args.size():
					ConfigManager.update_in_game_setting("audio", "sfx_volume", float(args[i + 1]))
			# === Game Server === #
			"-gm", "--gamemode":
				if i + 1 < args.size():
					ConfigManager.update_in_game_setting("game", "game_mode", args[i + 1])
			"-ip", "--host":
				if i + 1 < args.size():
					ConfigManager.update_in_game_setting("network", "server_ip", args[i + 1])
					external_client_used = true
			"-m", "--map":
				if i + 1 < args.size():
					ConfigManager.update_in_game_setting("game", "map_name", args[i + 1])
			"-mp", "--maxplayers":
				if i + 1 < args.size():
					ConfigManager.update_in_game_setting("game", "max_players", int(args[i + 1]))
			"-p", "--port":
				if i + 1 < args.size():
					ConfigManager.update_in_game_setting("network", "port", int(args[i + 1]))
			"-sid", "--serverid":
				if i + 1 < args.size():
					ConfigManager.update_in_game_setting("network", "server_id", args[i + 1])
			# === Client === #
			"-c", "--client":
				# Set mode to client
				ConfigManager.client_mode = ConfigManager.CLIENTMODE.CLIENT
			"-ds", "--dedicated":
				ConfigManager.client_mode = ConfigManager.CLIENTMODE.DEDICATED_SERVER
			"-o", "--offline":
				ConfigManager.client_mode = ConfigManager.CLIENTMODE.OFFLINE
				
			# === Debug === #
			"-debug": # (--debug is used for the engine itself)
				ConfigManager.debug = true
