extends Node

var CC_Type_Registry: CCTypesRegistry = CCTypesRegistry.new()

var RegistryList: Array[RegistryBase] = [
    CC_Type_Registry,
]


func _ready():
    pass


func cc_types() -> CCTypesRegistry:
    return CC_Type_Registry


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
func load_manifest(manifest: Dictionary, manifest_dir_path: String = ""):
    if not manifest.has("files"):
        return

    var keys = manifest["files"].keys()
    for key in keys:
        var data: Dictionary

        if DisplayServer.get_name() == "headless":
            var path = manifest_dir_path + "/" + manifest["files"][key]

            var file = FileAccess.open(path, FileAccess.READ)
            var json_data = JSON.new()
            json_data.parse(file.get_as_text())
            file.close()

            data = json_data.data
        else:
            data = DataCache.get_cached_json(key).data

        for registry in RegistryList:
            if not registry.can_load_from_json(data):
                continue

            registry.load_from_json(data)

