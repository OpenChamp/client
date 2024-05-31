extends Node

var items: Dictionary = {}


func has_item(item_id: Identifier) -> bool:
	return items.has(item_id)


func get_item_list() -> Array[Item]:
	return items.values()


func serialize_data(json_string):
	var json_data = JSON.new()
	var data = json_data.parse(json_string)

	if not data.data:
		push_error("No data found in JSON string")
		return

	if not data.data is Dictionary:
		push_error("Data is not an object")
		return

	var data_object = data.data as Dictionary

	if not data_object.has("format_version"):
		push_error("No format_version found in JSON data")
		return
	
	var format_version = data_object["format_version"].to_int()
	if format_version != 1:
		push_error("Invalid format_version found in JSON data %d" % format_version)
		return

	if not data_object.has("item_list"):
		push_error("No items found in JSON data")
		return

	if not data_object["item_list"] is Array:
		push_error("Items is not an array")
		return

	_serialize_items_list(data_object["item_list"] as Array)
	

func _serialize_items_list(items_list: Array):

	for item_dict in items_list:
		if not item_dict is Dictionary:
			push_error("Item is not an object")
			return
		
		var new_item = Item.new(item_dict as Dictionary)
		items[new_item.get_id()] = new_item
