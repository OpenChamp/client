extends Node

var _CC_Type_Registry := CCTypesRegistry.new()
var _Item_Registry := ItemRegistry.new()
var _Character_Registry := CharacterRegistry.new()

var _RegistryList: Array[RegistryBase] = [
	_CC_Type_Registry,
	_Item_Registry,
	_Character_Registry
]


func _ready():
	pass


func cc_types() -> CCTypesRegistry:
	return _CC_Type_Registry


func items() -> ItemRegistry:
	return _Item_Registry


func characters() -> CharacterRegistry:
	return _Character_Registry


## Get a list of files that are not cached yet.
## This function should be called on the client before loading the manifest file.
## All missing files should be downloaded and cached before loading the manifest file.
func get_cache_misses(manifest: Dictionary) -> Array[String]:
	if not manifest.has("files"):
		return []

	var cache_misses = []
	var keys = manifest["files"].keys()
	for key in keys:
		if not DataCache.is_cached(key):
			cache_misses.append(key)

	return cache_misses


## If executed on a dedicated server, this will load the manifest file from the server's
## file system using the paths defined in the manifest file.
## If executed on a client this will load the manifest file using the file hashes
## and load the files from the cache.
func load_manifest(manifest: Dictionary, gamemode: String = "") -> Dictionary:
	if not manifest.has("files"):
		return {}

	var manifest_dir_path = ""
	if gamemode != "":
		var gamemode_id = Identifier.for_resource("gamemode://" + gamemode)
		manifest_dir_path = AssetIndexer.get_asset_path(gamemode_id).replace("/manifest.json", "")

	var map_config: Dictionary = {}
	var keys = manifest["files"].keys()
	for key in keys:
		var data: Dictionary

		if manifest_dir_path != "":
			var path = manifest_dir_path + "/" + manifest["files"][key]

			if FileAccess.file_exists(path):
				var file = FileAccess.open(path, FileAccess.READ)
				var json_data = JSON.new()
				json_data.parse(file.get_as_text())
				file.close()

				data = json_data.data
			else:
				var json_data = load(path) as JSON
				data = json_data.data
		else:
			data = DataCache.get_cached_json(key).data

		var loaded = false

		for registry in _RegistryList:
			if not registry.can_load_from_json(data):
				continue
			
			loaded = registry.load_from_json(data)
			if loaded:
				break
		
		if not loaded:
			if map_config == {} and data["type"] == "map":
				map_config = data["data"]
			else:
				print("No loader for '" + key + "' : '" + manifest["files"][key] +"' found or failed to load.")


	for registry in _RegistryList:
		registry.assure_validity()

	return map_config
