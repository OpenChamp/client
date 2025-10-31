extends CharacterBody3D
class_name OC_Entity

@export var server_pos: Vector3
@export var death_sound: AudioStream
var target_pos: Vector3 = Vector3.ZERO

## === Signals === ##
signal died
## === Core Stats === ##
@export var Team : int        = 1
@export var MaxHealth : int   = 100
@export var Health : int      = 100
@export var MaxMana : int     = 100
@export var Mana : int        = 100
@export var MoveSpeed : float = 5.0
@export var total_experience: int = 0

## === Offensive Stats === ##
@export var PhysicalPower : float = 1.0
@export var MagicalPower : float = 1.0
@export var AttackSpeed : float = 1.0
@export var CritChance : float = 0.0
@export var CritBonus : int = 0

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
@export var TotalExp: int = 100;

## == Scene Requirements == #
@onready var NavAgent: NavigationAgent3D = $NavigationAgent3D

## == Movement & Targeting == #
@export var target_node : Node3D

func get_team() -> int:
	return Team

func gain_experience(exp: int):
	# Override this in player classes to handle experience gain
	print("Gained ", exp, " experience")
	TotalExp += exp

func lose_experience(exp: int):
	# Override this in player classes to handle experience loss
	print("Lost ", exp, " experience")
	TotalExp -= exp

func take_damage(damage: int):
	Health -= damage
	if Health <= 0:
		die()

func heal(heal_amount: int):
	Health += heal_amount
	if Health > MaxHealth:
		Health = MaxHealth

func set_target_node(node:Node3D):
	target_node = node
	_set_target(node.global_position)

func _set_target(pos:Vector3):
	NavAgent.set_target_position(pos)
	
func die():
	queue_free()
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
