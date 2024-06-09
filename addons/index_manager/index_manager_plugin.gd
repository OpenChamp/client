@tool
extends EditorPlugin

var dock


func _enter_tree():
	# Initialization of the plugin goes here.
	# Load the dock scene and instantiate it.
	dock = load("res://addons/index_manager/index_manager_dock.tscn").instantiate()


	# Add the loaded scene to the docks.
	add_control_to_dock(DOCK_SLOT_LEFT_BR, dock)


func _exit_tree():
	# Clean-up of the plugin goes here.
	# Remove the dock.
	remove_control_from_docks(dock)
	# Erase the control from the memory.
	dock.free()
