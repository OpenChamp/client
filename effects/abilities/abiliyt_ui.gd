extends ability

@export var range:float = 15.0
@export var isActivated = false
@export var ability_name:String
@export var isAoe:bool
@export var aoe_radius = 5
@export var ability:PackedScene = preload("res://effects/abilities/arrow_storm.tscn")
@export var mana_cost:float = 10.0
@export var cooldown:float = 2

@onready var gui = $gui;
@onready var aoe = $aoe;
@onready var direction:Vector3;

func _ready():
	gui.hide();
	if aoe:
		aoe.hide();


func _process(delta):
	if !isActivated:
		return
	# Get Mouse position in 3d space
	var mouse_pos:Vector3 = get_mouse_3d()
	direction = mouse_pos - global_position
	var distance = direction.length();
	var middle = (mouse_pos + global_position) / 2
	
	if isAoe:
	# Check if distance > length
		if distance > range:
			var new_position = global_transform.origin + direction.normalized() * range
			aoe.global_transform.origin = new_position
		else:
			# Move Directly to mousepos
			aoe.global_transform.origin = mouse_pos
	else:
		gui.global_position = middle
		gui.mesh.size.y = distance
		gui.look_at(mouse_pos)

func trigger(n:int):
	if !isActivated:
		init()
	else:
		exec(n)

func init():
	isActivated = true;
	gui.show()
	if isAoe:
		# Set GUI to range
		gui.mesh.inner_radius = range
		gui.mesh.outer_radius = range + 0.2
		aoe.show();
	pass;


func exec(id: int):
	isActivated = false;
	gui.hide()
	aoe.hide()
	var server_listener = self;
	while !server_listener.is_in_group("Map"):
		server_listener = server_listener.get_parent()
	server_listener = server_listener.get_node("ServerListener");
	var pos:Vector3;
	var type:int;
	if isAoe:
		pos = aoe.global_position
		type = 0;
	else:
		pos = direction
		type = 1;
	server_listener.rpc_id(get_multiplayer_authority(), "spawn_ability", ability_name, type, pos, mana_cost, cooldown, id)
