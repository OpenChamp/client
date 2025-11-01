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
@export var Team : int        = 1
@export var MaxHealth : int   = 100
@export var Health : int      = 100
@export var MaxMana : int     = 100
@export var Mana : int        = 100
@export var MoveSpeed : float = 5.0
@export var RequiredExp: float = 100.0
@export var CurrentExp: float = 0.0
@export var Level: int = 1
## === Offensive Stats === ##
@export var PhysicalPower : float = 1.0
@export var MagicalPower : float = 1.0
@export var AttackSpeed : float = 1.0
@export var AttackRange : float = 1.0
@export var CritChance : float = 0.0
@export var CritBonus : int = 0
@export var ProjectileSpeed: float = 5.0
## === Defensive Stats === ##
@export var Armor: int = 0;
@export var MagicResist: int = 0;
@export var Dodge: int = 0;

## === Scaling & Utility Stats === ##
@export var HealthRegen: float = 1.0;
@export var ManaRegen: float = 1.0;
@export var LifeSteal: float = 0.0;
@export var OmniVamp: float = 0.0;
@export var Resistance: float = 0.0;
@export var VisionRange: float = 5.0;

## == Scene Requirements == #
@onready var NavAgent: NavigationAgent3D = $NavigationAgent3D

## == Movement & Targeting == #
@export var target_node : Node3D
var max_follow_time: float = 8.0
var can_attack:bool = true

# == Engine Functions == #
func _ready():
	self.add_to_group(str("team", Team))
	pass;
func _physics_process(_d):
	pass;
func _process(_d):
	pass;
func setup_stats():
	Health = MaxHealth
	Mana = MaxHealth

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
			MoveSpeed -= effect.strength
			if MoveSpeed < 0:
				MoveSpeed = 0
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
	Health -= damage

@rpc("authority", "call_local")
func heal(heal_amount: int):
	Health += heal_amount
	if Health > MaxHealth:
		Health = MaxHealth

# === Experience Functions === #
func distribute_experience(total_exp: int, entities_in_range: Array):
	var exp_per_entity = float(total_exp) / entities_in_range.size()
	for entity in entities_in_range:
		entity.gain_experience(exp_per_entity)

func gain_experience(added_exp: float):
	CurrentExp += added_exp
	check_level_up()

func lose_experience(lost_exp: int):
	CurrentExp -= lost_exp

func check_level_up():
	if CurrentExp >= RequiredExp:
		Level += 1
		CurrentExp -= RequiredExp
		RequiredExp = RequiredExp * 1.2
		level_up()
	
func level_up():
	print("Leveled Up to Level ", Level)
	pass;


func set_target_node(node:Node3D):
	print("TARGET NODE SET")
	if target_node:
		target_node.died.disconnect(_on_target_died)
	target_node = node
	target_node.died.connect(_on_target_died)
	_set_target(node.global_position)

func _set_target(pos:Vector3):
	NavAgent.set_target_position(pos)
	
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
	if NavAgent:
		NavAgent.set_target_position(target_pos);
	else:
		ready.connect(func():NavAgent.set_target_position(target_pos))
