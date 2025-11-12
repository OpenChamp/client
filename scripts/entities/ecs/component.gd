## Base Component Class for Entity Component System
## All gameplay components inherit from this base class
class_name Component
extends RefCounted

## Reference to the entity that owns this component
var entity: Node

## Called when component is added to entity
func initialize(owner: Node) -> void:
	entity = owner

## Called during entity._ready()
func on_ready() -> void:
	pass

## Called during entity._physics_process()
func on_physics_process(_delta: float) -> void:
	pass

## Called during entity._process()
func on_process(_delta: float) -> void:
	pass

## Called when entity takes damage
func on_damage_taken(_damage: int, _damage_type: OC.DAMAGE_TYPE) -> void:
	pass

## Called when entity dies
func on_death() -> void:
	pass

## Called when component is removed
func on_cleanup() -> void:
	pass
