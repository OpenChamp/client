extends Node3D

@export var time_elapsed : float
@export var caster_minion : PackedScene

func _ready():
	add_child(load("res://scenes/maps/rift.tscn").instantiate())
	pass

func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		_server_tick(delta)
		$Timer.start()

	else:
		_client_tick(delta)

func _server_tick(delta: float) -> void:
	time_elapsed += delta


func _client_tick(delta: float) -> void:
	$UI/Time.text = "[center] [color=red]" + sec_to_time(int(time_elapsed)) + "[/color] [/center]"

# Client Functions

func sec_to_time(sec: int) -> String:
	print(sec)
	var minutes = int(sec / 60)
	var seconds = sec % 60
	return str(minutes) + ":" + str(seconds)

# Server Functions
func start_game():
	pass

func spawn_minion():
	add_child(caster_minion.instantiate())
	print("Minion Added")
