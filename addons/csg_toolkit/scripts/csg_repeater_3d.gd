@tool
class_name CSGRepeater3D extends CSGCombiner3D

const REPEATER_NODE_META = "REPEATED_NODE_META"

var _dirty: bool = false
var _template_node_path: NodePath
@export var template_node_path: NodePath:
	get: return _template_node_path
	set(value):
		_template_node_path = value
		_mark_dirty()

var _template_node_scene: PackedScene
@export var template_node_scene: PackedScene:
	get: return _template_node_scene
	set(value):
		_template_node_scene = value
		_mark_dirty()

var _repeat: Vector3 = Vector3.ONE
@export var repeat := Vector3.ONE:
	get:
		return _repeat
	set(value):
		# Clamp to reasonable limits to prevent performance issues
		value.x = clamp(value.x, 1, 100)
		value.y = clamp(value.y, 1, 100)
		value.z = clamp(value.z, 1, 100)
		_repeat = value
		_mark_dirty()

var _spacing: Vector3 = Vector3.ZERO
@export var spacing := Vector3.ZERO:
	get:
		return _spacing
	set(value):
		_spacing = value
		_mark_dirty()

@export_group("Pattern Options")
var _pattern_type: PatternType = PatternType.GRID
@export var pattern_type: PatternType = PatternType.GRID:
	get: return _pattern_type
	set(value):
		_pattern_type = value
		_mark_dirty()

enum PatternType {
	GRID,
	CIRCULAR,
	SPIRAL,
	RANDOM_GRID
}

var _circular_radius: float = 5.0
@export var circular_radius: float = 5.0:
	get: return _circular_radius
	set(value):
		_circular_radius = max(0.1, value)
		_mark_dirty()

var _spiral_turns: float = 2.0
@export var spiral_turns: float = 2.0:
	get: return _spiral_turns
	set(value):
		_spiral_turns = max(0.1, value)
		_mark_dirty()

@export_group("Variation Options")
var _randomize_rotation: bool = false
@export var randomize_rotation: bool = false:
	get: return _randomize_rotation
	set(value):
		_randomize_rotation = value
		_mark_dirty()

var _randomize_scale: bool = false
@export var randomize_scale: bool = false:
	get: return _randomize_scale
	set(value):
		_randomize_scale = value
		_mark_dirty()

var _scale_variance: float = 0.2
@export_range(0.0, 1.0) var scale_variance: float = 0.2:
	get: return _scale_variance
	set(value):
		_scale_variance = value
		if _randomize_scale:
			_mark_dirty()

var _position_jitter: float = 0.0
@export var position_jitter: float = 0.0:
	get: return _position_jitter
	set(value):
		_position_jitter = max(0.0, value)
		_mark_dirty()

var _random_seed: int = 0
@export var random_seed: int = 0:
	get: return _random_seed
	set(value):
		_random_seed = value
		_mark_dirty()

var rng: RandomNumberGenerator

func _ready():
	rng = RandomNumberGenerator.new()
	_mark_dirty()

func _process(_delta):
	if not Engine.is_editor_hint(): return

	if _dirty:
		_dirty = false
		repeat_template()

func _exit_tree():	
	# Clean up any remaining repeated nodes
	clear_children()

func _mark_dirty():
	_dirty = true
	
func clear_children():
	# Clear existing children except the template node
	var children_to_remove = []
	for child in get_children(true):
		if child.has_meta(REPEATER_NODE_META):
			children_to_remove.append(child)
	
	# Remove children immediately for better performance
	for child in children_to_remove:
		remove_child(child)
		child.queue_free()

func repeat_template():		
	clear_children()

	var template_node = get_node_or_null(template_node_path)
	var using_scene = false
	
	# Determine template source
	if not template_node:
		if not template_node_scene or not template_node_scene.can_instantiate():
			return
		template_node = template_node_scene.instantiate()
		using_scene = true
		# Add to scene tree temporarily for duplication
		add_child(template_node)
	
	# Early exit for single instance
	var total_repeats = int(_repeat.x) * int(_repeat.y) * int(_repeat.z)
	if total_repeats <= 1:
		if using_scene:
			remove_child(template_node)
			template_node.queue_free()
		return
	
	# Set random seed for consistent results
	rng.seed = _random_seed
	
	# Generate positions based on pattern type
	var positions = _generate_positions()
	
	# Create instances at calculated positions
	for i in range(positions.size()):
		var position = positions[i]
		
		# Skip origin position if it's the first one (0,0,0)
		if i == 0 and position.is_zero_approx():
			continue
			
		var instance = template_node.duplicate()
		instance.set_meta(REPEATER_NODE_META, true)
		
		# Set position
		instance.transform.origin = position
		
		# Apply variations
		_apply_variations(instance)
		
		# Add the instance to the combiner
		add_child(instance)
	
	# Clean up temporary template node if using scene
	if using_scene:
		remove_child(template_node)
		template_node.queue_free()

func _generate_positions() -> Array:
	var positions = []
	
	match _pattern_type:
		PatternType.GRID:
			positions = _generate_grid_positions()
		PatternType.CIRCULAR:
			positions = _generate_circular_positions()
		PatternType.SPIRAL:
			positions = _generate_spiral_positions()
		PatternType.RANDOM_GRID:
			positions = _generate_random_grid_positions()
	
	return positions

func _generate_grid_positions() -> Array:
	var positions = []
	var base_spacing = _spacing
	
	for x in range(int(_repeat.x)):
		for y in range(int(_repeat.y)):
			for z in range(int(_repeat.z)):
				var position = Vector3(
					x * base_spacing.x,
					y * base_spacing.y,
					z * base_spacing.z
				)
				
				# Add position jitter if enabled
				if _position_jitter > 0.0:
					position += Vector3(
						rng.randf_range(-_position_jitter, _position_jitter),
						rng.randf_range(-_position_jitter, _position_jitter),
						rng.randf_range(-_position_jitter, _position_jitter)
					)
				
				positions.append(position)
	
	return positions

func _generate_circular_positions() -> Array:
	var positions = []
	var total_count = int(_repeat.x)  # Use X as the count for circular pattern
	
	if total_count <= 1:
		return [Vector3.ZERO]
	
	for i in range(total_count):
		var angle = (i * TAU) / total_count
		var position = Vector3(
			cos(angle) * _circular_radius,
			0,
			sin(angle) * _circular_radius
		)
		
		# Add vertical layers if Y repeat > 1
		for layer in range(int(_repeat.y)):
			var layered_position = position + Vector3(0, layer * _spacing.y, 0)
			positions.append(layered_position)
	
	return positions

func _generate_spiral_positions() -> Array:
	var positions = []
	var total_count = int(_repeat.x)
	
	if total_count <= 1:
		return [Vector3.ZERO]
	
	for i in range(total_count):
		var t = float(i) / float(total_count - 1)
		var angle = t * _spiral_turns * TAU
		var radius = _circular_radius * t
		
		var position = Vector3(
			cos(angle) * radius,
			t * _spacing.y * _repeat.y,  # Vertical progression
			sin(angle) * radius
		)
		
		positions.append(position)
	
	return positions

func _generate_random_grid_positions() -> Array:
	var positions = []
	var grid_positions = _generate_grid_positions()
	
	# Shuffle the grid positions for random placement
	for i in range(grid_positions.size()):
		var j = rng.randi_range(i, grid_positions.size() - 1)
		var temp = grid_positions[i]
		grid_positions[i] = grid_positions[j]
		grid_positions[j] = temp
	
	return grid_positions

func _apply_material_recursive(node: Node, material: Material):
	if node is CSGShape3D:
		node.material_override = material
	
	for child in node.get_children():
		_apply_material_recursive(child, material)

func _apply_variations(instance: Node3D):
	# Apply random rotation if enabled
	if _randomize_rotation:
		var rotation_angles = Vector3(
			rng.randf_range(0, TAU) if _randomize_rotation else 0,
			rng.randf_range(0, TAU) if _randomize_rotation else 0,
			rng.randf_range(0, TAU) if _randomize_rotation else 0
		)
		instance.transform.basis = instance.transform.basis.rotated(Vector3.RIGHT, rotation_angles.x)
		instance.transform.basis = instance.transform.basis.rotated(Vector3.UP, rotation_angles.y)
		instance.transform.basis = instance.transform.basis.rotated(Vector3.FORWARD, rotation_angles.z)
	
	# Apply random scale if enabled
	if _randomize_scale:
		var scale_factor = 1.0 + rng.randf_range(-_scale_variance, _scale_variance)
		scale_factor = max(0.1, scale_factor)  # Prevent negative or zero scale
		instance.transform.basis = instance.transform.basis.scaled(Vector3.ONE * scale_factor)

# Utility function to regenerate with new seed
func regenerate():
	_mark_dirty()

# Get total instance count for current settings
func get_instance_count() -> int:
	match _pattern_type:
		PatternType.GRID:
			return int(_repeat.x * _repeat.y * _repeat.z) - 1  # -1 for origin
		PatternType.CIRCULAR:
			return int(_repeat.x * _repeat.y) - 1
		PatternType.SPIRAL:
			return int(_repeat.x) - 1
		PatternType.RANDOM_GRID:
			return int(_repeat.x * _repeat.y * _repeat.z) - 1
	return 0

func apply_template():
	if get_child_count() == 0:
		return
	var stack = []
	stack.append_array(get_children())
	while stack.size() > 0:
		var node = stack.pop_back()
		node.set_owner(owner)
		stack.append_array(node.get_children())
