extends Node

const Logger = preload("res://addons/delta_rollback/Logger.gd")
const DummyNetworkAdaptor = preload("res://addons/delta_rollback/DummyNetworkAdaptor.gd")

const GAME_PORT_SETTING = 'network/rollback/log_inspector/replay_port'
const MATCH_SCENE_PATH_SETTING = 'network/rollback/log_inspector/replay_match_scene_path'
const MATCH_SCENE_METHOD_SETTING = 'network/rollback/log_inspector/replay_match_scene_method'

var active := false
var connection: StreamPeerTCP

var match_scene_path: String
var match_scene_method: String = 'setup_match_for_replay'

var _setting_up_match := false

func _ready() -> void:
	if "replay" in OS.get_cmdline_args():
		if not ProjectSettings.has_setting(MATCH_SCENE_PATH_SETTING):
			_show_error_and_quit("Match scene not configured for replay")
			return
		match_scene_path = ProjectSettings.get_setting(MATCH_SCENE_PATH_SETTING)
		
		if ProjectSettings.has_setting(MATCH_SCENE_METHOD_SETTING):
			match_scene_method = ProjectSettings.get_setting(MATCH_SCENE_METHOD_SETTING)
		
		active = true
		
		print ("Connecting to replay server...")
		if not connect_to_replay_server():
			_show_error_and_quit("Unable to connect to replay server")
			return

func _show_error_and_quit(msg: String) -> void:
	OS.alert(msg)
	get_tree().quit(1)

func connect_to_replay_server() -> bool:
	if is_connected_to_replay_server():
		return true
	
	if connection:
		connection.disconnect_from_host()
		connection = null
	
	var port = 49111
	if ProjectSettings.has_setting(GAME_PORT_SETTING):
		port = ProjectSettings.get_setting(GAME_PORT_SETTING)
	
	connection = StreamPeerTCP.new()
	return connection.connect_to_host('127.0.0.1', port) == OK

func is_connected_to_replay_server() -> bool:
	return connection and connection.is_connected_to_host()

func poll() -> void:
	if not active:
		return
	if connection:
		connection.poll()
		var status = connection.get_status()
		if status == StreamPeerTCP.STATUS_CONNECTED:
			while not _setting_up_match and connection.get_available_bytes() >= 4:
				var data = connection.get_var()
				if data is Dictionary:
					process_message(data)
		elif status == StreamPeerTCP.STATUS_NONE:
			get_tree().quit()
		elif status == StreamPeerTCP.STATUS_ERROR:
			OS.alert("Error in connection to replay server")
			get_tree().quit(1)

func _process(delta: float) -> void:
	poll()

func process_message(msg: Dictionary) -> void:
	if not msg.has('type'):
		push_error("SyncReplay message has no 'type' property: %s" % msg)
		return
	
	var type = msg['type']
	match type:
		"setup_match":
			var my_peer_id = msg.get('my_peer_id', 1)
			var peer_ids = msg.get('peer_ids', [])
			var match_info = msg.get('match_info', {})
			_do_setup_match1(my_peer_id, peer_ids, match_info)
		
		"load_state":
			var state = msg.get('state', {})
			var events = msg.get('events', {})
			_do_load_state(state, events)
		
		"execute_frame":
			_do_execute_frame(msg)
			
		_:
			push_error("SyncReplay message has unknown type: %s" % type)

func _do_setup_match1(my_peer_id: int, peer_ids: Array, match_info: Dictionary) -> void:
	SyncManager.stop()
	SyncManager.clear_peers()
	
	SyncManager.network_adaptor = DummyNetworkAdaptor.new(my_peer_id)
	SyncManager.mechanized = true
	
	for peer_id in peer_ids:
		SyncManager.add_peer(peer_id)
	
	var match_scene = load(match_scene_path).instantiate()
	if match_scene.has_method("set_launched_from_SyncReplay"):
		match_scene.set_launched_from_SyncReplay()
	var tree = get_tree()
	tree.current_scene.free()
	tree.root.add_child(match_scene)
	tree.current_scene = match_scene
	
	_setting_up_match = true
	call_deferred("_do_setup_match2", my_peer_id, peer_ids, match_info)

func _do_setup_match2(my_peer_id: int, peer_ids: Array, match_info: Dictionary) -> void:
	_setting_up_match = false
	
	var match_scene = get_tree().current_scene
	
	if not match_scene.has_method(match_scene_method):
		_show_error_and_quit("Match scene has no such method: %s" % match_scene_method)
		return
	
	# Call the scene's setup method.
	match_scene.call(match_scene_method, my_peer_id, peer_ids, match_info)

	SyncManager.start()

func _do_load_state(state: Dictionary, events: Dictionary) -> void:
	state = SyncManager.sync_booster.unserialize(state)
	events = SyncManager.sync_booster.unserialize(events)
	SyncManager._call_load_state_forward(state, events)

func _do_execute_frame(msg: Dictionary) -> void:
	var frame_type: int = msg['frame_type']
	var input_frames_received: Dictionary = msg.get('input_frames_received', {})
	var rollback_ticks: int = msg.get('rollback_ticks', 0)
	
	input_frames_received = SyncManager.sync_booster.unserialize(input_frames_received)
	SyncManager.mechanized_input_received = input_frames_received
	SyncManager.mechanized_rollback_ticks = rollback_ticks
	
	match frame_type:
		Logger.FrameType.TICK:
			SyncManager.execute_mechanized_tick()
		
		Logger.FrameType.INTERPOLATION_FRAME:
			SyncManager.execute_mechanized_interpolation_frame(msg['delta'])
		
		Logger.FrameType.INTERFRAME:
			SyncManager.execute_mechanized_interframe()
		
		_:
			SyncManager.reset_mechanized_data()
