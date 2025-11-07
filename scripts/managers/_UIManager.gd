class_name UserInterfaceManager
extends Node

# Signals for UI events
signal menu_changed(menu_name: String)
signal ui_transition_started(from_menu: String, to_menu: String)
signal ui_transition_completed(menu_name: String)

# Menu scene paths - updated to match actual project structure
const Menu = {
	"Connect": "res://scenes/ui/menu/connecting_menu.tscn",
	"MainMenu": "res://scenes/ui/menu/main_menu.tscn", 
	"Settings": "res://scenes/ui/menu/settings_menu.tscn",
	"Registration": "res://scenes/ui/menu/registration_menu.tscn",
	"Credits": "res://scenes/ui/menu/credits_menu.tscn",
	"InGame": "res://scenes/ui/ingame.tscn",
	"Loading": "res://scenes/ui/loading.tscn"
}

# UI state management
var ui_root: Node
var current_menu: Node
var current_menu_name: String = ""
var menu_stack: Array[String] = []
var is_transitioning: bool = false

# Transition settings
@export var transition_duration: float = 0.3
@export var fade_color: Color = Color.BLACK

# Preloaded scenes for better performance
var preloaded_menus: Dictionary = {}

func _ready() -> void:
	print("UI Manager ready")
	# Preload commonly used menus
	preload_menu("MainMenu")
	preload_menu("Settings")
	preload_menu("InGame")

func preload_menu(menu_name: String) -> void:
	"""Preload a menu scene for faster access"""
	var menu_path = Menu.get(menu_name)
	if menu_path and not preloaded_menus.has(menu_name):
		if ResourceLoader.exists(menu_path):
			preloaded_menus[menu_name] = load(menu_path)
		else:
			push_warning("Menu scene not found: " + menu_path)

func change_menu(menu_name: String, add_to_stack: bool = false) -> bool:
	"""Change to a different menu with optional transition"""
	if is_transitioning:
		push_warning("Cannot change menu while transitioning")
		return false
		
	var menu_path = Menu.get(menu_name)
	if not menu_path:
		push_error("Unknown menu: " + menu_name)
		return false
	
	if not ResourceLoader.exists(menu_path):
		push_error("Menu scene not found: " + menu_path)
		return false
	
	# Add current menu to stack if requested
	if add_to_stack and current_menu_name != "":
		menu_stack.push_back(current_menu_name)
	
	# Start transition
	is_transitioning = true
	ui_transition_started.emit(current_menu_name, menu_name)
	
	# Load new menu scene
	var new_menu_scene: PackedScene
	if preloaded_menus.has(menu_name):
		new_menu_scene = preloaded_menus[menu_name]
	else:
		new_menu_scene = load(menu_path)
	
	var new_menu = new_menu_scene.instantiate()
	
	# Perform transition
	await _perform_menu_transition(new_menu, menu_name)
	
	return true

func _perform_menu_transition(new_menu: Node, menu_name: String) -> void:
	"""Handle the actual menu transition with fade effect"""
	if not ui_root:
		push_error("UI root not set")
		return
	
	# Create fade overlay
	var fade_overlay = ColorRect.new()
	fade_overlay.color = fade_color
	fade_overlay.color.a = 0.0
	fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_overlay.z_index = 1000
	ui_root.add_child(fade_overlay)
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, transition_duration * 0.5)
	await tween.finished
	
	# Remove old menu
	if current_menu and is_instance_valid(current_menu):
		current_menu.queue_free()
	
	# Add new menu
	ui_root.add_child(new_menu)
	current_menu = new_menu
	current_menu_name = menu_name
	
	# Fade in
	tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, transition_duration * 0.5)
	await tween.finished
	
	# Clean up
	fade_overlay.queue_free()
	is_transitioning = false
	
	# Emit signals
	menu_changed.emit(menu_name)
	ui_transition_completed.emit(menu_name)

func go_back() -> bool:
	"""Return to the previous menu in the stack"""
	if menu_stack.is_empty():
		push_warning("No previous menu in stack")
		return false
	
	var previous_menu = menu_stack.pop_back()
	return await change_menu(previous_menu)

func clear_menu_stack() -> void:
	"""Clear the menu navigation stack"""
	menu_stack.clear()

func show_overlay_menu(menu_name: String) -> Node:
	"""Show a menu as an overlay without replacing the current menu"""
	var menu_path = Menu.get(menu_name)
	if not menu_path:
		push_error("Unknown overlay menu: " + menu_name)
		return null
	
	if not ResourceLoader.exists(menu_path):
		push_error("Overlay menu scene not found: " + menu_path)
		return null
	
	var overlay_scene: PackedScene
	if preloaded_menus.has(menu_name):
		overlay_scene = preloaded_menus[menu_name]
	else:
		overlay_scene = load(menu_path)
	
	var overlay_menu = overlay_scene.instantiate()
	
	if ui_root:
		ui_root.add_child(overlay_menu)
		# Ensure overlay appears on top
		ui_root.move_child(overlay_menu, -1)
	
	return overlay_menu

func hide_overlay_menu(overlay_menu: Node) -> void:
	"""Remove an overlay menu"""
	if overlay_menu and is_instance_valid(overlay_menu):
		overlay_menu.queue_free()

func set_ui_root(root_node: Node) -> void:
	"""Set the root node for UI elements"""
	ui_root = root_node
	print("UI root set to: ", root_node.name if root_node else StringName("null"))

func get_ui_root() -> Node:
	"""Get the current UI root node"""
	return ui_root

func get_current_menu() -> Node:
	"""Get the currently active menu"""
	return current_menu

func get_current_menu_name() -> String:
	"""Get the name of the currently active menu"""
	return current_menu_name

func is_menu_loaded(menu_name: String) -> bool:
	"""Check if a menu is currently loaded"""
	return current_menu_name == menu_name

func preload_all_menus() -> void:
	"""Preload all menu scenes for better performance"""
	for menu_name in Menu.keys():
		preload_menu(menu_name)

func unload_preloaded_menus() -> void:
	"""Clear all preloaded menus to free memory"""
	preloaded_menus.clear()

func get_menu_stack_size() -> int:
	"""Get the current size of the menu stack"""
	return menu_stack.size()

func _exit_tree() -> void:
	"""Clean up when the manager is removed"""
	unload_preloaded_menus()
	if current_menu and is_instance_valid(current_menu):
		current_menu.queue_free()
