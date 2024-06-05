extends Node3D


func _ready():
	print("Level Loaded")


## DEBUG: Spawn minions using a button click #######################################################
func _input(event):
	if multiplayer.is_server():
		# Minion wave for team 2 on "["
		if event is InputEventKey and event.pressed and event.keycode == KEY_BRACKETLEFT:
			$BlueMinionSpawnerMid.spawn_wave()
		# Single minion for team 1 on "]"
		if event is InputEventKey and event.pressed and event.keycode == KEY_BRACKETRIGHT:
			$RedMinionSpawnerMid.spawn_minion()
####################################################################################################