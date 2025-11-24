class_name SettingsManager
extends Control

# Current hotkey being edited
var current_editing_hotkey_button: Button = null
var current_editing_action: String = ""
var hotkey_action_metatag = "keybind"

func _ready() -> void:
	var overrides = ConfigManager.get_hotkey_overrides()
	var hotkey_buttons = _collect_all_hotkey_buttons()
	for button in hotkey_buttons:
		button.pressed.connect(_on_hotkey_button_pressed.bind(button))
		var key = button.get_meta(hotkey_action_metatag)
		if overrides.has(key):
			button.text = OS.get_keycode_string(ConfigManager.get_value("Hotkeys", key).keycode)
	# Start with input processing disabled - only enable when editing a hotkey
	set_process_input(false)

## Handle hotkey button pressed - start listening for input
func _on_hotkey_button_pressed(button:Button) -> void:
	if current_editing_hotkey_button:
		# Restore previous button text if editing was cancelled
		current_editing_hotkey_button.modulate.a = 1.0
	
	current_editing_hotkey_button = button
	current_editing_action = button.get_meta(hotkey_action_metatag)
	if not current_editing_action:
		push_error("No Keybind Set on button ref");
		return;
	
	# Highlight the button being edited
	current_editing_hotkey_button.modulate.a = 0.6
	current_editing_hotkey_button.text = "..."
	
	# Start input listening
	set_process_input(true)

## Process input to capture hotkey
func _input(event: InputEvent) -> void:
	# Only intercept input if we're currently editing a hotkey
	if not current_editing_hotkey_button:
		return
	
	# Only intercept keyboard events
	if not event is InputEventKey:
		return
	
	if event.pressed:
		var key_name = OS.get_keycode_string(event.keycode)
		
		# Update the button display
		current_editing_hotkey_button.text = key_name
		current_editing_hotkey_button.modulate.a = 1.0
		
		ConfigManager.set_keybind(current_editing_hotkey_button.get_meta(hotkey_action_metatag), event)
		
		current_editing_hotkey_button = null
		current_editing_action = ""
		set_process_input(false)
		
		get_tree().root.set_input_as_handled()

func _collect_all_hotkey_buttons() -> Array:
	var buttons: Array = []
	var starting_node = self
	_collect_buttons_recursive(starting_node, buttons)
	return buttons

## Recursively collect buttons from node and children
func _collect_buttons_recursive(node: Node, buttons: Array) -> void:
	if node is Button and node.has_meta(hotkey_action_metatag):
		buttons.append(node)
	
	for child in node.get_children():
		_collect_buttons_recursive(child, buttons)
