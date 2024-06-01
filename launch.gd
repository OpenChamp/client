extends Node2D

const Startup = preload("res://startup.tscn")

# This scene only has one purpose: to load the startup scene and then remove itself from the scene tree.
# This a workaround to guarantee that all the autoload scripts have been loaded before the startup scene is loaded.
# This way all the translations have finished loading and the game can start without any issues.
func _ready():
	call_deferred("_start_game")


func _start_game():
	get_tree().change_scene_to_packed(Startup)
