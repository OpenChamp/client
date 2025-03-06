@tool
extends VBoxContainer

const LogData = preload("res://addons/delta_rollback/log_inspector/LogData.gd")
const ReplayServer = preload("res://addons/delta_rollback/log_inspector/ReplayServer.gd")
const DebugStateComparer = preload("res://addons/delta_rollback/DebugStateComparer.gd")

const JSON_INDENT = "    "

@onready var tick_number_field = $HBoxContainer/TickNumber
@onready var input_data_tree = $GridContainer/InputPanel/InputDataTree
@onready var input_mismatches_data_tree = $GridContainer/InputMismatchesPanel/InputMismatchesDataTree
@onready var state_data_tree = $GridContainer/StatePanel/StateDataTree
@onready var state_mismatches_data_tree = $GridContainer/StateMismatchesPanel/StateMismatchesDataTree

var log_data: LogData
var replay_server: ReplayServer
var replay_peer_id: int

func _ready() -> void:
	for tree in [input_mismatches_data_tree, state_mismatches_data_tree]:
		tree.set_column_title(1, "Local")
		tree.set_column_title(2, "Remote")
		tree.set_column_titles_visible(true)

func set_log_data(_log_data: LogData) -> void:
	log_data = _log_data

func set_replay_server(_replay_server: ReplayServer) -> void:
	replay_server = _replay_server

func set_replay_peer_id(_replay_peer_id: int) -> void:
	replay_peer_id = _replay_peer_id

func refresh_from_log_data() -> void:
	tick_number_field.max_value = log_data.max_tick
	_on_TickNumber_value_changed(tick_number_field.value)

func refresh_replay() -> void:
	if log_data.is_loading():
		return
	
	if replay_server and replay_server.is_connected_to_game():
		var tick: int = int(tick_number_field.value)
		var state_frame: LogData.StateData = log_data.state.get(tick, null)
		if state_frame:
			var state_data: Dictionary
			if state_frame.mismatches.has(replay_peer_id):
				state_data = state_frame.mismatches[replay_peer_id]
			else:
				state_data = state_frame.state
			
			var events = SyncManager.get_events_up_to_tick(tick, state_data, log_data.events, log_data._events_scripts)
			replay_server.send_message({
				type = "load_state",
				state = state_data,
				events = events,
			})

func clear() -> void:
	tick_number_field.max_value = 0
	tick_number_field.value = 0
	_clear_trees()

func _clear_trees() -> void:
	input_data_tree.clear()
	input_mismatches_data_tree.clear()
	state_data_tree.clear()
	state_mismatches_data_tree.clear()

func _on_TickNumber_value_changed(value: float) -> void:
	if log_data.is_loading():
		return
	
	var tick: int = int(value)
	
	var input_frame: LogData.InputData = log_data.input.get(tick, null)
	var state_frame: LogData.StateData = log_data.state.get(tick, null)
	
	_clear_trees()
	
	if input_frame:
		_create_tree_items_from_dictionary(input_data_tree, input_data_tree.create_item(), input_frame.input)
		_create_tree_from_mismatches(input_mismatches_data_tree, input_frame.input, input_frame.mismatches)
	
	if state_frame:
		_create_tree_items_from_dictionary(state_data_tree, state_data_tree.create_item(), state_frame.state)
		_create_tree_from_mismatches(state_mismatches_data_tree, state_frame.state, state_frame.mismatches)
	
	refresh_replay()

static func _convert_array_to_dictionary(a: Array) -> Dictionary:
	var d := {}
	for i in range(a.size()):
		d[str(i)] = a[i]
	return d

func _create_tree_items_from_dictionary(tree: Tree, parent_item: TreeItem, data: Dictionary, data_column: int = 1) -> void:
	for key in data:
		var value = data[key]
		
		var item = tree.create_item(parent_item)
		item.set_text(0, str(key))
		
		if value is Dictionary:	
			_create_tree_items_from_dictionary(tree, item, value)
		elif value is Array:
			_create_tree_items_from_dictionary(tree, item, _convert_array_to_dictionary(value))
		else:
			item.set_text(data_column, str(value))
		
		if key is String and key.begins_with('/root/SyncManager/'):
			item.collapsed = true

func _create_tree_from_mismatches(tree: Tree, data: Dictionary, mismatches: Dictionary) -> void:
	if mismatches.size() == 0:
		return
	
	var root = tree.create_item()
	for peer_id in mismatches:
		var peer_data = mismatches[peer_id]
		
		var peer_item = tree.create_item(root)
		peer_item.set_text(0, "Peer %s" % peer_id)
		
		var comparer = DebugStateComparer.new()
		comparer.find_mismatches(data, peer_data)
		
		for mismatch in comparer.mismatches:
			var mismatch_item = tree.create_item(peer_item)
			mismatch_item.set_expand_right(0, true)
			mismatch_item.set_expand_right(1, true)
			
			match mismatch.type:
				DebugStateComparer.MismatchType.MISSING:
					mismatch_item.set_text(0, "[MISSING] %s" % mismatch.path)
					
					if mismatch.local_state is Dictionary:
						_create_tree_items_from_dictionary(tree, mismatch_item, mismatch.local_state)
					elif mismatch.local_state is Array:
						_create_tree_items_from_dictionary(tree, mismatch_item, _convert_array_to_dictionary(mismatch.local_state))
					else:
						var child = tree.create_item(mismatch_item)
						child.set_text(1, JSON.stringify(mismatch.local_state, JSON_INDENT))
				
				DebugStateComparer.MismatchType.EXTRA:
					mismatch_item.set_text(0, "[EXTRA] %s" % mismatch.path)
					
					if mismatch.remote_state is Dictionary:
						_create_tree_items_from_dictionary(tree, mismatch_item, mismatch.remote_state, 2)
					elif mismatch.remote_state is Array:
						_create_tree_items_from_dictionary(tree, mismatch_item, _convert_array_to_dictionary(mismatch.remote_state), 2)
					else:
						var child = tree.create_item(mismatch_item)
						child.set_text(2, JSON.stringify(mismatch.remote_state, JSON_INDENT))
				
				DebugStateComparer.MismatchType.REORDER:
					mismatch_item.set_text(0, "[REORDER] %s" % mismatch.path)
					
					for i in range(max(mismatch.local_state.size(), mismatch.remote_state.size())):
						var order_item = tree.create_item(mismatch_item)
						if i < mismatch.local_state.size():
							order_item.set_text(1, mismatch.local_state[i])
						if i < mismatch.remote_state.size():
							order_item.set_text(2, mismatch.remote_state[i])
				
				DebugStateComparer.MismatchType.DIFFERENCE:
					mismatch_item.set_text(0, "[DIFF] %s" % mismatch.path)
					
					var child = tree.create_item(mismatch_item)
					child.set_text(1, JSON.stringify(mismatch.local_state, JSON_INDENT))
					child.set_text(2, JSON.stringify(mismatch.remote_state, JSON_INDENT))

func _on_PreviousMismatchButton_pressed() -> void:
	if log_data.is_loading():
		return
	
	var current_tick := int(tick_number_field.value)
	var previous_mismatch := -1
	for mismatch_tick in log_data.mismatches:
		if mismatch_tick < current_tick:
			previous_mismatch = mismatch_tick
		else:
			break
	if previous_mismatch != -1:
		tick_number_field.value = previous_mismatch

func _on_NextMismatchButton_pressed() -> void:
	if log_data.is_loading():
		return
	
	var current_tick := int(tick_number_field.value)
	var next_mismatch := -1
	for mismatch_tick in log_data.mismatches:
		if mismatch_tick > current_tick:
			next_mismatch = mismatch_tick
			break
	if next_mismatch != -1:
		tick_number_field.value = next_mismatch

func _on_StartButton_pressed() -> void:
	tick_number_field.value = 0

func _on_EndButton_pressed() -> void:
	tick_number_field.value = tick_number_field.max_value
