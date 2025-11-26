class_name EntityManagementSystem
extends Node

const TEMPLATE_SCENES = {
	"champion" : preload("res://scenes/champs/ranger.tscn"),
	"melee_minion" : preload("res://scenes/entities/minions/minion_entity_melee.tscn"),
	"ranged_minion" : preload("res://scenes/entities/minions/minion_entity_ranged.tscn"),
	"magic_minion" : preload("res://scenes/entities/minions/minion_entity_mage.tscn"),
	"cannon_minion" : preload("res://scenes/entities/minions/minion_entity_cannon.tscn"),
}

enum EntityState { # -- Pulled from entity_state.hpp -- cmkrist 24/11/25
	SPAWNED,
	IDLE,
	# Idle is for players || If jungle is item and is attacked, it goes from SPAWNED -> IDLE -> ATTACKING
	PATHFINDING_WAITING,
	HOLDING_FOR_TARGET,
	MOVING,
	STOPPING,
	STUCK,
	ATTACKING,
	DEAD
};

var available_ids: Dictionary = {}
var entity_ref: Dictionary = {}
var game_root:Node


func _ready():
	clear_ids()
	
func clear_ids():
	for i in 10000:
		available_ids[i] = true
	
func valid_id(id:int):
	if available_ids.has(id):
		available_ids[id] = false
		return true
	return false
	

func create_entity(entity_data): # See utility/serializer/decode_entity_packet for structure -- cmkrist
	if not valid_id(entity_data.id):
		push_warning("EntityID already taken for ",entity_data.id)
		return;
	if entity_data.template_id == "player":
		return # Not an entity to the client
	var entity : Entity = TEMPLATE_SCENES[entity_data.template_id].instantiate()
	print(EntityTemplates.get_available_entities());
	var entity_template = EntityTemplates.get_entity_template(entity_data.template_id)
	var components = entity_template.get("_children")
	if not components:
		push_warning("Entity: ", entity.name , " Template: ", entity_data.template_id, " Error: Failed to initialize XML Components")
		return
	for key in components:
		match key:
			"stats":
				print("Loading stats for template: ", entity_data.template_id)
				print("Stats from template: ", components["stats"]);
				for stat_name in components["stats"]:
					if stat_name in entity:
						# Typecast everything to string for consistency -- cmkrist 19/11/2025
						var value : String = str(components["stats"][stat_name])
						print("  Setting %s = %s" % [stat_name, value])
						entity.set_stat(stat_name, value)
					else:
						print("  WARNING: Entity class doesn't have stat '%s'" % stat_name)
			_:
				print(key, components[key])
	entity.name = str(entity_data.id)
	entity.set_stat("team", str(entity_data.team))
	if not game_root:
		push_error("No Game Root Set")
		return
	game_root.get_node("Entities").add_child(entity, true)
	entity.global_position =  Vector3(entity_data.pos.x, 1, entity_data.pos.y)
	print("Entity %d spawned: health=%f, max_health=%f" % [entity_data.id, entity.health, entity.max_health])
	entity_ref[entity_data.id] = entity

func destroy_entity(entity_id):
	if entity_ref.has(entity_id) and entity_ref[entity_id]:
		var entity = entity_ref[entity_id]
		entity.queue_free()
		entity_ref.erase(entity_id)
	available_ids[entity_id] = true

func handle_combat(combat_data):
	if not entity_ref.has(combat_data.attacker_id) or not entity_ref.has(combat_data.target_id):
		push_error("Combat attempted on invalid entitites:", combat_data.attacker_id, "|", combat_data.target_id)
		return
	entity_ref.get(combat_data.attacker_id).dealt_damage(combat_data.damage)
	entity_ref.get(combat_data.target_id).took_damage(combat_data.damage)

func state_change(entity_id, state:EntityState):
	if not entity_ref.has(entity_id) or not entity_ref[entity_id]:
		push_error("Received State for non-existing entity: ", entity_id)
		return
	entity_ref[entity_id].update_state(state)
	
func update_entity_stat(stat):
	print("update_entity_stat called with: ", stat, " (type: %s)" % typeof(stat))
	if not entity_ref.has(stat.id) or not entity_ref[stat.id]:
		push_error("Received State for non-existing entity: ", stat.id)
		return
	if not entity_ref[stat.id].has_method("set_stat"):
		push_error("Entity with ID %d has no set_stat method!" % stat.id)
		return;
	print("Calling set_stat(%s, %s)" % [stat.name, stat.value])
	entity_ref[stat.id].set_stat(stat.name, stat.value)
