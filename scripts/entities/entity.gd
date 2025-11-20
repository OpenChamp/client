class_name Entity
extends Node3D

enum STATES {
	alive,
	dead
}
var state := STATES.alive
# TODO: Create enum for minion states
@export var minion_state: int = 0
var server_position : Vector3

# === Core Stats ===
var max_health: float = 1.0
var health:int = 0
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

@export var red_material = preload("res://default_assets/materials/entities/red_team.tres")
@export var blue_material = preload("res://default_assets/materials/entities/blue_team.tres")
@export var def_material = preload("res://default_assets/materials/cloth_material.tres")

func _process(delta):
	# Movement logic here
	if server_position:
		# Simple interpolation towards server position
		if global_position != server_position:
			look_at(server_position, Vector3.UP);
			#global_position = global_position.lerp(server_position, move_speed * delta);
			global_position = server_position
		

func set_stat(stat_name: String, stat_value: String) -> void:
	if self[stat_name] == null:
		push_error("Stat %s does not exist on Self!" % stat_name)
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
	if $HealthBar:
		if stat_name == "health":
			$HealthBar.set_health(value)
		elif stat_name == "max_health":
			$HealthBar.set_max_health(value)
	update_material();

func get_material(team = self.team_id) -> StandardMaterial3D:
	if team:
		match team:
			1:
				return blue_material
			2:
				return red_material
	return def_material

func update_material():
	var mat := get_material();
	if $Body:
		$Body.material_override = mat;
	

func die():
	if state == STATES.dead: return
	state = STATES.dead
	print("Minion Death")
	$Body.hide()
	$MoneyEmitter.emitting = true
	$AudioStreamPlayer3D.play()
	$AudioStreamPlayer3D.finished.connect(queue_free)
