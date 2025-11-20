class_name UserInterfaceManager
extends Node

# Signals for UI events
signal interface_changed(interface_name: String)
signal ui_transition_started(from_interface: String, to_interface: String)
signal ui_transition_completed(interface_name: String)

# Interface scene paths - updated to match actual project structure
const Interface = {
	"Connect": "res://scenes/ui/menu/connecting_menu.tscn",
	"MainMenu": "res://scenes/ui/menu/main_menu_new.tscn", 
	"Settings": "res://scenes/ui/menu/settings_new.tscn",
	"Registration": "res://scenes/ui/menu/registration_menu.tscn",
	"Credits": "res://scenes/ui/menu/credits_menu.tscn",
	"Ingame": "res://scenes/ui/ingame.tscn",
	"Loading": "res://scenes/ui/loading.tscn"
}

# UI state management
var ui_root: Node
var current_interface: Node
var current_interface_name: String = ""
var interface_stack: Array[String] = []
var interface_stack_max : int = 5
var is_transitioning: bool = false

# Transition settings
@export var transition_duration: float = 0.3
@export var fade_color: Color = Color.BLACK

# Preloaded scenes for better performance
var preloaded_interfaces: Dictionary = {}

func _ready() -> void:
	print("UI Manager ready")
	# Preload commonly used interfaces
	preload_interface("Maininterface")
	preload_interface("Settings")
	preload_interface("InGame")

func preload_interface(interface_name: String) -> void:
	"""Preload a interface scene for faster access"""
	var interface_path = Interface.get(interface_name)
	if interface_path and not preloaded_interfaces.has(interface_name):
		if ResourceLoader.exists(interface_path):
			preloaded_interfaces[interface_name] = load(interface_path)
		else:
			push_warning("interface scene not found: " + interface_path)

func change_interface(interface_name: String) -> bool:
	"""Change to a different interface with optional transition"""
	print("Changing Interface To ", interface_name)
	if is_transitioning:
		push_warning("Interruping ongoing transition: " + interface_name)

	var interface_path = Interface.get(interface_name)
	if not interface_path:
		push_error("Unknown interface: " + interface_name)
		return false
	
	if not ResourceLoader.exists(interface_path):
		push_error("interface scene not found: " + interface_path)
		return false
	
	# Add current interface to stack
	interface_stack.push_back(current_interface_name)
	if interface_stack.size() > interface_stack_max:
		interface_stack.pop_front()
	
	# Start transition
	is_transitioning = true
	ui_transition_started.emit(current_interface_name, interface_name)
	
	# Load new interface scene
	var new_interface_scene: PackedScene
	if preloaded_interfaces.has(interface_name):
		new_interface_scene = preloaded_interfaces[interface_name]
	else:
		new_interface_scene = load(interface_path)
	
	var new_interface = new_interface_scene.instantiate()
	
	# Perform transition
	await _perform_interface_transition(new_interface, interface_name)
	
	return true

func _perform_interface_transition(new_interface: Node, interface_name: String) -> void:
	"""Handle the actual interface transition with fade effect"""
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
	
	# Remove old interface
	if current_interface and is_instance_valid(current_interface):
		current_interface.queue_free()
	
	# Add new interface
	ui_root.add_child(new_interface)
	current_interface = new_interface
	current_interface_name = interface_name
	
	# Fade in
	tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, transition_duration * 0.5)
	await tween.finished
	
	# Clean up
	fade_overlay.queue_free()
	is_transitioning = false
	
	# Emit signals
	interface_changed.emit(interface_name)
	ui_transition_completed.emit(interface_name)

func go_back() -> bool:
	"""Return to the previous interface in the stack"""
	if interface_stack.is_empty():
		push_warning("No previous interface in stack")
		return false
	
	var previous_interface = interface_stack.pop_back()
	return await change_interface(previous_interface)

func clear_interface_stack() -> void:
	"""Clear the interface navigation stack"""
	interface_stack.clear()

func show_overlay_interface(interface_name: String) -> Node:
	"""Show a interface as an overlay without replacing the current interface"""
	var interface_path = Interface.get(interface_name)
	if not interface_path:
		push_error("Unknown overlay interface: " + interface_name)
		return null
	
	if not ResourceLoader.exists(interface_path):
		push_error("Overlay interface scene not found: " + interface_path)
		return null
	
	var overlay_scene: PackedScene
	if preloaded_interfaces.has(interface_name):
		overlay_scene = preloaded_interfaces[interface_name]
	else:
		overlay_scene = load(interface_path)
	
	var overlay_interface = overlay_scene.instantiate()
	
	if ui_root:
		ui_root.add_child(overlay_interface)
		# Ensure overlay appears on top
		ui_root.move_child(overlay_interface, -1)
	
	return overlay_interface

func hide_overlay_interface(overlay_interface: Node) -> void:
	"""Remove an overlay interface"""
	if overlay_interface and is_instance_valid(overlay_interface):
		overlay_interface.queue_free()

func set_ui_root(root_node: Node) -> void:
	"""Set the root node for UI elements"""
	ui_root = root_node
	print("UI root set to: ", root_node.name if root_node else StringName("null"))

func get_ui_root() -> Node:
	"""Get the current UI root node"""
	return ui_root

func get_current_interface() -> Node:
	"""Get the currently active interface"""
	return current_interface

func get_current_interface_name() -> String:
	"""Get the name of the currently active interface"""
	return current_interface_name

func is_interface_loaded(interface_name: String) -> bool:
	"""Check if a interface is currently loaded"""
	return current_interface_name == interface_name

func preload_all_interfaces() -> void:
	"""Preload all interface scenes for better performance"""
	for interface_name in Interface.keys():
		preload_interface(interface_name)

func unload_preloaded_interfaces() -> void:
	"""Clear all preloaded interfaces to free memory"""
	preloaded_interfaces.clear()

func get_interface_stack_size() -> int:
	"""Get the current size of the interface stack"""
	return interface_stack.size()

func _exit_tree() -> void:
	"""Clean up when the manager is removed"""
	unload_preloaded_interfaces()
	if current_interface and is_instance_valid(current_interface):
		current_interface.queue_free()
