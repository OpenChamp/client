extends Node

var items: Dictionary = {}


func has_item(item_id: Identifier) -> bool:
	return items.has(item_id)


func get_item_list() -> Array[Item]:
	return items.values()


func serialize_from_hash(data_hash: String) -> bool:
	if not DynamicAssetLoader.has_patch_cached(data_hash):
		print("Patch not found in cache")
		return false

	var data = DynamicAssetLoader.get_cached_patch(data_hash)
	if not data:
		print("Failed to load patch")
		return false

	if not data is Dictionary:
		print("Data is not an object")
		return false

	return _serialize_data(data)


func serialize_from_json_string(json_string: String) -> bool:
	var json_data = JSON.new()
	var err = json_data.parse(json_string)

	if err != OK:
		push_error("Failed to parse JSON data")
		return false

	if not json_data:
		push_error("Invalid JSON data")
		return false

	if not json_data.data is Dictionary:
		push_error("Data is not an object")
		return false

	if not _serialize_data(json_data.data):
		return false

	DynamicAssetLoader.cache_patch_data(json_string)
	return true


func _serialize_data(data_object: Dictionary) -> bool:

	if not data_object.has("format_version"):
		push_error("No format_version found in JSON data")
		return false
	
	var format_version = data_object["format_version"].to_int()
	if format_version != 1:
		push_error("Invalid format_version found in JSON data %d" % format_version)
		return false

	if not data_object.has("item_list"):
		push_error("No items found in JSON data")
		return false

	if not data_object["item_list"] is Array:
		push_error("Items is not an array")
		return false

	return _serialize_items_list(data_object["item_list"] as Array)
	

func _serialize_items_list(items_list: Array) -> bool:

	for item_dict in items_list:
		if not item_dict is Dictionary:
			push_error("Item is not an object")
			return false
		
		var new_item = Item.new(item_dict as Dictionary)
		items[new_item.get_id()] = new_item

	return true
