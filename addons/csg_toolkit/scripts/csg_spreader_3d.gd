@tool
class_name CSGSpreader3D extends CSGCombiner3D

const SPREADER_NODE_META = "SPREADER_NODE_META"

var _dirty: bool = false
var _template_node_path: NodePath
@export var template_node_path: NodePath:
	get: return _template_node_path
	set(value):
		_template_node_path = value
		_mark_dirty()

var _spread_area_3d: Shape3D = null
@export var spread_area_3d: Shape3D = null:
	get: return _spread_area_3d
	set(value):
		_spread_area_3d = value
		_mark_dirty()

var _max_count: int = 10
@export var max_count: int = 10:
	get: return _max_count
	set(value):
		# Clamp to reasonable limits to prevent performance issues
		_max_count = clamp(value, 1, 1000)
		_mark_dirty()

@export_group("Spread Options")
var _noise_threshold: float = 0.5
@export var noise_threshold: float = 0.5:
	get: return _noise_threshold
	set(value):
		_noise_threshold = clamp(value, 0.0, 1.0)
		_mark_dirty()

var _seed: int = 0
@export var seed: int = 0:
	get: return _seed
	set(value):
		_seed = value
		_mark_dirty()

var _allow_rotation: bool = false
@export var allow_rotation: bool = false:
	get: return _allow_rotation
	set(value):
		_allow_rotation = value
		_mark_dirty()

var _allow_scale: bool = false
@export var allow_scale: bool = false:
	get: return _allow_scale
	set(value):
		_allow_scale = value
		_mark_dirty()

var _snap_distance = 0
@export var snap_distance = 0:
	get: return _snap_distance
	set(value):
		_snap_distance = value
		_mark_dirty()

@export_group("Collision Options")
var _avoid_overlaps: bool = false
@export var avoid_overlaps: bool = false:
	get: return _avoid_overlaps
	set(value):
		_avoid_overlaps = value
		_mark_dirty()

var _min_distance: float = 1.0
@export var min_distance: float = 1.0:
	get: return _min_distance
	set(value):
		_min_distance = max(0.0, value)
		_mark_dirty()

var _max_placement_attempts: int = 100
@export var max_placement_attempts: int = 100:
	get: return _max_placement_attempts
	set(value):
		_max_placement_attempts = clamp(value, 10, 1000)
		_mark_dirty()

var rng: RandomNumberGenerator

func _ready():
	rng = RandomNumberGenerator.new()
	_mark_dirty()

func _process(_delta):
	if not Engine.is_editor_hint(): return
	
	# Only process if in editor mode
	if _dirty:
		spread_template()
		_dirty = false

func _exit_tree():
	if not Engine.is_editor_hint():
		return
	# Clean up any remaining spread nodes
	clear_children()

func _mark_dirty():
	_dirty = true

func clear_children():
	# Clear existing children except the template node
	var children_to_remove = []
	for child in get_children(true):
		if child.has_meta(SPREADER_NODE_META):
			children_to_remove.append(child)
	
	# Remove children immediately for better performance
	for child in children_to_remove:
		remove_child(child)
		child.queue_free()

func get_random_position_in_area() -> Vector3:
	if spread_area_3d is SphereShape3D:
		# Sphere: Random point within the sphere's radius using more uniform distribution
		var radius = spread_area_3d.get_radius()
		var u = rng.randf()
		var v = rng.randf()
		var theta = u * TAU
		var phi = acos(2.0 * v - 1.0)
		var r = radius * pow(rng.randf(), 1.0/3.0)  # Cubic root for uniform volume distribution
		
		var x = r * sin(phi) * cos(theta)
		var y = r * sin(phi) * sin(theta)
		var z = r * cos(phi)
		return Vector3(x, y, z)

	if spread_area_3d is BoxShape3D:
		# Box: Random point within the box's size
		var size = spread_area_3d.size
		var x = rng.randf_range(-size.x * 0.5, size.x * 0.5)
		var y = rng.randf_range(-size.y * 0.5, size.y * 0.5)
		var z = rng.randf_range(-size.z * 0.5, size.z * 0.5)
		return Vector3(x, y, z)

	if spread_area_3d is CapsuleShape3D:
		# Capsule: Random point within the capsule's bounds
		var radius = spread_area_3d.get_radius()
		var height = spread_area_3d.get_height() * 0.5
		
		# Choose either hemisphere or cylindrical part
		if rng.randf() < noise_threshold:  # Bias towards cylinder part
			# Generate point in the cylinder
			var angle = rng.randf() * TAU
			var r = radius * sqrt(rng.randf())  # Square root for uniform area distribution
			var x = r * cos(angle)
			var z = r * sin(angle)
			var y = rng.randf_range(-height, height)
			return Vector3(x, y, z)
		else:
			# Generate point in one of the hemispheres
			var hemisphere_y = height if rng.randf() < noise_threshold else -height
			var u = rng.randf()
			var v = rng.randf()
			var theta = u * TAU
			var phi = acos(1.0 - v)  # Only upper hemisphere
			var r = radius * pow(rng.randf(), 1.0/3.0)
			
			var x = r * sin(phi) * cos(theta)
			var y = hemisphere_y + r * cos(phi) * (1 if hemisphere_y > 0 else -1)
			var z = r * sin(phi) * sin(theta)
			return Vector3(x, y, z)

	if spread_area_3d is CylinderShape3D:
		# Cylinder: Random point within the cylinder's bounds
		var radius = spread_area_3d.get_radius()
		var height = spread_area_3d.get_height() * 0.5
		var angle = rng.randf() * TAU
		var r = radius * sqrt(rng.randf())  # Square root for uniform area distribution
		var x = r * cos(angle)
		var z = r * sin(angle)
		var y = rng.randf_range(-height, height)
		return Vector3(x, y, z)

	if spread_area_3d is HeightMapShape3D:
		var width = spread_area_3d.map_width
		var depth = spread_area_3d.map_depth
		if width <= 0 or depth <= 0 or spread_area_3d.map_data.size() == 0:
			return Vector3.ZERO
			
		var x = rng.randi_range(0, width - 1)
		var z = rng.randi_range(0, depth - 1)
		var index = x + z * width
		if index < spread_area_3d.map_data.size():
			var y = spread_area_3d.map_data[index]
			return Vector3(x, y, z)
		return Vector3.ZERO

	if spread_area_3d is WorldBoundaryShape3D:
		# WorldBoundary: Limited to reasonable bounds
		var bound = 100.0  # Reasonable limit
		return Vector3(
			rng.randf_range(-bound, bound),
			0,  # Usually represents ground plane
			rng.randf_range(-bound, bound)
		)

	if spread_area_3d is ConvexPolygonShape3D or spread_area_3d is ConcavePolygonShape3D:
		# Convex/Concave Polygon: Use AABB approximation
		var points = spread_area_3d.points if spread_area_3d.has_method("get_points") else []
		if points.size() == 0:
			return Vector3.ZERO
			
		# Calculate bounding box from points
		var min_point = points[0]
		var max_point = points[0]
		for point in points:
			min_point = min_point.min(point)
			max_point = max_point.max(point)
		
		return Vector3(
			rng.randf_range(min_point.x, max_point.x),
			rng.randf_range(min_point.y, max_point.y),
			rng.randf_range(min_point.z, max_point.z)
		)
	
	print("Warning: Shape type not supported for spreading: ", spread_area_3d.get_class())
	return Vector3.ZERO

func spread_template():		
	if not spread_area_3d:
		return
	
	clear_children()

	var template_node = get_node_or_null(template_node_path)
	if not template_node:
		return

	# Set the RNG seed for consistent results
	rng.seed = _seed

	# Spread the template node around the area
	var instances_created = 0
	var placed_positions = []  # Track positions for collision avoidance
	
	for i in range(_max_count):
		var noise_value = rng.randf()
		if noise_value <= _noise_threshold:
			continue
		
		var position_found = false
		var final_position = Vector3.ZERO
		
		# Try to find a valid position (with collision avoidance if enabled)
		for attempt in range(_max_placement_attempts if _avoid_overlaps else 1):
			var test_position = get_random_position_in_area()
			
			if not _avoid_overlaps:
				final_position = test_position
				position_found = true
				break
			
			# Check for overlaps with existing positions
			var overlap = false
			for existing_pos in placed_positions:
				if test_position.distance_to(existing_pos) < _min_distance:
					overlap = true
					break
			
			if not overlap:
				final_position = test_position
				position_found = true
				break
		
		if not position_found:
			continue  # Skip this instance if no valid position found
			
		var instance = template_node.duplicate()
		instance.set_meta(SPREADER_NODE_META, true)
		
		# Position the instance
		instance.transform.origin = final_position
		placed_positions.append(final_position)
		
		# Apply rotation if enabled
		if _allow_rotation:
			var rotation_y = rng.randf_range(0, TAU)
			instance.transform.basis = instance.transform.basis.rotated(Vector3.UP, rotation_y)
		
		# Apply scale if enabled
		if _allow_scale:
			var scale_factor = rng.randf_range(0.5, 2.0)  # More reasonable scale range
			instance.transform.basis = instance.transform.basis.scaled(Vector3.ONE * scale_factor)
		
		add_child(instance)
		instances_created += 1
