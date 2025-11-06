## ============================================================================
## AOE SYSTEM - Area of Effect Combat
## ============================================================================
## Provides AOE damage, effects, and advanced combat patterns.
## Note: This class uses static methods and integrates with CombatManager
## ============================================================================

class_name AOESystem

## Shape types for AOE patterns
enum ShapeType {
	CIRCLE,
	CONE,
	LINE,
	RECTANGLE,
	DONUT,
	CUSTOM
}

## Query filter for selecting targets
class QueryFilter:
	var include_allies: bool = false
	var include_enemies: bool = true
	var include_neutrals: bool = false
	var include_structures: bool = false
	var max_targets: int = -1  # -1 = unlimited
	var custom_filter: Callable = func(_target): return true
	
	func matches(creature: Creature, caster_team: int) -> bool:
		# Check team alignment
		if creature.team == caster_team:
			if not include_allies:
				return false
		elif creature.team == OC.TEAM.NEUTRAL:
			if not include_neutrals:
				return false
		else:
			if not include_enemies:
				return false
		
		# Apply custom filter
		return custom_filter.call(creature)

## AOE Result containing affected targets
class AOEResult:
	var targets: Array[Creature] = []
	var positions: Array[Vector3] = []
	var distances: Array[float] = []
	
	func get_sorted_by_distance() -> Array[Creature]:
		var sorted = targets.duplicate()
		sorted.sort_custom(func(a, b):
			var idx_a = targets.find(a)
			var idx_b = targets.find(b)
			return distances[idx_a] < distances[idx_b]
		)
		return sorted

## ============================================================================
## PRIMARY METHODS
## ============================================================================

## Query AOE and return all affected creatures
static func query_aoe(center: Vector3, shape_type: ShapeType, 
					 shape_data: Dictionary, query_filter: QueryFilter,
					 caster_team: int = OC.TEAM.NEUTRAL) -> AOEResult:
	
	var result = AOEResult.new()
	var all_creatures = get_all_creatures_in_world()
	
	for creature in all_creatures:
		# Apply filter
		if not query_filter.matches(creature, caster_team):
			continue
		
		# Check if in shape
		if is_in_aoe_shape(creature.global_position, center, shape_type, shape_data):
			var distance = center.distance_to(creature.global_position)
			result.targets.append(creature)
			result.positions.append(creature.global_position)
			result.distances.append(distance)
			
			# Check max targets
			if query_filter.max_targets > 0 and result.targets.size() >= query_filter.max_targets:
				break
	
	return result

## Apply damage to all creatures in AOE
static func apply_aoe_damage(caster: Creature, center: Vector3, radius: float,
							 damage: int, damage_type: OC.DAMAGE_TYPE,
							 exclude_caster: bool = true,
							 extra_data: Dictionary = {}) -> Array[Creature]:
	
	var filter = QueryFilter.new()
	filter.include_enemies = true
	filter.include_neutrals = true
	
	var shape_data = {"radius": radius}
	var result = query_aoe(center, ShapeType.CIRCLE, shape_data, filter, caster.team)
	
	var damaged: Array[Creature] = []
	for target in result.targets:
		if exclude_caster and target == caster:
			continue
		
		var dmg_dealt = CombatManager.apply_damage(caster, target, damage, damage_type, extra_data)
		if dmg_dealt > 0:
			damaged.append(target)
	
	return damaged

## Apply effect to all creatures in AOE
static func apply_aoe_effect(caster: Creature, center: Vector3, radius: float,
							 effect: Effect, exclude_caster: bool = true) -> Array[Creature]:
	
	var filter = QueryFilter.new()
	filter.include_enemies = true
	filter.include_neutrals = true
	
	var shape_data = {"radius": radius}
	var result = query_aoe(center, ShapeType.CIRCLE, shape_data, filter, caster.team)
	
	var affected: Array[Creature] = []
	for target in result.targets:
		if exclude_caster and target == caster:
			continue
		
		CombatManager.apply_effect(target, effect)
		affected.append(target)
	
	return affected

## Apply healing to all creatures in AOE
static func apply_aoe_healing(caster: Creature, center: Vector3, radius: float,
							  heal_amount: int, include_enemies: bool = false) -> Array[Creature]:
	
	var filter = QueryFilter.new()
	filter.include_allies = true
	filter.include_enemies = include_enemies
	
	var shape_data = {"radius": radius}
	var result = query_aoe(center, ShapeType.CIRCLE, shape_data, filter, caster.team)
	
	var healed: Array[Creature] = []
	for target in result.targets:
		CombatManager.apply_healing(caster, target, heal_amount)
		healed.append(target)
	
	return healed

## ============================================================================
## SHAPE DETECTION
## ============================================================================

## Check if position is within AOE shape
static func is_in_aoe_shape(position: Vector3, center: Vector3, 
							 shape_type: ShapeType, shape_data: Dictionary) -> bool:
	
	match shape_type:
		ShapeType.CIRCLE:
			var radius = shape_data.get("radius", 5.0)
			return center.distance_to(position) <= radius
		
		ShapeType.SPHERE:  # Same as circle in 3D
			var radius = shape_data.get("radius", 5.0)
			return center.distance_to(position) <= radius
		
		ShapeType.CONE:
			var radius = shape_data.get("radius", 5.0)
			var direction = shape_data.get("direction", Vector3.FORWARD).normalized()
			var angle = shape_data.get("angle", 45.0)  # in degrees
			return is_in_cone(position, center, direction, radius, angle)
		
		ShapeType.LINE:
			var length = shape_data.get("length", 10.0)
			var direction = shape_data.get("direction", Vector3.FORWARD).normalized()
			var width = shape_data.get("width", 1.0)  # width of ray
			return is_in_line(position, center, direction, length, width)
		
		ShapeType.RECTANGLE:
			var width = shape_data.get("width", 5.0)
			var height = shape_data.get("height", 5.0)
			var direction = shape_data.get("direction", Vector3.FORWARD).normalized()
			return is_in_rectangle(position, center, width, height, direction)
		
		ShapeType.DONUT:
			var inner_radius = shape_data.get("inner_radius", 2.0)
			var outer_radius = shape_data.get("outer_radius", 5.0)
			var distance = center.distance_to(position)
			return distance >= inner_radius and distance <= outer_radius
		
		ShapeType.CUSTOM:
			var check_func: Callable = shape_data.get("check_func", func(_p): return false)
			return check_func.call(position)
	
	return false

## Check if position is in cone
static func is_in_cone(position: Vector3, apex: Vector3, direction: Vector3,
					   radius: float, angle_degrees: float) -> bool:
	
	var to_point = (position - apex).normalized()
	var distance = apex.distance_to(position)
	
	# Check distance
	if distance > radius:
		return false
	
	# Check angle
	var angle_radians = deg_to_rad(angle_degrees / 2.0)
	var dot_product = to_point.dot(direction)
	var angle_check = dot_product >= cos(angle_radians)
	
	return angle_check

## Check if position is in line/ray
static func is_in_line(position: Vector3, start: Vector3, direction: Vector3,
					   length: float, width: float) -> bool:
	
	var end = start + direction * length
	var to_point = position - start
	
	# Project point onto line
	var projection = to_point.dot(direction)
	
	# Check if within line length
	if projection < 0 or projection > length:
		return false
	
	# Find closest point on line
	var closest = start + direction * projection
	var distance_to_line = position.distance_to(closest)
	
	return distance_to_line <= (width / 2.0)

## Check if position is in rectangle
static func is_in_rectangle(position: Vector3, center: Vector3, width: float,
							height: float, direction: Vector3) -> bool:
	
	# Calculate right vector perpendicular to direction
	var right = Vector3.UP.cross(direction).normalized()
	var forward = direction
	
	# Transform position relative to rectangle center
	var relative = position - center
	
	# Project onto rectangle axes
	var forward_projection = abs(relative.dot(forward))
	var right_projection = abs(relative.dot(right))
	
	return forward_projection <= (height / 2.0) and right_projection <= (width / 2.0)

## ============================================================================
## UTILITY FUNCTIONS
## ============================================================================

## Get all creatures in world (can be optimized with spatial partition)
static func get_all_creatures_in_world() -> Array[Creature]:
	var creatures: Array[Creature] = []
	var root = get_tree().root.get_child(0)
	
	for node in root.get_tree().get_nodes_in_group("creatures"):
		if node is Creature:
			creatures.append(node)
	
	return creatures

## Get creatures within range of a point
static func get_creatures_in_range(center: Vector3, radius: float, 
								   team_filter: int = -1) -> Array[Creature]:
	
	var creatures: Array[Creature] = []
	var all = get_all_creatures_in_world()
	
	for creature in all:
		if center.distance_to(creature.global_position) <= radius:
			if team_filter == -1 or creature.team == team_filter:
				creatures.append(creature)
	
	return creatures

## Find closest creature to position
static func find_closest_creature(center: Vector3, exclude: Creature = null,
								 max_range: float = -1) -> Creature:
	
	var closest: Creature = null
	var closest_distance = INF
	
	for creature in get_all_creatures_in_world():
		if creature == exclude:
			continue
		
		var distance = center.distance_to(creature.global_position)
		
		if max_range > 0 and distance > max_range:
			continue
		
		if distance < closest_distance:
			closest = creature
			closest_distance = distance
	
	return closest

## Find all creatures in a direction (like a skill shot)
static func find_creatures_in_direction(start: Vector3, direction: Vector3,
										max_distance: float, 
										detection_width: float = 2.0) -> Array[Creature]:
	
	var shape_data = {
		"direction": direction,
		"length": max_distance,
		"width": detection_width
	}
	
	var filter = QueryFilter.new()
	filter.include_enemies = true
	filter.include_neutrals = true
	
	var result = query_aoe(start, ShapeType.LINE, shape_data, filter)
	return result.targets

## ============================================================================
## ADVANCED AOE PATTERNS
## ============================================================================

## Pulsar effect - expanding circle over time
static func create_pulsar_effect(origin: Creature, center: Vector3, 
								 min_radius: float, max_radius: float,
								 duration: float, tick_rate: float,
								 apply_callback: Callable) -> void:
	
	var elapsed = 0.0
	var tween = create_tween() if origin.has_node(".") else null
	
	if not tween:
		# Fallback without tween
		while elapsed < duration:
			var progress = elapsed / duration
			var current_radius = lerp(min_radius, max_radius, progress)
			apply_callback.call(current_radius)
			elapsed += tick_rate
			await get_tree().create_timer(tick_rate).timeout
	else:
		# Use tween for smooth animation
		tween.tween_callback(func():
			while elapsed < duration:
				var progress = elapsed / duration
				var current_radius = lerp(min_radius, max_radius, progress)
				apply_callback.call(current_radius)
				elapsed += tick_rate
				await get_tree().create_timer(tick_rate).timeout
		)

## Chain attack - hits one target then chains to nearby
static func apply_chain_damage(caster: Creature, initial_target: Creature,
							   base_damage: int, damage_type: OC.DAMAGE_TYPE,
							   chain_range: float, max_chains: int) -> Array[Creature]:
	
	var hit_targets: Array[Creature] = []
	var to_process: Array[Creature] = [initial_target]
	
	while to_process.size() > 0 and hit_targets.size() < max_chains:
		var current = to_process.pop_front()
		
		if current in hit_targets:
			continue
		
		hit_targets.append(current)
		CombatManager.apply_damage(caster, current, base_damage, damage_type)
		
		# Find nearby targets
		var nearby = get_creatures_in_range(current.global_position, chain_range)
		for nearby_target in nearby:
			if nearby_target not in hit_targets and nearby_target.team != caster.team:
				to_process.append(nearby_target)
	
	return hit_targets

## Knockback effect - push creatures away from center
static func apply_aoe_knockback(center: Vector3, radius: float, 
							    knockback_force: float, 
								upward_force: float = 0.0) -> Array[Creature]:
	
	var creatures = get_creatures_in_range(center, radius)
	
	for creature in creatures:
		if not creature.has_method("apply_force"):
			continue
		
		var direction = (creature.global_position - center).normalized()
		var force = direction * knockback_force + Vector3.UP * upward_force
		creature.apply_force(force)
	
	return creatures

## ============================================================================
## VISUALIZATION & DEBUGGING
## ============================================================================

## Draw AOE shape for debugging (only in editor or with debug enabled)
static func debug_draw_aoe(center: Vector3, shape_type: ShapeType,
						  shape_data: Dictionary, color: Color = Color.WHITE,
						  duration: float = 1.0) -> void:
	
	match shape_type:
		ShapeType.CIRCLE:
			debug_draw_circle(center, shape_data.get("radius", 5.0), color, duration)
		
		ShapeType.CONE:
			debug_draw_cone(center, shape_data.get("direction", Vector3.FORWARD),
						   shape_data.get("radius", 5.0), 
						   shape_data.get("angle", 45.0), color, duration)
		
		ShapeType.LINE:
			debug_draw_line(center, shape_data.get("direction", Vector3.FORWARD),
						   shape_data.get("length", 10.0), color, duration)
		
		ShapeType.RECTANGLE:
			debug_draw_rectangle(center, shape_data.get("width", 5.0),
								 shape_data.get("height", 5.0),
								 shape_data.get("direction", Vector3.FORWARD),
								 color, duration)

## Draw circle for debugging
static func debug_draw_circle(center: Vector3, radius: float, 
							  color: Color = Color.WHITE, duration: float = 1.0) -> void:
	
	var segments = 32
	for i in range(segments):
		var angle1 = (TAU / segments) * i
		var angle2 = (TAU / segments) * (i + 1)
		
		var point1 = center + Vector3(cos(angle1) * radius, 0, sin(angle1) * radius)
		var point2 = center + Vector3(cos(angle2) * radius, 0, sin(angle2) * radius)
		
		DebugDraw.line(point1, point2, color, duration)

## Draw cone for debugging
static func debug_draw_cone(center: Vector3, direction: Vector3, radius: float,
							angle_degrees: float, color: Color = Color.WHITE,
							duration: float = 1.0) -> void:
	
	var cone_depth = radius
	var cone_tip = center + direction * cone_depth
	
	# Draw cone sides
	var segments = 16
	var angle_rad = deg_to_rad(angle_degrees / 2.0)
	
	for i in range(segments):
		var angle = (TAU / segments) * i
		var offset = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		var base_point = center + offset
		DebugDraw.line(center, cone_tip, color, duration)
		DebugDraw.line(base_point, cone_tip, color, duration)

## Draw line for debugging
static func debug_draw_line(start: Vector3, direction: Vector3, length: float,
							color: Color = Color.WHITE, duration: float = 1.0) -> void:
	
	var end = start + direction * length
	DebugDraw.line(start, end, color, duration)

## Draw rectangle for debugging
static func debug_draw_rectangle(center: Vector3, width: float, height: float,
								 direction: Vector3, color: Color = Color.WHITE,
								 duration: float = 1.0) -> void:
	
	var right = Vector3.UP.cross(direction).normalized()
	var forward = direction
	
	var corners = [
		center + forward * (height / 2.0) + right * (width / 2.0),
		center + forward * (height / 2.0) - right * (width / 2.0),
		center - forward * (height / 2.0) - right * (width / 2.0),
		center - forward * (height / 2.0) + right * (width / 2.0),
	]
	
	for i in range(4):
		DebugDraw.line(corners[i], corners[(i + 1) % 4], color, duration)

