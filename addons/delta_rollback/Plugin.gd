@tool
extends EditorPlugin

const LogInspector = preload("res://addons/delta_rollback/log_inspector/LogInspector.tscn")

var log_inspector

func _enter_tree() -> void:
	var project_settings_node = load("res://addons/delta_rollback/ProjectSettings.gd").new()
	project_settings_node.add_project_settings()
	project_settings_node.free()
	
	add_autoload_singleton("SyncManager", "res://addons/delta_rollback/SyncManager.gd")
	
	log_inspector = LogInspector.instantiate()
	get_editor_interface().get_base_control().add_child(log_inspector)
	log_inspector.set_editor_interface(get_editor_interface())
	add_tool_menu_item("Log inspector...", self.open_log_inspector)
	
	if not ProjectSettings.has_setting("input/sync_debug"):
		var sync_debug = InputEventKey.new()
		sync_debug.keycode = KEY_F11
		
		ProjectSettings.set_setting("input/sync_debug", {
			deadzone = 0.5,
			events = [
				sync_debug,
			],
		})
		
		# Cause the ProjectSettingsEditor to reload the input map from the
		# ProjectSettings.
		get_tree().root.get_child(0).propagate_notification(EditorSettings.NOTIFICATION_EDITOR_SETTINGS_CHANGED)

func open_log_inspector() -> void:
	log_inspector.popup_centered_ratio()

func _exit_tree() -> void:
	remove_tool_menu_item("Log inspector...")
	if log_inspector:
		log_inspector.free()
		log_inspector = null
