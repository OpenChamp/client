extends MultiplayerSpawner

const MapPath = "res://scenes/maps/"

func ready():
	# load all maps in MapPath
	var dir = DirAccess.open(MapPath);
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn"):
				var map_scene = load(MapPath + file_name)
				if map_scene:
					var map_instance = map_scene.instantiate()
					add_child(map_instance)
					print("MapSpawner: Loaded map %s" % file_name)
				else:
					push_error("MapSpawner: Failed to load map %s" % file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("MapSpawner: Failed to open directory %s" % MapPath)