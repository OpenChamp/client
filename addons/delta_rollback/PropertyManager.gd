extends PropertyManager


func _ready() -> void:
	initialize(ProjectSettings.get_setting("network/rollback/max_buffer_size") + 2)


func _network_process(_data: Dictionary) -> void:
	if SyncManager._logger:
		SyncManager._logger.start_timing("property_manager_np")
	var events = network_process(SyncManager.current_tick)
	for e in events:
		SyncManager.register_event(self, e)
	if SyncManager._logger:
		SyncManager._logger.stop_timing("property_manager_np")


func _save_state() -> Array:
	return save_state()


func _load_state(state: Array) -> void:
	if SyncManager._logger:
		SyncManager._logger.start_timing("property_manager")
	load_state(state, SyncManager.load_type)
	if SyncManager._logger:
		SyncManager._logger.stop_timing("property_manager", true)


func _interpolate_state(state_before: Array, state_after: Array, weight: float) -> void:
	interpolate_state(state_before, state_after, weight)


func _load_state_forward(state: Array, events: Dictionary) -> void:
	load_state_forward(state, events)


static func _prepare_events_up_to_tick(sync_manager: Node, tick_number: int, events: Dictionary, state: Array) -> Dictionary:
	# only keep the last tick for each node
	var prepared_events := {}
	for t in events.keys():
		# Only load up to the asked tick
		if t > tick_number:
			break
		var new_event = events[t]
		for e in new_event:
			# don't care if the node is not present or if the value will be erased by the state
			if sync_manager.get_node_or_null(e[0]) and not e[0] in state[0]:
				prepared_events[e[0]] = e[1]
				
	return prepared_events
