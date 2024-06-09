extends ResourceFormatLoader
class_name DynmaicTextureHandler


func _recognize_path(path: String, _type: StringName) -> bool:
	return path.begins_with("texture://")


func _load(
	path:String,
	_original_path:String, 
	_use_sub_threads:bool, 
	_cache_mode:int
):
	var id_string = path.replace("texture://", "")
	var texture_id := Identifier.from_string(id_string)
	if not texture_id.is_valid():
		print("Got invalid Identidier: '" + id_string + "'")
		return FAILED

	var resource_id = Identifier.from_values(texture_id.get_group(), "textures/" + texture_id.get_name())
	var fixed_path: String = AssetIndexer.get_asset_path(resource_id)

	if fixed_path == null:
		print("Dynamic Texture '" + path + "' does not exist in AssetIndexer. (null)")
		return FAILED

	if fixed_path == "":
		print("Dynamic Texture '" + path + "' does not exist in AssetIndexer. (empty)")
		return FAILED

	if not FileAccess.file_exists(fixed_path):
		print("Dynamic Texture '" + path + "' does not exist in Filesystem.")
		return FAILED
	
	print("loading '" + path + "' as: " + fixed_path)

	var loaded_texture = Image.load_from_file(fixed_path)
	if loaded_texture == null:
		print("Error loading image from file.")
	
	loaded_texture = ImageTexture.create_from_image(loaded_texture)

	if loaded_texture == null:
		print("error loading dynamic texture: '" + path + "'")
	
	return loaded_texture
