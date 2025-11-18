extends Node3D
class_name Ranger
enum STATES {
	alive,
	dead
}
var state := STATES.alive
@export var speed: float = 5.0
@export var health:int = 0
# TODO: Create enum for minion states
@export var minion_state: int = 0
var server_position : Vector3
# === Core Stats ===
var max_health: float = 1.0
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
var team_id: int = 0 # [0 = Neutral, 1 = Team 1, 2 = Team 2] -- cmkrist 15/11/2025


func _process(delta):
	# Movement logic here
	if server_position:
		# Simple interpolation towards server position
		global_position = global_position.lerp(server_position, speed * delta)

func set_stat(stat_name: String, stat_value: String) -> void:
	if self[stat_name] == null:
		push_error("Stat %s does not exist on Ranger!" % stat_name)
		return
	var value = null
	# Attempt to convert to int or float if applicable
	if stat_value.is_valid_int():
		value = int(stat_value)
	elif stat_value.is_valid_float():
		value = float(stat_value)
	else:
		value = stat_value
	self[stat_name] = value
# var debug_target_indicator: MeshInstance3D
#
# func _ready() -> void:
	# debug_target_indicator = MeshInstance3D.new()
	# debug_target_indicator.mesh = SphereMesh.new()
	# get_parent().add_child(debug_target_indicator)
	# set_process(true)
	#
## Server
# func _physics_process(delta: float) -> void:
	# if Util.dedicated_server:
		# move_towards_target(delta)
#
## Client
# func _process(delta: float) -> void:
	# if Util.dedicated_server:
		# return
	## Client-side move closer to server position
	# var direction = server_pos - position
	# var distance = direction.length()
	# if distance > 2:
		## Desynced from server, fix pos
		# direction = direction.normalized()
		# look_at(direction)
		# var move_amount = min(distance, stats.move_speed * delta)
		# position += direction * move_amount
	# else:
		# move_towards_target(delta)
	# if debug_target_indicator:
		# debug_target_indicator.global_position = target_pos
#
# func move_towards_target(_delta: float) -> void:
	# if target_pos == Vector3.ZERO:
		# return
	# if not nav_agent.is_target_reachable():
		# print(position)
		# print(target_pos)
		# print("Target is not reachable!")
		# return
	# var dest = nav_agent.get_next_path_position()
	# var local_dest = dest - global_position
	# var direction = local_dest.normalized()
	# if Util.dedicated_server and (local_dest - position).length() < 1:
		# _on_target_reached()
		# return
	# velocity = direction * move_speed
	# move_and_slide()
	## Update clients with current position
	# if Util.dedicated_server:
		# rpc("update_position", position)
	# else:
		# if 1 > (server_pos - position).length():
			# position = server_pos
#
## === Server Only Functions === #
# func _on_target_reached() -> void:
	# if not Util.dedicated_server: return
