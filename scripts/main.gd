extends Node

func _ready():
	Util.load_settings()
	Util.load_args()
	Util.show_debug_overlay()
	if Util.dedicated_server || Util.dedicated_client:
		get_tree().call_deferred("change_scene_to_file", "res://scenes/game/ingame.tscn")
	else:
		get_tree().call_deferred("change_scene_to_file", "res://scenes/ui/menu.tscn")
