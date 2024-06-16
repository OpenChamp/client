extends Unit
class_name Champion

@export var server_position:Vector3

@export var nametag : String

# Called when the node enters the scene tree for the first time.
func _ready():
	# Modify default unit permissions
	can_respawn = true;
	pass # Replace with function body.


func _process(delta):
	super(delta);

func _physics_process(delta: float) -> void:
	super(delta);

@rpc("authority", "call_local")
func change_state(new, args):
	$StateMachine.change_state(new, args);
