class_name Item extends Object

var gold_cost: int = 0
var components: Array[String] = []

var stats = StatCollection.new()

var id: Identifier
var texture_id: Identifier


func get_id() -> Identifier:
	return id


func get_texture_id() -> Identifier:
	return texture_id


func get_stats() -> StatCollection:
	return stats


func get_combine_cost() -> int:
	return gold_cost


func calculate_gold_cost() -> int:
	var cost = gold_cost
	for component in components:
		cost += RegistryManager.items().get(component).calculate_gold_cost()

	return cost


func is_valid() -> bool:
	if not id.is_valid():
		return false

	if not texture_id.is_valid():
		return false

	if gold_cost < 0:
		return false

	if components.size() > 0:
		for component in components:
			if not Identifier.from_string(component).is_valid():
				return false

			if not RegistryManager.items().contains(component):
				return false
			
	return true


func _init(
	_id: Identifier,
	_texture_id: Identifier,
	_gold_cost: int,
	_components: Array[String],
	_stats: StatCollection
):
	id = _id
	texture_id = _texture_id
	gold_cost = _gold_cost
	components = _components
	stats = _stats

	