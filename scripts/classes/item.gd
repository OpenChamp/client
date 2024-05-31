class_name Item extends Object

@export var gold_cost: int = 0
@export var components: Array[String] = []

@export var health_max: int = 0
@export var health_regen: int = 0
@export var mana_max: int = 0
@export var mana_regen: int = 0
@export var armor: int = 0
@export var attack_damage: int = 0
@export var attack_speed: int = 0
@export var movement_speed: int = 0


var id: Identifier
var texture_id: Identifier


func get_id() -> Identifier:
	return id


func get_texture_id() -> Identifier:
	return texture_id


func _init(json_data_object: Dictionary):
	if not json_data_object:
		push_error("Item: No data object provided.")
		return
	
	if not json_data_object.has("id"):
		push_error("Item: No name provided.")
		return

	id = Identifier.from_string(json_data_object["id"])

	if Registries.has_item(id):
		push_error("Item (%s): Item already exists in item registry." % id)
		return

	if not json_data_object.has("texture"):
		push_error("Item (%s): No texture provided." % id)
		return
	
	texture_id = Identifier.from_string(json_data_object["texture"])
	
	if not json_data_object.has("recipe"):
		push_error("Item (%s): No recipe provided." % id)
		return
	
	if not json_data_object["recipe"].has("gold_cost"):
		push_error("Item (%s): No gold cost provided." % id)
		return
	
	gold_cost = json_data_object["recipe"]["gold_cost"]

	if json_data_object["recipe"].has("components"):
		var comps = json_data_object["recipe"]["components"]
		if not (comps is Array):
			push_error("Item (%s): Components must be an array." % id)
			return

		for comp in comps:
			if not (comp is String):
				push_error("Item (%s): Component must be a string." % id)
				return
			
			if not Registries.has_item(comp):
				push_error("Item (%s): Component (%s) not found in item registry." % [id, comp])
				return
			
			components.append(comp)

	if not json_data_object.has("stats"):
		push_error("Item (%s): No stats provided." % id)
		return

	var stats = json_data_object["stats"]
	if not (stats is Dictionary):
		push_error("Item (%s): Stats must be a dictionary." % id)
		return

	if stats.has("health_max"):
		health_max = stats["health_max"]
	
	if stats.has("health_regen"):
		health_regen = stats["health_regen"]
	
	if stats.has("mana_max"):
		mana_max = stats["mana_max"]

	if stats.has("mana_regen"):
		mana_regen = stats["mana_regen"]

	if stats.has("armor"):
		armor = stats["armor"]

	if stats.has("attack_damage"):
		attack_damage = stats["attack_damage"]

	if stats.has("attack_speed"):
		attack_speed = stats["attack_speed"]

	if stats.has("movement_speed"):
		movement_speed = stats["movement_speed"]

	if json_data_object.has("effects"):
		print("Item (%s): Effects not implemented." % id)
		# TODO: Implement item effects
