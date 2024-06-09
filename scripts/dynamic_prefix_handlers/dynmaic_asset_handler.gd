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
	var string_id = path.replace("dyn://", "")
	var resource_id := Identifier.from_string(string_id)
	if not resource_id.is_valid():
		print("Got invalid Identidier: '" + string_id + "'")
		return FAILED
	
	match resource_id.get_content_type():
		"textures":
			return ResourceLoader.load("texture://"+resource_id.get_group() + ":" + resource_id.get_name().replace("textures/", ""))
		"fonts":
			return ResourceLoader.load("font://"+resource_id.get_group() + ":" + resource_id.get_name().replace("fonts/", ""))

	return FAILED