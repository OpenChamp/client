extends Node

func _ready():
	Util.load_settings()
	Util.load_args()
	
	Util.show_debug_overlay()
	
	if Util.dedicated_server || Util.server_id:
		get_tree().change_scene_to_file("res://scenes/game.tscn")
		pass
	else:
		get_tree().change_scene_to_file("res://scenes/mainMenu.tscn")
