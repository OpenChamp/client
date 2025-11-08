## ============================================================================
## DAMAGE CALCULATOR - Damage Calculation Utility
## ============================================================================
## Handles all damage calculations including defense reductions, critical hits,
## and damage type interactions.
## ============================================================================

class_name DamageCalculator

## ============================================================================
## PRIMARY CALCULATION METHOD
## ============================================================================

## Calculate final damage with all modifiers applied
func calculate_damage(base_damage: int, damage_type: OC.DAMAGE_TYPE, 
					  attacker: Creature, defender: Creature,
					  extra_data: Dictionary = {}) -> int:
	
	if base_damage <= 0:
		return 0
	
	var final_damage = float(base_damage)
	
	# Apply attacker damage multipliers
	final_damage = _apply_attacker_modifiers(final_damage, attacker, damage_type, extra_data)
	
	# Apply critical strike
	if extra_data.get("can_crit", true):
		var crit_result = calculate_critical_damage(
			int(final_damage),
			attacker.crit_chance,
			extra_data.get("crit_damage_multiplier", 1.5)
		)
		final_damage = float(crit_result.final_damage)
		if crit_result.is_critical:
			extra_data["was_critical"] = true
	
	# Apply defense/resistance reductions
	final_damage = _apply_defense_reductions(final_damage, defender, damage_type)
	
	# Apply damage type specific logic
	final_damage = _apply_damage_type_logic(final_damage, damage_type, attacker, defender)
	
	# Apply true damage (ignores resistances)
	if extra_data.has("true_damage"):
		final_damage += extra_data.true_damage
	
	# Ensure minimum damage (always deal at least 1 damage)
	final_damage = max(1.0, final_damage)
	
	return int(final_damage)

## ============================================================================
## ATTACKER MODIFIER APPLICATION
## ============================================================================

## Apply all attacker-side damage modifiers
func _apply_attacker_modifiers(base_damage: float, attacker: Creature, 
							   damage_type: OC.DAMAGE_TYPE, extra_data: Dictionary) -> float:
	
	var modified = base_damage
	
	# Apply power stats based on damage type
	match damage_type:
		OC.DAMAGE_TYPE.PHYSICAL:
			modified *= attacker.physical_power
		
		OC.DAMAGE_TYPE.MAGICAL:
			modified *= attacker.magic_power
	
	# Apply flat bonuses
	if extra_data.has("flat_damage_bonus"):
		modified += extra_data.flat_damage_bonus
	
	# Apply attacker effects/buffs
	modified = _apply_effect_damage_modifiers(modified, attacker, true)
	
	# Apply percentage bonuses from attacker
	if extra_data.has("damage_multiplier"):
		modified *= extra_data.damage_multiplier
	
	return modified

## ============================================================================
## DEFENSE REDUCTION CALCULATION
## ============================================================================

## Calculate final damage after defense reductions
func _apply_defense_reductions(base_damage: float, defender: Creature, 
							   damage_type: OC.DAMAGE_TYPE) -> float:
	
	match damage_type:
		OC.DAMAGE_TYPE.PHYSICAL:
			return calculate_defense_reduction(int(base_damage), defender.armor, "armor")
		
		OC.DAMAGE_TYPE.MAGICAL:
			return calculate_defense_reduction(int(base_damage), defender.magic_resist, "magic_resist")
		
		OC.DAMAGE_TYPE.TRUE:
			# True damage ignores all defenses
			return base_damage
	
	return base_damage

## Calculate defense reduction based on defense type
func calculate_defense_reduction(base_damage: int, defense_value: int, 
								 _defense_type: String = "armor") -> int:
	
	if defense_value <= 0:
		return base_damage
	
	# Defense formula options - using percentage reduction model
	# armor_reduction = defense_value / (defense_value + 100)
	var reduction_percent = float(defense_value) / (float(defense_value) + 100.0)
	reduction_percent = clamp(reduction_percent, 0.0, 0.95)  # Cap at 95% max reduction
	
	var reduced_damage = int(float(base_damage) * (1.0 - reduction_percent))
	return max(1, reduced_damage)  # Always deal at least 1 damage

## ============================================================================
## CRITICAL STRIKE CALCULATION
## ============================================================================

## Calculate critical strike chance and damage
func calculate_critical_damage(base_damage: int, crit_chance: float, 
							   crit_damage_multiplier: float = 1.5) -> Dictionary:
	
	var is_critical = false
	var final_damage = base_damage
	
	# Clamp crit chance to 0-100%
	var clamped_crit_chance = clamp(crit_chance, 0.0, 100.0)
	
	# Roll for critical
	if randf() * 100.0 < clamped_crit_chance:
		is_critical = true
		final_damage = int(float(base_damage) * crit_damage_multiplier)
	
	return {
		"is_critical": is_critical,
		"final_damage": final_damage,
		"damage_increase": final_damage - base_damage
	}

## ============================================================================
## DAMAGE TYPE SPECIFIC LOGIC
## ============================================================================

## Apply damage type specific calculations
func _apply_damage_type_logic(base_damage: float, damage_type: OC.DAMAGE_TYPE,
							  attacker: Creature, defender: Creature) -> float:
	
	match damage_type:
		OC.DAMAGE_TYPE.PHYSICAL:
			# Apply life steal
			if attacker.life_steal > 0:
				var heal_amount = int(base_damage * (attacker.life_steal / 100.0))
				if attacker.has_method("heal"):
					attacker.rpc("heal", heal_amount)
			return base_damage
		
		OC.DAMAGE_TYPE.MAGICAL:
			# Apply spell vamp
			if attacker.spell_vamp > 0:
				var heal_amount = int(base_damage * (attacker.spell_vamp / 100.0))
				if attacker.has_method("heal"):
					attacker.rpc("heal", heal_amount)
			return base_damage
		
		OC.DAMAGE_TYPE.TRUE:
			# Apply omni vamp
			if attacker.omni_vamp > 0:
				var heal_amount = int(base_damage * (attacker.omni_vamp / 100.0))
				if attacker.has_method("heal"):
					attacker.rpc("heal", heal_amount)
			return base_damage
	
	return base_damage

## ============================================================================
## EFFECT-BASED MODIFIERS
## ============================================================================

## Apply damage modifiers from active effects
func _apply_effect_damage_modifiers(base_damage: float, attacker: Creature,
									 is_attacking: bool) -> float:
	
	var modified = base_damage
	
	# Apply buffs/debuffs that affect damage
	if attacker.has_meta("active_effects"):
		var effects: Array = attacker.get_meta("active_effects")
		for effect in effects:
			match effect.type:
				Effect.Type.BUFF_DAMAGE:
					modified *= (1.0 + effect.strength / 100.0)
				
				Effect.Type.DEBUFF_DAMAGE:
					modified *= (1.0 - effect.strength / 100.0)
	
	return modified

## ============================================================================
## HEALING CALCULATION
## ============================================================================

## Calculate final healing amount with modifiers
func calculate_healing(base_healing: int, healer: Creature, 
					  target: Creature, extra_data: Dictionary = {}) -> int:
	
	if base_healing <= 0:
		return 0
	
	var final_healing = float(base_healing)
	
	# Apply healer's healing power if available
	if healer and healer.has_meta("healing_power"):
		final_healing *= healer.get_meta("healing_power")
	
	# Apply healing bonus multipliers
	if extra_data.has("healing_multiplier"):
		final_healing *= extra_data.healing_multiplier
	
	# Apply target resistance to healing (debuffs might reduce healing received)
	if target and target.has_meta("healing_reduction"):
		final_healing *= (1.0 - target.get_meta("healing_reduction"))
	
	# Cap healing at target's missing health
	if target:
		var missing_health = target.max_health - target.health
		final_healing = min(final_healing, float(missing_health))
	
	return int(max(0.0, final_healing))

## ============================================================================
## EXPERIENCE CALCULATION
## ============================================================================

## Calculate experience reward from defeating an enemy
func calculate_experience_reward(victim: Creature, killer: Creature,
								 kill_streak: int = 0) -> int:
	
	var base_exp = 100
	
	# Scale with victim's level
	var level_diff = victim.level - killer.level
	var level_multiplier = pow(1.1, float(level_diff))
	
	# Kill streak bonus
	var streak_bonus = 1.0 + (kill_streak * 0.1)
	
	# Calculate final experience
	var final_exp = int(float(base_exp) * level_multiplier * streak_bonus)
	
	# Minimum experience
	final_exp = max(50, final_exp)
	
	return final_exp

## ============================================================================
## SHIELD CALCULATION
## ============================================================================

## Calculate shield amount with modifiers
func calculate_shield(base_shield: int, shielder: Creature = null,
					 target: Creature = null) -> int:
	
	var final_shield = float(base_shield)
	
	# Apply shielder's shield power if available
	if shielder and shielder.has_meta("shield_power"):
		final_shield *= shielder.get_meta("shield_power")
	
	return int(final_shield)

## ============================================================================
## TESTING/DEBUG FUNCTIONS
## ============================================================================

## Test damage calculation against a hypothetical scenario
func test_damage_scenario(base_damage: int, attacker_power: float = 1.0,
						 crit_chance: float = 0.0, defender_armor: int = 0) -> Dictionary:
	
	var damage = float(base_damage) * attacker_power
	
	# Apply critical
	var is_crit = randf() * 100 < crit_chance
	if is_crit:
		damage *= 1.5
	
	# Apply armor reduction
	var armor_reduction = float(defender_armor) / (float(defender_armor) + 100.0)
	armor_reduction = clamp(armor_reduction, 0.0, 0.95)
	damage *= (1.0 - armor_reduction)
	
	damage = max(1.0, damage)
	
	return {
		"base_damage": base_damage,
		"final_damage": int(damage),
		"was_critical": is_crit,
		"armor_reduction_percent": armor_reduction * 100.0
	}
