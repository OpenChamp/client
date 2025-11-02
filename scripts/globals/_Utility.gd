extends Node

# Settings variables
var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var fullscreen: bool = false
var vsync: bool = true
var username: String = "Player"
var show_fps: bool = false
var debug: bool = true

# Config file handling
const SETTINGS_PATH := "user://settings.cfg"
const AUTH_TOKEN_PATH := "user://auth.dat"
var config := ConfigFile.new()

# Args Variables
var server_id: String = ""
var ip: String = ""
var player_id: String = ""
var map_name: String = ""
var game_mode: String = ""
var dedicated_server: bool = false

# Server Args Variables
var port := 7000
var max_players := 10
var players := {}
var player_sessions
var player_ids = []


func _process(_d: float):
	var fps = Engine.get_frames_per_second()
	# For multi-server stress testing script
	if debug and dedicated_server:
		# print("FPS: " + str(fps))
		pass
	if show_fps:
		get_node("FPSCounter").text = "FPS: " + str(fps)
	if dedicated_server:
		_update_debug_overlay()


##===== Settings =====##

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
	NetworkManager.websocket_url = config.get_value("network", "websocket_url", "ws://127.0.0.1:8080/ws")
	NetworkManager.token = config.get_value("network", "token", "")

	toggle_fps_counter(show_fps)


func save_settings():
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", 1.0)
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("video", "vsync", vsync)
	config.set_value("video", "show_fps", show_fps)
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


func set_up():
	load_settings()
	load_args()
	if debug:
		show_debug_overlay()


##===== Auth =====##

func get_token():
	var token_file = FileAccess.open(AUTH_TOKEN_PATH, FileAccess.READ)
	if token_file:
		return token_file.get_as_text()
	else:
		return ""


func set_token(new_token):
	var token_file = FileAccess.open(AUTH_TOKEN_PATH, FileAccess.WRITE)
	token_file.store_string(new_token)
	return true



##===== Args =====##

func load_args():
	var args = OS.get_cmdline_args()
	var env_players = OS.get_environment("PLAYERS_JSON")
	var raw_players
	if env_players:
		raw_players = JSON.parse_string(env_players)  # Passed in by portmanager in go
	if raw_players:
		for player in raw_players:
			players[player["id"]] = {"name": player["Username"], "connected": false, "nodepath": null}
			player_ids.append(player["id"])
	for i in range(args.size()):
		match args[i]:
			"-ip", "--host":
				if i + 1 < args.size():
					ip = args[i + 1]
			"-sid", "--serverid":
				if i + 1 < args.size():
					server_id = args[i + 1]
			"-ws", "--webid":
				if i + 1 < args.size():
					player_id = args[i + 1]
			"-p", "--port":
				if i + 1 < args.size():
					port = int(args[i + 1])
					print("Port Set")
			"-m", "--map":
				if i + 1 < args.size():
					map_name = args[i + 1]
			"-mp", "--maxplayers":
				if i + 1 < args.size():
					max_players = int(args[i + 1])
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

func show_debug_overlay():
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
	username_label.text = "Username: " + username
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

	print("Debug overlay displayed")


func _update_debug_overlay():
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
				if players.has(peer_id):
					ping = str(players[peer_id].ping)
				player_label.text = players[peer_id]["name"] + " - " + ping
				player_label.add_theme_color_override("font_color", Color.WHITE)
				player_label.add_theme_color_override("font_shadow_color", Color.BLACK)
				player_label.add_theme_constant_override("shadow_offset_x", 1)
				player_label.add_theme_constant_override("shadow_offset_y", 1)
				player_list.add_child(player_label)


func toggle_fps_counter(on: bool = false):
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
