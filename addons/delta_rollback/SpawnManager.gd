extends Node

const REUSE_DESPAWNED_NODES_SETTING := 'network/rollback/spawn_manager/reuse_despawned_nodes'

var spawn_records := {}
var spawned_nodes := {}
var retired_nodes := {}
var interpolation_nodes := {}
var counter := {}
var waiting_before_remove: = {}
var ticks_before_remove: = 20
var connections: = {}

enum {
	UNDO_DESPAWN,
	UNDO_SPAWN,
}

var reuse_despawned_nodes := false

var _frame_spawn_parents := {}

func _ready() -> void:
	if ProjectSettings.has_setting(REUSE_DESPAWNED_NODES_SETTING):
		reuse_despawned_nodes = ProjectSettings.get_setting(REUSE_DESPAWNED_NODES_SETTING)
	ticks_before_remove = ProjectSettings.get_setting("network/rollback/max_buffer_size") + 2
	
#	add_to_group('network_sync')

func reset() -> void:
	spawn_records.clear()
	counter.clear()
	waiting_before_remove.clear()
	connections.clear()
	
	for node in spawned_nodes.values():
		node.queue_free()
	spawned_nodes.clear()
	
	interpolation_nodes.clear()
	
	for nodes in retired_nodes.values():
		for node in nodes:
			node.queue_free()
	retired_nodes.clear()

func _rename_node(name: String) -> String:
	if not counter.has(name):
		counter[name] = 0
	counter[name] += 1
	return name + str(counter[name])

func _remove_colliding_node(name: String, parent: Node, warning: = true) -> void:
	var existing_node = parent.get_node_or_null(name)
	if existing_node:
		if warning:
			push_warning("Removing node %s which is in the way of new spawn" % existing_node)
		parent.remove_child(existing_node)
		existing_node.queue_free()

static func _node_name_sort_callback(a: Node, b: Node) -> bool:
	return a.name.casecmp_to(b.name) == -1

func _alphabetize_children(parent: Node) -> void:
	var children = parent.get_children()
	children.sort_custom(_node_name_sort_callback)
	for index in range(children.size()):
		var child = children[index]
		parent.move_child(child, index)

func _instance_scene(scene: PackedScene) -> Node:
	var resource_path: = scene.resource_path
	if retired_nodes.has(resource_path):
		var nodes: Array = retired_nodes[resource_path]
		var node: Node

		while nodes.size() > 0:
			node = retired_nodes[resource_path].pop_front()
			if is_instance_valid(node) and not node.is_queued_for_deletion():
				break
			else:
				node = null

		if nodes.size() == 0:
			retired_nodes.erase(resource_path)

		if node:
			#print ("Reusing %s" % resource_path)
			return node

	#print ("Instancing new %s" % resource_path)
	var node = scene.instantiate()
	return node

func add_node_in_pool(scene: PackedScene) -> void:
	var resource_path: = scene.resource_path
	if not retired_nodes.has(resource_path):
		retired_nodes[resource_path] = []
	var array: Array = retired_nodes[resource_path]
	array.append(scene.instantiate())

func spawn(name: String, parent: Node, scene: PackedScene, data, rename: bool = true) -> Node:
	var spawned_node = _instance_scene(scene)
	var internal_name = _rename_node(name)
	if rename:
		name = internal_name
	_remove_colliding_node(name, parent)
	spawned_node.name = name
	parent.add_child(spawned_node)
	for n in get_tree().get_nodes_in_group("network_sync"):
		SyncManager.set_groups_for_node(n)
	_frame_spawn_parents[parent] = true
	
	var spawn_record := {
		name = spawned_node.name,
		parent = parent.get_path(),
		scene = scene.resource_path,
	}

	spawn_records[internal_name] = spawn_record
	spawned_nodes[internal_name] = spawned_node

	#print ("[%s] spawned: %s" % [SyncManager.current_tick, spawned_node.name])
	spawned_node.set_meta("spawn_tick", SyncManager.current_tick)
	spawned_node.set_meta("spawn_name", internal_name)
	_init_node(spawned_node, data)

	return spawned_node

func despawn(node: Node) -> void:
	if node.has_method("_network_despawn"):
		node._network_despawn()
	
	if not node.has_meta("spawn_name"):
		push_error("Can't despawn a node that was not spawned")
		return
	
	var internal_name: String = node.get_meta("spawn_name")
	if node.get_parent():
		node.get_parent().remove_child(node)
	
	waiting_before_remove[internal_name] = 0

func _network_process(_data: Dictionary) -> void:
	for p in _frame_spawn_parents:
		_alphabetize_children(p)
	_frame_spawn_parents.clear()
	var to_remove: = []
	for key in waiting_before_remove.keys():
		waiting_before_remove[key] += 1
		if waiting_before_remove[key] > ticks_before_remove:
			to_remove.append(key)
	for remove_internal_name in to_remove:
		_delete_node(remove_internal_name)

func _delete_node(internal_name: String) -> void:
	# This node was already deleted and we are rolling back, just erase remaining state
	if not spawned_nodes.has(internal_name):
		spawn_records.erase(internal_name)
		waiting_before_remove.erase(internal_name)
		return
	
	var node: Node = spawned_nodes[internal_name]
	if node.get_parent():
		node.get_parent().remove_child(node)
	
	if reuse_despawned_nodes and is_instance_valid(node) and not node.is_queued_for_deletion():
		if node.has_method('_network_prepare_for_reuse'):
			node._network_prepare_for_reuse()
		if connections.has(node):
			for connection in connections[node]:
				var callable = Callable(connection[1], connection[2])
				node.disconnect(connection[0], callable)
			connections.erase(node)
		var scene_path
		if interpolation_nodes.has(internal_name):
			scene_path = interpolation_nodes[internal_name].scene
		else:
			scene_path = spawn_records[internal_name].scene
		if not retired_nodes.has(scene_path):
			retired_nodes[scene_path] = []
		retired_nodes[scene_path].append(node)
	else:
		node.queue_free()

	spawn_records.erase(internal_name)
	spawned_nodes.erase(internal_name)
	waiting_before_remove.erase(internal_name)


func _init_node(node: Node, args) -> void:
	if not node.has_method("_network_spawn"):
		return
	
	var processed_data = args
	if node.has_method("_network_spawn_preprocess"):
		processed_data = node.callv("_network_spawn_preprocess", args) if args is Array \
			else node._network_spawn_preprocess(args)
	SyncManager.register_event(self, {
			type = "init",
			node = node.get_meta("spawn_name"),
			data = processed_data,
		})
	# Disable event registration because registering the call is enough
	SyncManager.disable_event_registration = true
	if processed_data is Array:
		node.callv("_network_spawn", processed_data)
	else:
		node._network_spawn(processed_data)
	SyncManager.disable_event_registration = false


func _save_state() -> Dictionary:
	return {
		spawn_records = spawn_records.duplicate(),
		counter = counter.duplicate(),
		waiting_before_remove = waiting_before_remove.duplicate()
	}

func _load_state(state: Dictionary) -> void:
	if SyncManager._logger:
		SyncManager._logger.start_timing("spawn_manager_load_state_%s" % SyncManager.load_type)
	_frame_spawn_parents.clear()
	
	if SyncManager.load_type == SyncManager.LoadType.ROLLBACK:
		# clear interpolation data
		for internal_name in interpolation_nodes.keys():
			if interpolation_nodes[internal_name].type == UNDO_SPAWN:
				_delete_node(internal_name)
		interpolation_nodes.clear()
	
	for internal_name in spawned_nodes.keys():
		if state.spawn_records.has(internal_name):
			if waiting_before_remove.has(internal_name) and not state.waiting_before_remove.has(internal_name):
				# Node that is absent before load but should be added
				var node: Node = spawned_nodes[internal_name]
				var parent: Node = get_node(state.spawn_records[internal_name].parent)
				parent.add_child(node)
				_frame_spawn_parents[parent] = true
				if SyncManager.load_type == SyncManager.LoadType.INTERPOLATION_BACKWARD:
					interpolation_nodes[internal_name] = {
						type = UNDO_DESPAWN,
						scene = spawn_records[internal_name].scene,
					}
			elif SyncManager.load_type == SyncManager.LoadType.INTERPOLATION_FORWARD and interpolation_nodes.has(internal_name):
				if interpolation_nodes[internal_name].type == UNDO_SPAWN:
					# unspawn is cancelled, node is restored
					var node: Node = spawned_nodes[internal_name]
					var parent: Node = get_node(state.spawn_records[internal_name].parent)
					parent.add_child(node)
					_frame_spawn_parents[parent] = true
					interpolation_nodes.erase(internal_name)
				elif interpolation_nodes[internal_name].type == UNDO_DESPAWN:
					# undespawn is cancelled, remove node
					var node: Node = spawned_nodes[internal_name]
					if node.get_parent():
						node.get_parent().remove_child(node)
		else:
			if SyncManager.load_type == SyncManager.LoadType.INTERPOLATION_BACKWARD:
				# keep this node, it will be used in interpolation_forward
				interpolation_nodes[internal_name] = {
					type = UNDO_SPAWN,
					scene = spawn_records[internal_name].scene,
				}
				var node: Node = spawned_nodes[internal_name]
				if node.get_parent():
					node.get_parent().remove_child(node)
			else:
				# This node's spawn was cancelled, we can remove it completely
				_delete_node(internal_name)
	
	for p in _frame_spawn_parents:
		_alphabetize_children(p)
	_frame_spawn_parents.clear()

	spawn_records = state['spawn_records'].duplicate()
	counter = state['counter'].duplicate()
	waiting_before_remove = state['waiting_before_remove'].duplicate()
	if SyncManager._logger:
		SyncManager._logger.stop_timing("spawn_manager_load_state_%s" % SyncManager.load_type)

func _load_state_forward(state: Dictionary, events: Dictionary) -> void:
	for internal_name in state.spawn_records.keys():
		if not spawned_nodes.has(internal_name):
			var spawn_record = state.spawn_records[internal_name]
			var spawned_node = _instance_scene(load(spawn_record.scene))
			var name = spawn_record.name
			var parent = get_node(spawn_record.parent)
			_remove_colliding_node(name, parent, false)
			spawned_node.name = name
			spawned_node.set_meta("spawn_name", internal_name)
			spawned_nodes[internal_name] = spawned_node
			parent.add_child(spawned_node)
			_alphabetize_children(parent)
	_load_state(state)
	_load_events(events)

func _load_events(events: Dictionary) -> void:
	for internal_name in events.keys():
		var parent = get_node_or_null(spawn_records[internal_name].parent)
		if parent:
			var node = parent.get_node(NodePath(spawn_records[internal_name].name))
			for e in events[internal_name]:
				if e['type'] == "init" and node.has_method("_network_spawn"):
					var args = e['data']
					if args is Array:
						node.callv("_network_spawn", args)
					else:
						node._network_spawn(args)
				elif e['type'] == "connect":
					var data = e['data'].duplicate()
					data[1] = get_node(data[1])
					node.callv("connect", data)


static func _prepare_events_up_to_tick(_sync_manager: Node, tick_number: int, events: Dictionary, state: Dictionary) -> Dictionary:
	# only keep the last tick for each node
	var prepared_events := {}
	for t in events.keys():
		# Only load up to the asked tick
		if t > tick_number:
			break
		var new_event = events[t]
		for e in new_event:
			var path = e['node']
			if not state.spawn_records.has(path):
				continue
			if not prepared_events.has(path):
				prepared_events[path] = []
			prepared_events[path].append(e)
	return prepared_events



func connect_signal(node: Node, name: String, target: Node, method: String, binds := [], flags := 0) -> void:
	if (not node.has_meta("spawn_tick")) or node.get_meta("spawn_tick") != SyncManager.current_tick:
		push_error("connect_signal only connects nodes on the tick they were spawn (desync risk)")
		return
	
	var callable: = Callable(target, method).bindv(binds)
	node.connect(name, callable, flags)
	SyncManager.register_event(self, {
		type = "connect",
		node = node.get_meta("spawn_name"),
		data = [name, target.get_path(), method, binds.duplicate(true), flags],
	})
	if not connections.has(node):
		connections[node] = []
	connections[node].append([name, target, method])
