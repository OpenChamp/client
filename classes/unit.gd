extends CharacterBody3D
class_name Unit


# General Stats:
@export var id: int
@export var team: int
# Defensive Stats:

#@export var magic_resist:float = 20.0

# Offensive Stats:
#@export var attack_windup: float = 0.2
#@export var attack_time: float = 0.1
#@export var critical_chance: float = 0.0
#@export var critical_damage: float = 100


var maximum_stats: StatCollection
var current_stats: StatCollection

var has_mana: bool = false

var current_shielding: int = 0

# Rotation:
@export var turn_speed: float = 15.0

# Each bit of cc_state represents a different type of crowd control.
var cc_state: int = 0
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


func _init():
	maximum_stats = StatCollection.from_dict({
		"health_max": 640,
		"health_regen": 3.5,

		"mana_max": 280,
		"mana_regen": 7,
		
		"armor": 26,
		"magic_resist": 30,

		"attack_range": 3.0,
		"attack_damage": 60,
		"attack_speed": 0.75,

		"movement_speed": 100,
	} as Dictionary)
	
	current_stats = maximum_stats.get_copy()

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

	var taken = float(current_stats.armor) / 100.0
	taken = damage / (taken + 1)

	var actual_damage = int(taken)
	if current_shielding > 0:
		current_shielding -= actual_damage
		if current_shielding <= 0:
			current_stats.health_max += current_shielding
			current_shielding = 0
	else:
		current_stats.health_max -= actual_damage
	
	if current_stats.health_max <= 0:
		current_stats.health_max = 0
		die()


func heal(amount:float, keep_extra:bool = false):
	current_stats.health_max += int(amount)
	if current_stats.health_max <= maximum_stats.health_max: return
	if keep_extra:
		current_shielding = current_stats.health_max - maximum_stats.health_max
	current_stats.health_max = maximum_stats.health_max


func die():
	get_tree().quit()

# UI
func _update_healthbar(node: ProgressBar):
	node.value = current_stats.health_max


func move_on_path(delta: float):
	if nav_agent.is_navigation_finished(): return
	if not can_move(): return
	server_position = global_position
	
	var target_location = nav_agent.get_next_path_position()
	var direction = target_location - global_position
	
	velocity = direction.normalized() * current_stats.movement_speed * delta
	rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), turn_speed * delta)
	move_and_slide()


func apply_effect(effect: UnitEffect):
	effect_array.append(effect)
	add_child(effect)
	recalculate_cc_state()


func _on_cc_end(effect: UnitEffect):
	effect_array.erase(effect)
	effect.end()
	recalculate_cc_state()


func recalculate_cc_state() -> int:
	var new_state := 0
	for effect in effect_array:
		new_state = new_state | effect.cc_mask
	cc_state = new_state
	return new_state


func can_move() -> bool:
	return cc_state & CCTypesRegistry.CC_MASK_MOVEMENT == 0


func can_cast_movement() -> bool:
	return cc_state & CCTypesRegistry.CC_MASK_CAST_MOBILITY == 0


func can_attack() -> bool:
	return cc_state & CCTypesRegistry.CC_MASK_ATTACK == 0


func can_cast() -> bool:
	return cc_state & CCTypesRegistry.CC_MASK_CAST == 0


func can_change_target() -> bool:
	return cc_state & CCTypesRegistry.CC_MASK_TARGET == 0


func can_take_damage() -> bool:
	return cc_state & CCTypesRegistry.CC_MASK_TAKE_DAMAGE == 0


@rpc("authority", "call_local")
func change_state(new, args):
	$StateMachine.change_state(new, args);
