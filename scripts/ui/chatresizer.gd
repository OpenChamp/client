extends Control

var drag_started = false
var initial_mouse_pos = Vector2()
var initial_panel_pos = Vector2()
var initial_panel_size = Vector2()

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start dragging
				drag_started = true
				initial_mouse_pos = get_global_mouse_position()
				initial_panel_pos = get_parent().position
				initial_panel_size = get_parent().size
			else:
				# Stop dragging
				drag_started = false
	
	elif event is InputEventMouseMotion:
		if drag_started:
			var parent_panel = get_parent()
			var current_mouse_pos = get_global_mouse_position()
			var delta = current_mouse_pos - initial_mouse_pos
			
			# Calculate new size based on delta
			var min_size = Vector2(300, 150)
			var new_size = Vector2(
				max(min_size.x, initial_panel_size.x + delta.x),
				max(min_size.y, initial_panel_size.y - delta.y)
			)
			
			# Apply new size to panel
			parent_panel.custom_minimum_size = new_size
			parent_panel.size = new_size
			
			# Move pannel up by the new height
			parent_panel.global_position.y = current_mouse_pos.y

func _ready():
	# Show a resize cursor when hovering over this control
	mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
