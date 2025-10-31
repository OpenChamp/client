extends MultiplayerSpawner

@export var map_scene:PackedScene

func spawn_map():
	if !multiplayer.is_server(): return;
	print("Attempting to spawn map")
	var map = map_scene.instantiate()
	map.name="GameMap"
	get_node(spawn_path).call_deferred("add_child", map, true)
