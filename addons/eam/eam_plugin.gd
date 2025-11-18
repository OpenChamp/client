@tool
class_name EAMPlugin
extends EditorPlugin

var dock_scene = preload("res://addons/eam/eam_dock.tscn")
var dock


func _enter_tree():
	# Engine Setup
	if not EditorInterface.get_editor_settings().has_setting("ExternalAssetManager/CustomLocations"):
		EditorInterface.get_editor_settings().set_setting("ExternalAssetManager/CustomLocations", [{
			"prefix": "data",
			"basepath": "user://",
			"location": "external/data"
		}])
	
	# Initialization
	dock = dock_scene.instantiate()
	add_control_to_bottom_panel(dock, "External Asset Manager")


func _exit_tree():
	# Clean-up
	remove_control_from_bottom_panel(dock)
	dock.queue_free()
