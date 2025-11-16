## ============================================================================
## COMBAT MANAGER - Comprehensive Combat System
## ============================================================================
## Handles all combat calculations, damage dealing, effect management, 
## and combat event tracking for the game.
##
## Key Features:
## - Centralized damage calculation with all modifier types
## - Stat modification system with stacking rules
## - Combat event logging for replays and analysis
## - Buff/debuff management with proper cleanup
## - Team-aware damage applications
## - Performance-optimized for network sync
## ============================================================================

extends Node

# === Signals === #
signal damage_dealt(attacker: Creature, defender: Creature, damage: int, damage_type: OC.DAMAGE_TYPE)
signal damage_reduced(damage: int, reduction: int, reduction_type: String)
signal healing_applied(target: Creature, heal_amount: int)
signal effect_applied(target: Creature, effect: Effect)
signal effect_removed(target: Creature, effect: Effect)
signal kill_confirmed(killer: Creature, victim: Creature)
signal stat_modified(target: Creature, stat_name: String, modifier: StatModifier)
signal combat_event_logged(event: CombatEvent)

# === Combat Event Tracking === #
var active_combats: Dictionary = {}  # creature_id -> CombatState
var combat_history: Array[CombatEvent] = []
var damage_calculator: DamageCalculator
var stat_modifier_system: StatModifierSystem
var effect_manager: EffectManager

# === Configuration === #
@export var enable_logging: bool = true
@export var max_history_size: int = 1000
@export var damage_threshold_for_log: int = 0  # Log all damage if 0
@export var verbose_logging: bool = false

# === Internal State === #
var is_ready: bool = false
var creature_effects: Dictionary = {}  # creature_id -> Array[Effect]
var creature_stat_modifiers: Dictionary = {}  # creature_id -> Array[StatModifier]

# === Debug === #
var debug_mode: bool = false

func _ready():
	# Initialize subsystems
	damage_calculator = DamageCalculator.new()
	stat_modifier_system = StatModifierSystem.new()
	effect_manager = EffectManager.new()
	
	# Register with game manager if available
	if GameManager:
		if GameManager.has_signal("slow_tick"):
			GameManager.slow_tick.connect(_on_slow_tick)
	
	is_ready = true
	print("CombatManager: Initialized successfully")

func reset():
	pass; # May be needed later
## ============================================================================
## PRIMARY API - DAMAGE APPLICATION
## ============================================================================

## Apply damage from attacker to defender with all modifiers
func apply_damage(attacker: Creature, defender: Creature, base_damage: int, 
				  damage_type: OC.DAMAGE_TYPE = OC.DAMAGE_TYPE.PHYSICAL,
				  extra_data: Dictionary = {}) -> int:
	
	if not is_ready or not _validate_combat_targets(attacker, defender):
		return 0
	
	# Check if damage can be dealt (invulnerability, shields, etc)
	if not _check_damage_preconditions(defender):
		return 0
	
	# Calculate final damage with all modifiers
	var final_damage = damage_calculator.calculate_damage(
		base_damage,
		damage_type,
		attacker,
		defender,
		extra_data
	)
	
	# Track damage reduction for logging
	var reduction = base_damage - final_damage
	if reduction > 0:
		damage_reduced.emit(base_damage, reduction, "defense")
	
	# Apply the damage
	defender.rpc("take_damage", final_damage, damage_type)
	
	# Check for kill
	if defender.health <= 0:
		_handle_kill(attacker, defender)
	
	# Log combat event
	_log_damage_event(attacker, defender, final_damage, damage_type, extra_data)
	
	# Emit signal
	damage_dealt.emit(attacker, defender, final_damage, damage_type)
	
	return final_damage

## Apply healing to a target creature
func apply_healing(healer: Creature, target: Creature, heal_amount: int) -> int:
	if not is_ready or not target:
		return 0
	
	# Check for healing reduction effects
	var modified_heal = _apply_healing_modifiers(target, heal_amount)
	
	target.rpc("heal", modified_heal)
	
	healing_applied.emit(target, modified_heal)
	_log_healing_event(healer, target, modified_heal)
	
	return modified_heal

## ============================================================================
## STAT MODIFICATION SYSTEM (Buff/Debuff/Items)
## ============================================================================

## Add a temporary or permanent stat modifier
func add_stat_modifier(creature: Creature, modifier: StatModifier) -> void:
	if not creature or not modifier: return
	
	var creature_id = creature.creature_id
	
	# Initialize array if needed
	if not creature_stat_modifiers.has(creature_id):
		creature_stat_modifiers[creature_id] = []
	
	# Add modifier
	creature_stat_modifiers[creature_id].append(modifier)
	
	# Apply modifier immediately
	_apply_stat_modifier(creature, modifier)
	
	# Schedule removal if temporary
	if modifier.duration > 0:
		await get_tree().create_timer(modifier.duration).timeout
		remove_stat_modifier(creature, modifier)
	
	stat_modified.emit(creature, modifier.stat_name, modifier)
	if verbose_logging:
		print("CombatManager: Added stat modifier to %s: %s +%s" % [creature.name, modifier.stat_name, modifier.value])

## Remove a specific stat modifier
func remove_stat_modifier(creature: Creature, modifier: StatModifier) -> void:
	if not creature:
		return
	
	var creature_id = creature.creature_id
	if not creature_stat_modifiers.has(creature_id):
		return
	
	# Remove modifier
	if creature_stat_modifiers[creature_id].has(modifier):
		creature_stat_modifiers[creature_id].erase(modifier)
		
		# Revert modifier
		_revert_stat_modifier(creature, modifier)
		if verbose_logging:
			print("CombatManager: Removed stat modifier from %s: %s" % [creature.name, modifier.stat_name])

## Get all modifiers for a stat
func get_stat_modifiers(creature: Creature, stat_name: String) -> Array[StatModifier]:
	var creature_id = creature.creature_id
	var result: Array[StatModifier] = []
	
	if not creature_stat_modifiers.has(creature_id):
		return result
	
	for modifier in creature_stat_modifiers[creature_id]:
		if modifier.stat_name == stat_name:
			result.append(modifier)
	
	return result

## Calculate total modifier for a specific stat
func calculate_stat_total_modifier(creature: Creature, stat_name: String) -> float:
	var total: float = 0.0
	
	for modifier in get_stat_modifiers(creature, stat_name):
		match modifier.modifier_type:
			StatModifier.ModifierType.FLAT:
				total += modifier.value
			StatModifier.ModifierType.PERCENTAGE:
				total += modifier.value  # Will be applied as multiplier elsewhere
			StatModifier.ModifierType.MULTIPLICATIVE:
				total *= (1.0 + modifier.value)
	
	return total

## ============================================================================
## EFFECT MANAGEMENT
## ============================================================================

## Apply an effect to a target
func apply_effect(target: Creature, effect: Effect) -> void:
	if not target or not effect: return;
	
	var creature_id = target.creature_id
	
	# Initialize effects array if needed
	if not creature_effects.has(creature_id):
		creature_effects[creature_id] = []
	
	# Apply effect
	_apply_effect_immediately(target, effect)
	creature_effects[creature_id].append(effect)
	
	effect_applied.emit(target, effect)
	
	# Schedule removal if has duration
	if effect.duration > 0:
		await get_tree().create_timer(effect.duration).timeout
		remove_effect(target, effect)
	
	if verbose_logging:
		print("CombatManager: Applied effect to %s: %s (duration: %.1f)" % [target.name, Effect.Type.keys()[effect.type], effect.duration])

## Remove an effect from a target
func remove_effect(target: Creature, effect: Effect) -> void:
	if not target:
		return
	
	var creature_id = target.creature_id
	if not creature_effects.has(creature_id):
		return
	
	# Remove the effect
	if creature_effects[creature_id].has(effect):
		creature_effects[creature_id].erase(effect)
		_revert_effect(target, effect)
		effect_removed.emit(target, effect)
		if verbose_logging:
			print("CombatManager: Removed effect from %s: %s" % [target.name, Effect.Type.keys()[effect.type]])

## Remove all effects of a specific type
func remove_effects_by_type(target: Creature, effect_type: Effect.Type) -> void:
	if not target:
		return
	
	var creature_id = target.creature_id
	if not creature_effects.has(creature_id):
		return
	
	var to_remove: Array[Effect] = []
	for effect in creature_effects[creature_id]:
		if effect.type == effect_type:
			to_remove.append(effect)
	
	for effect in to_remove:
		remove_effect(target, effect)

## Get all active effects on a creature
func get_active_effects(creature: Creature) -> Array[Effect]:
	var creature_id = creature.creature_id
	if creature_effects.has(creature_id):
		return creature_effects[creature_id]
	return []

## ============================================================================
## DAMAGE TYPE SPECIFIC LOGIC
## ============================================================================

## Calculate armor/magic resistance reduction
func calculate_defense_reduction(base_damage: int, defense_value: int, 
								  defense_type: String = "armor") -> int:
	return damage_calculator.calculate_defense_reduction(base_damage, defense_value, defense_type)

## Apply critical strike calculation
func calculate_critical_damage(base_damage: int, crit_chance: float, 
							   crit_damage: float) -> Dictionary:
	return damage_calculator.calculate_critical_damage(base_damage, crit_chance, crit_damage)

## Check for dodge/evasion
func check_evasion(dodger: Creature, attacker: Creature) -> bool:
	var dodge_chance = dodger.dodge if dodger.dodge > 0 else 0
	
	# Reduce dodge chance by attacker's accuracy if it exists
	var accuracy_reduction = 0
	if attacker.has_meta("accuracy"):
		accuracy_reduction = attacker.get_meta("accuracy")
	
	dodge_chance = max(0, dodge_chance - accuracy_reduction)
	return randf() * 100 < dodge_chance

## ============================================================================
## KILL CONFIRMATION & REWARDS
## ============================================================================

## Handle kill confirmation and rewards
func _handle_kill(killer: Creature, victim: Creature) -> void:
	kill_confirmed.emit(killer, victim)
	
	# Award experience
	_distribute_experience(killer, victim)
	
	# Log kill event
	_log_kill_event(killer, victim)
	
	if verbose_logging:
		print("CombatManager: %s killed %s" % [killer.name, victim.name])

## Distribute experience to killer(s)
func _distribute_experience(killer: Creature, victim: Creature) -> void:
	# Base experience calculation
	var base_exp = _calculate_base_experience(victim)
	
	# Apply modifiers
	var total_exp = base_exp
	
	# TODO: Handle team-wide experience distribution when ready
	if killer.has_method("distribute_experience"):
		killer.distribute_experience(int(total_exp), [killer])

## Calculate base experience from victim
func _calculate_base_experience(victim: Creature) -> int:
	var base = 100
	if victim.has_meta("base_exp"):
		base = victim.get_meta("base_exp")
	
	# Scale with level
	base = int(base * (1.0 + (victim.level * 0.1)))
	return base

## ============================================================================
## INTERNAL HELPER FUNCTIONS
## ============================================================================

## Validate that combat can occur between targets
func _validate_combat_targets(attacker: Creature, defender: Creature) -> bool:
	if not attacker or not defender:
		return false
	
	# Check same team (friendly fire rules)
	if attacker.team == defender.team and attacker.team != OC.TEAM.NEUTRAL:
		return false
	
	# Check if defender is dead
	if defender.health <= 0:
		return false
	
	# Check line of sight / range if needed
	# TODO: Add proper visibility/range checks
	
	return true

## Check preconditions before damage is applied
func _check_damage_preconditions(defender: Creature) -> bool:
	# Check for invulnerability
	if defender.has_meta("invulnerable") and defender.get_meta("invulnerable"):
		return false
	
	# Check for stun/cc that blocks damage
	if defender.has_meta("blocked_damage") and defender.get_meta("blocked_damage"):
		return false
	
	return true

## Apply healing modifiers (healing reduction, etc)
func _apply_healing_modifiers(target: Creature, heal_amount: int) -> int:
	var modified = heal_amount
	
	# Check for healing reduction effects
	for effect in get_active_effects(target):
		if effect.type == Effect.Type.DEBUFF_DAMAGE:
			# Some debuffs might reduce healing
			modified = int(modified * 0.8)  # 20% reduction example
	
	return modified

## Apply stat modifier to creature
func _apply_stat_modifier(creature: Creature, modifier: StatModifier) -> void:
	if not creature.has_method("set_stat_modified"):
		return
	
	creature.set_stat_modified(modifier.stat_name, modifier.value, modifier.modifier_type)

## Revert stat modifier from creature
func _revert_stat_modifier(creature: Creature, modifier: StatModifier) -> void:
	if not creature.has_method("revert_stat_modified"):
		return
	
	creature.revert_stat_modified(modifier.stat_name, modifier.value, modifier.modifier_type)

## Apply effect immediately
func _apply_effect_immediately(creature: Creature, effect: Effect) -> void:
	match effect.type:
		Effect.Type.SLOW:
			var modifier = StatModifier.new("move_speed", -effect.strength, effect.duration)
			add_stat_modifier(creature, modifier)
		
		Effect.Type.DAMAGE_OVER_TIME:
			# DOT is handled by the Effect class itself
			pass
		
		Effect.Type.STUN:
			creature.set_meta("stunned", true)
		
		Effect.Type.ROOT:
			creature.set_meta("rooted", true)
		
		Effect.Type.SHIELD:
			var shield_amount = int(effect.strength)
			if creature.has_meta("shield"):
				shield_amount += creature.get_meta("shield")
			creature.set_meta("shield", shield_amount)
		
		Effect.Type.BUFF_ARMOR:
			var modifier = StatModifier.new("armor", effect.strength, effect.duration)
			add_stat_modifier(creature, modifier)
		
		Effect.Type.BUFF_DAMAGE:
			var modifier = StatModifier.new("physical_power", effect.strength, effect.duration)
			add_stat_modifier(creature, modifier)
		
		Effect.Type.BUFF_SPEED:
			var modifier = StatModifier.new("move_speed", effect.strength, effect.duration)
			add_stat_modifier(creature, modifier)

## Revert effect from creature
func _revert_effect(creature: Creature, effect: Effect) -> void:
	match effect.type:
		Effect.Type.STUN:
			creature.set_meta("stunned", false)
		
		Effect.Type.ROOT:
			creature.set_meta("rooted", false)
		
		Effect.Type.SHIELD:
			var shield_amount = creature.get_meta("shield") if creature.has_meta("shield") else 0
			shield_amount = max(0, shield_amount - int(effect.strength))
			if shield_amount > 0:
				creature.set_meta("shield", shield_amount)
			else:
				creature.remove_meta("shield")

## ============================================================================
## LOGGING & TRACKING
## ============================================================================

## Log a damage event
func _log_damage_event(attacker: Creature, defender: Creature, damage: int, 
					   damage_type: OC.DAMAGE_TYPE, extra_data: Dictionary) -> void:
	if not enable_logging:
		return
	
	if damage < damage_threshold_for_log and damage_threshold_for_log > 0:
		return
	
	var event = CombatEvent.new()
	event.event_type = CombatEvent.EventType.DAMAGE
	event.attacker_id = attacker.creature_id
	event.defender_id = defender.creature_id
	event.value = damage
	event.damage_type = damage_type
	event.timestamp = Time.get_ticks_msec()
	event.extra_data = extra_data
	
	_record_combat_event(event)

## Log a healing event
func _log_healing_event(healer: Creature, target: Creature, heal_amount: int) -> void:
	if not enable_logging:
		return
	
	var event = CombatEvent.new()
	event.event_type = CombatEvent.EventType.HEALING
	event.attacker_id = healer.creature_id if healer else -1
	event.defender_id = target.creature_id
	event.value = heal_amount
	event.timestamp = Time.get_ticks_msec()
	
	_record_combat_event(event)

## Log a kill event
func _log_kill_event(killer: Creature, victim: Creature) -> void:
	if not enable_logging:
		return
	
	var event = CombatEvent.new()
	event.event_type = CombatEvent.EventType.KILL
	event.attacker_id = killer.creature_id
	event.defender_id = victim.creature_id
	event.timestamp = Time.get_ticks_msec()
	
	_record_combat_event(event)

## Record a combat event in history
func _record_combat_event(event: CombatEvent) -> void:
	combat_history.append(event)
	
	# Trim history if too large
	if combat_history.size() > max_history_size:
		combat_history.pop_front()
	
	combat_event_logged.emit(event)

## Get combat events for a creature
func get_combat_events_for_creature(creature_id: int, event_type: CombatEvent.EventType = -1) -> Array[CombatEvent]:
	var result: Array[CombatEvent] = []
	
	for event in combat_history:
		if (event.attacker_id == creature_id or event.defender_id == creature_id):
			if event_type == -1 or event.event_type == event_type:
				result.append(event)
	
	return result

## ============================================================================
## PERIODIC UPDATES
## ============================================================================

## Called on slow tick from GameManager
func _on_slow_tick() -> void:
	# Clean up dead creatures from tracking
	var dead_creatures: Array[int] = []
	for creature_id in active_combats.keys():
		var state = active_combats[creature_id]
		if state.creature.health <= 0:
			dead_creatures.append(creature_id)
	
	for creature_id in dead_creatures:
		active_combats.erase(creature_id)
		creature_effects.erase(creature_id)
		creature_stat_modifiers.erase(creature_id)

## ============================================================================
## DEBUG UTILITIES
## ============================================================================

## Print combat state for debugging
func print_combat_debug_info(creature: Creature) -> void:
	print("\n=== Combat Debug Info for %s ===" % creature.name)
	print("Health: %d/%d" % [creature.health, creature.max_health])
	print("Active Effects: %d" % get_active_effects(creature).size())
	print("Active Stat Modifiers: %d" % get_stat_modifiers(creature, "").size())
	print("Recent Combat Events: %d" % get_combat_events_for_creature(creature.creature_id).size())
	print("====================================\n")

## Get formatted combat log
func get_formatted_combat_log(limit: int = 100) -> String:
	var output = "\n=== Combat Log ===\n"
	var events_to_show = min(limit, combat_history.size())
	
	for i in range(combat_history.size() - events_to_show, combat_history.size()):
		if i < 0:
			continue
		var event = combat_history[i]
		output += event.to_string() + "\n"
	
	output += "==================\n"
	return output
