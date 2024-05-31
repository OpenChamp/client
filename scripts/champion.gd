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

var abilities : Array[Node] = []

@export var pid: int
@export var _max_mana: float = 300.0
@export var _mana: float = 300.0


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
	
	
	abilities.append(ability1_scene.instantiate())
	abilities.append(ability2_scene.instantiate())
	abilities.append(ability3_scene.instantiate())
	abilities.append(ability4_scene.instantiate())
	
	for _ability in abilities:
		add_child(_ability, true)


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
			move(nav_agent, delta)
	elif not target_entity == null:
		update_target_location(nav_agent, target_entity.global_transform.origin)
		move(nav_agent, delta)
	else:
		move(nav_agent, delta)


func trigger_ability(n:int):
	abilities[n-1].trigger(n)


@rpc("authority", "call_local")
func set_mana(cost: int) -> void:
	_mana -= cost
	print("ABILITY USED, remaining MANA: " + str(_mana))


func get_mana() -> int:
	return _mana


func get_max_mana() -> int:
	return _max_mana
