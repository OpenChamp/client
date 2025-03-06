extends Node
class_name NetworkArray

var contents := []:
	set = _readonly,
	get = get_contents
var _size := []
var _contents_ind := 0
var _buffer_size: int

func _ready() -> void:
	add_to_group("network_sync")
	_buffer_size = ProjectSettings.get_setting("network/rollback/max_buffer_size")
	for _i in _buffer_size:
		contents.append([])
		_size.append(0)

func _readonly(_value):
	pass

func get_contents() -> Array:
	return contents[_contents_ind].slice(0, _size[_contents_ind])

func append(value) -> void:
	var local_contents: Array = contents[_contents_ind]
	var index: int = _size[_contents_ind]
	if local_contents.size() <= index:
		local_contents.append(value)
	else:
		local_contents[index] = value
	contents[_contents_ind] = local_contents
	_size[_contents_ind] = index + 1
	SyncManager.register_event(self, {
		type = "append",
		value = value,
	})

func clear() -> void:
	_contents_ind = (_contents_ind + 1) % _buffer_size
	contents[_contents_ind].clear()
	SyncManager.register_event(self, {
		type = "clear",
	})

func _save_state() -> Dictionary:
	return {
		contents_ind = _contents_ind,
		size = _size.duplicate()
	}

func _load_state(state: Dictionary) -> void:
	_contents_ind = state.contents_ind
	_size = state.size.duplicate()

func _load_state_forward(state: Dictionary, events: Array) -> void:
	for i in _buffer_size:
		contents[i].clear()
		_size[i] = 0
	contents[_contents_ind] = events
	_size[_contents_ind] = events.size()
	_load_state(state)

static func _prepare_events_up_to_tick(_sync_manager: Node, tick_number: int, events: Dictionary, _state: Dictionary) -> Array:
	# only keep the last tick for each node
	var final_contents := []
	for t in events.keys():
		# Only load up to the asked tick
		if t > tick_number:
			break
		var new_event = events[t]
		for e in new_event:
			if e.type == "append":
				final_contents.append(e.value)
			elif e.type == "clear":
				final_contents.clear()
	return final_contents
