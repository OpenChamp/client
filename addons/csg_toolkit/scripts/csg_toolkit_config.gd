@tool
extends Node
class_name CsgTkConfig
# Constants
const CSG_TOOLKIT = "CSG_TOOLKIT"
const DEFAULT_BEHAVIOR = "DEFAULT_BEHAVIOR" # sibling
const ACTION_KEY = "ACTION_KEY" # shift
const AUTO_HIDE = "AUTO_HIDE" # true

# Configurable
var default_behavior: CSGBehavior = CSGBehavior.SIBLING
var action_key: Key = KEY_SHIFT
var auto_hide: bool = true

signal config_saved()

func _enter_tree():
	load_config()
	
func save_config():
	var config = ConfigFile.new()
	config.load("res://addons/csg_toolkit/csg_toolkit_config.cfg")
	config.set_value(CSG_TOOLKIT, DEFAULT_BEHAVIOR, default_behavior)
	config.set_value(CSG_TOOLKIT, ACTION_KEY, action_key)
	config.set_value(CSG_TOOLKIT, AUTO_HIDE, auto_hide)
	config.save("res://addons/csg_toolkit/csg_toolkit_config.cfg")
	print("CsgToolkit: Saved Config")
	config_saved.emit()

func load_config():
	var config = ConfigFile.new()
	if config.load("res://addons/csg_toolkit/csg_toolkit_config.cfg") == OK:
		default_behavior = config.get_value(CSG_TOOLKIT, DEFAULT_BEHAVIOR, default_behavior)
		action_key = config.get_value(CSG_TOOLKIT, ACTION_KEY, action_key)
		auto_hide = config.get_value(CSG_TOOLKIT, AUTO_HIDE, auto_hide)
	else:
		save_config()
	

enum CSGBehavior { SIBLING, CHILD }
