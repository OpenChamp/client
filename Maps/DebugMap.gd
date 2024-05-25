extends Node3D

## DEBUG: Make minions follow camera ###############################################################
@onready var player = $Player
func _physics_process(delta):
	get_tree().call_group("minions", "update_target_location", player.global_transform.origin)
####################################################################################################

# Called when the node enters the scene tree for the first time.
func _ready():
	$Player.min_x = -30
	$Player.max_x = 30
	$Player.min_z = -10
	$Player.max_z = 10
	print("Level Loaded")

func spawn_minion_wave(team:int, wave_size:int = 6, delay:float = .5):
	var wave = $MinionSpawner.get_wave(team, wave_size)
	for minion in wave:
		spawn_minion(team, minion)
		await get_tree().create_timer(delay).timeout

func spawn_minion(team:int = 0, minion = null):
	if minion != null:
		$Minions.add_child(minion)
	else:
		$Minions.add_child($MinionSpawner.get_minion(team))

## DEBUG: Spawn minions using a button click #######################################################
func _input(event):
	if multiplayer.is_server():
		# Minion wave for team 1 on "["
		if event is InputEventKey and event.pressed and event.keycode == KEY_BRACKETLEFT:
			spawn_minion_wave(1)
		# Single minion for team 2 on "]"
		if event is InputEventKey and event.pressed and event.keycode == KEY_BRACKETRIGHT:
			spawn_minion(2)
####################################################################################################
