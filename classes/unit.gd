extends CharacterBody3D
class_name Unit


# General Stats:
@export var id: int
@export var team: int
@export var move_speed: float = 100.0
# Defensive Stats:
@export var max_health: float = 100.0
@onready var current_health: float = max_health
@export var health_regen: float = 5
var overheal: float = 0;
@export var armor: float = 20.0
#@export var magic_resist:float = 20.0
# Offensive Stats:
@export var attack_damage: float = 60.0
@export var attack_speed: float = 0.75
#@export var attack_windup: float = 0.2
@export var attack_range: float = 3.0
#@export var attack_time: float = 0.1
#@export var critical_chance: float = 0.0
#@export var critical_damage: float = 100
# Rotation:
@export var turn_speed: float = 15.0

# Each bit of cc_state represents a different type of crowd control.
var cc_state: int = 6
var effect_array: Array[UnitEffect] = []

var target_entity: Node = null
var server_position

@export var can_respawn: bool = false;
@onready var nav_agent :NavigationAgent3D = $NavigationAgent3D
# Signals
signal died
# UI
@export var projectile_scene: PackedScene = null
@onready var healthbar = $Healthbar


func _ready():
	pass


# Movement
func update_target_location(target_location: Vector3):
	print("Target Location Updated");
	target_entity = null
	nav_agent.target_position = target_location


## Combat
func take_damage(damage: float):
	if not can_take_damage(): return
	var taken: float = armor / 100
	taken = damage / (taken + 1)
	if overheal > 0:
		overheal -= taken
		if overheal <= 0:
			current_health += overheal
			overheal = 0
	else:
		current_health -= taken
	if current_health <= 0:
		current_health = 0
		die()

func heal(amount:float, keep_extra:bool = false):
	current_health += amount
	if current_health <= max_health: return
	if keep_extra:
		overheal = current_health - max_health
	current_health = max_health

func die():
	get_tree().quit()

# UI
func _update_healthbar(node: ProgressBar):
	node.value = current_health


func move_on_path(delta: float):
	if nav_agent.is_navigation_finished(): return
	if not can_move(): return
	server_position = global_position
	
	var target_location = nav_agent.get_next_path_position()
	var direction = target_location - global_position
	
	velocity = direction.normalized() * move_speed * delta
	rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), turn_speed * delta)
	move_and_slide()


func apply_cc(cc_mask: int, duration: float):
	var effect = UnitEffect.new()
	effect.one_shot = true
	effect.cc_mask = cc_mask
	effect.time_left = duration
	cc_state = cc_state | cc_mask
	effect_array.append(effect)
	add_child(effect)


func _on_cc_end(effect: UnitEffect):
	effect_array.erase(effect)
	var cc_removal_mask := ~effect.cc_mask
	for eff in effect_array:
		var shared_cc := eff.cc_mask & effect.cc_mask
		if shared_cc != 0:
			cc_removal_mask = cc_removal_mask & ~shared_cc
	cc_state = cc_state & cc_removal_mask
	effect.end()


func can_move() -> bool:
	return cc_state & 1 == 0


func can_attack() -> bool:
	return cc_state & 1 == 0


func can_cast_movement() -> bool:
	return cc_state & 2 == 0


func can_cast() -> bool:
	return cc_state & 4 == 0


func can_change_target() -> bool:
	return cc_state & 8 == 0


func can_take_damage() -> bool:
	return cc_state & 16 == 0


@rpc("authority", "call_local")
func change_state(new, args):
	$StateMachine.change_state(new, args);
