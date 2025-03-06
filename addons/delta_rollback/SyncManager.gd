@tool
extends Node

const PropertyManagerScript = preload("res://addons/delta_rollback/PropertyManager.gd")
const SpawnManager = preload("res://addons/delta_rollback/SpawnManager.gd")
const SoundManager = preload("res://addons/delta_rollback/SoundManager.gd")
const NetworkAdaptor = preload("res://addons/delta_rollback/NetworkAdaptor.gd")
const MessageSerializer = preload("res://addons/delta_rollback/MessageSerializer.gd")
const Logger = preload("res://addons/delta_rollback/Logger.gd")
const DebugStateComparer = preload("res://addons/delta_rollback/DebugStateComparer.gd")

class Peer extends RefCounted:
	var peer_id: int
	
	var rtt: int
	var last_ping_received: int
	var time_delta: float
	
	var last_remote_input_tick_received: int = 0
	var next_local_input_tick_requested: int = 1
	var last_remote_hash_tick_received: int = 0
	var next_local_hash_tick_requested: int = 1
	
	var remote_lag: int
	var local_lag: int
	
	var calculated_advantage: float
	var advantage_list := []
	
	func _init(_peer_id: int) -> void:
		peer_id = _peer_id
	
	func record_advantage(ticks_to_calculate_advantage: int) -> void:
		advantage_list.append(local_lag - remote_lag)
		if advantage_list.size() >= ticks_to_calculate_advantage:
			var total: float = 0
			for x in advantage_list:
				total += x
			calculated_advantage = total / advantage_list.size()
			advantage_list.clear()
	
	func clear_advantage() -> void:
		calculated_advantage = 0.0
		advantage_list.clear()
	
	func clear() -> void:
		rtt = 0
		last_ping_received = 0
		time_delta = 0
		last_remote_input_tick_received = 0
		next_local_input_tick_requested = 0
		last_remote_hash_tick_received = 0
		next_local_hash_tick_requested = 0
		remote_lag = 0
		local_lag = 0
		clear_advantage()

class StateBufferFrame:
	var tick: int
	var data: Dictionary

	func _init(_tick, _data) -> void:
		tick = _tick
		data = _data

class StateHashFrame:
	var tick: int
	var state_hash: int
	
	var peer_hashes := {}
	var mismatch := false
	
	func _init(_tick: int, _state_hash: int) -> void:
		tick = _tick
		state_hash = _state_hash
	
	func record_peer_hash(peer_id: int, peer_hash: int) -> bool:
		peer_hashes[peer_id] = peer_hash
		if peer_hash != state_hash:
			mismatch = true
			return false
		return true
	
	func has_peer_hash(peer_id: int) -> bool:
		return peer_hashes.has(peer_id)
	
	func is_complete(peers: Dictionary) -> bool:
		for peer_id in peers:
			if not peer_hashes.has(peer_id):
				return false
		return true
	
	func get_missing_peers(peers: Dictionary) -> Array:
		var missing := []
		for peer_id in peers:
			if not peer_hashes.has(peer_id):
				missing.append(peer_id)
		return missing

class EventBufferFrame:
	var tick: int
	var data: Dictionary

	func _init(_tick, _data) -> void:
		tick = _tick
		data = _data
	
	func _add_script_event(node_path: String, script_path: String) -> void:
		if not data.has(""):
			data[""] = []
		data[""].append({
			type = "script",
			node_path = node_path,
			script_path = script_path
		})

enum LoadType {
	ROLLBACK,
	INTERPOLATION_BACKWARD,
	INTERPOLATION_FORWARD,
}

const DEFAULT_NETWORK_ADAPTOR_PATH := "res://addons/delta_rollback/RPCNetworkAdaptor.gd"
const DEFAULT_MESSAGE_SERIALIZER_PATH := "res://addons/delta_rollback/MessageSerializer.gd"
const SYNC_DEBUGGER_PATH = "res://addons/delta_rollback/SyncDebugger.gd"

var network_adaptor: NetworkAdaptor:
	set = set_network_adaptor
var message_serializer: MessageSerializer:
	set = set_message_serializer
var sync_booster: = SyncBooster.new()

var peers := {}
var input_buffer := []
var state_buffer := []
var state_hashes := []
var event_buffer := []
var mechanized := false:
	set = set_mechanized
var mechanized_replay := false
var mechanized_input_received := {}
var mechanized_rollback_ticks := 0

var max_buffer_size := 20
var ticks_to_calculate_advantage := 60
var input_delay := 2:
	set = set_input_delay
var max_input_frames_per_message := 5
var max_messages_at_once := 2
var max_ticks_to_regain_sync := 300
var min_lag_to_regain_sync := 5
var interpolation := false
var max_state_mismatch_count := 10
var disable_event_registration := false

var debug_rollback_ticks := 0
var debug_random_rollback_ticks := 0
var debug_message_bytes := 700
var debug_skip_nth_message := 0
var debug_physics_process_msecs := 10.0
var debug_process_msecs := 10.0
var debug_check_message_serializer_roundtrip := false
var debug_check_local_state_consistency := false
var debug_use_sync_debugger := false


var ping_frequency := 1.0
var input_tick: int = 0
var current_tick: int = 0
var skip_ticks: int = 0
var rollback_ticks: int = 0
var requested_input_complete_tick: int = 0
var started := false
var load_type: int = LoadType.ROLLBACK
var tick_time: float

var _host_starting := false
var _ping_timer: Timer
var _spawn_manager
var _property_manager
var _sound_manager
var _logger
var _input_buffer_start_tick: int
var _state_buffer_start_tick: int
var _state_hashes_start_tick: int
var _input_send_queue := []
var _input_send_queue_start_tick: int
var _ticks_spent_regaining_sync := 0
var _time_since_last_tick := 0.0
var _debug_skip_nth_message_counter := 0
var _input_complete_tick := 0
var _state_complete_tick := 0
var _last_state_hashed_tick := 0
var _state_mismatch_count := 0
var _in_rollback := false
var _ran_physics_process := false
var _ticks_since_last_interpolation_frame := 0
var _debug_check_local_state_consistency_buffer := []
var _current_event_buffer_frame_data := {}
var _event_scripts := {}
var _event_scripts_in_buffer := {}
var _peer_left_for_peer: = {}

signal sync_started ()
signal sync_stopped ()
signal sync_lost ()
signal sync_regained ()
signal sync_error (msg)

signal skip_ticks_flagged (count)
signal rollback_flagged (tick)
signal prediction_missed (tick, peer_id, local_input, remote_input)
signal remote_state_mismatch (tick, peer_id, local_hash, remote_hash)

signal peer_added (peer_id)
signal peer_removed (peer_id)
signal peer_pinged_back (peer)

signal state_loaded (rollback_ticks)
signal tick_finished (is_rollback)
signal tick_retired (tick)
signal tick_input_complete (tick)
signal interpolation_frame ()

func _enter_tree() -> void:
	var project_settings_node = load("res://addons/delta_rollback/ProjectSettings.gd").new()
	project_settings_node.add_project_settings()
	project_settings_node.free()

func _exit_tree() -> void:
	stop_logging()

func _ready() -> void:
	#get_tree().connect("network_peer_disconnected", self, "remove_peer")
	#get_tree().connect("server_disconnected", self, "stop")
	
	var project_settings := {
		max_buffer_size = 'network/rollback/max_buffer_size',
		ticks_to_calculate_advantage = 'network/rollback/ticks_to_calculate_advantage',
		input_delay = 'network/rollback/input_delay',
		_ping_frequency = 'network/rollback/ping_frequency',
		interpolation = 'network/rollback/interpolation',
		max_input_frames_per_message = 'network/rollback/limits/max_input_frames_per_message',
		max_messages_at_once = 'network/rollback/limits/max_messages_at_once',
		max_ticks_to_regain_sync = 'network/rollback/limits/max_ticks_to_regain_sync',
		min_lag_to_regain_sync = 'network/rollback/limits/min_lag_to_regain_sync',
		max_state_mismatch_count = 'network/rollback/limits/max_state_mismatch_count',
		debug_rollback_ticks = 'network/rollback/debug/rollback_ticks',
		debug_random_rollback_ticks = 'network/rollback/debug/random_rollback_ticks',
		debug_message_bytes = 'network/rollback/debug/message_bytes',
		debug_skip_nth_message = 'network/rollback/debug/skip_nth_message',
		debug_physics_process_msecs = 'network/rollback/debug/physics_process_msecs',
		debug_process_msecs = 'network/rollback/debug/process_msecs',
		debug_check_message_serializer_roundtrip = 'network/rollback/debug/check_message_serializer_roundtrip',
		debug_check_local_state_consistency = 'network/rollback/debug/check_local_state_consistency',
		debug_use_sync_debugger = 'network/rollback/debug/use_sync_debugger',
	}
	for property_name in project_settings:
		var setting_name = project_settings[property_name]
		set(property_name, ProjectSettings.get_setting(setting_name))
	
	_ping_timer = Timer.new()
	_ping_timer.name = "PingTimer"
	_ping_timer.wait_time = ping_frequency
	_ping_timer.autostart = true
	_ping_timer.one_shot = false
	_ping_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_ping_timer.timeout.connect(_on_ping_timer_timeout)
	add_child(_ping_timer)
	
	_spawn_manager = SpawnManager.new()
	_spawn_manager.name = "SpawnManager"
	add_child(_spawn_manager)
	
	_property_manager = PropertyManagerScript.new()
	_property_manager.name = "PropertyManager"
	add_child(_property_manager)
	
	_sound_manager = SoundManager.new()
	_sound_manager.name = "SoundManager"
	add_child(_sound_manager)
	_sound_manager.setup_sound_manager(self)
	
	sync_booster.name = "SyncBooster"
	add_child(sync_booster)
	
	if debug_use_sync_debugger:
		var sync_debugger = load(SYNC_DEBUGGER_PATH).new()
		sync_debugger.name = "SyncDebugger"
		add_child(sync_debugger)
	
	if network_adaptor == null:
		reset_network_adaptor()
	if message_serializer == null:
		set_message_serializer(_create_class_from_project_settings('network/rollback/classes/message_serializer', DEFAULT_MESSAGE_SERIALIZER_PATH))

func _set_readonly_variable(_value) -> void:
	pass

func _create_class_from_project_settings(setting_name: String, default_path: String):
	var class_path := ''
	if ProjectSettings.has_setting(setting_name):
		class_path = ProjectSettings.get_setting(setting_name)
	if class_path == '':
		class_path = default_path
	return load(class_path).new()

func set_network_adaptor(_network_adaptor: NetworkAdaptor) -> void:
	assert(not started, "Changing the network adaptor after SyncManager has started will probably break everything")
	
	if network_adaptor != null:
		network_adaptor.detach_network_adaptor(self)
		network_adaptor.received_ping.disconnect(_on_received_ping)
		network_adaptor.received_ping_back.disconnect(_on_received_ping_back)
		network_adaptor.received_remote_start.disconnect(_on_received_remote_start)
		network_adaptor.received_remote_stop.disconnect(_on_received_remote_stop)
		network_adaptor.received_input_tick.disconnect(_on_received_input_tick)
		
		remove_child(network_adaptor)
		network_adaptor.queue_free()
	
	network_adaptor = _network_adaptor
	network_adaptor.name = 'NetworkAdaptor'
	add_child(network_adaptor)
	network_adaptor.received_ping.connect(_on_received_ping)
	network_adaptor.received_ping_back.connect(_on_received_ping_back)
	network_adaptor.received_remote_start.connect(_on_received_remote_start)
	network_adaptor.received_remote_stop.connect(_on_received_remote_stop)
	network_adaptor.received_input_tick.connect(_on_received_input_tick)
	network_adaptor.attach_network_adaptor(self)

func reset_network_adaptor() -> void:
	set_network_adaptor(_create_class_from_project_settings('network/rollback/classes/network_adaptor', DEFAULT_NETWORK_ADAPTOR_PATH))

func set_message_serializer(_message_serializer: MessageSerializer) -> void:
	assert(not started, "Changing the message serializer after SyncManager has started will probably break everything")
	message_serializer = _message_serializer

func set_mechanized(_mechanized: bool) -> void:
#	assert(not started, "Changing the mechanized flag after SyncManager has started will probably break everything")
	mechanized = _mechanized
	mechanized_replay = _mechanized
	
	set_process(not mechanized_replay)
	set_physics_process(not mechanized_replay)
	_ping_timer.paused = mechanized
	
	if mechanized_replay:
		stop_logging()

func set_ping_frequency(p_ping_frequency) -> void:
	ping_frequency = p_ping_frequency
	if _ping_timer:
		_ping_timer.wait_time = ping_frequency

func set_input_delay(_input_delay: int) -> void:
	if started:
		push_warning("Cannot change input delay after sync'ing has already started")
	input_delay = _input_delay

func add_peer(peer_id: int) -> void:
	assert(not peers.has(peer_id), "Peer with given id already exists")
	assert(peer_id != network_adaptor.get_network_unique_id(), "Cannot add ourselves as a peer in SyncManager")
	
	if peers.has(peer_id):
		return
	if peer_id == network_adaptor.get_network_unique_id():
		return
	
	peers[peer_id] = Peer.new(peer_id)
	emit_signal("peer_added", peer_id)

func has_peer(peer_id: int) -> bool:
	return peers.has(peer_id)

func get_peer(peer_id: int) -> Peer:
	return peers.get(peer_id)

func remove_peer(peer_id: int) -> void:
	if peers.has(peer_id):
		if started:
			_sync_remove_peer(peer_id)
		else:
			_remove_peer_internal(peer_id)

func _remove_peer_internal(peer_id: int) -> void:
	peers.erase(peer_id)
	emit_signal("peer_removed", peer_id)
	if peers.size() == 0:
		stop()

# don't remove peer immediately since there may be inputs that are only 
# in one peer and can cause desyncs
func _sync_remove_peer(p_peer_id: int) -> void:
	_peer_left_for_me.bind(p_peer_id).rpc()

func clear_peers() -> void:
	for peer_id in peers.keys().duplicate():
		_remove_peer_internal(peer_id)

func _get_system_time_msecs() -> int:
	return int(round(1000.0 * Time.get_unix_time_from_system()))

func _on_ping_timer_timeout() -> void:
	if peers.size() == 0:
		return
	var msg = {
		local_time = _get_system_time_msecs(),
	}
	for peer_id in peers:
		assert(peer_id != network_adaptor.get_network_unique_id(), "Cannot ping ourselves")
		network_adaptor.send_ping(peer_id, msg)

func _on_received_ping(peer_id: int, msg: Dictionary) -> void:
	assert(peer_id != network_adaptor.get_network_unique_id(), "Cannot ping back ourselves")
	msg['remote_time'] = _get_system_time_msecs()
	network_adaptor.send_ping_back(peer_id, msg)

func _on_received_ping_back(peer_id: int, msg: Dictionary) -> void:
	var system_time = _get_system_time_msecs()
	var peer = peers[peer_id]
	peer.last_ping_received = system_time
	peer.rtt = system_time - msg['local_time']
	peer.time_delta = msg['remote_time'] - msg['local_time'] - (peer.rtt / 2.0)
	emit_signal("peer_pinged_back", peer)

func start_logging(log_file_path: String, match_info: Dictionary = {}) -> void:
	if mechanized_replay:
		return
	
	if not _logger:
		_logger = Logger.new(self)
	else:
		_logger.stop()
	
	if _logger.start(log_file_path, network_adaptor.get_network_unique_id(), match_info) != OK:
		stop_logging()

func stop_logging() -> void:
	if _logger:
		_logger.stop()
		_logger = null

func start() -> void:
	assert(network_adaptor.is_network_host() or mechanized_replay, "start() should only be called on the host")
	if started or _host_starting:
		return
	if mechanized_replay:
		_on_received_remote_start()
		return
	if network_adaptor.is_network_host():
		var highest_rtt: int = 0
		for peer in peers.values():
			highest_rtt = max(highest_rtt, peer.rtt)
		
		# Call _remote_start() on all the other peers.
		for peer_id in peers:
			network_adaptor.send_remote_start(peer_id)
		
		# Attempt to prevent double starting on the host.
		_host_starting = true
		
		# Wait for half the highest RTT to start locally.
		print ("Delaying host start by %sms" % (highest_rtt / 2))
		await get_tree().create_timer(highest_rtt / 2000.0).timeout
		
		_on_received_remote_start()
		_host_starting = false

func _reset() -> void:
	input_tick = 0
	current_tick = input_tick - input_delay
	skip_ticks = 0
	rollback_ticks = 0
	input_buffer.clear()
	state_buffer.clear()
	state_hashes.clear()
	event_buffer.clear()
	_input_buffer_start_tick = 1
	_state_buffer_start_tick = 0
	_state_hashes_start_tick = 1
	_input_send_queue.clear()
	_input_send_queue_start_tick = 1
	_ticks_spent_regaining_sync = 0
	_time_since_last_tick = 0.0
	_debug_skip_nth_message_counter = 0
	_input_complete_tick = 0
	_state_complete_tick = 0
	_last_state_hashed_tick = 0
	_state_mismatch_count = 0
	_in_rollback = false
	_ran_physics_process = false
	_ticks_since_last_interpolation_frame = 0
	_debug_check_local_state_consistency_buffer.clear()
	_current_event_buffer_frame_data.clear()
	_event_scripts.clear()
	_event_scripts_in_buffer.clear()
	_peer_left_for_peer.clear()

func _on_received_remote_start() -> void:
	_reset()
	tick_time = (1.0 / ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))
	started = true
	network_adaptor.start_network_adaptor(self)
	for n in get_tree().get_nodes_in_group("network_sync"):
		set_groups_for_node(n)
	emit_signal("sync_started")

func set_groups_for_node(n: Node) -> void:
	if n.has_method("_load_state"):
		n.add_to_group("network_sync_load_state")
	if n.has_method("_save_state"):
		n.add_to_group("network_sync_save_state")
	if n.has_method("_interpolate_state"):
		n.add_to_group("network_sync_interpolate")
	if n.has_method("_network_process"):
		n.add_to_group("network_sync_process")
	if n.has_method("_network_preprocess"):
		n.add_to_group("network_sync_preprocess")
	if n.has_method("_network_postprocess"):
		n.add_to_group("network_sync_postprocess")
	if n.has_method("_get_local_input"):
		n.add_to_group("network_sync_input")
	n.remove_from_group("network_sync")

func stop() -> void:
	if network_adaptor.is_network_host() and not mechanized_replay:
		for peer_id in peers:
			network_adaptor.send_remote_stop(peer_id)
	
	_on_received_remote_stop()

func _on_received_remote_stop() -> void:
	if not (started or _host_starting):
		return
	
	network_adaptor.stop_network_adaptor(self)
	started = false
	_host_starting = false
	_reset()
	
	for peer in peers.values():
		peer.clear()
	
	emit_signal("sync_stopped")
	_spawn_manager.reset()
	_property_manager.reset()

func _handle_fatal_error(msg: String):
	emit_signal("sync_error", msg)
	push_error("NETWORK SYNC LOST: " + msg)
	stop()
	if _logger:
		_logger.log_fatal_error(msg)
	return null

func _call_get_local_input() -> Dictionary:
	return sync_booster.call_get_local_input(network_adaptor.get_network_unique_id())

func _call_network_process(input_frame: InputBufferFrame) -> void:
	sync_booster.call_network_process(input_frame)
	_spawn_manager._network_process({})

func _call_network_preprocess(input_frame: InputBufferFrame) -> void:
	sync_booster.call_network_preprocess(input_frame)

func _call_network_postprocess(input_frame: InputBufferFrame) -> void:
	sync_booster.call_network_postprocess(input_frame)

func _call_save_state() -> Dictionary:
	if _logger:
		_logger.start_timing("call_save_state")
	var res = sync_booster.call_save_state()
	res[str(_spawn_manager.get_path())] = _spawn_manager._save_state()
	if _logger:
		_logger.stop_timing("call_save_state")
	return res

func _call_load_state(state: Dictionary, p_load_type: int) -> void:
	if _logger:
		_logger.start_timing("call_load_state")
	load_type = p_load_type
	_spawn_manager._load_state(state[str(_spawn_manager.get_path())])
	sync_booster.call_load_state(state)
	if _logger:
		_logger.stop_timing("call_load_state", true)

func _call_load_state_forward(state: Dictionary, events: Dictionary) -> void:
	_spawn_manager.reset()
	_property_manager.reset()
	var spawn_manager_path: = str(_spawn_manager.get_path())
	_spawn_manager._load_state_forward(state[spawn_manager_path], events.get(spawn_manager_path, {}))
	state.erase(spawn_manager_path)
	for node_path in state:
		if node_path == '$':
			continue
		var node = get_node_or_null(node_path)
		assert(node != null, "Unable to restore state to missing node: %s" % node_path)
		if node:
			if node.has_method('_load_state_forward'):
				node._load_state_forward(state[node_path], events.get(node_path, {}))
			elif node.has_method('_load_state'):
				node._load_state(state[node_path])

func _call_interpolate_state(weight: float) -> void:
	if _logger:
		_logger.start_timing("call_load_state")
	if not state_buffer.is_empty():
		sync_booster.call_interpolate_state(state_buffer[-2].data, state_buffer[-1].data, weight)
	if _logger:
		_logger.stop_timing("call_load_state")

func _save_current_state() -> void:
	assert(current_tick >= 0, "Attempting to store state for negative tick")
	if current_tick < 0:
		return
	
	state_buffer.append(StateBufferFrame.new(current_tick, _call_save_state()))
	event_buffer.append(EventBufferFrame.new(current_tick, _current_event_buffer_frame_data))
	
	# If the input for this state is complete, then update _state_complete_tick.
	if _input_complete_tick > _state_complete_tick:
		# Set to the current_tick so long as its less than or equal to the
		# _input_complete_tick, otherwise, cap it to the _input_complete_tick.
		_state_complete_tick = current_tick if current_tick <= _input_complete_tick else _input_complete_tick

func _update_input_complete_tick() -> void:
	while input_tick >= _input_complete_tick + 1:
		var input_frame: InputBufferFrame = get_input_frame(_input_complete_tick + 1)
		if not input_frame:
			break
		if not input_frame.is_complete(peers):
			break
		# When we add debug rollbacks mark the input as not complete
		# so that the invariant "an complete input cannot be rolled back" is respected
		# NB: a complete input can still be loaded in a rollback for the incomplete next frame
		if debug_random_rollback_ticks > 0 and _input_complete_tick + 1 > current_tick - debug_random_rollback_ticks:
			break
		if debug_rollback_ticks > 0 and _input_complete_tick + 1 > current_tick - debug_rollback_ticks:
			break
		
		if _logger:
			_logger.write_input(input_frame.tick, input_frame.get_players())
		
		_input_complete_tick += 1
		
		# This tick should be recomputed with complete inputs, let's roll back
		if _input_complete_tick == requested_input_complete_tick:
			requested_input_complete_tick = 0
			var tick_delta = current_tick - _input_complete_tick
			if tick_delta >= 0 and rollback_ticks <= tick_delta:
				rollback_ticks = tick_delta + 1
				emit_signal("rollback_flagged", _input_complete_tick)
		
		emit_signal("tick_input_complete", _input_complete_tick)

func _update_state_hashes() -> void:
	while _state_complete_tick > _last_state_hashed_tick:
		var state_frame: StateBufferFrame = _get_state_frame(_last_state_hashed_tick + 1)
		if not state_frame:
			_handle_fatal_error("Unable to hash state")
			return
		
		_last_state_hashed_tick += 1
		
		var state_hash = _calculate_data_hash(state_frame.data)
		state_hashes.append(StateHashFrame.new(_last_state_hashed_tick, state_hash))
		
		if _logger:
			var event_frame = _get_event_frame(_last_state_hashed_tick)
			if not _event_scripts_in_buffer.is_empty():
				# send all event scripts received as they don't represent state
				for node_path in _event_scripts_in_buffer.keys():
					var script_path = _event_scripts_in_buffer[node_path]
					event_frame._add_script_event(node_path, script_path)
					_event_scripts[node_path] = script_path
				_event_scripts_in_buffer.clear()
			var serialized_events = SyncManager.sync_booster.serialize(event_frame.data)
			_logger.write_event(_last_state_hashed_tick, serialized_events)
			_logger.write_state(_last_state_hashed_tick, state_frame.data)

func _do_tick(is_rollback: bool = false) -> bool:
	var input_frame := get_input_frame(current_tick)
	var previous_frame := get_input_frame(current_tick - 1)
	_current_event_buffer_frame_data = {}
	
	assert(input_frame != null, "Input frame for current_tick is null")
	
	var peers_ticks_since_real_input = {}
	for peer_id in peers:
		var peer: Peer = peers[peer_id]
		peers_ticks_since_real_input[peer_id] = -1 if peer.last_remote_input_tick_received == 0 \
		 else current_tick - peer.last_remote_input_tick_received
	input_frame = sync_booster.call_predict_missing_input(peers_ticks_since_real_input, input_frame, previous_frame)
	
	_call_network_preprocess(input_frame)
	_call_network_process(input_frame)
	_call_network_postprocess(input_frame)
	
	# If the game was stopped during the last network process, then we return
	# false here, to indicate that a full tick didn't complete and we need to
	# abort.
	if not started:
		return false
	
	_save_current_state()
	
	# Debug check that states computed multiple times with complete inputs are the same
	if debug_check_local_state_consistency and _last_state_hashed_tick >= current_tick:
		_debug_check_consistent_local_state(state_buffer[-1], "Recomputed")
	
	emit_signal("tick_finished", is_rollback)
	return true

func _get_or_create_input_frame(tick: int) -> InputBufferFrame:
	var input_frame: InputBufferFrame
	if input_buffer.size() == 0:
		input_frame = InputBufferFrame.new()
		input_frame.tick = tick
		input_buffer.append(input_frame)
	elif tick > input_buffer[-1].tick:
		var highest = input_buffer[-1].tick
		while highest < tick:
			highest += 1
			input_frame = InputBufferFrame.new()
			input_frame.tick = highest
			input_buffer.append(input_frame)
	else:
		input_frame = get_input_frame(tick)
		if input_frame == null:
			return _handle_fatal_error("Requested input frame (%s) not found in buffer" % tick)
	
	return input_frame

func _cleanup_buffers() -> bool:
	# Clean-up the input send queue.
	var min_next_input_tick_requested = _calculate_minimum_next_input_tick_requested()
	while _input_send_queue_start_tick < min_next_input_tick_requested:
		_input_send_queue.pop_front()
		_input_send_queue_start_tick += 1
	
	# Clean-up old state buffer frames. We need to keep one extra frame of state
	# because when we rollback, we need to load the state for the frame before
	# the first one we need to run again.
	while state_buffer.size() > max_buffer_size + 1:
		var state_frame_to_retire: StateBufferFrame = state_buffer[0]
		var input_frame = get_input_frame(state_frame_to_retire.tick + 1)
		if input_frame == null:
			var message = "Attempting to retire state frame %s, but input frame %s is missing" % [state_frame_to_retire.tick, state_frame_to_retire.tick + 1]
			push_warning(message)
			if _logger:
				_logger.data['buffer_underrun_message'] = message
			return false
		if not input_frame.is_complete(peers):
			var missing: Array = input_frame.get_missing_peers(peers)
			var message = "Attempting to retire state frame %s, but input frame %s is still missing input (missing peer(s): %s)" % [state_frame_to_retire.tick, input_frame.tick, missing]
			push_warning(message)
			if _logger:
				_logger.data['buffer_underrun_message'] = message
			return false
		
		if state_frame_to_retire.tick > _last_state_hashed_tick:
			var message = "Unable to retire state frame %s, because we haven't hashed it yet" % state_frame_to_retire.tick
			push_warning(message)
			if _logger:
				_logger.data['buffer_underrun_message'] = message
			return false
		
		state_buffer.pop_front()
		event_buffer.pop_front()
		_state_buffer_start_tick += 1
		
		emit_signal("tick_retired", state_frame_to_retire.tick)
	
	# Clean-up old input buffer frames. Unlike state frames, we can have many
	# frames from the future if we are running behind. We don't want having too
	# many future frames to end up discarding input for the current frame, so we
	# only count input frames before the current frame towards the buffer size.
	while (current_tick - _input_buffer_start_tick) > max_buffer_size:
		_input_buffer_start_tick += 1
		input_buffer.pop_front()
	
	while state_hashes.size() > (max_buffer_size * 2):
		var state_hash_to_retire: StateHashFrame = state_hashes[0]
		if not state_hash_to_retire.is_complete(peers) and not mechanized_replay:
			var missing: Array = state_hash_to_retire.get_missing_peers(peers)
			var message = "Attempting to retire state hash frame %s, but we're still missing hashes (missing peer(s): %s)" % [state_hash_to_retire.tick, missing]
			push_warning(message)
			if _logger:
				_logger.data['buffer_underrun_message'] = message
			return false
		
		if state_hash_to_retire.mismatch:
			_state_mismatch_count += 1
		else:
			_state_mismatch_count = 0
		if _state_mismatch_count > max_state_mismatch_count:
			_handle_fatal_error("Fatal state mismatch")
			return false
		
		_state_hashes_start_tick += 1
		state_hashes.pop_front()
	
	return true

func get_input_frame(tick: int) -> InputBufferFrame:
	if tick < _input_buffer_start_tick:
		return null
	var index = tick - _input_buffer_start_tick
	if index >= input_buffer.size():
		return null
	var input_frame = input_buffer[index]
	assert(input_frame.tick == tick, "Input frame retreived from input buffer has mismatched tick number")
	return input_frame

func get_latest_input_from_peer(peer_id: int) -> Dictionary:
	if peers.has(peer_id):
		var peer: Peer = peers[peer_id]
		var input_frame = get_input_frame(peer.last_remote_input_tick_received)
		if input_frame:
			return input_frame.get_player_input(peer_id)
	return {}

func get_latest_input_for_node(node: Node) -> Dictionary:
	return get_latest_input_from_peer_for_path(node.get_network_master(), str(node.get_path()))

func get_latest_input_from_peer_for_path(peer_id: int, path: String) -> Dictionary:
	return get_latest_input_from_peer(peer_id).get(path, {})

func _get_state_frame(tick: int) -> StateBufferFrame:
	if tick < _state_buffer_start_tick:
		return null
	var index = tick - _state_buffer_start_tick
	if index >= state_buffer.size():
		return null
	var state_frame = state_buffer[index]
	assert(state_frame.tick == tick, "State frame retreived from state buffer has mismatched tick number")
	return state_frame

func _get_event_frame(tick: int) -> EventBufferFrame:
	if tick < _state_buffer_start_tick:
		return null
	var index = tick - _state_buffer_start_tick
	if index >= event_buffer.size():
		return null
	var event_frame = event_buffer[index]
	assert(event_frame.tick == tick, "Event frame retreived from event buffer has mismatched tick number")
	return event_frame

func _get_state_hash_frame(tick: int) -> StateHashFrame:
	if tick < _state_hashes_start_tick:
		return null
	var index = tick - _state_hashes_start_tick
	if index >= state_hashes.size():
		return null
	var state_hash_frame = state_hashes[index]
	assert(state_hash_frame.tick == tick, "State hash frame retreived from state hashes has mismatched tick number")
	return state_hash_frame

func is_current_tick_input_complete() -> bool:
	return current_tick <= _input_complete_tick

func _get_input_messages_from_send_queue_in_range(first_index: int, last_index: int, reverse: bool = false) -> Array:
	var indexes = range(first_index, last_index + 1) if not reverse else range(last_index, first_index - 1, -1)
	
	var all_messages := []
	var msg := {}
	for index in indexes:
		msg[_input_send_queue_start_tick + index] = _input_send_queue[index]
		
		if max_input_frames_per_message > 0 and msg.size() == max_input_frames_per_message:
			all_messages.append(msg)
			msg = {}
	
	if msg.size() > 0:
		all_messages.append(msg)
	
	return all_messages

func _get_input_messages_from_send_queue_for_peer(peer: Peer) -> Array:
	var first_index := peer.next_local_input_tick_requested - _input_send_queue_start_tick
	var last_index := _input_send_queue.size() - 1
	var max_messages := (max_input_frames_per_message * max_messages_at_once)
	
	if (last_index + 1) - first_index <= max_messages:
		return _get_input_messages_from_send_queue_in_range(first_index, last_index, true)
	
	var new_messages = int(ceil(max_messages_at_once / 2.0))
	var old_messages = int(floor(max_messages_at_once / 2.0))
	
	return _get_input_messages_from_send_queue_in_range(last_index - (new_messages * max_input_frames_per_message) + 1, last_index, true) + \
		   _get_input_messages_from_send_queue_in_range(first_index, first_index + (old_messages * max_input_frames_per_message) - 1)

func _get_state_hashes_for_peer(peer: Peer) -> Dictionary:
	var ret := {}
	if peer.next_local_hash_tick_requested >= _state_hashes_start_tick:
		var index = peer.next_local_hash_tick_requested - _state_hashes_start_tick
		while index < state_hashes.size():
			var state_hash_frame: StateHashFrame = state_hashes[index]
			ret[state_hash_frame.tick] = state_hash_frame.state_hash
			index += 1
	return ret

func _record_advantage(force_calculate_advantage: bool = false) -> void:
	for peer in peers.values():
		# Number of frames we are predicting for this peer.
		peer.local_lag = (input_tick + 1) - peer.last_remote_input_tick_received
		# Calculate the advantage the peer has over us.
		peer.record_advantage(ticks_to_calculate_advantage if not force_calculate_advantage else 0)
		
		if _logger:
			_logger.add_value("peer_%s" % peer.peer_id, {
				local_lag = peer.local_lag,
				remote_lag = peer.remote_lag,
				advantage = peer.local_lag - peer.remote_lag,
				calculated_advantage = peer.calculated_advantage,
			})

func _calculate_skip_ticks() -> bool:
	# Attempt to find the greatest advantage.
	var max_advantage: float
	for peer in peers.values():
		max_advantage = max(max_advantage, peer.calculated_advantage)
	
	if max_advantage >= 2.0 and skip_ticks == 0:
		skip_ticks = int(max_advantage / 2)
		emit_signal("skip_ticks_flagged", skip_ticks)
		return true
	
	return false

func _calculate_max_local_lag() -> int:
	var max_lag := 0
	for peer in peers.values():
		max_lag = max(max_lag, peer.local_lag)
	return max_lag

func _calculate_minimum_next_input_tick_requested() -> int:
	if peers.size() == 0:
		return 1
	var peer_list := peers.values().duplicate()
	var result: int = peer_list.pop_front().next_local_input_tick_requested
	for peer in peer_list:
		result = min(result, peer.next_local_input_tick_requested)
	return result

func _send_input_messages_to_peer(peer_id: int) -> void:
	assert(peer_id != network_adaptor.get_network_unique_id(), "Cannot send input to ourselves")
	var peer = peers[peer_id]
	
	var state_hashes = _get_state_hashes_for_peer(peer)
	var input_messages = _get_input_messages_from_send_queue_for_peer(peer)
	
	if _logger:
		_logger.data['messages_sent_to_peer_%s' % peer_id] = input_messages.size()
	
	for input in _get_input_messages_from_send_queue_for_peer(peer):
		var msg = {
			MessageSerializer.InputMessageKey.NEXT_INPUT_TICK_REQUESTED: peer.last_remote_input_tick_received + 1,
			MessageSerializer.InputMessageKey.INPUT: input,
			MessageSerializer.InputMessageKey.NEXT_HASH_TICK_REQUESTED: peer.last_remote_hash_tick_received + 1,
			MessageSerializer.InputMessageKey.STATE_HASHES: state_hashes,
		}
		
		var bytes = message_serializer.serialize_message(msg)
		
		# See https://gafferongames.com/post/packet_fragmentation_and_reassembly/
		if debug_message_bytes > 0:
			if bytes.size() > debug_message_bytes:
				push_error("Sending message w/ size %s bytes" % bytes.size())
		
		if _logger:
			_logger.add_value("messages_sent_to_peer_%s_size" % peer_id, bytes.size())
			_logger.increment_value("messages_sent_to_peer_%s_total_size" % peer_id, bytes.size())
			_logger.merge_array_value("input_ticks_sent_to_peer_%s" % peer_id, input.keys())
		
		#var ticks = msg[InputMessageKey.INPUT].keys()
		#print ("[%s] Sending ticks %s - %s" % [current_tick, min(ticks[0], ticks[-1]), max(ticks[0], ticks[-1])])
		
		network_adaptor.send_input_tick(peer_id, bytes)

func _send_input_messages_to_all_peers() -> void:
	if debug_skip_nth_message > 1:
		_debug_skip_nth_message_counter += 1
		if _debug_skip_nth_message_counter >= debug_skip_nth_message:
			print("[%s] Skipping message to simulate packet loss" % current_tick)
			_debug_skip_nth_message_counter = 0
			return
	
	for peer_id in peers:
		_send_input_messages_to_peer(peer_id)

func _physics_process(_delta: float) -> void:
	if not started:
		return
	
	if _logger:
		_logger.begin_tick(current_tick + 1)
		_logger.data['input_complete_tick'] = _input_complete_tick
		_logger.data['state_complete_tick'] = _state_complete_tick
	
	var start_time := Time.get_ticks_usec()
	
	# @todo Is there a way we can move this to _remote_start()?
	# Store an initial state before any ticks.
	if current_tick == 0:
		_save_current_state()
		if _logger:
			_calculate_data_hash(state_buffer[0].data)
			_logger.write_state(0, state_buffer[0].data)
	
	#####
	# STEP 1: PERFORM ANY ROLLBACKS, IF NECESSARY.
	#####
	
	if mechanized:
		rollback_ticks = mechanized_rollback_ticks
	else:
		if debug_random_rollback_ticks > 0:
			randomize()
			debug_rollback_ticks = randi() % debug_random_rollback_ticks
		if debug_rollback_ticks > 0 and current_tick >= debug_rollback_ticks:
			rollback_ticks = max(rollback_ticks, debug_rollback_ticks)
		
		# We need to reload the current tick since we did a partial rollback
		# to the previous tick in order to interpolate.
		if interpolation and current_tick > 0 and rollback_ticks == 0:
			_call_load_state(state_buffer[-1].data, LoadType.INTERPOLATION_FORWARD)
			if debug_check_local_state_consistency:
				# Save already computed states for better logging in case of discrepancy
				_debug_check_local_state_consistency_buffer = [state_buffer[-1]]
				var state := StateBufferFrame.new(current_tick, _call_save_state())
				_debug_check_consistent_local_state(state, "Loaded interpolation forward")
		
	
	if rollback_ticks > 0:
		if _logger:
			_logger.data['rollback_ticks'] = rollback_ticks
			_logger.start_timing('rollback')
		
		var original_tick = current_tick
		
		# Rollback our internal state.
		assert(rollback_ticks + 1 <= state_buffer.size(), "Not enough state in buffer to rollback requested number of frames")
		if rollback_ticks + 1 > state_buffer.size():
			_handle_fatal_error("Not enough state in buffer to rollback %s frames" % rollback_ticks)
			return
		
		_call_load_state(state_buffer[-rollback_ticks - 1].data, LoadType.ROLLBACK)
		
		current_tick -= rollback_ticks
		
		if debug_check_local_state_consistency:
			# Save already computed states for better logging in case of discrepancy
			_debug_check_local_state_consistency_buffer = state_buffer.slice(state_buffer.size() - rollback_ticks - 1, state_buffer.size() - 1)
			# Debug check that states computed multiple times with complete inputs are the same
			if _last_state_hashed_tick >= current_tick:
				var state := StateBufferFrame.new(current_tick, _call_save_state())
				_debug_check_consistent_local_state(state, "Loaded")
		
		state_buffer.resize(state_buffer.size() - rollback_ticks)
		event_buffer.resize(event_buffer.size() - rollback_ticks)
		
		# Invalidate sync ticks after this, they may be asked for again
		if requested_input_complete_tick > 0 and current_tick < requested_input_complete_tick:
			requested_input_complete_tick = 0
		
		emit_signal("state_loaded", rollback_ticks)
		
		_in_rollback = true
		
		# Iterate forward until we're at the same spot we left off.
		while rollback_ticks > 0:
			current_tick += 1
			if not _do_tick(true):
				return
			rollback_ticks -= 1
		assert(current_tick == original_tick, "Rollback didn't return to the original tick")
		
		_in_rollback = false
		
		if _logger:
			_logger.stop_timing('rollback')
	
	#####
	# STEP 2: SKIP TICKS, IF NECESSARY.
	#####
	
	if not mechanized_replay:
		_record_advantage()
		
		if _ticks_spent_regaining_sync > 0:
			_ticks_spent_regaining_sync += 1
			if max_ticks_to_regain_sync > 0 and _ticks_spent_regaining_sync > max_ticks_to_regain_sync:
				_handle_fatal_error("Unable to regain synchronization")
				return
			
			# Check again if we're still getting input buffer underruns.
			if not _cleanup_buffers():
				# This can happen if there's a fatal error in _cleanup_buffers().
				if not started:
					return
				# Even when we're skipping ticks, still send input.
				_send_input_messages_to_all_peers()
				if _logger:
					_logger.skip_tick(Logger.SkipReason.INPUT_BUFFER_UNDERRUN, start_time)
				return
			
			# Check if our max lag is still greater than the min lag to regain sync.
			if min_lag_to_regain_sync > 0 and _calculate_max_local_lag() > min_lag_to_regain_sync:
				#print ("REGAINING SYNC: wait for local lag to reduce")
				# Even when we're skipping ticks, still send input.
				_send_input_messages_to_all_peers()
				if _logger:
					_logger.skip_tick(Logger.SkipReason.WAITING_TO_REGAIN_SYNC, start_time)
				return
			
			# If we've reach this point, that means we've regained sync!
			_ticks_spent_regaining_sync = 0
			emit_signal("sync_regained")
			
			# We don't want to skip ticks through the normal mechanism, because
			# any skips that were previously calculated don't apply anymore.
			skip_ticks = 0
		
		# Attempt to clean up buffers, but if we can't, that means we've lost sync.
		elif not _cleanup_buffers():
			# This can happen if there's a fatal error in _cleanup_buffers().
			if not started:
				return
			emit_signal("sync_lost")
			_ticks_spent_regaining_sync = 1
			# Even when we're skipping ticks, still send input.
			_send_input_messages_to_all_peers()
			if _logger:
				_logger.skip_tick(Logger.SkipReason.INPUT_BUFFER_UNDERRUN, start_time)
			return
		
		if skip_ticks > 0:
			skip_ticks -= 1
			if skip_ticks == 0:
				for peer in peers.values():
					peer.clear_advantage()
			else:
				# Even when we're skipping ticks, still send input.
				_send_input_messages_to_all_peers()
				if _logger:
					_logger.skip_tick(Logger.SkipReason.ADVANTAGE_ADJUSTMENT, start_time)
				return
		
		if _calculate_skip_ticks():
			# This means we need to skip some ticks, so may as well start now!
			if _logger:
				_logger.skip_tick(Logger.SkipReason.ADVANTAGE_ADJUSTMENT, start_time)
			return
	else:
		_cleanup_buffers()
	
	#####
	# STEP 3: GATHER INPUT AND RUN CURRENT TICK
	#####
	
	input_tick += 1
	current_tick += 1
	
	if not mechanized:
		var input_frame := _get_or_create_input_frame(input_tick)
		# The underlying error would have already been reported in
		# _get_or_create_input_frame() so we can just return here.
		if input_frame == null:
			return
		
		if _logger:
			_logger.data['input_tick'] = input_tick
		
		var local_input = _call_get_local_input()
		_calculate_data_hash(local_input)
		input_frame.add_input_for_player(network_adaptor.get_network_unique_id(), local_input, false)
		
		# Only serialize and send input when we have real remote peers.
		if peers.size() > 0:
			var serialized_input := message_serializer.serialize_input(local_input)
			
			# check that the serialized then unserialized input matches the original 
			if debug_check_message_serializer_roundtrip:
				var unserialized_input := message_serializer.unserialize_input(serialized_input)
				_calculate_data_hash(unserialized_input)
				if local_input["$"] != unserialized_input["$"]:
					push_error("The input is different after being serialized and unserialized \n Original: %s \n Unserialized: %s" % [ordered_dict2str(local_input), ordered_dict2str(unserialized_input)])
				
			_input_send_queue.append(serialized_input)
			assert(input_tick == _input_send_queue_start_tick + _input_send_queue.size() - 1, "Input send queue ticks numbers are misaligned")
			_send_input_messages_to_all_peers()
	
	if current_tick > 0:
		if _logger:
			_logger.start_timing("current_tick")
		
		if not _do_tick():
			return
		
		if _logger:
			_logger.stop_timing("current_tick")
		
		if interpolation:
			# Return to state from the previous frame, so we can interpolate
			# towards the state of the current frame.
			_call_load_state(state_buffer[-2].data, LoadType.INTERPOLATION_BACKWARD)
			if debug_check_local_state_consistency:
				# Save already computed states for better logging in case of discrepancy
				_debug_check_local_state_consistency_buffer = [state_buffer[-2]]
				var state := StateBufferFrame.new(current_tick - 1, _call_save_state())
				_debug_check_consistent_local_state(state, "Loaded interpolation backward")
	
	_time_since_last_tick = 0.0
	_ran_physics_process = true
	_ticks_since_last_interpolation_frame += 1
	
	var total_time_msecs = float(Time.get_ticks_usec() - start_time) / 1000.0
	if debug_physics_process_msecs > 0 and total_time_msecs > debug_physics_process_msecs:
		push_error("[%s] SyncManager._physics_process() took %.02fms" % [current_tick, total_time_msecs])
	
	if _logger:
		_logger.end_tick(start_time)

func _process(delta: float) -> void:
	if not started:
		return
	
	var start_time = Time.get_ticks_usec()
	
	# These are things that we want to run during "interpolation frames", in
	# order to slim down the normal frames. Or, if interpolation is disabled,
	# we need to run these always. If we haven't managed to run this for more
	# one tick, we make sure to sneak it in just in case.
	if _logger:
		_logger.begin_interpolation_frame(current_tick)
	
	_time_since_last_tick += delta
	
	# Don't interpolate if we are skipping ticks, or just ran physics process.
	if interpolation and skip_ticks == 0 and _ticks_spent_regaining_sync == 0:
		_call_interpolate_state(Engine.get_physics_interpolation_fraction())
	
	# If there are no other peers, then we'll never receive any new input,
	# so we need to update the _input_complete_tick elsewhere. Here's a fine
	# place to do it!
	if peers.size() == 0:
		_update_input_complete_tick()
	
	_update_state_hashes()
	
	if interpolation:
		emit_signal("interpolation_frame")
	
	# Do this last to catch any data that came in late.
	network_adaptor.poll()
	
	if _logger:
		_logger.end_interpolation_frame(start_time)
	
	# Clear counter, because we just did an interpolation frame.
	_ticks_since_last_interpolation_frame = 0
	
	# Clear flag so subsequent _process() calls will know that they weren't
	# preceeded by _physics_process().
	_ran_physics_process = false
	
	var total_time_msecs = float(Time.get_ticks_usec() - start_time) / 1000.0
	if debug_process_msecs > 0 and total_time_msecs > debug_process_msecs:
		push_error("[%s] SyncManager._process() took %.02fms" % [current_tick, total_time_msecs])


# Calculates the hash without any keys that start with '_' (if string)
# or less than 0 (if integer) to allow some properties to not count when
# comparing comparing data.
#
# This can be used for comparing input (to prevent a difference betwen predicted
# input and real input from causing a rollback) and state (for when a property
# is only used for interpolation).
func _calculate_data_hash(input: Dictionary) -> int:
	var serialized_hash: = sync_booster.hash_special_dict(input)
	input['$'] = serialized_hash
	return serialized_hash

func _on_received_input_tick(peer_id: int, serialized_msg: PackedByteArray) -> void:
	if not started:
		return
	
	var msg = message_serializer.unserialize_message(serialized_msg)
	
	var all_remote_input: Dictionary = msg[MessageSerializer.InputMessageKey.INPUT]
	var all_remote_ticks = all_remote_input.keys()
	all_remote_ticks.sort()
	
	var first_remote_tick = all_remote_ticks[0]
	var last_remote_tick = all_remote_ticks[-1]
	
	if first_remote_tick >= input_tick + max_buffer_size:
		# This either happens because we are really far behind (but maybe, just
		# maybe could catch up) or we are receiving old ticks from a previous
		# round that hadn't yet arrived. Just discard the message and hope for
		# the best, but if we can't keep up, another one of the fail safes will
		# detect that we are out of sync.
		print ("Discarding message from the future")
		# We return because we don't even want to do the accounting that happens
		# after integrating input, since the data in this message could be
		# totally bunk (ie. if it's from a previous match).
		return
	
	if _logger:
		_logger.begin_interframe()
	
	var peer: Peer = peers[peer_id]
	
	# Only process if it contains ticks we haven't received yet.
	if last_remote_tick > peer.last_remote_input_tick_received:
		# Integrate the input we received into the input buffer.
		for remote_tick in all_remote_ticks:
			# Skip ticks we already have.
			if remote_tick <= peer.last_remote_input_tick_received:
				continue
			# This means the input frame has already been retired, which can only
			# happen if we already had all the input.
			if remote_tick < _input_buffer_start_tick:
				continue
			
			var remote_input = message_serializer.unserialize_input(all_remote_input[remote_tick])
			var input_frame := _get_or_create_input_frame(remote_tick)
			if input_frame == null:
				# _get_or_create_input_frame() will have already flagged the error,
				# so we can just return here.
				return
			
			# If we already have non-predicted input for this peer, then skip it.
			if not input_frame.is_player_input_predicted(peer_id):
				continue
			
			#print ("Received remote tick %s from %s" % [remote_tick, peer_id])
			if _logger:
				_logger.add_value('remote_ticks_received_from_%s' % peer_id, remote_tick)
			
			# If we received a tick in the past and we aren't already setup to
			# rollback earlier than that...
			var tick_delta = current_tick - remote_tick
			if tick_delta >= 0 and rollback_ticks <= tick_delta:
				# Grab our predicted input, and store the remote input.
				var local_input = input_frame.get_player_input(peer_id)
				input_frame.add_input_for_player(peer_id, remote_input, false)
				
				# Check if the remote input matches what we had predicted, if not,
				# flag that we need to rollback.
				if local_input['$'] != remote_input['$']:
					rollback_ticks = tick_delta + 1
					emit_signal("prediction_missed", remote_tick, peer_id, local_input, remote_input)
					emit_signal("rollback_flagged", remote_tick)
			else:
				# Otherwise, just store it.
				input_frame.add_input_for_player(peer_id, remote_input, false)
		
		# Find what the last remote tick we received was after filling these in.
		var index = (peer.last_remote_input_tick_received - _input_buffer_start_tick) + 1
		while index < input_buffer.size() and not input_buffer[index].is_player_input_predicted(peer_id):
			peer.last_remote_input_tick_received += 1
			index += 1
		
		# Update _input_complete_tick for new input.
		_update_input_complete_tick()
	
	# Record the next frame the other peer needs.
	peer.next_local_input_tick_requested = max(msg[MessageSerializer.InputMessageKey.NEXT_INPUT_TICK_REQUESTED], peer.next_local_input_tick_requested)
	
	# Number of frames the remote is predicting for us.
	peer.remote_lag = (peer.last_remote_input_tick_received + 1) - peer.next_local_input_tick_requested
	
	# Process state hashes.
	var remote_state_hashes = msg[MessageSerializer.InputMessageKey.STATE_HASHES]
	for remote_tick in remote_state_hashes:
		var state_hash_frame := _get_state_hash_frame(remote_tick)
		if state_hash_frame and not state_hash_frame.has_peer_hash(peer_id):
			if not state_hash_frame.record_peer_hash(peer_id, remote_state_hashes[remote_tick]):
				emit_signal("remote_state_mismatch", remote_tick, peer_id, state_hash_frame.state_hash, remote_state_hashes[remote_tick])
	
	# Find what the last remote state hash we received was after filling these in.
	var index = (peer.last_remote_hash_tick_received - _state_hashes_start_tick) + 1
	while index < state_hashes.size() and state_hashes[index].has_peer_hash(peer_id):
		peer.last_remote_hash_tick_received += 1
		index += 1
	
	# Record the next state hash that the other peer needs.
	peer.next_local_hash_tick_requested = max(msg[MessageSerializer.InputMessageKey.NEXT_HASH_TICK_REQUESTED], peer.next_local_hash_tick_requested)

func reset_mechanized_data() -> void:
	mechanized_input_received.clear()
	mechanized_rollback_ticks = 0

func _process_mechanized_input() -> void:
	for peer_id in mechanized_input_received:
		var peer_input = mechanized_input_received[peer_id]
		for tick in peer_input:
			var input = peer_input[tick]
			var input_frame := _get_or_create_input_frame(int(tick))
			input_frame.add_input_for_player(int(peer_id), input, false)

func execute_mechanized_tick() -> void:
	_process_mechanized_input()
	_physics_process(tick_time)
	reset_mechanized_data()

func execute_mechanized_interpolation_frame(delta: float) -> void:
	_update_input_complete_tick()
	_ran_physics_process = false
	_process(delta)
	_process_mechanized_input()
	reset_mechanized_data()

func execute_mechanized_interframe() -> void:
	_process_mechanized_input()
	reset_mechanized_data()

func sort_dictionary_keys(input: Dictionary) -> Dictionary:
	var output := {}
	
	var keys = input.keys()
	keys.sort()
	for key in keys:
		output[key] = input[key]
	
	return output

func spawn(name: String, parent: Node, scene: PackedScene, data = {}, rename: bool = true) -> Node:
	if not started:
		var res = scene.instantiate()
		parent.add_child(res)
		_spawn_manager._init_node(res, data)
		return res
	
	return _spawn_manager.spawn(name, parent, scene, data, rename)

func despawn(node: Node) -> void:
	if not started:
		node.queue_free()
	else:
		_spawn_manager.despawn(node)
 
 

func set_synced(node: Node, property: String, value, interpolate:=false, deep_duplicate_value:=false) -> void:
	if not node.is_inside_tree() or not started:
		node.set_indexed(property, value)
		return
		
	_property_manager.set_synced(current_tick, node, property, value, interpolate, deep_duplicate_value)

func connect_signal(node: Node, name: String, target: Node, method: String, binds := [], flags := 0) -> void:
	if not started:
		var callable: = Callable(target, method).bindv(binds)
		node.connect(name, callable, flags)
		return
	
	_spawn_manager.connect_signal(node, name, target, method, binds, flags)

func is_in_rollback() -> bool:
	return _in_rollback

func set_default_sound_bus(bus: String) -> void:
	if _sound_manager == null:
		await self.ready
	_sound_manager.default_bus = bus

func play_sound(identifier: String, sound: AudioStream, info: Dictionary = {}) -> void:
	_sound_manager.play_sound(identifier, sound, info)

func ensure_current_tick_input_complete() -> bool:
	if is_current_tick_input_complete():
		return true
	if requested_input_complete_tick == 0 or requested_input_complete_tick > current_tick:
		requested_input_complete_tick = current_tick
	return false

func ordered_dict2str(dict: Dictionary) -> String:
	var ret := "{"
	for i in dict.size():
		var key = dict.keys()[i]
		var value = dict[key]
		var value_str := ordered_dict2str(value) if value is Dictionary else str(value)
		ret += "%s:%s" % [key, value_str]
		if i != dict.size() - 1:
			ret += ", "
	ret += "}"
	return ret

func _debug_check_consistent_local_state(state: StateBufferFrame, message := "Loaded") -> void:
	var hashed_state := _calculate_data_hash(state.data)
	var previously_hashed_frame := _get_state_hash_frame(current_tick)
	var previous_state = _debug_check_local_state_consistency_buffer.pop_front()
	if previously_hashed_frame and previously_hashed_frame.state_hash != hashed_state:
		var comparer = DebugStateComparer.new()
		comparer.find_mismatches(previous_state.data, state.data)
		push_error("%s state is not consistent with saved state:\n %s" % [
			message,
			comparer.print_mismatches(),
			])

func register_event(node: Node, data) -> void:
	if disable_event_registration or not started:
		return
	
	var path := str(node.get_path())
	
	if not _event_scripts.has(path) and not _event_scripts_in_buffer.has(path):
		_event_scripts_in_buffer[path] = node.get_script().resource_path
	
	if not _current_event_buffer_frame_data.has(path):
		_current_event_buffer_frame_data[path] = []
	
	_current_event_buffer_frame_data[path].append(data)


func add_node_in_pool(scene: PackedScene) -> void:
	_spawn_manager.add_node_in_pool(scene)


func set_current_tick_for_replay(p_tick) -> void:
	current_tick = p_tick
	input_tick = p_tick
	_input_complete_tick = p_tick
	_input_send_queue_start_tick = p_tick + 1


func get_events_up_to_tick(tick_number: int, state_data: Dictionary, events: Dictionary, event_scripts: Dictionary) -> Dictionary:
	var res := {}
	for path in events.keys():
		if path == "":
			for tick_events in events[path].values():
				for event in tick_events:
					assert(event.type == "script")
					event_scripts[event.node_path] = load(event.script_path)
		elif event_scripts.has(path):
			var local_state_data = state_data.get(path, {})
			var script = event_scripts[path]
			if script is String:
				script = load(script)
			res[path] = script._prepare_events_up_to_tick(self, tick_number, events[path], local_state_data)
		else:
			push_error("Script of the event sending Node can't be found: %s" % path)
	return res


@rpc("any_peer", "call_local", "reliable")
func _peer_left_for_me(p_peer_id: int) -> void:
	if not (p_peer_id in peers):
		return
	var caller_id: = multiplayer.get_remote_sender_id()
	var d: Array = _peer_left_for_peer.get(p_peer_id, [])
	d.append(caller_id)
	_peer_left_for_peer[p_peer_id] = d
	# do it multiple times if several peers are removed at once
	var redo: = true
	while redo:
		redo = false
		var peers_left: Array = _peer_left_for_peer.keys()
		var to_remove: = []
		for peer_left in peers_left:
			var validated_peers: Array = _peer_left_for_peer[peer_left]
			var all_validated: = true
			var all_peers: = peers.keys().duplicate()
			all_peers.append(network_adaptor.get_network_unique_id())
			for peer in all_peers:
				if not (peer in validated_peers or peer == peer_left):
					all_validated = false
					break
			if all_validated:
				redo = true
				to_remove.append(peer_left)
		for peer_left in to_remove:
			_remove_peer_internal(peer_left)
			_peer_left_for_peer.erase(peer_left)
