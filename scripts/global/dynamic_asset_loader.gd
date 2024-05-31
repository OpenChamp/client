extends Node

var asset_map: Dictionary = {}

func path_join(parts: Array) -> String:
	if parts.size() == 0:
		print("empty array given")
		return ""
	
	var joined_parts:String = str(parts[0])
	for i in range(1, parts.size()):
		joined_parts += "/" + str(parts[i])
	
	return joined_parts


func dump_asset_map():
	print("runtime assets map:")
	for key in asset_map.keys():
		print(str(key) + " -> " + asset_map[key])


func _ready():
	var external_dir = DirAccess.open("user://external")
	if not external_dir:
		DirAccess.make_dir_absolute("user://external")
		print("Created external directory, no assets found")
		return
	
	external_dir.list_dir_begin()
	var asset_pack = external_dir.get_next()
	while asset_pack != "":
		if external_dir.current_is_dir():
			_load_asset_pack(asset_pack)
		
		asset_pack = external_dir.get_next()
	
	dump_asset_map()


func _load_asset_pack(pack: String):
	var pack_dir = DirAccess.open(path_join(["user://external", pack]))
	if not pack_dir:
		print("Failed to open asset pack: " + pack)
		return

	print("loading asset pack: " + pack)

	pack_dir.list_dir_begin()
	var asset_group = pack_dir.get_next()

	while asset_group != "":
		if pack_dir.current_is_dir():
			_load_asset_group(pack, asset_group)
		
		asset_group = pack_dir.get_next()


func _load_asset_group(pack: String, group: String):
	var group_dir = DirAccess.open(path_join(["user://external", pack, group]))
	if not group_dir:
		print("Failed to open asset group: " + group)
		return

	print("loading asset group: " + pack + "/" + group)

	group_dir.list_dir_begin()
	var asset_type = group_dir.get_next()
	while asset_type != "":
		match asset_type:
			"textures":
				_load_textures(pack, group)
			"lang":
				_load_lang(pack, group)
			"_":
				print("Unknown asset (" + asset_type + ") in " + pack + "/" + group)
		
		asset_type = group_dir.get_next()


func _load_textures(pack: String, group: String, texture_subdir: String = "textures"):
	var texture_dir = DirAccess.open(path_join(["user://external", pack, group, texture_subdir]))
	if not texture_dir:
		print("Failed to open texture directory")
		return

	print("loading textures for " + pack + "/" + group + "/" + texture_subdir)

	texture_dir.list_dir_begin()
	var texture_name = texture_dir.get_next()
	while texture_name != "":
		if texture_dir.current_is_dir():
			_load_textures(pack, group, texture_subdir + "/" + texture_name)
		else:
			# load texture
			var texture_path = path_join(["user://external", pack, group, texture_subdir, texture_name])
			var texture_id = Identifier.new(group, texture_subdir + "/" + texture_name)

			asset_map[texture_id] = texture_path

		texture_name = texture_dir.get_next()


func _load_lang(pack: String, group: String):
	var lang_dir = DirAccess.open(path_join(["user://external", pack, group, "lang"]))
	if not lang_dir:
		print("Failed to open lang directory")
		return

	print("loading lang files for " + pack + "/" + group)

	lang_dir.list_dir_begin()
	var next_lang_file = lang_dir.get_next()
	while next_lang_file != "":
		var lang_file = next_lang_file
		next_lang_file = lang_dir.get_next()

		if lang_dir.current_is_dir():
			push_error("Lang files should not be in subdirectories (found in " + pack + "/" + group + "/lang)")
			continue
		
		# unlike textures, lang files might be always needed and there is no way to tell
		# which ones are needed and which ones are not
		# because of that, we will load all lang files directly

		var lang_path = path_join(["user://external", pack, group, "lang", lang_file])

		var raw_lang_resource = ResourceLoader.load(lang_path)
		if not raw_lang_resource:
			push_error("Failed to load lang file '" + lang_path + "' from " + pack + "/" + group)
			continue
		
		var lang_resource: Translation = null

		if raw_lang_resource is Translation:
			lang_resource = raw_lang_resource as Translation
		elif raw_lang_resource is OptimizedTranslation:
			lang_resource = raw_lang_resource as OptimizedTranslation
		elif raw_lang_resource is JSON:
			lang_resource = JsonTranslation.fromJson(raw_lang_resource as JSON, lang_file.get_basename())
		else:
			push_error("Invalid lang file '" + lang_path + "' of type '" + str(raw_lang_resource) + "' from " + pack + "/" + group)
			continue

		TranslationServer.add_translation(lang_resource)
		print("Loaded lang file: " + lang_path)
