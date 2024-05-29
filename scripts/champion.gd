extends Unit

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var range_collider_activate: Area3D = $ActivationArea
@onready var range_collider_attack: Area3D = $AttackArea
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var healthbar: ProgressBar = $Healthbar

@export var ability1_scene: PackedScene
@export var ability2_scene: PackedScene
@export var ability3_scene: PackedScene
@export var ability4_scene: PackedScene

var ability1
var ability2
var ability3
var ability4


@export var pid: int
@export var max_mana: float = 300.0
@export var mana: float = 300.0

func _ready():
	attack_range = 20.0
	setup(
		nav_agent,
		range_collider_activate,
		range_collider_attack,
		mesh_instance,
		attack_timer,
		healthbar
	)
	
	ability1 = ability1_scene.instantiate()
	ability2 = ability2_scene.instantiate()
	add_child(ability1, true)
	add_child(ability2, true)

func _process(delta):
	_update_healthbar(healthbar)
	healthbar.show()
	if not multiplayer.is_server():
		return
	if not attack_timer.is_stopped():
		return
	if attack_timeout > 0:
		attack_timeout -= delta;
	if is_attacking:
		if target_entity == null or target_entity.health <= 0:
			target_entity = null
			is_attacking = false
			return
		if target_in_attack_range(range_collider_attack):
			init_auto_attack()
		else:
			if not target_entity == null:
				update_target_location(nav_agent, target_entity.global_transform.origin)
			else:
				target_entity = null
				is_attacking = false
			move(nav_agent)
	elif not target_entity == null:
		update_target_location(nav_agent, target_entity.global_transform.origin)
		move(nav_agent)
	else:
		move(nav_agent)


func trigger_ability(n:int):
	if n == 1:
		ability1.trigger()
	if n == 2:
		ability2.trigger()
	#if n == 3:
		#ability3.trigger()
	#if n == 4:
		#ability4.trigger()
	pass
	
