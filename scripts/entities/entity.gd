class_name Entity
extends Node3D

const ROTATE_SPEED: float = 5.0  # Radians per second

var state : EntityManagementSystem.EntityState
# TODO: Create enum for minion states
@export var minion_state: int = 0
var server_position : Vector3

# === Core Stats ===
var max_health: float = 1.0
var health: float = 0.0
var max_mana: float = 0.0
var mana: float = 0.0
var move_speed: float = 0.0
var level: int = 1

# === Offensive Stats ===
var attack_range: float = 1.0
var attack_speed: float = 1.0
var auto_damage_type # DamageType enum reference - needs to be defined
var crit_chance: float = 0.0
var crit_bonus: int = 0
var true_bonus: int = 0
var magic_power: float = 1.0
var physical_power: float = 1.0
var projectile_speed: float = 5.0

# === Defensive Stats ===
var armor: int = 0 # Percentage physical damage reduction
var magic_resist: int = 0 # Percentage magic damage reduction
var dodge: int = 0 # Percentage chance to dodge

# === Scaling & Utility Stats ===
var health_regen: float = 1.0
var mana_regen: float = 1.0
var life_steal: float = 0.0 # Percentage of physical damage dealt returned as health
var spell_vamp: float = 0.0 # Percentage of magic damage dealt returned as health
var omni_vamp: float = 0.0 # Percentage of damage dealt returned as health
var leech: float = 0.0 # Percentage of damage dealt returned as mana
var vision_range: float = 1.0

# === Team & Faction ===
var team: int = 0 # [0 = Neutral, 1 = Team 1, 2 = Team 2] -- cmkrist 15/11/2025
@export var red_material = preload("res://default_assets/materials/entities/red_team.tres")
@export var blue_material = preload("res://default_assets/materials/entities/blue_team.tres")
@export var def_material = preload("res://default_assets/materials/cloth_material.tres")

var is_dying : bool = false
func _process(delta):
	if state == EntityManagementSystem.EntityState.DEAD:
		die()
	# Movement logic here
	if server_position:
		var distance = global_position.distance_to(server_position)
		if distance > 0.001:  # Avoid near-zero distance which causes singular matrix error
			# Get direction to server position
			var direction = (server_position - global_position).normalized()
			
			# Get our current forward direction (-Z axis in Godot)
			var current_forward = -global_transform.basis.z
			
			# Calculate angle between current forward and target direction
			var angle_diff = current_forward.angle_to(direction)
			
			# If not already facing the target, rotate towards it
			if angle_diff > 0.01:  # Small threshold to avoid jitter
				# Calculate rotation axis (perpendicular to both vectors)
				var rotation_axis = current_forward.cross(-direction)
				
				# Only rotate if cross product is non-zero (vectors not parallel)
				if rotation_axis.length() > 0.001:
					rotation_axis = rotation_axis.normalized()
					
					# Rotate at ROTATE_SPEED, but don't overshoot
					var rotation_amount = min(angle_diff, ROTATE_SPEED * delta)
					
					# Apply rotation
					global_transform.basis = global_transform.basis.rotated(rotation_axis, rotation_amount)
			
			# Move smoothly towards server position at move_speed
			global_position += direction * move_speed * delta 
		

func set_stat(stat_name: String, stat_value: String) -> void:
	if self[stat_name] == null:
		push_error("Stat %s does not exist on Self!" % stat_name)
		return
	var value = null
	# Attempt to convert to int or float if applicable
	# Try float first since many stats are floats (including health)
	print("Converting stat '%s' with value '%s'" % [stat_name, stat_value])
	print("  is_valid_float: %s" % stat_value.is_valid_float())
	print("  is_valid_int: %s" % stat_value.is_valid_int())
	print("  length: %d" % stat_value.length())
	print("  first char code: %d" % (stat_value[0].unicode_at(0) if stat_value.length() > 0 else -1))
	
	if stat_value.is_valid_float():
		value = float(stat_value)
		print("  -> Converted to float: %f" % value)
	elif stat_value.is_valid_int():
		value = int(stat_value)
		print("  -> Converted to int: %d" % value)
	else:
		value = stat_value
		print("  -> Kept as string: '%s'" % value)
	
	self[stat_name] = value
	
	# Clamp health to valid range (but only if max_health has been set to a reasonable value)
	if stat_name == "health" and typeof(value) in [TYPE_INT, TYPE_FLOAT]:
		# Only clamp if max_health is actually set to something meaningful (> 1.0 or health is smaller)
		if max_health > 1.0 or value < max_health:
			var clamped = max(0.0, min(value, max_health))
			if clamped != value:
				print("Clamped health from %s to %f" % [value, clamped])
				self[stat_name] = clamped
				value = clamped
	
	# Update max_health clamping if health exceeds it
	if stat_name == "max_health" and typeof(value) in [TYPE_INT, TYPE_FLOAT]:
		# If health is higher than the new max_health, clamp health down
		if health > value:
			var clamped_health = max(0.0, value)
			print("Clamped health from %f to %f (max_health changed)" % [health, clamped_health])
			self["health"] = clamped_health
			health = clamped_health
	# update material on team
	if stat_name == "team":
		update_material()
	
	# Update health bar if it exists
	var stat_bar = get_node_or_null("StatBar")
	var sb_stat_whitelist = ["health", "mana", "max_health", "max_mana"]
	if stat_bar != null:
		if sb_stat_whitelist.has(stat_name):
			if stat_name.find("max") != -1:
				stat_bar.set_max(stat_name, value)
			else:
				stat_bar.set_stat(stat_name, value)
		else:
			print(stat_name)
	# If health reaches 0 or below, trigger death
	if stat_name == "health" and value <= 0.0 and state != EntityManagementSystem.EntityState.DEAD:
		print("Health reached 0 for entity %s, triggering death" % name)
		update_state(EntityManagementSystem.EntityState.DEAD)
	
func dealt_damage(_amount):
	pass # -- dunno if it'll get used, maybe quests? -- cmkrist 24/11/2025
	
func take_damage(amount):
	set_stat("health", str(health - amount));
func took_damage(amount): # <-- intentional so it reads better, I know it's wrong but I like it -- cmkrist 24/11/2025
	take_damage(amount)
	

func get_material(team = self.team) -> StandardMaterial3D:
	if team:
		match team:
			1:
				return blue_material
			2:
				return red_material
	return def_material

func update_material():
	var mat := get_material();
	var body = get_node_or_null("Body")
	if body != null:
		body.material_override = mat;
	
func update_state(state:EntityManagementSystem.EntityState):
	self.state = state
	print("New State: ", state)

func die():
	if is_dying:
		return
	is_dying = true
	print("Minion Death")
	var body = get_node_or_null("Body")
	if body != null:
		body.hide()
	
	# Play money emitter and audio if available
	var audio_player = get_node_or_null("AudioStreamPlayer3D")
	var money_emitter = get_node_or_null("MoneyEmitter")
	if audio_player != null:
		if money_emitter != null:
			money_emitter.emitting = true
		audio_player.play()
	
	# Cleanup after 5 seconds max to ensure corpses don't pile up
	var cleanup_timer = get_tree().create_timer(5.0)
	cleanup_timer.timeout.connect(func():
		print("Destroying entity %s by timeout" % name)
		EntityManager.destroy_entity(int(name))
	)
