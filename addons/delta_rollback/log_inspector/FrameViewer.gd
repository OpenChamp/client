@tool
extends Control

const Logger = preload("res://addons/delta_rollback/Logger.gd")
const ReplayServer = preload("res://addons/delta_rollback/log_inspector/ReplayServer.gd")
const LogData = preload("res://addons/delta_rollback/log_inspector/LogData.gd")

@onready var time_field = $VBoxContainer/HBoxContainer/Time
@onready var seek_on_replay_peer_field = $VBoxContainer/HBoxContainer/SeekOnReplayPeerField
@onready var auto_replay_to_current_field = $VBoxContainer/HBoxContainer/ReplayContainer/HBoxContainer/AutoReplayToCurrentField
@onready var replay_to_current_button = $VBoxContainer/HBoxContainer/ReplayContainer/HBoxContainer/ReplayToCurrentButton
@onready var data_graph = $VBoxContainer/VSplitContainer/DataGraph
@onready var data_grid = $VBoxContainer/VSplitContainer/DataGrid
@onready var settings_dialog = $SettingsDialog

var log_data: LogData
var replay_server: ReplayServer
var replay_peer_id: int
var replay_frame: int = -1
var replay_last_interpolation_frame_time: int = 0

var current_frames := {}

func set_log_data(_log_data: LogData) -> void:
	log_data = _log_data
	data_graph.set_log_data(log_data)
	data_grid.set_log_data(log_data)
	settings_dialog.setup_settings_dialog(log_data, data_graph, data_grid)

func refresh_from_log_data() -> void:
	if log_data.is_loading():
		return

	time_field.max_value = log_data.end_time - log_data.start_time

	data_graph.refresh_from_log_data()
	data_grid.refresh_from_log_data()
	settings_dialog.refresh_from_log_data()

	replay_frame = -1
	_on_Time_value_changed(time_field.value)

func set_replay_server(_replay_server: ReplayServer) -> void:
	if replay_server != null:
		replay_server.game_disconnected.disconnect(self._on_replay_server_game_disconnected)

	replay_server = _replay_server

	if replay_server:
		replay_server.game_disconnected.connect(self._on_replay_server_game_disconnected)

func _on_replay_server_game_disconnected() -> void:
	replay_frame = -1

func set_replay_peer_id(_replay_peer_id: int) -> void:
	replay_peer_id = _replay_peer_id

func refresh_replay() -> void:
	replay_frame = -1
	if auto_replay_to_current_field.pressed:
		replay_to_current_frame()

func clear() -> void:
	current_frames.clear()
	refresh_from_log_data()

func _on_Time_value_changed(value: float) -> void:
	if log_data.is_loading():
		return

	var time := int(value)

	# Update our tracking of the current frame.
	for peer_id in log_data.peer_ids:
		var frame: LogData.FrameData = log_data.get_frame_by_time(peer_id, log_data.start_time + time)
		if frame:
			current_frames[peer_id] = frame.frame
		else:
			current_frames[peer_id] = 0

	data_graph.cursor_time = time
	data_grid.cursor_time = time

	if auto_replay_to_current_field.pressed:
		replay_to_current_frame()

func _on_PreviousFrameButton_pressed() -> void:
	jump_to_previous_frame()

func jump_to_previous_frame() -> void:
	if log_data.is_loading():
		return

	var frame_time := 0

	if seek_on_replay_peer_field.pressed:
		frame_time = _get_previous_frame_time_for_peer(replay_peer_id)
	else:
		for peer_id in current_frames:
			frame_time = int(max(frame_time, _get_previous_frame_time_for_peer(peer_id)))

	if frame_time > log_data.start_time:
		time_field.value = frame_time - log_data.start_time
	else:
		time_field.value = 0

func _get_previous_frame_time_for_peer(peer_id: int) -> int:
	var frame_id = current_frames[peer_id]
	if frame_id > 0:
		frame_id -= 1
	var frame: LogData.FrameData = log_data.get_frame(peer_id, frame_id)
	return frame.start_time

func _on_NextFrameButton_pressed() -> void:
	jump_to_next_frame()

func jump_to_next_frame() -> void:
	if log_data.is_loading():
		return

	var frame_time := log_data.end_time

	if seek_on_replay_peer_field.pressed:
		frame_time = _get_next_frame_time_for_peer(replay_peer_id)
	else:
		for peer_id in current_frames:
			var peer_frame_time = _get_next_frame_time_for_peer(peer_id)
			if peer_frame_time != 0:
				frame_time = int(min(frame_time, _get_next_frame_time_for_peer(peer_id)))

	if frame_time > log_data.start_time:
		time_field.value = frame_time - log_data.start_time
	else:
		time_field.value = 0

func _get_next_frame_time_for_peer(peer_id: int) -> int:
	var frame_id = current_frames[peer_id]
	if frame_id < log_data.get_frame_count(peer_id) - 1:
		frame_id += 1
		var frame: LogData.FrameData = log_data.get_frame(peer_id, frame_id)
		return frame.start_time
	return 0

func replay_to_current_frame() -> void:
	if not replay_server or not replay_server.is_connected_to_game():
		return
	if log_data.is_loading():
		return
	if log_data.peer_ids.size() == 0:
		return
	if not current_frames.has(replay_peer_id):
		return

	var current_frame_id: int = current_frames[replay_peer_id]

	# If replay_frame is ahead of current frame, we have to replay from the beginning.
	if replay_frame > current_frame_id:
		replay_frame = -1

	# Reset replay.
	if replay_frame == -1:
		replay_last_interpolation_frame_time = 0
		replay_server.send_match_info(log_data, replay_peer_id)

	replay_frame += 1
	for frame_id in range(replay_frame, log_data.frames[replay_peer_id].size()):
		if frame_id > current_frame_id:
			break
		var frame_data: LogData.FrameData = log_data.get_frame(replay_peer_id, frame_id)
		if frame_data.type == Logger.FrameType.TICK and frame_data.data.get('skipped', false):
			# Don't replay skipped ticks.
			continue
		_send_replay_frame_data(frame_data)

	replay_frame = current_frame_id

func _send_replay_frame_data(frame_data: LogData.FrameData) -> void:
	var frame_type: int = frame_data.data['frame_type']

	var msg := {
		type = "execute_frame",
		frame_type = frame_type,
		rollback_ticks = frame_data.data.get('rollback_ticks', 0),
	}

	var input_frames_received := {}

	if frame_type == Logger.FrameType.TICK:
		var tick = int(frame_data.data['tick'])
		if tick > 0:
			# Get input for local peer.
			input_frames_received[replay_peer_id] = {
				tick: log_data.input[tick].get_input_for_peer(replay_peer_id, replay_peer_id),
			}
		replay_last_interpolation_frame_time = frame_data.data['end_time']
	elif frame_type == Logger.FrameType.INTERPOLATION_FRAME:
		var start_time = frame_data.data['start_time']
		if replay_last_interpolation_frame_time > 0:
			msg['delta'] = (start_time - replay_last_interpolation_frame_time) / 1000.0
		else:
			# If we can't know the actual delta, let's use a small value that's
			# bigger than zero, arbitrarily 1.0/120.0
			msg['delta'] = 0.00833333
		replay_last_interpolation_frame_time = start_time

	# Get input received from each of the peers.
	for peer_id in log_data.peer_ids:
		var ticks: Array = frame_data.data.get("remote_ticks_received_from_%s" % peer_id, [])
		if ticks.size() > 0:
			var peer_input_ticks := {}
			for tick in ticks:
				tick = int(tick)
				peer_input_ticks[tick] = log_data.input[tick].get_input_for_peer(peer_id, replay_peer_id)
			input_frames_received[peer_id] = peer_input_ticks
	msg['input_frames_received'] = input_frames_received

	replay_server.send_message(msg)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.pressed:
		if event.keycode == KEY_PAGEUP:
			jump_to_next_frame()
		elif event.keycode == KEY_PAGEDOWN:
			jump_to_previous_frame()
		elif event.keycode == KEY_UP:
			time_field.value += 1
		elif event.keycode == KEY_DOWN:
			time_field.value -= 1

func _on_StartButton_pressed() -> void:
	time_field.value = 0

func _on_EndButton_pressed() -> void:
	time_field.value = time_field.max_value

func _on_DataGraph_cursor_time_changed(cursor_time) -> void:
	time_field.value = cursor_time

func _on_SettingsButton_pressed() -> void:
	settings_dialog.popup_centered()

func _on_ReplayToCurrentButton_pressed() -> void:
	replay_to_current_frame()

func _on_AutoReplayToCurrentField_toggled(button_pressed: bool) -> void:
	replay_to_current_button.disabled = button_pressed
	if button_pressed:
		replay_to_current_frame()
