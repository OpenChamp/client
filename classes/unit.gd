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
var cc_state: int = 0
# 1: Stunned
# 2: Snared
# 4: Silenced
# 8: Disarmed
# 16: Stasis

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


func _process(delta):
	_update_healthbar(healthbar)

func _physics_process(delta: float):
	move(delta);

# Movement
func update_target_location(target_location: Vector3):
	print("Target Location Updated");
	target_entity = null
	nav_agent.target_position = target_location


func move(delta: float):
	var target_location = nav_agent.get_next_path_position()
	if global_position.distance_to(target_location) <= .1:
		return
	var current_location = global_position
	var direction = target_location - current_location
	velocity = direction.normalized() * move_speed * delta
	rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), turn_speed * delta)
	move_and_slide()

## Combat
func take_damage(damage: float):
	var taken: float = armor / 100
	taken = damage / (taken + 1)
	if overheal > 0:
		overheal -= taken
		if overheal <= 0:
			current_health -= overheal
			overheal = 0
	else:
		current_health -= taken
	if current_health <= 0:
		current_health = 0
		die()

func heal(amount:float, keep_extra:bool = false):
	current_health += amount
	if current_health > max_health and not keep_extra:
		current_health = max_health
	else:
		overheal = current_health - max_health
		current_health = max_health

func die():
	get_tree().quit()

# UI
func _update_healthbar(node: ProgressBar):
	node.value = current_health


func move_on_path(delta: float):
	server_position = global_position
	var target_location = nav_agent.get_next_path_position()
	# Check if target is looking at target
	
	if nav_agent.is_navigation_finished():
		return
	var direction = target_location - global_position
	velocity = direction.normalized() * move_speed * delta
	rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), turn_speed * delta)
	move_and_slide()
	


@rpc("authority", "call_local")
func change_state(new, args):
	$StateMachine.change_state(new, args);
