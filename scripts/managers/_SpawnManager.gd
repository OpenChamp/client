class_name SpawnManager
extends Node

var game_root: Node # Reference to the main game node passed from outside

var minion_pool: Array = []
var camp_pool: Array = []
var wave_pool: Array = []
# Object Pooling and Spawn rates
func spawn_camp(camp_id: int):
	if game_root == null:
		print("SpawnManager: game_root is not set!")
		return false
	pass;

func spawn_map(map_name: String):
	if game_root == null:
		print("SpawnManager: game_root is not set!")
		return false
	if map_name.is_empty():
		push_warning("Map was not set, defaulting to Konda");
		map_name = "Konda"
	# Check if map file exists
	var map_file = load("res://scenes/maps/" + map_name + ".tscn")
	if map_file == null:
		print("Map file not found: " + map_name)
		return false
	# Load and set up the map
	var map_instance = map_file.instantiate()
	game_root.get_node("./Spawners/Map").add_child(map_instance)
	return true
	
func spawn_player():
	if game_root == null:
		print("SpawnManager: game_root is not set!")
		return false
	pass
		
func spawn_wave():
	if game_root == null:
		print("SpawnManager: game_root is not set!")
		return false
	pass;
	
func set_pool_size():
	pass;
