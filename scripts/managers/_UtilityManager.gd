extends Node

# Config file handling
const SETTINGS_PATH := "user://settings.cfg"
const AUTH_TOKEN_PATH := "user://auth.dat"
var config := ConfigFile.new()

# Args Variables (Utility owns these - set once at startup)
var server_id: String = ""
var ip: String = ""
var player_id: String = ""
var map_name: String = ""
var game_mode: String = ""
var dedicated_server: bool = false
var dedicated_client: bool = false

# Server Args Variables
#var port := 7000
#var max_players := 10
#var players := {}
#var player_sessions
#var player_ids = []

# Debug mode
var debug: bool = true

func _process(_d: float):
	var fps = Engine.get_frames_per_second()
	if debug and dedicated_server:
		# print("FPS: " + str(fps))
		pass
	if has_node("FPSCounter"):
		get_node("FPSCounter").text = "FPS: " + str(fps)
	if dedicated_server:
		_update_debug_overlay()


##===== Settings I/O =====##

func load_settings() -> void:
	var err = config.load(SETTINGS_PATH)
	if err != OK:
		print("Util: No settings file found, using defaults")

func get_config() -> Dictionary:
	## Returns settings as a dictionary for GameManager
	return {
		"audio": {
			"master_volume": config.get_value("audio", "master_volume", 1.0),
			"music_volume": config.get_value("audio", "music_volume", 1.0),
			"sfx_volume": config.get_value("audio", "sfx_volume", 1.0),
		},
		"video": {
			"fullscreen": config.get_value("video", "fullscreen", false),
			"vsync": config.get_value("video", "vsync", true),
			"show_fps": config.get_value("video", "show_fps", false),
		},
		"network": {
			"websocket_url": config.get_value("network", "websocket_url", "ws://127.0.0.1:8080/ws"),
			"token": config.get_value("network", "token", ""),
		}
	}

func save_settings(settings: Dictionary) -> void:
	# Update ConfigFile from settings dictionary
	if settings.has("audio"):
		for key in settings["audio"]:
			config.set_value("audio", key, settings["audio"][key])
	if settings.has("video"):
		for key in settings["video"]:
			config.set_value("video", key, settings["video"][key])
	if settings.has("network"):
		for key in settings["network"]:
			config.set_value("network", key, settings["network"][key])
	
	config.save(SETTINGS_PATH)
	print("Util: Settings saved to disk")

func apply_settings(settings: Dictionary) -> void:
	## Apply settings to engine
	# Audio settings
	if settings.has("audio"):
		if settings["audio"].has("master_volume"):
			AudioServer.set_bus_volume_db(0, linear_to_db(settings["audio"]["master_volume"]))
	
	# Video settings
	if settings.has("video"):
		if settings["video"].has("fullscreen"):
			var target_mode = DisplayServer.WINDOW_MODE_FULLSCREEN if settings["video"]["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
			DisplayServer.window_set_mode(target_mode)
		
		if settings["video"].has("vsync"):
			var vsync_mode = DisplayServer.VSYNC_ENABLED if settings["video"]["vsync"] else DisplayServer.VSYNC_DISABLED
			DisplayServer.window_set_vsync_mode(vsync_mode)
		
		if settings["video"].has("show_fps"):
			toggle_fps_counter(settings["video"]["show_fps"])
	
	print("Util: Settings applied")

func load_server_config(_config_path: String) -> void:
	# TODO: Add config path reading settings
	pass


##===== Auth I/O =====##

func get_token() -> String:
	var token_file = FileAccess.open(AUTH_TOKEN_PATH, FileAccess.READ)
	if token_file:
		return token_file.get_as_text()
	return ""

func set_token(new_token: String) -> bool:
	var token_file = FileAccess.open(AUTH_TOKEN_PATH, FileAccess.WRITE)
	if token_file:
		token_file.store_string(new_token)
		return true
	return false


##===== Command Line Args =====##

func load_args() -> void:
	var args = OS.get_cmdline_args()
	var env_players = OS.get_environment("PLAYERS_JSON")
	if (env_players): NetworkManager.set_player_whitelist(JSON.parse_string(env_players))
	for i in range(args.size()):
		match args[i]:
			# === Network === #
			"-ip", "--host":
				if i + 1 < args.size():
					ip = args[i + 1]
			"-ws", "--webid":
				if i + 1 < args.size():
					player_id = args[i + 1]
			# === Auth === #
			
			# === Config === #
			
			# === Server === #
			
			# === Client === #
			"-c", "--client":
				dedicated_client = true
			"-sid", "--serverid":
				if i + 1 < args.size():
					server_id = args[i + 1]
			
			"-p", "--port":
				if i + 1 < args.size():
					NetworkManager.port = int(args[i + 1])
					print("Port Set")
			"-m", "--map":
				if i + 1 < args.size():
					map_name = args[i + 1]
			"-mp", "--maxplayers":
				if i + 1 < args.size():
					NetworkManager.max_connections = int(args[i + 1])
			"-gm", "--gamemode":
				if i + 1 < args.size():
					game_mode = args[i + 1]
			"-ds", "--dedicated":
				dedicated_server = true


##===== Helper Functions =====##

func get_mouse_vector3() -> Vector3:
	var viewport = get_viewport()
	var mouse_screen_pos = viewport.get_mouse_position()
	var from = viewport.get_camera_3d().project_ray_origin(mouse_screen_pos)
	var to = from + viewport.get_camera_3d().project_ray_normal(mouse_screen_pos) * 1000
	var space_state = get_window().get_world_3d().direct_space_state
	var ray_params = PhysicsRayQueryParameters3D.new()
	ray_params.from = from
	ray_params.to = to
	var result = space_state.intersect_ray(ray_params)
	if result:
		return result.position
	return Vector3.ZERO


##===== Debug Overlay =====##

func show_debug_overlay() -> void:
	# Check if debug overlay already exists
	if has_node("DebugOverlay"):
		return

	# Create container
	var debug_container = VBoxContainer.new()
	debug_container.name = "DebugOverlay"

	# Position in upper right corner
	debug_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	debug_container.position.x -= 250  # Offset from right edge (wider for player list)
	debug_container.position.y += 10   # Offset from top edge

	# Create gametype label
	var gametype_label = Label.new()
	var gametype = "Dedicated" if dedicated_server else "Client"
	gametype_label.text = "Gametype: " + gametype
	gametype_label.add_theme_color_override("font_color", Color.WHITE)
	gametype_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	gametype_label.add_theme_constant_override("shadow_offset_x", 1)
	gametype_label.add_theme_constant_override("shadow_offset_y", 1)

	# Create username label
	var username_label = Label.new()
	username_label.text = "Username: " + (GameManager.config.get("network", {}).get("username", "Player") if GameManager.config else "Player")
	username_label.add_theme_color_override("font_color", Color.WHITE)
	username_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	username_label.add_theme_constant_override("shadow_offset_x", 1)
	username_label.add_theme_constant_override("shadow_offset_y", 1)

	# Add labels to container
	debug_container.add_child(gametype_label)
	debug_container.add_child(username_label)

	# If dedicated server, add player list
	if dedicated_server:
		var separator = HSeparator.new()
		debug_container.add_child(separator)

		var players_title = Label.new()
		players_title.text = "Connected Players:"
		players_title.add_theme_color_override("font_color", Color.YELLOW)
		players_title.add_theme_color_override("font_shadow_color", Color.BLACK)
		players_title.add_theme_constant_override("shadow_offset_x", 1)
		players_title.add_theme_constant_override("shadow_offset_y", 1)
		debug_container.add_child(players_title)

		# Create player list container
		var player_list = VBoxContainer.new()
		player_list.name = "PlayerList"
		debug_container.add_child(player_list)

		# Start timer to update player list
		var update_timer = Timer.new()
		update_timer.name = "DebugUpdateTimer"
		update_timer.wait_time = 1.0  # Update every second
		update_timer.timeout.connect(_update_debug_overlay)
		update_timer.autostart = true
		debug_container.add_child(update_timer)

	# Add to scene tree
	add_child(debug_container)

	print("Util: Debug overlay displayed")


func _update_debug_overlay() -> void:
	if not has_node("DebugOverlay/PlayerList"):
		return

	var player_list = get_node("DebugOverlay/PlayerList")

	# Clear existing player entries
	for child in player_list.get_children():
		child.queue_free()

	# Get connected peers
	if multiplayer and multiplayer.multiplayer_peer:
		var connected_peers = multiplayer.get_peers()

		if connected_peers.size() == 0:
			var no_players = Label.new()
			no_players.text = "No players connected"
			no_players.add_theme_color_override("font_color", Color.GRAY)
			no_players.add_theme_color_override("font_shadow_color", Color.BLACK)
			no_players.add_theme_constant_override("shadow_offset_x", 1)
			no_players.add_theme_constant_override("shadow_offset_y", 1)
			player_list.add_child(no_players)
		else:
			for peer_id in connected_peers:
				var player_label = Label.new()
				var ping = "N/A"
				if NetworkManager.players.has(peer_id):
					ping = str(NetworkManager.players[peer_id].ping)
				player_label.text = NetworkManager.players[peer_id]["name"] + " - " + ping
				player_label.add_theme_color_override("font_color", Color.WHITE)
				player_label.add_theme_color_override("font_shadow_color", Color.BLACK)
				player_label.add_theme_constant_override("shadow_offset_x", 1)
				player_label.add_theme_constant_override("shadow_offset_y", 1)
				player_list.add_child(player_label)


func toggle_fps_counter(on: bool = false) -> void:
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
