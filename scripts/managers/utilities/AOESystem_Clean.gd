## ============================================================================
## AOE SYSTEM - Area of Effect Combat
## ============================================================================
## Provides AOE damage, effects, and advanced combat patterns.
## Integrates with CombatManager for damage application.
## ============================================================================

class_name AOESystem

## Shape types for AOE patterns
enum ShapeType {
	CIRCLE,
	CONE,
	LINE,
	RECTANGLE,
	DONUT
}

## ============================================================================
## MAIN API - Simple AOE Operations
## ============================================================================

## Apply damage in a circular AOE
static func damage_circle(caster: Creature, center: Vector3, radius: float,
						 damage: int, damage_type: OC.DAMAGE_TYPE,
						 exclude_caster: bool = true) -> Array[Creature]:
	
	var targets = get_creatures_in_radius(center, radius, caster.team)
	var hit: Array[Creature] = []
	
	for target in targets:
		if exclude_caster and target == caster:
			continue
		
		var dmg = CombatManager.apply_damage(caster, target, damage, damage_type)
		if dmg > 0:
			hit.append(target)
	
	return hit

## Apply effect in a circular AOE
static func effect_circle(caster: Creature, center: Vector3, radius: float,
						 effect: Effect, exclude_caster: bool = true) -> Array[Creature]:
	
	var targets = get_creatures_in_radius(center, radius, caster.team)
	var affected: Array[Creature] = []
	
	for target in targets:
		if exclude_caster and target == caster:
			continue
		
		CombatManager.apply_effect(target, effect)
		affected.append(target)
	
	return affected

## Apply healing in a circular AOE (to allies)
static func heal_circle(caster: Creature, center: Vector3, radius: float,
					   heal_amount: int, include_enemies: bool = false) -> Array[Creature]:
	
	var healed: Array[Creature] = []
	
	for creature in get_all_creatures():
		if center.distance_to(creature.global_position) > radius:
			continue
		
		# Only heal allies by default
		if creature.team != caster.team and not include_enemies:
			continue
		
		CombatManager.apply_healing(caster, creature, heal_amount)
		healed.append(creature)
	
	return healed

## Apply damage in a cone shape
static func damage_cone(caster: Creature, center: Vector3, direction: Vector3,
					   radius: float, angle_degrees: float, damage: int,
					   damage_type: OC.DAMAGE_TYPE) -> Array[Creature]:
	
	var targets = get_creatures_in_cone(center, direction, radius, angle_degrees, caster.team)
	var hit: Array[Creature] = []
	
	for target in targets:
		if target == caster:
			continue
		var dmg = CombatManager.apply_damage(caster, target, damage, damage_type)
		if dmg > 0:
			hit.append(target)
	
	return hit

## Apply damage in a line (skill shot)
static func damage_line(caster: Creature, start: Vector3, direction: Vector3,
					   length: float, width: float, damage: int,
					   damage_type: OC.DAMAGE_TYPE) -> Array[Creature]:
	
	var targets = get_creatures_in_line(start, direction, length, width, caster.team)
	var hit: Array[Creature] = []
	
	for target in targets:
		if target == caster:
			continue
		var dmg = CombatManager.apply_damage(caster, target, damage, damage_type)
		if dmg > 0:
			hit.append(target)
	
	return hit

## ============================================================================
## TARGET FINDING - Geometry Detection
## ============================================================================

## Get all creatures in radius
static func get_creatures_in_radius(center: Vector3, radius: float,
									exclude_team: int = -1) -> Array[Creature]:
	
	var targets: Array[Creature] = []
	for creature in get_all_creatures():
		var distance = center.distance_to(creature.global_position)
		if distance <= radius:
			if exclude_team == -1 or creature.team != exclude_team:
				targets.append(creature)
	
	return targets

## Get creatures in cone shape
static func get_creatures_in_cone(apex: Vector3, direction: Vector3, radius: float,
								  angle_degrees: float, exclude_team: int = -1) -> Array[Creature]:
	
	var targets: Array[Creature] = []
	var angle_half = deg_to_rad(angle_degrees / 2.0)
	var dir_normalized = direction.normalized()
	
	for creature in get_all_creatures():
		var dist = apex.distance_to(creature.global_position)
		if dist > radius:
			continue
		
		var to_target = (creature.global_position - apex).normalized()
		var dot = to_target.dot(dir_normalized)
		
		if dot >= cos(angle_half):
			if exclude_team == -1 or creature.team != exclude_team:
				targets.append(creature)
	
	return targets

## Get creatures in line (skill shot pattern)
static func get_creatures_in_line(start: Vector3, direction: Vector3, length: float,
								  width: float, exclude_team: int = -1) -> Array[Creature]:
	
	var targets: Array[Creature] = []
	var dir_norm = direction.normalized()
	
	for creature in get_all_creatures():
		var creature_pos = creature.global_position
		
		# Project creature onto line
		var to_creature = creature_pos - start
		var projection = to_creature.dot(dir_norm)
		
		# Check if within line bounds
		if projection < 0 or projection > length:
			continue
		
		# Find closest point on line
		var closest = start + dir_norm * projection
		var distance_to_line = creature_pos.distance_to(closest)
		
		if distance_to_line <= (width / 2.0):
			if exclude_team == -1 or creature.team != exclude_team:
				targets.append(creature)
	
	return targets

## Find closest creature to position
static func find_closest(center: Vector3, max_range: float = -1,
						exclude_team: int = -1) -> Creature:
	
	var closest: Creature = null
	var closest_dist = INF
	
	for creature in get_all_creatures():
		var dist = center.distance_to(creature.global_position)
		
		if max_range > 0 and dist > max_range:
			continue
		
		if exclude_team != -1 and creature.team == exclude_team:
			continue
		
		if dist < closest_dist:
			closest = creature
			closest_dist = dist
	
	return closest

## ============================================================================
## ADVANCED PATTERNS - Complex Combat Scenarios
## ============================================================================

## Chain damage - jump from target to nearby targets
static func apply_chain_damage(caster: Creature, initial_target: Creature,
							   damage: int, damage_type: OC.DAMAGE_TYPE,
							   chain_range: float, max_chains: int) -> Array[Creature]:
	
	var hit: Array[Creature] = []
	var to_process: Array[Creature] = [initial_target]
	
	while to_process.size() > 0 and hit.size() < max_chains:
		var current = to_process.pop_front()
		
		if current in hit:
			continue
		
		hit.append(current)
		CombatManager.apply_damage(caster, current, damage, damage_type)
		
		# Find nearby targets for chaining
		var nearby = get_creatures_in_radius(current.global_position, chain_range)
		for nearby_target in nearby:
			if nearby_target not in hit and nearby_target.team != caster.team:
				if to_process.find(nearby_target) == -1:
					to_process.append(nearby_target)
	
	return hit

## Shockwave - expanding ring of damage (DONUT shape)
static func apply_shockwave(caster: Creature, origin: Vector3,
						   inner_radius: float, outer_radius: float,
						   damage: int, damage_type: OC.DAMAGE_TYPE) -> Array[Creature]:
	
	var hit: Array[Creature] = []
	
	for creature in get_all_creatures():
		if creature.team == caster.team:
			continue
		
		var dist = origin.distance_to(creature.global_position)
		if dist >= inner_radius and dist <= outer_radius:
			var dmg = CombatManager.apply_damage(caster, creature, damage, damage_type)
			if dmg > 0:
				hit.append(creature)
	
	return hit

## Sweeping attack - line that can hit multiple targets
static func apply_sweep(caster: Creature, start: Vector3, end: Vector3,
					   width: float, damage: int, damage_type: OC.DAMAGE_TYPE) -> Array[Creature]:
	
	var direction = (end - start).normalized()
	var length = start.distance_to(end)
	
	return damage_line(caster, start, direction, length, width, damage, damage_type)

## Knockback effect - push creatures away from center
static func apply_knockback(center: Vector3, radius: float, force: float) -> int:
	
	var count = 0
	for creature in get_creatures_in_radius(center, radius):
		var direction = (creature.global_position - center).normalized()
		var knockback_vector = direction * force
		
		# Apply force (requires creature to support velocity application)
		if creature.has_method("apply_knockback"):
			creature.apply_knockback(knockback_vector)
			count += 1
	
	return count

## ============================================================================
## UTILITY - Global Creature Lookup
## ============================================================================

## Get all creatures in the game world
static func get_all_creatures() -> Array[Creature]:
	var creatures: Array[Creature] = []
	
	# Get from root scene tree - searches all nodes
	var root = get_tree_root()
	if not root:
		return creatures
	
	# Find all creatures (this searches the entire tree)
	var all_nodes = root.find_children("*", "", false, false)
	for node in all_nodes:
		if node is Creature and not node.is_queued_for_deletion():
			creatures.append(node)
	
	return creatures

## Get tree root safely
static func get_tree_root() -> Node:
	if Engine.is_editor_hint():
		return null
	
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree:
		return main_loop.root.get_child(0)
	
	return null

