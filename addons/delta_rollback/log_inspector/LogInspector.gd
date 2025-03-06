@tool
extends Window

const LogData = preload("res://addons/delta_rollback/log_inspector/LogData.gd")
const ReplayServer = preload("res://addons/delta_rollback/log_inspector/ReplayServer.gd")

@onready var file_dialog = $FileDialog
@onready var progress_dialog = $ProgressDialog
@onready var data_description_label = $MarginContainer/VBoxContainer/LoadToolbar/DataDescriptionLabel
@onready var data_description_label_default_text = data_description_label.text
@onready var mode_button = $MarginContainer/VBoxContainer/LoadToolbar/ModeButton
@onready var state_input_viewer = $MarginContainer/VBoxContainer/StateInputViewer
@onready var frame_viewer = $MarginContainer/VBoxContainer/FrameViewer
@onready var replay_server = $ReplayServer
@onready var replay_server_status_label = $MarginContainer/VBoxContainer/ReplayToolbar/ServerContainer/HBoxContainer/ReplayStatusLabel
@onready var start_server_button = $MarginContainer/VBoxContainer/ReplayToolbar/ServerContainer/HBoxContainer/StartServerButton
@onready var stop_server_button = $MarginContainer/VBoxContainer/ReplayToolbar/ServerContainer/HBoxContainer/StopServerButton
@onready var disconnect_button = $MarginContainer/VBoxContainer/ReplayToolbar/ServerContainer/HBoxContainer/DisconnectButton
@onready var launch_game_button = $MarginContainer/VBoxContainer/ReplayToolbar/ClientContainer/HBoxContainer/LaunchGameButton
@onready var show_peer_field = $MarginContainer/VBoxContainer/ReplayToolbar/ClientContainer/HBoxContainer/ShowPeerField

enum DataMode {
	STATE_INPUT,
	FRAME,
}

const LOADING_LABEL := "Loading %s..."

var log_data: LogData = LogData.new()

var _files_to_load := []

func _ready() -> void:
	state_input_viewer.set_log_data(log_data)
	frame_viewer.set_log_data(log_data)

	log_data.load_error.connect(self._on_log_data_load_error)
	log_data.load_progress.connect(self._on_log_data_load_progress)
	log_data.load_finished.connect(self._on_log_data_load_finished)
	log_data.data_updated.connect(self.refresh_from_log_data)

	state_input_viewer.set_replay_server(replay_server)
	frame_viewer.set_replay_server(replay_server)

	file_dialog.current_dir = OS.get_user_data_dir() + "/detailed_logs/"

	# Show and make full screen if the scene is being run on its own.
	if get_parent() == get_tree().root:
		visible = true
		start_log_inspector()
	else:
		visible = false

func _on_LogInspector_about_to_show() -> void:
	start_log_inspector()

func start_log_inspector() -> void:
	update_replay_server_status()
	replay_server.start_listening()

func set_editor_interface(editor_interface) -> void:
	replay_server.set_editor_interface(editor_interface)

func _on_ClearButton_pressed() -> void:
	if log_data.is_loading():
		return

	log_data.clear()
	data_description_label.text = data_description_label_default_text
	state_input_viewer.clear()
	frame_viewer.clear()

func _on_AddLogButton_pressed() -> void:
	file_dialog.current_file = ''
	file_dialog.current_path = ''
	file_dialog.popup_centered()
	file_dialog.invalidate()

func _on_FileDialog_files_selected(paths: PackedStringArray) -> void:
	if paths.size() > 0:
		var already_loading: bool = (_files_to_load.size() > 0) or log_data.is_loading()
		for path in paths:
			_files_to_load.append(path)
		if not already_loading:
			var first_file = _files_to_load.pop_front()
			progress_dialog.set_label(LOADING_LABEL % first_file.get_file())
			progress_dialog.popup_centered()
			log_data.load_log_file(first_file)

func refresh_from_log_data() -> void:
	if log_data.is_loading():
		return

	data_description_label.text = "%s logs (peer ids: %s) and %s ticks" % [log_data.peer_ids.size(), log_data.peer_ids, log_data.max_tick]
	if log_data.mismatches.size() > 0:
		data_description_label.text += " with %s mismatches" % log_data.mismatches.size()

	show_peer_field.clear()
	for peer_id in log_data.peer_ids:
		show_peer_field.add_item("Peer %s" % peer_id, peer_id)

	refresh_replay()
	state_input_viewer.refresh_from_log_data()
	frame_viewer.refresh_from_log_data()

func _on_log_data_load_error(msg) -> void:
	progress_dialog.hide()
	_files_to_load.clear()
	OS.alert(msg)

func _on_log_data_load_progress(current, total) -> void:
	progress_dialog.update_progress(current, total)

func _on_log_data_load_finished() -> void:
	if _files_to_load.size() > 0:
		var next_file = _files_to_load.pop_front()
		progress_dialog.set_label(LOADING_LABEL % next_file.get_file())
		log_data.load_log_file(next_file)
	else:
		progress_dialog.hide()

func _on_ModeButton_item_selected(index: int) -> void:
	state_input_viewer.visible = false
	frame_viewer.visible = false

	if index == DataMode.STATE_INPUT:
		state_input_viewer.visible = true
	elif index == DataMode.FRAME:
		frame_viewer.visible = true

	refresh_replay()

func _on_StartServerButton_pressed() -> void:
	replay_server.start_listening()

func _on_StopServerButton_pressed() -> void:
	if replay_server.is_connected_to_game():
		replay_server.disconnect_from_game(false)
	else:
		replay_server.stop_listening()

func update_replay_server_status() -> void:
	match replay_server.get_status():
		ReplayServer.Status.NONE:
			replay_server_status_label.text = 'Disabled.'
			start_server_button.disabled = false
			stop_server_button.disabled = true
			disconnect_button.disabled = true
			launch_game_button.disabled = true
		ReplayServer.Status.LISTENING:
			replay_server_status_label.text = 'Listening for connections...'
			start_server_button.disabled = true
			stop_server_button.disabled = false
			disconnect_button.disabled = true
			launch_game_button.disabled = false
		ReplayServer.Status.CONNECTED:
			replay_server_status_label.text = 'Connected to game.'
			start_server_button.disabled = true
			stop_server_button.disabled = false
			disconnect_button.disabled = false
			launch_game_button.disabled = true

func refresh_replay() -> void:
	var replay_peer_id = show_peer_field.get_selected_id()

	if replay_server:
		replay_server.send_match_info(log_data, replay_peer_id)

	state_input_viewer.set_replay_peer_id(replay_peer_id)
	frame_viewer.set_replay_peer_id(replay_peer_id)

	var mode = mode_button.selected
	if mode == DataMode.STATE_INPUT:
		state_input_viewer.refresh_replay()
	elif mode == DataMode.FRAME:
		frame_viewer.refresh_replay()

func _on_ReplayServer_started_listening() -> void:
	update_replay_server_status()

func _on_ReplayServer_stopped_listening() -> void:
	update_replay_server_status()

func _on_ReplayServer_game_connected() -> void:
	update_replay_server_status()
	refresh_replay()

func _on_ReplayServer_game_disconnected() -> void:
	update_replay_server_status()

func _on_LaunchGameButton_pressed() -> void:
	replay_server.launch_game()

func _on_DisconnectButton_pressed() -> void:
	replay_server.disconnect_from_game()

func _on_ShowPeerField_item_selected(index: int) -> void:
	refresh_replay()
