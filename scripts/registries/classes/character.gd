extends Object
class_name Character

var stats = StatCollection.new()
var stat_growth = StatCollection.new()

var id: Identifier
var model_id: Identifier
var icon_id: Identifier

var tags: Array[String] = []

func get_id() -> Identifier:
	return id


func get_model_id() -> Identifier:
	if AssetIndexer.get_asset_path(model_id) == "":
		print("Character (%s): Model asset not found." % id.to_string())
		return Identifier.for_resource("model://openchamp:character/fallback")
	
	return model_id


func get_icon_id() -> Identifier:
	if AssetIndexer.get_asset_path(icon_id) == "":
		print("Character (%s): Icon asset not found." % id.to_string())
		return Identifier.for_resource("texture://openchamp:character/fallback")
	
	return icon_id


func get_stats() -> StatCollection:
	return stats


func get_stat_growth() -> StatCollection:
	return stat_growth


func is_valid(_registry: RegistryBase = null) -> bool:
	if not id.is_valid():
		return false
			
	return true


func _init(
	_id: Identifier,
	_model_id: Identifier,
	_icon_id: Identifier,
	_stats: StatCollection,
	_stat_growth: StatCollection,
	_tags: Array[String]
):
	id = _id
	model_id = _model_id
	icon_id = _icon_id
	stats = _stats
	stat_growth = _stat_growth
	tags = _tags
