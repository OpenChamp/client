## ============================================================================
## COMBAT EVENT - Combat Event Record for Logging and Replay
## ============================================================================
## Records individual combat events for replay systems and analytics.
## ============================================================================

class_name CombatEvent

extends RefCounted

## Event Type Enumeration
enum EventType {
	DAMAGE,
	HEALING,
	KILL,
	DEATH,
	BUFF_APPLIED,
	BUFF_REMOVED,
	DEBUFF_APPLIED,
	DEBUFF_REMOVED,
	SHIELD_GAINED,
	SHIELD_LOST,
	STAT_CHANGE,
	ABILITY_USED,
	ITEM_USED,
	RESPAWN,
	TEAM_EVENT
}

# === Core Properties === #
var event_type: EventType
var timestamp: int  # Milliseconds since game start
var attacker_id: int = -1  # -1 = no attacker
var defender_id: int = -1  # -1 = no defender

# === Event Details === #
var value: int = 0  # Damage, healing, etc
var damage_type: OC.DAMAGE_TYPE = OC.DAMAGE_TYPE.PHYSICAL
var extra_data: Dictionary = {}

# === Calculated Fields === #
var tick_count: int = 0  # Game tick when event occurred

## Constructor
func _init(p_event_type: EventType = EventType.DAMAGE) -> void:
	event_type = p_event_type
	timestamp = Time.get_ticks_msec()

## ============================================================================
## CONVENIENCE CONSTRUCTORS
## ============================================================================

## Create a damage event
static func create_damage_event(attacker_id: int, defender_id: int, 
								damage: int, dmg_type: OC.DAMAGE_TYPE = OC.DAMAGE_TYPE.PHYSICAL) -> CombatEvent:
	var event = CombatEvent.new(EventType.DAMAGE)
	event.attacker_id = attacker_id
	event.defender_id = defender_id
	event.value = damage
	event.damage_type = dmg_type
	return event

## Create a healing event
static func create_healing_event(healer_id: int, target_id: int, healing: int) -> CombatEvent:
	var event = CombatEvent.new(EventType.HEALING)
	event.attacker_id = healer_id
	event.defender_id = target_id
	event.value = healing
	return event

## Create a kill event
static func create_kill_event(killer_id: int, victim_id: int) -> CombatEvent:
	var event = CombatEvent.new(EventType.KILL)
	event.attacker_id = killer_id
	event.defender_id = victim_id
	return event

## Create a buff applied event
static func create_buff_event(target_id: int, buff_name: String, duration: float) -> CombatEvent:
	var event = CombatEvent.new(EventType.BUFF_APPLIED)
	event.defender_id = target_id
	event.extra_data = {
		"buff_name": buff_name,
		"duration": duration
	}
	return event

## ============================================================================
## UTILITY FUNCTIONS
## ============================================================================

## Get the time since this event in milliseconds
func get_age_ms() -> int:
	return Time.get_ticks_msec() - timestamp

## Get the time since this event in seconds
func get_age_seconds() -> float:
	return float(get_age_ms()) / 1000.0

## Check if this event involves a specific creature
func involves_creature(creature_id: int) -> bool:
	return attacker_id == creature_id or defender_id == creature_id

## Get the type name as string
func get_type_name() -> String:
	return EventType.keys()[event_type]

## ============================================================================
## STRING REPRESENTATIONS
## ============================================================================

func _to_string() -> String:
	var type_name = get_type_name()
	
	match event_type:
		EventType.DAMAGE:
			var dmg_type = OC.DAMAGE_TYPE.keys()[damage_type]
			return "%s: Creature%d dealt %d %s damage to Creature%d" % [type_name, attacker_id, value, dmg_type, defender_id]
		
		EventType.HEALING:
			return "%s: Creature%d healed Creature%d for %d HP" % [type_name, attacker_id, defender_id, value]
		
		EventType.KILL:
			return "%s: Creature%d eliminated Creature%d" % [type_name, attacker_id, defender_id]
		
		EventType.BUFF_APPLIED:
			return "%s: Applied '%s' to Creature%d" % [type_name, extra_data.get("buff_name", "unknown"), defender_id]
		
		EventType.BUFF_REMOVED:
			return "%s: Removed '%s' from Creature%d" % [type_name, extra_data.get("buff_name", "unknown"), defender_id]
		
		_:
			return "%s: Creatures %d <-> %d" % [type_name, attacker_id, defender_id]

## Get a formatted log line for display
func to_log_line() -> String:
	var time_str = "[%.2fs]" % get_age_seconds()
	return "%s %s" % [time_str, _to_string()]

## Get a detailed description
func get_detailed_description() -> String:
	var description = "%s\n" % _to_string()
	description += "Timestamp: %d ms\n" % timestamp
	description += "Age: %.2f seconds\n" % get_age_seconds()
	
	if extra_data.size() > 0:
		description += "Extra Data:\n"
		for key in extra_data.keys():
			description += "  - %s: %s\n" % [key, extra_data[key]]
	
	return description

## ============================================================================
## SERIALIZATION
## ============================================================================

## Convert to dictionary for serialization
func to_dict() -> Dictionary:
	return {
		"type": event_type,
		"timestamp": timestamp,
		"attacker_id": attacker_id,
		"defender_id": defender_id,
		"value": value,
		"damage_type": damage_type,
		"extra_data": extra_data,
		"tick_count": tick_count
	}

## Create from dictionary
static func from_dict(data: Dictionary) -> CombatEvent:
	var event = CombatEvent.new(data.get("type", EventType.DAMAGE))
	event.timestamp = data.get("timestamp", 0)
	event.attacker_id = data.get("attacker_id", -1)
	event.defender_id = data.get("defender_id", -1)
	event.value = data.get("value", 0)
	event.damage_type = data.get("damage_type", OC.DAMAGE_TYPE.PHYSICAL)
	event.extra_data = data.get("extra_data", {})
	event.tick_count = data.get("tick_count", 0)
	return event

## Convert to JSON string
func to_json() -> String:
	var dict = to_dict()
	return JSON.stringify(dict)

## Create from JSON string
static func from_json(json_string: String) -> CombatEvent:
	var dict = JSON.parse_string(json_string)
	if dict == null:
		return CombatEvent.new()
	return from_dict(dict)

## ============================================================================
## COMPARISON & FILTERING
## ============================================================================

## Check if this event matches a filter
func matches_filter(attacker: int = -1, defender: int = -1, 
				   event_types: Array[EventType] = []) -> bool:
	
	if attacker >= 0 and attacker_id != attacker:
		return false
	
	if defender >= 0 and defender_id != defender:
		return false
	
	if event_types.size() > 0 and event_type not in event_types:
		return false
	
	return true
