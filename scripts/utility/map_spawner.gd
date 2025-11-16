extends MultiplayerSpawner

func spawn_map(map_name:String):
	if !multiplayer.is_server(): return
	print("Attempting to spawn map")
	var map_scene = load(str("res://scenes/maps/", map_name, ".tscn"))
	var map = map_scene.instantiate()
	map.name="GameMap"
	get_node(spawn_path).call_deferred("add_child", map, true)
