extends RefCounted

enum LogType {
	HEADER,
	FRAME,
	STATE,
	INPUT,
	EVENT,
}

enum FrameType {
	INTERFRAME,
	TICK,
	INTERPOLATION_FRAME,
}

enum SkipReason {
	ADVANTAGE_ADJUSTMENT,
	INPUT_BUFFER_UNDERRUN,
	WAITING_TO_REGAIN_SYNC,
}

var data := {}

var _start_times := {}

var _writer_thread: Thread
var _writer_thread_semaphore: Semaphore
var _writer_thread_mutex: Mutex
var _write_queue := []
var _log_file: FileAccess
var _started := false

var SyncManager

func _init(_sync_manager) -> void:
	# Inject the SyncManager to prevent cyclic reference.
	SyncManager = _sync_manager
	
	_writer_thread_mutex = Mutex.new()
	_writer_thread_semaphore = Semaphore.new()
	_writer_thread = Thread.new()

func start(log_file_name: String, peer_id: int, match_info: Dictionary = {}) -> int:
	if not _started:
		var err: int
		
		_log_file = FileAccess.open_compressed(log_file_name, FileAccess.WRITE, FileAccess.COMPRESSION_FASTLZ)
		err = FileAccess.get_open_error()
		if err != OK:
			return err
		
		var header := {
			log_type = LogType.HEADER,
			peer_id = peer_id,
			match_info = match_info,
		}
		_log_file.store_var(header)
		
		_started = true
		_writer_thread.start(_writer_thread_function)
	
	return OK

func stop() -> void:
	_writer_thread_mutex.lock()
	var is_running = _started
	_writer_thread_mutex.unlock()
	
	if is_running:
		if data.size() > 0:
			write_current_data()
		
		_writer_thread_mutex.lock()
		_started = false
		_writer_thread_mutex.unlock()
		
		_writer_thread_semaphore.post()
		_writer_thread.wait_to_finish()
		
		_log_file.close()
		_write_queue.clear()
		data.clear()
		_start_times.clear()

static func _get_system_time_msecs() -> int:
	return int(round(1000.0 * Time.get_unix_time_from_system()))

func _writer_thread_function() -> void:
	while true:
		_writer_thread_semaphore.wait()
		
		var data_to_write
		var should_exit: bool
		
		_writer_thread_mutex.lock()
		data_to_write = _write_queue.pop_front()
		should_exit = not _started
		_writer_thread_mutex.unlock()
		
		if data_to_write is Dictionary:
			_log_file.store_var(data_to_write)
		elif should_exit:
			break

func write_current_data() -> void:
	if data.size() == 0:
		return
	
	var copy := data.duplicate(true)
	copy['log_type'] = LogType.FRAME
	
	if not copy.has('frame_type'):
		copy['frame_type'] = FrameType.INTERFRAME
	
	_writer_thread_mutex.lock()
	_write_queue.push_back(copy)
	_writer_thread_mutex.unlock()
	
	_writer_thread_semaphore.post()
	
	data.clear()

func write_state(tick: int, state: Dictionary) -> void:
	var data_to_write := {
		'log_type': LogType.STATE,
		'tick': tick,
		'state': SyncManager.sync_booster.serialize(state.duplicate(true)),
	}
	
	_writer_thread_mutex.lock()
	_write_queue.push_back(data_to_write)
	_writer_thread_mutex.unlock()
	
	_writer_thread_semaphore.post()

func write_event(tick: int, event: Dictionary) -> void:
	if event.is_empty():
		return
	
	var data_to_write := {
		'log_type': LogType.EVENT,
		'tick': tick,
		'event': SyncManager.sync_booster.serialize(event.duplicate(true)),
	}
	
	_writer_thread_mutex.lock()
	_write_queue.push_back(data_to_write)
	_writer_thread_mutex.unlock()
	
	_writer_thread_semaphore.post()

func write_input(tick: int, input: Dictionary) -> void:
	var data_to_write := {
		log_type = LogType.INPUT,
		tick = tick,
		input = {},
	}
	for key in input.keys():
		data_to_write['input'][key] = SyncManager.sync_booster.serialize(input[key][0].duplicate(true))
	
	_writer_thread_mutex.lock()
	_write_queue.push_back(data_to_write)
	_writer_thread_mutex.unlock()
	
	_writer_thread_semaphore.post()

func begin_interframe() -> void:
	if not data.has('frame_type'):
		data['frame_type'] = FrameType.INTERFRAME
	if not data.has('start_time'):
		data['start_time'] = _get_system_time_msecs()

func end_interframe() -> void:
	if not data.has('frame_type'):
		data['frame_type'] = FrameType.INTERFRAME
	if not data.has('start_time'):
		data['start_time'] = _get_system_time_msecs() - 1
	data['end_time'] = _get_system_time_msecs()
	write_current_data()

func begin_tick(tick: int) -> void:
	if data.size() > 0:
		end_interframe()
	
	data['frame_type'] = FrameType.TICK
	data['tick'] = tick
	data['start_time'] = _get_system_time_msecs()

func end_tick(start_ticks_usecs: int) -> void:
	data['end_time'] = _get_system_time_msecs()
	data['duration'] = float(Time.get_ticks_usec() - start_ticks_usecs) / 1000.0
	write_current_data()

func skip_tick(skip_reason: int, start_ticks_usecs: int) -> void:
	data['skipped'] = true
	data['skip_reason'] = skip_reason
	end_tick(start_ticks_usecs)

func begin_interpolation_frame(tick: int) -> void:
	if data.size() > 0:
		end_interframe()
	
	data['frame_type'] = FrameType.INTERPOLATION_FRAME
	data['tick'] = tick
	data['start_time'] = _get_system_time_msecs()

func end_interpolation_frame(start_ticks_usecs: int) -> void:
	data['end_time'] = _get_system_time_msecs()
	data['duration'] = float(Time.get_ticks_usec() - start_ticks_usecs) / 1000.0
	write_current_data()

func log_fatal_error(msg: String) -> void:
	if not data.has('end_time'):
		data['end_time'] = _get_system_time_msecs()
	data['fatal_error'] = true
	data['fatal_error_message'] = msg
	write_current_data()

func set_value(key: String, value) -> void:
	data[key] = value

func add_value(key: String, value) -> void:
	if not data.has(key):
		data[key] = []
	data[key].append(value)

func merge_array_value(key: String, value: Array) -> void:
	if not data.has(key):
		data[key] = value
	else:
		data[key] = data[key] + value

func increment_value(key: String, amount: int = 1) -> void:
	if not data.has(key):
		data[key] = amount
	else:
		data[key] += amount

func start_timing(timer: String) -> void:
	assert(not _start_times.has(timer), "Timer already exists: %s" % timer)
	_start_times[timer] = Time.get_ticks_usec()

func stop_timing(timer: String, accumulate: bool = false) -> void:
	assert(_start_times.has(timer), "No such timer: %s" % timer)
	if _start_times.has(timer):
		add_timing(timer, float(Time.get_ticks_usec() - _start_times[timer]) / 1000.0, accumulate)
		_start_times.erase(timer)

func add_timing(timer: String, msecs: float, accumulate: bool = false) -> void:
	if not data.has('timings'):
		data['timings'] = {}
	if data['timings'].has(timer) and accumulate:
		var old_average = data['timings'][timer + '.average']
		var old_count = data['timings'][timer + '.count']
		
		data['timings'][timer] += msecs
		data['timings'][timer + '.max'] = max(data['timings'][timer + '.max'], msecs)
		data['timings'][timer + '.average'] = ((old_average * old_count) + msecs) / (old_count + 1)
		data['timings'][timer + '.count'] += 1
	else:
		data['timings'][timer] = msecs
		if accumulate:
			data['timings'][timer + '.max'] = msecs
			data['timings'][timer + '.average'] = 0.0
			data['timings'][timer + '.count'] = 1
			
