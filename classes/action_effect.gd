extends Node

## The base class for all action effects.
## [br][br]
## This class creates a common interface for all action effects
## and provides some basic functionality that all action effects
## should have.
## [br][br]
## Actions effects are used to define the effects of actions
## that can be performed by units in the game.
## These effects can both be active and passive and can have
## a wide range of effects on the game world.
## [br][br]
## This class is meant to be extended by other classes that
## implement specific action effects.
class_name ActionEffect


## The activation state of the action effect
## [br][br]
## This is used to determine what the action effect is currently doing
## and what it should do next upon activation.
## Note that this set of states is not exhaustive and might get extended
## in the future. Don't rely on the exact values of this enum.
enum ActivationState{
	## Indicates that the action effect is not doing anything
	NONE,
	## Indicates that the action effect is ready to be activated
	READY,
	## Indicates that the action effect is currently in the targeting phase
	## This is used to make sure that only one effect shows a range indicator at a time
	TARGETING,
	## Indicates that the action effect is currently channeling
	## This means that the ability is currently having an effect on the game world
	## but will be interrupted if the caster is interrupted or moves.
	CHANNELING,
	## Indicates that the action effect is currently active.
	## This state is used for effects that have a duration and are not interrupted by movement.
	## The state will decay into the COOLDOWN or READY state once the duration is over.
	ACTIVE,
	## Indicates that the action effect is currently on cooldown.
	## The on_activation function should just do nothing in this state.
	COOLDOWN
}


## The type of an an active ability.
## [br][br]
## This is used to determine how certain effects should be applied.
## For example, a single targeted ability should only affect one target
## while an area untargeted ability should affect all units in an area.
enum AbilityType{
	## Indicates that the ability is passive and can not be activated.
	PASSIVE,
	## Indicates that the ability is targeted and can only affect one unit.
	## In other words this is a point and click ability.
	SINGLE_TARGETED,
	## Point and click ability that can affect multiple units.
	## This is used mostly for abilities that potentially hit multiple units but are not area effects.
	MULTILE_TARGETED,
	## Indicates that the ability is untargeted but only affects one unit.
	SINGLE_UNTARGETED,
	## Indicates that an ability affects all units in an area but disappears after one use.
	AREA_ONETIME,
	## Indicates that an ability affects all units in an area and stays active for a duration.
	## These DOT effects will be applied in regular intervals and on first contact.
	AREA_CONTINUOUS
}


# Common fields for all action effects
# These are all protected fields and should not be accessed directly
# outside of the action effect class and its subclasses.


## The current activation state of the action effect
var _activation_state: ActivationState = ActivationState.NONE


## The type of ability described by the action effect
var _ability_type: AbilityType = AbilityType.PASSIVE


## The currently running timer for the action effect
## If nothing is running this should be null
var _current_timer: Timer = null


## Indicates if the action effect has been loaded and is ready to be used
## This should be false until _from_dict has been called
var _is_loaded: bool = false


## The display id of the action effect
## This field is used to have a unique name for action effects
## created by the same action effect subclass.
## This is used to as the translation key for the action effect
## and to identify the action effect in the game world.
## This field is set in the generic _from_dict function.
var _display_id: Identifier = null


## Indicates if the action effect is exclusive.
## This means a unit can only have one effect with the
## same display id active at a time.
## This is set in the generic _from_dict function and optional.
var _is_exclusive: bool = false


## Create a new action effect from a dictionary
## This will load the action effect based on the class name,
## which has to be in the dictionary and be a subclass of ActionEffect.
## The dictionary should contain all the data needed to create the
## specific action effect subclass.
## The return value should be the new action effect instance or null if the
## creation failed.
static func from_dict(_dict: Dictionary) -> ActionEffect:
	if not _dict.has("base_id"):
		print("Could not create action effect from dictionary. Dictionary has no base_id key.")
		return null

	var _class_name = _dict["base_id"]
	if not ClassDB.class_exists(_class_name):
		print("Could not create action effect from dictionary. Class does not exist: " + _class_name)
		return null

	if _class_name == "ActionEffect":
		print("Could not create action effect from dictionary. Class is the base class: " + _class_name)
		return null

	if not ClassDB.is_parent_class(_class_name, "ActionEffect"):
		print("Could not create action effect from dictionary. Class is not a subclass of ActionEffect: " + _class_name)
		return null
	
	var _instance = ClassDB.instantiate(_class_name) as ActionEffect
	if _instance == null:
		print("Could not create action effect subclass instance: " + _class_name)
		return null

	if not _dict.has("display_id") or not _dict["display_id"].is_string():
		print("Could not create action effect from dictionary. Dictionary has no display_id key.")
		return null
	_instance._display_id = Identifier.from_string(_dict["display_id"])

	if _dict.has("is_exclusive") and _dict["is_exclusive"].is_bool():
		_instance._is_exclusive = _dict["is_exclusive"]

	if _instance._from_dict(_dict) == false:
		print("Could not create action effect from dictionary. Could not load data: " + _class_name)
		return null
	
	return _instance


# The getter functions for the action effect


## Get the current activation state of the action effect
func get_activation_state() -> ActivationState:
	return _activation_state


## Get the type of ability described by the action effect
func get_ability_type() -> AbilityType:
	return _ability_type


## Get the currently running timer for the action effect
func get_current_timer() -> Timer:
	return _current_timer


## Check if the action effect has been loaded and is ready to be used
## This should always be true if an action effect has been created
## succefully with from_dict.
func is_loaded() -> bool:
	return _is_loaded


## Get the display id of the action effect.
## Use this to identify the action effect in the game world.
## This is used as the translation key for the action effect,AbilityType
## to find an icon for the action effect and much more.
func get_display_id() -> Identifier:
	return _display_id


## Check if the action effect is exclusive.
## Use this to prevent shop purchases and other actions
## that would add an effect with the same display id to a unit.
func is_exclusive() -> bool:
	return _is_exclusive


# All the virtual functions that may be overridden by subclasses


## Activate the action effect.
## [br][br]
## Depending on the type of action effect this might either
## change the activation state or do nothing
func on_activation(_caster: Unit) -> ActivationState:
	return _activation_state


## Deactivate the action effect.
## [br][br]
## Depending on the type of action effect this might either
## change the activation state or do nothing.
## If the action effect is in the TARGETING state it should
## be canceled and the activation state should be set to READY or COOLDOWN.
func on_deactivation(_caster: Unit) -> ActivationState:
	return _activation_state


## Upgrade the action effect.
## [br][br]
## This function should be called when the action effect is upgraded.
## This will most likely only be used by player units, when they spend level up points.
func on_upgrade(_caster: Unit) -> ActivationState:
	return _activation_state


## Handle the auto attack cast event.
## [br][br]
## This function should be called when a unit casts an auto attack.
## This may be used to apply effects that change the projectile spawn behavior.
## One example would be a passive effect that spawns a second projectile on auto attack.
func on_auto_attack_cast (_caster: Unit, _target: Unit) -> ActivationState:
	return _activation_state


## Handle the auto attack hit event.
## [br][br]
## This function should be called when a unit's auto attack projectile hits a target.
## This is the main way to apply effects that are triggered by auto attacks.
## One example would be extra damage on crit.
func on_auto_attack_hit (_caster: Unit, _target: Unit, _crit: bool) -> ActivationState:
	return _activation_state


## Handle the auto attack miss event.
## [br][br]
## This function should be called when a unit's auto attack projectile misses a target.
## This can be used to apply effects that are triggered by a miss.
## One example would be a passive effect that applies a debuff on miss
func on_auto_attack_miss (_caster: Unit, _target: Unit) -> ActivationState:
	return _activation_state


## Handle the auto attack block event.
## [br][br]
## This function should be called when a unit's auto attack projectile is blocked by a unit.
## This can be used to apply effects that are triggered by a block.
## One example would be a passive effect that applies a debuff on block with a chance.
## Another would be applying healing when blocking damage an ally would have taken.
## Note: This should be raised by the blocker, not the caster.
func on_auto_attack_block(_blocker: Unit, _caster: Unit, _target: Unit, _missed: bool = true) -> ActivationState:
	return _activation_state


## Handle the auto attack received event.
## [br][br]
## This function should be called when a unit receives an auto attack.
## This can be used to apply effects that are triggered by receiving an auto attack.
## One example would be a passive effect that applies a buff on hit with a chance.
## Another example would be to reduce crit damage taken.
func on_auto_attack_received(_target: Unit, _caster: Unit, _crit: bool) -> ActivationState:
	return _activation_state


## Handle the ability cast event.
## [br][br]
## This function should be called when a unit casts an ability.
## This may be used to apply effects that change the ability cast behavior.
## In a way this is similar to on_auto_attack_cast but for abilities.
## It allows to spawn extra projectiles or apply effects before the ability intself is cast.
## [br][br]
## Note that for untargted abilities the targets array will be empty or null.
## For targeted abilities the targets array will contain the target unit(s).
func on_ability_cast (_caster: Unit, _targets: Array[Unit], _ability: ActionEffect) -> ActivationState:
	return _activation_state


## Handle the ability hit event.
## [br][br]
## This function should be called when an ability hits its targets.
## This is the main way to apply effects that are triggered by abilities.
## One example would be a passive effect that applies a debuff on hit with a chance.
## Another example would be simply extra damage on hit.
## [br][br]
## Note that the ability type is passed to allow for different effects based on the ability type.
## Also the targets are passed to allow for effects that are triggered by hitting multiple targets.
func on_ability_hit (_caster: Unit, _targets: Array[Unit], _ability: ActionEffect) -> ActivationState:
	return _activation_state


## Handle the ability miss event.
## [br][br]
## This function should be called when an ability misses its targets.
## This can be used to apply effects that are triggered by a miss.
func on_ability_miss (_caster: Unit, _targets: Array[Unit], _ability: ActionEffect) -> ActivationState:
	return _activation_state


## Handle the ability block event.
## [br][br]
## This function should be called when an ability is blocked by a unit.
## This can be used to apply effects that are triggered by a block.
func on_ability_block(_blocker: Unit, _caster: Unit, _targets: Array[Unit], _ability: ActionEffect, _missed: bool = true) -> ActivationState:
	return _activation_state


## Handle being hit by an ability.
## [br][br]
## This function should be called when a unit is hit by an ability.
## This can be used to apply effects that are triggered by being hit by an ability.
## One example would be a passive effect that reduces damage taken from abilities.
func on_ability_received(_target: Unit, _caster: Unit, _ability: ActionEffect) -> ActivationState:
	return _activation_state


## Actually load the action effect from a dictionary.
## The dictionary should contain all the data needed to create the
## specific action effect subclass.
## The return value should be true if the loading was successful
func _from_dict(_dict: Dictionary) -> bool:
	return false


## Updates the action effect once the current timer has finished.
func _on_timer_timeout() -> void:
	pass


# The ready function does nothing by default
# Child classes will do some setup though
func _ready() -> void:
	pass # Replace with function body.


# The process function does nothing by default
# Child classes might do some processing though
func _process(_delta: float) -> void:
	pass
