extends ResourceFormatLoader
class_name DynmaicFontHandler


func _recognize_path(path: String, _type: StringName) -> bool:
	return path.begins_with("font://")


func _load(
	path:String,
	_original_path:String, 
	_use_sub_threads:bool, 
	_cache_mode:int
):
	var id_string = path.replace("font://", "")
	var font_id := Identifier.from_string(id_string)
	if not font_id.is_valid():
		print("Got invalid Identidier: '" + id_string + "'")
		return FAILED
	
	var resource_id = Identifier.from_values(font_id.get_group(), "fonts/" + font_id.get_name())
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
	
	var loaded_font := FontFile.new()
	loaded_font.load_dynamic_font(fixed_path)

	if loaded_font == null:
		print("error loading dynamic font: '" + path + "'")
	
	return loaded_font
	