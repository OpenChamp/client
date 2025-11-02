extends CharacterBody3D
class_name OC_Entity

@export var server_pos: Vector3
@export var death_sound: AudioStream
var target_pos: Vector3 = Vector3.ZERO

## == States & Enums == ##
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

## === Signals === ##
signal died
## === Core Stats === ##
@export var team : int        = 1
@export var max_health : int   = 100
@export var health : int      = 100
@export var max_mana : int     = 100
@export var mana : int        = 100
@export var move_speed : float = 5.0
@export var required_exp: float = 100.0
@export var current_exp: float = 0.0
@export var level: int = 1
## === Offensive Stats === ##
@export var attack_range : float = 1.0 ## In units
@export var attack_speed : float = 1.0 ## Attacks per second
@export var crit_chance : float = 0.0 ## Percentage chance to crit
@export var crit_bonus : int = 0 ## Flat bonus damage on crit
@export var true_bonus : int = 0 ## Flat bonus true damage on hit
@export var magic_power : float = 1.0 # Flat Magic Damage
@export var physical_power : float = 1.0 # Flat Physical Damage
@export var projectile_speed: float = 5.0
## === Defensive Stats === ##
@export var armor: int = 0;
@export var magic_resist: int = 0;
@export var dodge: int = 0;
## === Scaling & Utility Stats === ##
@export var health_regen: float = 1.0;
@export var mana_regen: float = 1.0;
@export var life_steal: float = 0.0;
@export var omni_vamp: float = 0.0;
@export var resistance: float = 0.0;
@export var vision_range: float = 5.0;

## == Scene Requirements == #
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

## == Movement & Targeting == #
@export var target_node : Node3D
var max_follow_time: float = 8.0
var can_attack:bool = true

# == Engine Functions == #
func _ready():
	self.add_to_group(str("team", team))
	pass;
func _physics_process(_d):
	pass;
func _process(_d):
	pass;
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
					take_damage(int(damage_per_tick))
				)
		_:
			print("Effect type not handled: ", effect.type)

# === Health Functions === #
@rpc("authority", "call_local")
func take_damage(damage: int):
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
	check_level_up()

func lose_experience(lost_exp: int):
	current_exp -= lost_exp

func check_level_up():
	if current_exp >= required_exp:
		level += 1
		current_exp -= required_exp
		required_exp = required_exp * 1.2
		level_up()
	
func level_up():
	print("Leveled Up to Level ", level)
	pass;


func set_target_node(node:Node3D):
	print("TARGET NODE SET")
	if target_node:
		target_node.died.disconnect(_on_target_died)
	target_node = node
	target_node.died.connect(_on_target_died)
	_set_target(node.global_position)

func _set_target(pos:Vector3):
	nav_agent.set_target_position(pos)
	
func die():
	print("Base level death has been called")
	self.hide()
	died.emit()

func reset():
	if target_node:
		target_node.died.disconnect(_on_target_died)
		target_node = null
	state = OC_Entity.STATE.IDLE
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
	new_pos.y = .5
	target_pos = new_pos
	if nav_agent:
		nav_agent.set_target_position(target_pos);
	else:
		ready.connect(func():nav_agent.set_target_position(target_pos))
