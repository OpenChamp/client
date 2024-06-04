extends Unit

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var range_collider_activate: Area3D = $ActivationArea
@onready var range_collider_attack: Area3D = $AttackArea
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var healthbar_node: ProgressBar = $Healthbar

@export var ability1_scene: PackedScene
@export var ability2_scene: PackedScene
@export var ability3_scene: PackedScene
@export var ability4_scene: PackedScene

var abilities: Array[Node] = []

@export var pid: int
@export var nametag: String

@export var max_mana: float = 300.0
@export var mana: float = 300.0

@onready var maproot

func _ready():
	attack_range = 20.0
	speed = 1000.0
	maproot = get_parent()
	while !maproot.is_in_group('Map'):
		maproot = maproot.get_parent()
	setup(
		nav_agent,
		range_collider_activate,
		range_collider_attack,
		mesh_instance,
		attack_timer,
		healthbar_node
	)
	
	abilities.append(ability1_scene.instantiate())
	abilities.append(ability2_scene.instantiate())
	abilities.append(ability3_scene.instantiate())
	abilities.append(ability4_scene.instantiate())
	
	for _ability in abilities:
		add_child(_ability, true)

	can_respawn = true

func _process(delta):
	if not multiplayer.is_server(): return
	_update_healthbar(healthbar)
	# if attack_timeout > 0:
	# 	attack_timeout -= delta;

	# if not attack_timer.is_stopped():
	# 	return
	
	# if is_attacking:
	# 	if target_entity == null or target_entity.health <= 0:
	# 		target_entity = null
	# 		is_attacking = false
	# 		return
	# 	if target_in_attack_range(range_collider_attack):
	# 		init_auto_attack()
	# 	else:
	# 		if not target_entity == null:
	# 			update_target_location(nav_agent, target_entity.global_transform.origin)
	# 		else:
	# 			target_entity = null
	# 			is_attacking = false
	# 		move(nav_agent, delta)
	# elif not target_entity == null:
	# 	update_target_location(nav_agent, target_entity.global_transform.origin)
	# 	move(nav_agent, delta)
	# else:
	# 	move(nav_agent, delta)

func trigger_ability(n: int):
	abilities[n - 1].trigger(n)

func set_attack(target_name):
	var target_entity = maproot.find_child(str(target_name), true, false)
	if target_entity == null:
		return;
	if target_entity.team == team:
		print_debug("Same Team");
		return ;
	get_node("StateMachine").change_state("Attack", target_entity)

func die():
	super()
	# Respawn Logic
	var server_listener = $"../../ServerListener"
	server_listener.rpc_id(multiplayer.get_unique_id(), "respawn", self)
