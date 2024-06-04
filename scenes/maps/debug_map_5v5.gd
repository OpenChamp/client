extends Node3D


func _ready():
	print("Level Loaded")


## DEBUG: Spawn minions using a button click #######################################################
func _input(event):
	if multiplayer.is_server():
		# Spawn minion waves for team 1 on "["
		if event is InputEventKey and event.pressed and event.keycode == KEY_BRACKETLEFT:
			$BlueMinionSpawnerTop.spawn_wave()
			$BlueMinionSpawnerMid.spawn_wave()
			$BlueMinionSpawnerBot.spawn_wave()
		# Spawn minion waves for team 2 on "]"
		if event is InputEventKey and event.pressed and event.keycode == KEY_BRACKETRIGHT:
			$RedMinionSpawnerTop.spawn_wave()
			$RedMinionSpawnerMid.spawn_wave()
			$RedMinionSpawnerBot.spawn_wave()
####################################################################################################
