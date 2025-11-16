@tool
extends EditorPlugin

const QuillSettingsManager = preload("uid://cuc2uwqgbhjmi")
const TabManager = preload("uid://rcrd4dy7nevv")
const OutlineManager = preload("uid://p1uc0k4gy6jr")
const IconManager = preload("uid://dqgi3yvglh3w4")

var settings_manager: QuillSettingsManager
var tab_manager: TabManager
var outline_manager: OutlineManager
var icon_manager: IconManager

func _enter_tree() -> void:
	icon_manager = IconManager.new()
	icon_manager.init_icons()
	
	settings_manager = QuillSettingsManager.new()
	settings_manager.init_settings()
	
	tab_manager = TabManager.new()
	tab_manager.init(settings_manager, icon_manager)
	tab_manager.update_tabs()
	
	
	outline_manager = OutlineManager.new()
	outline_manager.init(settings_manager, icon_manager)
	
	tab_manager.script_tab_changed.connect(outline_manager._on_active_script_changed)
	
	var file_system: EditorFileSystem = EditorInterface.get_resource_filesystem()
	file_system.filesystem_changed.connect(schedule_update)
	
	EditorInterface.get_editor_settings().settings_changed.connect(_on_settings_changed)

func _exit_tree() -> void:
	var file_system: EditorFileSystem = EditorInterface.get_resource_filesystem()
	file_system.filesystem_changed.disconnect(schedule_update)
	EditorInterface.get_editor_settings().settings_changed.disconnect(_on_settings_changed)
	
	if outline_manager:
		outline_manager.cleanup()
	if tab_manager:
		tab_manager.cleanup()

func _process(delta: float) -> void:
	update_editor()
	set_process(false)

func schedule_update():
	set_process(true)

func update_editor():
	tab_manager.update_editor()
	outline_manager.update_editor()

func _on_settings_changed():
	var changed_settings: PackedStringArray = EditorInterface.get_editor_settings().get_changed_settings()
	
	settings_manager.sync_settings(changed_settings)
	icon_manager.handle_settings_change(changed_settings)
	tab_manager.handle_settings_change(changed_settings, settings_manager)

func get_current_script() -> Script:
	var script_editor: ScriptEditor = EditorInterface.get_script_editor()
	return script_editor.get_current_script()

func goto_line(index: int):
	var script_editor: ScriptEditor = EditorInterface.get_script_editor()
	script_editor.goto_line(index)
	
	var code_edit: CodeEdit = script_editor.get_current_editor().get_base_editor()
	code_edit.set_caret_line(index)
	code_edit.set_v_scroll(index)
	code_edit.set_caret_column(code_edit.get_line(index).length())
	code_edit.set_h_scroll(0)
	code_edit.grab_focus()

static func find_or_null(arr: Array[Node], index: int = 0) -> Node:
	if arr.is_empty():
		push_error("""
		Node that is needed for Quill-IDE not found.
		Plugin will not work correctly.
		This might be due to some other plugins or changes in the Engine.
		Please open an issue on Quill's Github, so we can figure out a fix.
		""")
		return null
	return arr[index]

func load_rel(path: String) -> Variant:
	var script_path: String = get_script().get_path().get_base_dir()
	return load(script_path.path_join(path))

func get_center_editor_rect() -> Rect2i:
	var script_editor: ScriptEditor = EditorInterface.get_script_editor()
	var size: Vector2i = Vector2i(400, 500) * EditorInterface.get_editor_scale()
	var x: int
	var y: int
	
	if script_editor.get_parent().get_parent() is Window:
		var window: Window = script_editor.get_parent().get_parent()
		var window_rect: Rect2 = window.get_visible_rect()
		x = window_rect.size.x / 2 - size.x / 2
		y = window_rect.size.y / 2 - size.y / 2
	else:
		x = script_editor.global_position.x + script_editor.size.x / 2 - size.x / 2
		y = script_editor.global_position.y + script_editor.size.y / 2 - size.y / 2
	
	return Rect2i(Vector2i(x, y), size)
