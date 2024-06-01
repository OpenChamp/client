extends Node

const HASH_CHUNK_SIZE = 1024
var asset_map: Dictionary = {}


func path_join(parts: Array) -> String:
	if parts.size() == 0:
		print("empty array given")
		return ""
	
	var joined_parts:String = str(parts[0])
	for i in range(1, parts.size()):
		joined_parts += "/" + str(parts[i])
	
	return joined_parts


func get_file_hash(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	
	# Start a SHA-256 context.
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	
	var file = FileAccess.open(path, FileAccess.READ)
	while not file.eof_reached():
		ctx.update(file.get_buffer(HASH_CHUNK_SIZE))
	
	return ctx.finish().hex_encode()


func get_string_hash(data: String) -> String:
	# Start a SHA-256 context.
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)

	ctx.update(data.to_utf8_buffer())

	return ctx.finish().hex_encode()


func has_patch_cached(data_hash: String) -> bool:
	var patchdata_path = path_join(["user://cache", "patchdata", data_hash + ".json"])
	return FileAccess.file_exists(patchdata_path)


func get_cached_patch(data_hash: String):
	var patchdata_path = path_join(["user://cache", "patchdata", data_hash + ".json"])
	if not FileAccess.file_exists(patchdata_path):
		push_error("No patch with given hash cached: " + patchdata_path)
		return null
	
	var patchdata = ResourceLoader.load(patchdata_path)
	if not patchdata:
		push_error("Failed to load patchdata: " + patchdata_path)
		return null
	
	if not patchdata.data is Dictionary:
		push_error("Invalid patchdata type: " + str(patchdata))
		return null
	
	return patchdata.data as Dictionary


func cache_patch_data(data):
	var data_string: String = ""

	if data is Dictionary:
		data_string = JSON.stringify(data, "    ")
	elif data is String:
		data_string = data
	else:
		push_error("Invalid patchdata type: " + str(data))
		return

	var data_hash = get_string_hash(data_string)
	if not data_hash:
		push_error("Failed to hash patchdata")
		return

	if DynamicAssetLoader.has_patch_cached(data_hash):
		print("Patchdata already cached: " + data_hash)
		return

	DirAccess.make_dir_recursive_absolute("user://cache/patchdata")

	var patchdata_path = path_join(["user://cache", "patchdata", data_hash + ".json"])
	var file = FileAccess.open(patchdata_path, FileAccess.WRITE)
	if not file:
		push_error("Failed to open patchdata file for writing: " + patchdata_path)
		return
	
	file.store_string(data_string)
	file.close()


func dump_asset_map():
	print("runtime assets map:")
	for key in asset_map.keys():
		print(str(key) + " -> " + asset_map[key])


func load_asset(asset_id: Identifier) -> Resource:
	if not asset_map.has(asset_id):
		push_error("Asset not found: " + str(asset_id))
		return null
	
	var asset_path = asset_map[asset_id]
	var asset = ResourceLoader.load(asset_path)
	if not asset:
		push_error("Failed to load asset: " + str(asset_id) + " from " + asset_path)
		return null
	
	return asset


func load_texture(asset_id: Identifier) -> Texture:
	var texture_id = Identifier.new(asset_id.group, "textures/" + asset_id.name)
	return load_asset(texture_id) as Texture


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
		if not group_dir.current_is_dir():
			asset_type = group_dir.get_next()
			continue

		# check if it is a shared asset type
		match asset_type:
			"_":
				pass
	
		# skip loadingclient side files in headless mode	
		if DisplayServer.get_name() != "headless":
			match asset_type:
				"textures":
					_load_textures(pack, group)
				"lang":
					_load_lang(pack, group)
				"patchdata":
					_cache_patchdata(pack, group)
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


func _cache_patchdata(pack: String, group: String):
	var patchdata_dir = DirAccess.open(path_join(["user://external", pack, group, "patchdata"]))
	if not patchdata_dir:
		print("Failed to open patchdata directory")
		return

	print("caching patchdata for " + pack + "/" + group)

	patchdata_dir.list_dir_begin()
	var next_patchdata_name = patchdata_dir.get_next()
	while next_patchdata_name != "":
		if patchdata_dir.current_is_dir():
			push_error("Patchdata files should not be in subdirectories (found in " + pack + "/" + group + "/patchdata)")
			next_patchdata_name = patchdata_dir.get_next()
			continue

		var patchdata_name = next_patchdata_name
		next_patchdata_name = patchdata_dir.get_next()

		if not patchdata_name.ends_with(".json"):
			push_error("Invalid patchdata file type: " + patchdata_name)
			continue
		
		var patchdata_path = path_join(["user://external", pack, group, "patchdata", patchdata_name])
		var patch_data_string = FileAccess.open(patchdata_path, FileAccess.READ).get_as_text()

		DynamicAssetLoader.cache_patch_data(patch_data_string)
