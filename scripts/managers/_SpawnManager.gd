class_name SpawnManagerClass
extends Node

## Signals for better event-driven architecture
signal map_spawned(map_instance: Node)
signal player_spawned(player_id: int, player_instance: Node)
signal wave_spawned(wave_data: Dictionary)
signal camp_spawned(camp_id: int, camp_instance: Node)
signal spawn_failed(spawner_type: String, reason: String)

## Constants
const DEFAULT_MAP := "Konda"
const MAP_PATH := "res://scenes/maps/%s.tscn"
const SPAWNER_GROUPS := {
	"map": "map_spawner",
	"player": "player_spawner",
	"minion": "minion_spawner",
	"jungle": "jungle_spawner"
}

## Exported variables
@export var game_root: Node
@export var entity_root: Node
@export_group("Spawners")
@export var map_spawner: MultiplayerSpawner
@export var player_spawner: MultiplayerSpawner
@export var minion_spawner: MultiplayerSpawner
@export var jungle_spawner: MultiplayerSpawner

@export_group("Pool Settings")
@export var minion_pool_size: int = 50
@export var camp_pool_size: int = 10
@export var wave_pool_size: int = 5

## Object pools - using typed arrays for better performance
var minion_pool: Array[Node] = []
var camp_pool: Array[Node] = []
var wave_pool: Array[Node] = []

## Cache for loaded resources
var _resource_cache: Dictionary = {}
var _spawner_cache: Dictionary = {}

## Player Controller
@onready var player_controller = load("res://scenes/ui/game_controller.tscn")

func _ready() -> void:
	_initialize_pools()

## Initialize System
func initialize(root: Node):
	# Make sure everything is good
	reset();
	# Spawn Nodes
	game_root = root
	if not root.get_node_or_null("./Entities"):
		var node = Node3D.new()
		node.name = "Entities"
		root.add_child(node, true)
	entity_root = root.get_node("./Entities")
	# Pools
	_initialize_pools()
	
	
## Initialize object pools
func _initialize_pools() -> void:
	minion_pool.resize(minion_pool_size)
	camp_pool.resize(camp_pool_size)
	wave_pool.resize(wave_pool_size)

## Reset all spawners and clear caches
func reset() -> void:
	map_spawner = null
	player_spawner = null
	minion_spawner = null
	jungle_spawner = null
	_spawner_cache.clear()
	_clear_pools()

## Clear all object pools
func _clear_pools() -> void:
	for pool in [minion_pool, camp_pool, wave_pool]:
		for obj in pool:
			if obj and is_instance_valid(obj):
				obj.queue_free()
		pool.clear()

## Generic spawner validation with caching
func _get_spawner(spawner_ref: MultiplayerSpawner, spawner_type: String) -> MultiplayerSpawner:
	# Return cached spawner if available
	if spawner_ref:
		return spawner_ref
	
	# Check cache
	if _spawner_cache.has(spawner_type):
		return _spawner_cache[spawner_type]
	
	# Find and cache spawner
	var group_name = SPAWNER_GROUPS.get(spawner_type, "")
	if group_name.is_empty():
		push_error("Invalid spawner type: %s" % spawner_type)
		return null
	
	var spawner = get_tree().get_first_node_in_group(group_name)
	if spawner:
		_spawner_cache[spawner_type] = spawner
	
	return spawner

## Validate if spawner is ready
func _is_spawner_ready(spawner: MultiplayerSpawner, spawner_type: String) -> bool:
	if not game_root:
		spawn_failed.emit(spawner_type, "GameRoot not set")
		return false
	
	var valid_spawner = _get_spawner(spawner, spawner_type)
	if not valid_spawner:
		spawn_failed.emit(spawner_type, "Spawner not found")
		return false
	
	# Update the reference
	match spawner_type:
		"map": map_spawner = valid_spawner
		"player": player_spawner = valid_spawner
		"minion": minion_spawner = valid_spawner
		"jungle": jungle_spawner = valid_spawner
	
	return true

## Load resource with caching
func _load_cached_resource(path: String) -> Resource:
	if _resource_cache.has(path):
		return _resource_cache[path]
	
	var resource = load(path)
	if resource:
		_resource_cache[path] = resource
	
	return resource
	

## Spawn map with validation and error handling
func spawn_map(map_name: String = "") -> bool:
	if not _is_spawner_ready(map_spawner, "map"):
		return false
	
	# Use default map if not specified
	if map_name.is_empty():
		push_warning("Map name not provided, using default: %s" % DEFAULT_MAP)
		map_name = DEFAULT_MAP
	
	# Load map resource
	var map_path = MAP_PATH % map_name
	var map_resource = _load_cached_resource(map_path)
	
	if not map_resource:
		var error_msg = "Map file not found: %s" % map_path
		push_error(error_msg)
		spawn_failed.emit("map", error_msg)
		return false
	
	# Instantiate and spawn
	var map_instance = map_resource.instantiate()
	if not map_instance:
		spawn_failed.emit("map", "Failed to instantiate map")
		return false
	
	map_spawner.spawn(map_instance)
	map_spawned.emit(map_instance)
	return true

func spawn_entity(entity: Node3D, position: Vector3 = Vector3.ZERO, parent: String = ""):
	# Called by EntityManager after entity creation
	if not entity_root:
		push_error("SpawnManager: Not initialized correctly - entity_node is null")
		return false
	if not entity:
		push_error("SpawnManager: Entity to spawn is null")
		return false
	if not entity.is_class("Node3D"):
		push_error("SpawnManager: Entity to spawn is not a Node3D")
		return false

	# Parent
	if not parent.is_empty():
		if entity_root and entity_root.has_node(parent):
			entity_root.get_node(parent).add_child(entity, true)
	else:
		entity_root.add_child(entity, true)
	
	# Position
	if position != Vector3.ZERO:
		entity.global_position = position
	else:
		entity.global_position = entity.server_position

	return true;
	

	

	


func spawn_player_controller():
	var controller_instance = player_controller.instantiate()
	game_root.add_child(controller_instance)

## Get object from pool or create new one
func _get_from_pool(pool: Array, scene_path: String) -> Node:
	# Try to find inactive object in pool
	for obj in pool:
		if obj and is_instance_valid(obj) and not obj.is_inside_tree():
			return obj
	
	# Create new object if pool is empty
	var resource = _load_cached_resource(scene_path)
	if resource:
		return resource.instantiate()
	
	return null

## Return object to pool
func _return_to_pool(pool: Array, obj: Node) -> void:
	if not obj or not is_instance_valid(obj):
		return
	
	# Remove from scene tree but keep in memory
	if obj.is_inside_tree():
		obj.get_parent().remove_child(obj)
	
	# Add to pool if not already there
	if obj not in pool:
		pool.append(obj)

## Set pool sizes dynamically
func set_pool_size(pool_type: String, size: int) -> void:
	match pool_type:
		"minion":
			minion_pool_size = size
			minion_pool.resize(size)
		"camp":
			camp_pool_size = size
			camp_pool.resize(size)
		"wave":
			wave_pool_size = size
			wave_pool.resize(size)
		_:
			push_warning("Invalid pool type: %s" % pool_type)

## Get pool statistics
func get_pool_stats() -> Dictionary:
	return {
		"minion_pool": {
			"size": minion_pool.size(),
			"active": minion_pool.filter(func(obj): return obj and obj.is_inside_tree()).size()
		},
		"camp_pool": {
			"size": camp_pool.size(),
			"active": camp_pool.filter(func(obj): return obj and obj.is_inside_tree()).size()
		},
		"wave_pool": {
			"size": wave_pool.size(),
			"active": wave_pool.filter(func(obj): return obj and obj.is_inside_tree()).size()
		}
	}
