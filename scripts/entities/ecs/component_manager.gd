## Component Manager - Manages ECS components for an entity
class_name ComponentManager
extends RefCounted

var entity: Node
var components: Dictionary = {}  # component_type -> Component instance

func _init(owner: Node) -> void:
	entity = owner

## Add a component to the entity
func add_component(component: Component) -> Component:
	if component == null:
		push_error("ComponentManager: Cannot add null component")
		return null
	
	var component_type = component.get_class()
	
	if components.has(component_type):
		push_warning("ComponentManager: Component %s already exists, replacing" % component_type)
		components[component_type].on_cleanup()
	
	component.initialize(entity)
	components[component_type] = component
	print("ComponentManager: Added %s to %s" % [component_type, entity.name])
	return component

## Get a component by type
func get_component(component_type: String) -> Component:
	return components.get(component_type, null)

## Check if entity has component
func has_component(component_type: String) -> bool:
	return components.has(component_type)

## Remove a component
func remove_component(component_type: String) -> void:
	if components.has(component_type):
		components[component_type].on_cleanup()
		components.erase(component_type)
		print("ComponentManager: Removed %s from %s" % [component_type, entity.name])

## Call on_ready() for all components
func on_ready() -> void:
	for component in components.values():
		component.on_ready()

## Call on_physics_process() for all components
func on_physics_process(delta: float) -> void:
	for component in components.values():
		component.on_physics_process(delta)

## Call on_process() for all components
func on_process(delta: float) -> void:
	for component in components.values():
		component.on_process(delta)

## Call on_damage_taken() for all components
func on_damage_taken(damage: int, damage_type: OC.DAMAGE_TYPE) -> void:
	for component in components.values():
		component.on_damage_taken(damage, damage_type)

## Call on_death() for all components
func on_death() -> void:
	for component in components.values():
		component.on_death()

## Cleanup all components
func cleanup() -> void:
	for component in components.values():
		component.on_cleanup()
	components.clear()

## Get all components (for debugging)
func get_all_components() -> Array:
	return components.values()

## Get component count
func get_component_count() -> int:
	return components.size()
