@tool
class_name CsgToolkit extends EditorPlugin
@onready var config: CsgTkConfig:
	get:
		return get_tree().root.get_node_or_null(AUTOLOAD_NAME) as CsgTkConfig

var sidebar: CSGSideToolkitBar
var topbar: CSGTopToolkitBar

const AUTOLOAD_NAME = "CsgToolkitAutoload"
static var csg_plugin_path

func _enter_tree():
	# Config
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/csg_toolkit/scripts/csg_toolkit_config.gd")
	csg_plugin_path = get_path()
	
	# Nodes
	add_custom_type("CSGRepeater3D", "CSGCombiner3D", preload("res://addons/csg_toolkit/scripts/csg_repeater_3d.gd"), null)
	add_custom_type("CSGSpreader3D", "CSGCombiner3D", preload("res://addons/csg_toolkit/scripts/csg_spreader_3d.gd"), null)
	
	# Sidebar
	var sidebarScene = preload("res://addons/csg_toolkit/scenes/csg_side_toolkit_bar.tscn")
	sidebar = sidebarScene.instantiate()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, sidebar)
	
	# Topbar
	var topbarScene = preload("res://addons/csg_toolkit/scenes/csg_top_toolkit_bar.tscn")
	topbar = topbarScene.instantiate()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, topbar)

func _exit_tree():
	remove_custom_type("CSGRepeater3D")
	remove_custom_type("CSGSpreader3D")
	
	remove_autoload_singleton(AUTOLOAD_NAME)
	
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, sidebar)
	sidebar.free()
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, topbar)
	topbar.free()
