extends MultiplayerSpawner

var loaded_champs = {};

func _ready() -> void:
	_add_all_champ_scenes("res://scenes/champs")

func spawn_player(id:int, champ:String):
	if !multiplayer.is_server(): return;
	if id==1: return;
	if not loaded_champs.has(champ + ".tscn"):
		get_tree().quit(-1);
	var new_player:CharacterBody3D = loaded_champs[champ + ".tscn"].instantiate()
	new_player.name = str(id);
	await get_node(spawn_path).call_deferred("add_child", new_player)
	new_player.translate(Vector3i(randi_range(-10, 10), 0, 0))
	

func _add_all_champ_scenes(path: String) -> void:
	# Use DirAccess (Godot 4) to iterate filesystem entries
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("player_spawner: Failed to open directory '%s'" % path)
		return

	# begin listing directory entries; skip hidden/navigational entries in the loop
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		# skip hidden and navigational entries
		if fname.begins_with("."):
			fname = dir.get_next()
			continue

		var full_path := path + "/" + fname
		if dir.current_is_dir():
			# recurse into subdirectory
			_add_all_champ_scenes(full_path)
		else:
			# Only consider .tscn files (case-insensitive)
			if fname.to_lower().ends_with(".tscn"):
				add_spawnable_scene(full_path)
				loaded_champs[fname] = (load(full_path))
				print("player_spawner: Added spawnable scene: %s" % full_path)
		fname = dir.get_next()

	dir.list_dir_end()
