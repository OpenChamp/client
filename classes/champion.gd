extends Unit
class_name Champion

@export var server_position:Vector3

@export var nametag : String

@export var max_mana: float = 100.0
@onready var current_mana: float = max_mana
@export var mana_regen: float = 5
# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	# Modify default unit permissions
	can_respawn = true;


func _process(delta):
	super(delta);

func _physics_process(delta: float) -> void:
	super(delta);

@rpc("authority", "call_local")
func change_state(new, args):
	$StateMachine.change_state(new, args);
