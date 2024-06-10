extends ResourceFormatLoader
class_name DynmaicPrefixHandler


func _recognize_path(path: String, _type: StringName) -> bool:
	if path.begins_with("texture://"):
		return true
	
	if path.begins_with("font://"):
		return true
	
	return path.begins_with("dyn://")


func _load(
	path:String,
	_original_path:String, 
	_use_sub_threads:bool, 
	_cache_mode:int
):
	var resource_id := Identifier.for_resource(path)
	if not resource_id.is_valid():
		print("Got invalid Identidier: '" + path + "'")
		return FAILED
	
	var fixed_path: String = AssetIndexer.get_asset_path(resource_id)
	var try_result = try_resource_load(fixed_path)
	if typeof(try_result) == typeof(FAILED) and try_result == FAILED:
		return FAILED

	if try_result != null:
		return try_result

	print("loading '" + resource_id.to_string() + "' as: " + fixed_path)
	match resource_id.get_content_type():
		"textures":
			return load_texture_from_path(fixed_path)
		"fonts":
			return load_font_from_path(fixed_path)

	return FAILED


func try_resource_load(resource_path):
	if resource_path == null:
		print("Dynamic Asset '" + resource_path + "' does not exist in AssetIndexer. (null)")
		return FAILED

	if resource_path == "":
		print("Dynamic Asset '" + resource_path + "' does not exist in AssetIndexer. (empty)")
		return FAILED

	if not FileAccess.file_exists(resource_path):
		print("Dynamic Asset '" + resource_path + "' does not exist in Filesystem.")
		return FAILED
	
	if ResourceLoader.exists(resource_path):
		print("loading '"+ resource_path + "' from the ResourceLoader.")
		return ResourceLoader.load(resource_path)

	return null


func load_texture_from_path(fixed_path: String):
	var loaded_texture = Image.load_from_file(fixed_path)
	if loaded_texture == null:
		print("Error loading image from file.")
	
	loaded_texture = ImageTexture.create_from_image(loaded_texture)

	if loaded_texture == null:
		print("error loading dynamic texture: '" + fixed_path + "'")
	
	return loaded_texture


func load_font_from_path(fixed_path: String):
	var loaded_font := FontFile.new()
	loaded_font.load_dynamic_font(fixed_path)

	if loaded_font == null:
		print("error loading dynamic font: '" + fixed_path + "'")
	
	return loaded_font
