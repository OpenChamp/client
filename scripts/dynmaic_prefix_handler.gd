extends ResourceFormatLoader
class_name DynmaicPrefixHandler


func _recognize_path(path: String, type: StringName) -> bool:
	return path.begins_with("dyn://")

func _load(
	path:String,
	original_path:String, 
	use_sub_threads:bool, 
	cache_mode:int
):
	print("loading dynamic resource: " + path)
	var string_id = path.replace("dyn://", "")
	var resource_id = Identifier.from_string(string_id)
	if not resource_id.is_valid():
		print("Got invalid Identidier: '" + string_id + "'")
		return FAILED
	
	var path_parts = resource_id.get_name().split("/")
	var suffix = _get_suffix(path_parts[0])
	
	var fixed_path = "user://external/default_assets/"
	fixed_path += resource_id.get_group()
	fixed_path += "/" + resource_id.get_name()
	fixed_path += suffix
	
	if not FileAccess.file_exists(fixed_path):
		print("Dynamic Resource '" + path + "' does not exist in Filesystem.")
		return FAILED
	
	var loaded_resource = null
	fixed_path = ProjectSettings.globalize_path(fixed_path)
	print("loading '" + path + "' as: " + fixed_path)
	
	if path_parts[0] == "textures":
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
