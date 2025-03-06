extends Node

var Map = null

func stage_map(mapname: String) -> void:
	match mapname:
		"rift":
			Map = preload("res://level/rift.tscn")
		_:
			Map = preload("res://level/rift.tscn")


func change_map(path: String = "") -> void:
	if path.begins_with("res://"):
		stage_map(path)
	add_child(Map)
		
