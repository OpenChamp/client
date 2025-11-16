## ============================================================================
## STAT MODIFIER - Temporary or Permanent Stat Modification
## ============================================================================
## Represents a modification to a creature's stat with optional stacking rules
## and automatic expiration.
## ============================================================================

class_name StatModifier

extends RefCounted

## Modifier Type Enumeration
enum ModifierType {
	FLAT,              # Add/subtract a flat value
	PERCENTAGE,        # Add/subtract a percentage
	MULTIPLICATIVE,    # Multiply by a factor
}

## Modifier Source (for debugging and stacking rules)
enum ModifierSource {
	ABILITY,           # From an ability cast
	ITEM,              # From an equipped item
	BUFF,              # From a temporary buff
	DEBUFF,            # From a temporary debuff
	STATUS_EFFECT,     # From a status condition
	ENVIRONMENTAL,     # From environmental effects
	PASSIVE,           # From a passive ability
	UNKNOWN
}

# === Properties === #
var stat_name: String
var value: float
var modifier_type: ModifierType = ModifierType.FLAT
var duration: float = 0.0  # 0 = permanent
var source: ModifierSource = ModifierSource.UNKNOWN
var source_id: String = ""  # ID of the source (ability ID, item ID, etc)
var stacking_group: String = ""  # For stacking rules
var stack_count: int = 1
var max_stacks: int = 1
var is_stackable: bool = false
var can_be_extended: bool = true
var priority: int = 0  # Higher = applied later
var is_hidden: bool = false  # Hidden from UI
var description: String = ""

# === Metadata === #
var creation_time: int = 0
var source_creature_id: int = -1

## Constructor
func _init(p_stat_name: String = "", p_value: float = 0.0, p_duration: float = 0.0,
		  p_type: ModifierType = ModifierType.FLAT, p_source: ModifierSource = ModifierSource.UNKNOWN) -> void:
	stat_name = p_stat_name
	value = p_value
	duration = p_duration
	modifier_type = p_type
	source = p_source
	creation_time = Time.get_ticks_msec()

## ============================================================================
## CONFIGURATION BUILDERS
## ============================================================================

## Set the modifier as stackable
func set_stackable(max_stack: int = -1) -> StatModifier:
	is_stackable = true
	if max_stack > 0:
		max_stacks = max_stack
	return self

## Set the stacking group for this modifier
func set_stacking_group(group: String) -> StatModifier:
	stacking_group = group
	return self

## Set the source information
func set_source(p_source: ModifierSource, p_source_id: String = "", creature_id: int = -1) -> StatModifier:
	source = p_source
	source_id = p_source_id
	source_creature_id = creature_id
	return self

## Set the priority (higher values applied later)
func set_priority(p_priority: int) -> StatModifier:
	priority = p_priority
	return self

## Set description for UI
func set_description(p_description: String) -> StatModifier:
	description = p_description
	return self

## Hide from UI
func set_hidden(p_hidden: bool = true) -> StatModifier:
	is_hidden = p_hidden
	return self

## ============================================================================
## UTILITY FUNCTIONS
## ============================================================================

## Check if this modifier has expired
func is_expired() -> bool:
	if duration <= 0:
		return false
	
	var age_ms = Time.get_ticks_msec() - creation_time
	return age_ms > (duration * 1000.0)

## Get remaining duration in seconds
func get_remaining_duration() -> float:
	if duration <= 0:
		return -1.0  # Permanent
	
	var age_ms = Time.get_ticks_msec() - creation_time
	var remaining_ms = (duration * 1000.0) - age_ms
	return max(0.0, remaining_ms / 1000.0)

## Get age in seconds
func get_age() -> float:
	var age_ms = Time.get_ticks_msec() - creation_time
	return age_ms / 1000.0

## Check if two modifiers can stack
func can_stack_with(other: StatModifier) -> bool:
	if not is_stackable or not other.is_stackable:
		return false
	
	if stacking_group == "" or other.stacking_group == "":
		return false
	
	return stacking_group == other.stacking_group

## Create a copy of this modifier
func duplicate_modifier() -> StatModifier:
	var copy = StatModifier.new(stat_name, value, duration, modifier_type, source)
	copy.source_id = source_id
	copy.stacking_group = stacking_group
	copy.stack_count = stack_count
	copy.max_stacks = max_stacks
	copy.is_stackable = is_stackable
	copy.can_be_extended = can_be_extended
	copy.priority = priority
	copy.is_hidden = is_hidden
	copy.description = description
	copy.source_creature_id = source_creature_id
	return copy

## ============================================================================
## STRING REPRESENTATIONS
## ============================================================================

func _to_string() -> String:
	var type_str = ModifierType.keys()[modifier_type]
	var source_str = ModifierSource.keys()[source]
	var duration_str = "permanent" if duration <= 0 else "%.1fs" % duration
	
	var result = "%s%+.1f %s (%s, %s)" % [stat_name, value, type_str, source_str, duration_str]
	
	if is_stackable:
		result += " [%d/%d stacks]" % [stack_count, max_stacks]
	
	return result

## Get formatted display string for UI
func get_display_string() -> String:
	var icon = "+"
	if value < 0:
		icon = "-"
	
	var value_str = "%d" % abs(int(value))
	if modifier_type == ModifierType.PERCENTAGE or modifier_type == ModifierType.MULTIPLICATIVE:
		value_str += "%"
	
	if duration > 0:
		value_str += " (%.1fs)" % duration
	
	return "%s %s %s" % [icon, stat_name, value_str]

## ============================================================================
## EQUALITY & COMPARISON
## ============================================================================

func _is_equal(other: StatModifier) -> bool:
	if other == null:
		return false
	
	return (stat_name == other.stat_name and
			value == other.value and
			modifier_type == other.modifier_type and
			source == other.source and
			source_id == other.source_id)

func _hash() -> int:
	return hash([stat_name, value, modifier_type, source, source_id])

## ============================================================================
## FACTORY FUNCTIONS FOR COMMON MODIFIERS
## ============================================================================

## Create a flat stat modifier
static func create_flat(stat: String, amount: float, dur: float = 0.0) -> StatModifier:
	return StatModifier.new(stat, amount, dur, ModifierType.FLAT)

## Create a percentage modifier
static func create_percentage(stat: String, percent: float, dur: float = 0.0) -> StatModifier:
	return StatModifier.new(stat, percent, dur, ModifierType.PERCENTAGE)

## Create a multiplicative modifier
static func create_multiplicative(stat: String, multiplier: float, dur: float = 0.0) -> StatModifier:
	return StatModifier.new(stat, multiplier - 1.0, dur, ModifierType.MULTIPLICATIVE)

## Create an armor buff
static func create_armor_buff(amount: int, dur: float) -> StatModifier:
	var mod = create_flat("armor", amount, dur)
	mod.set_source(ModifierSource.BUFF, "armor_buff")
	mod.set_description("+%d Armor" % amount)
	return mod

## Create an attack damage buff
static func create_damage_buff(amount: float, dur: float) -> StatModifier:
	var mod = create_flat("physical_power", amount, dur)
	mod.set_source(ModifierSource.BUFF, "damage_buff")
	mod.set_description("+%.1f Damage" % amount)
	return mod

## Create a movement speed buff
static func create_speed_buff(amount: float, dur: float) -> StatModifier:
	var mod = create_flat("move_speed", amount, dur)
	mod.set_source(ModifierSource.BUFF, "speed_buff")
	mod.set_description("+%.1f Speed" % amount)
	return mod

## Create a slow debuff
static func create_slow(amount: float, dur: float) -> StatModifier:
	var mod = create_flat("move_speed", -amount, dur)
	mod.set_source(ModifierSource.DEBUFF, "slow")
	mod.set_description("Slowed -%.1f Speed" % amount)
	return mod

## Create a damage reduction debuff
static func create_damage_reduction(percent: float, dur: float) -> StatModifier:
	var mod = create_percentage("physical_power", -percent, dur)
	mod.set_source(ModifierSource.DEBUFF, "damage_reduction")
	mod.set_description("Weakened -%d%% Damage" % int(percent))
	return mod
