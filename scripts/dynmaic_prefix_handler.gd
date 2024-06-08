extends ResourceFormatLoader
class_name DynmaicPrefixHandler


func _recognize_path(path: String, _type: StringName) -> bool:
	return path.begins_with("dyn://")


func _load(
	path:String,
	_original_path:String, 
	_use_sub_threads:bool, 
	_cache_mode:int
):
	print("loading dynamic resource: " + path)
	var string_id = path.replace("dyn://", "")
	var resource_id := Identifier.from_string(string_id)
	if not resource_id.is_valid():
		print("Got invalid Identidier: '" + string_id + "'")
		return FAILED

	var asset_map = AssetIndexer.get_asset_map()
	print("asset_map: " + str(asset_map))
	
	var fixed_path: String = AssetIndexer.get_asset_path(resource_id)

	if fixed_path == null:
		print("Dynamic Resource '" + path + "' does not exist in AssetIndexer. (null)")
		return FAILED

	if fixed_path == "":
		print("Dynamic Resource '" + path + "' does not exist in AssetIndexer. (empty)")
		return FAILED

	if not FileAccess.file_exists(fixed_path):
		print("Dynamic Resource '" + path + "' does not exist in Filesystem.")
		return FAILED
	
	var loaded_resource = null
	print("loading '" + path + "' as: " + fixed_path)
	
	if resource_id.is_texture():
		loaded_resource = Image.load_from_file(fixed_path)
		if loaded_resource == null:
			print("Error loading image from file.")
		
		loaded_resource = ImageTexture.create_from_image(loaded_resource)
	else:
		if not ResourceLoader.exists(fixed_path):
			print("Dynamic Resource '" + path + "' does not exist in ResourceLoader.")
			return FAILED
	
		loaded_resource = ResourceLoader.load(fixed_path)
	
	if loaded_resource == null:
		print("error loading dynamic resource: '" + path + "'")
	
	return loaded_resource

func _get_suffix(resource_type: String) -> String:
	match resource_type:
		"textures":
			return ".png"
		_:
			return ""
