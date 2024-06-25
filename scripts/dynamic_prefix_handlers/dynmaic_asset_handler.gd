extends ResourceFormatLoader
class_name DynmaicPrefixHandler


static func get_resource_path(path: String):
	var resource_id := Identifier.for_resource(path)
	if not resource_id.is_valid():
		print("Got invalid Identidier: '" + path + "'")
		return null

	var content_type := resource_id.get_content_type() as String
	
	var fixed_path := AssetIndexer.get_asset_path(resource_id) as String
	if fixed_path == null or fixed_path == "":
		print("Asset not found in AssetIndexer: '" + path + "'")
		return null

	return [fixed_path, content_type]


func _recognize_path(path: String, _type: StringName) -> bool:
	if path.begins_with("texture://"):
		return true
	
	if path.begins_with("font://"):
		return true

	if path.begins_with("material://"):
		return true

	if path.begins_with("model://"):
		return true

	if path.begins_with("gamemode://"):
		return true
	
	return path.begins_with("dyn://")


func _load(
	path:String,
	_original_path:String, 
	_use_sub_threads:bool, 
	_cache_mode:int
):	
	var resource_stuff = DynmaicPrefixHandler.get_resource_path(path)
	if resource_stuff == null:
		print("Failed to get resource path for: '" + path + "'")
		return FAILED

	var fixed_path := resource_stuff[0] as String
	var content_type := resource_stuff[1] as String
	
	var try_result = try_resource_load(fixed_path)
	if try_result != null:
		return try_result

	print("loading '" + path + "' as: " + fixed_path)
	match content_type:
		"textures":
			return load_texture_from_path(fixed_path)
		"fonts":
			return load_font_from_path(fixed_path)
		_:
			if fixed_path.ends_with(".json"):
				return load_json_from_path(fixed_path)

	return FAILED


func _rename_dependencies(path:String, renames: Dictionary):
	return OK


func try_resource_load(resource_path):	
	if ResourceLoader.exists(resource_path):
		print("loading '"+ resource_path + "' from the ResourceLoader.")
		var load_result = ResourceLoader.load(resource_path)
		if load_result != null:
			return load_result
		else:
			print("Failed to load resource from ResourceLoader: '" + resource_path + "'")
			return null

	return null


func load_texture_from_path(fixed_path: String):
	var loaded_image := Image.load_from_file(fixed_path)
	if loaded_image == null:
		print("Error loading image from file.")
		return FAILED
	
	var loaded_texture := ImageTexture.create_from_image(loaded_image)

	if loaded_texture == null:
		print("error loading dynamic texture: '" + fixed_path + "'")
		return FAILED
	
	return loaded_texture


func load_font_from_path(fixed_path: String):
	var loaded_font := FontFile.new()
	loaded_font.load_dynamic_font(fixed_path)

	if loaded_font == null:
		print("error loading dynamic font: '" + fixed_path + "'")
	
	return loaded_font


func load_json_from_path(fixed_path: String):
	var file := FileAccess.open(fixed_path, FileAccess.READ)
	if file == null:
		print("error dynamic json not in file loader: '" + fixed_path + "'")
		return FAILED

	var json_data := JSON.new()
	var error = json_data.parse(file.get_as_text())
	file.close()

	if error != OK:
		print("error parsing dynamic json: '" + fixed_path + "'")
		return FAILED

	return json_data
