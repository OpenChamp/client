class_name Creature
extends CharacterBody3D
## === Audio Clips === ##
@export var hurt_sound: AudioStream
@export var death_sound: AudioStream
# Multiple attack sounds for variety
@export var attack_sound_1: AudioStream
@export var attack_sound_2: AudioStream
@export var attack_sound_3: AudioStream

## === Signals === ##
signal died
signal leveled_up(level: int)
## == Team & Identification == ##
@export var creature_id: int
@export var team: int = -1
@export var team_group: String 
## == Movement Configuration == #
@export var server_pos: Vector3
@export var target_node: Node3D
@export var target_pos: Vector3
@export var follow_distance: float = 2.0
@export var max_follow_time: float = 8.0
## == Combat Configuration == ##
@export var attack_cooldown: float = 1.0
@export var attack_timer: float = 0.0
var can_attack_now: bool = true
## == State Management == ##
@export var state: STATE = STATE.IDLE
enum STATE {
	IDLE,
	MOVING,
	FOLLOWING,
	ATTACKING,
	DEAD
}
enum TARGET_STATUS {
	INVALID,
	OUT_OF_RANGE,
	IN_RANGE
}

## === Core Stats === ##
@export var max_health: float   = 100
@export var health: float      = 100
@export var max_mana: float     = 100
@export var mana: float        = 100
@export var move_speed: float = 5.0
@export var required_exp: float = 100.0
@export var addition_exp_per_level: float = 100.0
@export var current_exp: float = 0.0
@export var level: int = 1
## === Offensive Stats === ##
@export var attack_range: float = 1.0 ## In units
@export var attack_speed: float = 1.0 ## Attacks per second
@export var auto_damage_type: OC.DAMAGE_TYPE = OC.DAMAGE_TYPE.PHYSICAL
@export var crit_chance: float = 0.0 ## Percentage chance to crit
@export var crit_bonus: int = 0 ## Flat bonus damage on crit
@export var true_bonus: int = 0 ## Flat bonus true damage on hit
@export var magic_power: float = 1.0 # Flat Magic Damage
@export var physical_power: float = 1.0 # Flat Physical Damage
@export var projectile_speed: float = 5.0
## === Defensive Stats === ##
@export var armor: int = 0# Percentage physical damage reduction
@export var magic_resist: int = 0# Percentage magic damage reduction
@export var dodge: int = 0# Percentage chance to dodge
## === Scaling & Utility Stats === ##
@export var health_regen: float = 1.0# Health regenerated per second
@export var mana_regen: float = 1.0# Mana regenerated per second
@export var life_steal: float = 0.0# Percentage of physical damage dealt returned as health
@export var spell_vamp: float = 0.0# Percentage of magic damage dealt returned as health
@export var omni_vamp: float = 0.0# Percentage of damage dealt returned as health
@export var leech: float = 0.0# Percentage of damage dealt returned as mana
@export var resistance: float = 0.0# Percentage damage reduction
@export var vision_range: float = 5.0# Vision range in units

# == Ready Variables == #
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

# == Level Up Bonuses == #
# This dictionary holds the bonuses granted on level up for each level
# -1 key is used for every level that is not explicitly defined

var level_up_bonuses: Dictionary = {
	-1: {
		"max_health": 50,
		"health_regen": 2.0,
		"physical_power": 5.0,
		"magic_power": 5.0
	}
}
# == Engine Functions == #
func _ready():
	if team != -1:
		self.add_to_group(str("team", team))
	pass
func _physics_process(_d):
	pass
func _process(_d):
	pass
func setup_stats():
	health = max_health
	mana = max_mana

# === Effect Functions === #
func apply_effect(effect: Effect):
	get_tree().create_timer(effect.duration).timeout.connect(remove_effect.bind(effect))
	handle_effect(effect)

func remove_effect(effect: Effect):
	effect.strength = -effect.strength
	handle_effect(effect)

func handle_effect(effect: Effect):
	match effect.type:
		Effect.Type.SLOW:
			move_speed -= effect.strength
			if move_speed < 0:
				move_speed = 0
		Effect.Type.DAMAGE_OVER_TIME:
			var damage_per_tick = effect.strength
			var ticks = int(effect.duration)
			for i in range(ticks):
				get_tree().create_timer(float(i) + 1.0).timeout.connect(func():
					take_damage(int(damage_per_tick), effect.damage_type)
				)
		_:
			print("Effect type not handled: ", effect.type)

# === Health Functions === #
@rpc("authority", "call_local")
func take_damage(damage: int, damage_type: OC.DAMAGE_TYPE):
	match damage_type:
		OC.DAMAGE_TYPE.PHYSICAL:
			var reduced_damage = damage * (1.0 - float(armor) / 100.0)
			health -= reduced_damage
		OC.DAMAGE_TYPE.MAGICAL:
			var reduced_damage = damage * (1.0 - float(magic_resist) / 100.0)
			health -= reduced_damage
		OC.DAMAGE_TYPE.TRUE:
			health -= damage

@rpc("authority", "call_local")
func heal(heal_amount: int):
	health += heal_amount
	if health > max_health:
		health = max_health

# === Experience Functions === #
func distribute_experience(total_exp: int, entities_in_range: Array):
	var exp_per_entity = float(total_exp) / entities_in_range.size()
	for entity in entities_in_range:
		entity.gain_experience(exp_per_entity)

func gain_experience(added_exp: float):
	current_exp += added_exp
	if current_exp >= required_exp:
		level_up()

func level_up():
	level += 1
	current_exp -= required_exp
	required_exp += addition_exp_per_level
	# Apply Level Up Bonuses
	var bonuses = level_up_bonuses.get(level, level_up_bonuses.get(-1, {}))
	for stat_name in bonuses.keys():
		var bonus_value = bonuses[stat_name]
		set(stat_name, stat_name + bonus_value)
	leveled_up.emit(level)

func lose_experience(lost_exp: int):
	current_exp -= lost_exp
	if current_exp < 0:
		current_exp = 0
	
# === Targeting Functions === #
func set_target_node(node: Node3D):
	print("TARGET NODE SET")
	if target_node:
		target_node.died.disconnect(_on_target_died)
	target_node = node
	target_node.died.connect(_on_target_died)
	_set_target(node.global_position)

func _set_target(pos: Vector3):
	nav_agent.set_target_position(pos)
	
# === Combat Functions === #
func attack(body: Node3D = target_node):
	# Example Melee Attack Implementation
	if not can_attack_now: return
	if not body or body.is_dead(): reset(); return
	if not body.has_method("take_damage"): return
	# Animation or Audio can be played here

	# Networking RPC to apply damage
	body.rpc("take_damage", physical_power, auto_damage_type)
	can_attack_now = false
	attack_timer = attack_cooldown
	print("Example Attack Executed, don't leave this in production!")
	get_tree().create_timer(attack_cooldown).timeout.connect(func():can_attack_now = true)

func die():
	print("Base level death has been called")
	self.hide()
	died.emit()

func reset():
	if target_node:
		target_node.died.disconnect(_on_target_died)
		target_node = null
	state = STATE.IDLE
	$FollowTimer.stop()

func _on_target_died():
	print("Target Died")
	reset()

## === Networked RPCs === ##
@rpc("authority")
func update_position(new_pos: Vector3) -> void:
	server_pos = new_pos

@rpc("authority")
func update_global_position(new_pos: Vector3) -> void:
	set_global_position(new_pos)

@rpc("authority", "call_local")
func update_target(new_pos: Vector3) -> void:
	new_pos.y = 0.5
	target_pos = new_pos
	if nav_agent:
		nav_agent.set_target_position(target_pos)
	else:
		ready.connect(func(): nav_agent.set_target_position(target_pos))
