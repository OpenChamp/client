@tool
class_name TabManager

const BUILT_IN_SCRIPT: StringName = &"::GDScript"

var scripts_tab_container: TabContainer
var scripts_tab_bar: TabBar
var script_filter_txt: LineEdit
var scripts_item_list: ItemList
var panel_container: VSplitContainer

var selected_tab: int = -1
var last_tab_hovered: int = -1
var sync_script_list: bool = false
var file_to_navigate: String = &""
var tab_state: TabStateCache
var old_script_editor_base: ScriptEditorBase

var settings_manager: QuillSettingsManager
var icon_manager: IconManager

signal script_tab_changed(script: Script)

func init(settings_mgr: QuillSettingsManager, icon_mgr: IconManager):
	settings_manager = settings_mgr
	icon_manager = icon_mgr
	
	var script_editor: ScriptEditor = EditorInterface.get_script_editor()
	
	scripts_item_list = find_or_null(script_editor.find_children("*", "ItemList", true, false))
	scripts_item_list.allow_reselect = true
	
	script_filter_txt = find_or_null(scripts_item_list.get_parent().find_children("*", "LineEdit", true, false))
	script_filter_txt.gui_input.connect(_on_script_filter_input)
	
	scripts_tab_container = find_or_null(script_editor.find_children("*", "TabContainer", true, false))
	scripts_tab_bar = scripts_tab_container.get_tab_bar()
	
	tab_state = TabStateCache.new()
	tab_state.save(scripts_tab_container, scripts_tab_bar)
	
	scripts_tab_bar.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	scripts_tab_container.tabs_visible = settings_manager.is_script_tabs_visible
	scripts_tab_container.drag_to_rearrange_enabled = true
	update_tabs_position()
	
	scripts_tab_bar.tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_ACTIVE_ONLY
	scripts_tab_bar.drag_to_rearrange_enabled = true
	scripts_tab_bar.select_with_rmb = true
	
	scripts_tab_bar.tab_close_pressed.connect(_on_tab_close)
	scripts_tab_bar.tab_rmb_clicked.connect(_on_tab_rmb)
	scripts_tab_bar.tab_hovered.connect(_on_tab_hovered)
	scripts_tab_bar.mouse_exited.connect(_on_tab_bar_mouse_exited)
	scripts_tab_bar.active_tab_rearranged.connect(_on_active_tab_rearranged)
	scripts_tab_bar.gui_input.connect(_on_tab_bar_gui_input)
	scripts_tab_bar.tab_changed.connect(_on_tab_changed)
	
	panel_container = scripts_item_list.get_parent().get_parent()
	
	update_script_list_visibility()
	_on_tab_changed(scripts_tab_bar.current_tab)
	
	if not script_editor.editor_script_changed.is_connected(_on_active_script_changed):
		script_editor.editor_script_changed.connect(_on_active_script_changed)

	if not script_editor.script_changed.is_connected(_on_script_modified):
		script_editor.script_changed.connect(_on_script_modified)

func cleanup():
	if old_script_editor_base != null:
		old_script_editor_base.edited_script_changed.disconnect(_on_script_changed)
	
	if scripts_tab_container != null:
		tab_state.restore(scripts_tab_container, scripts_tab_bar)
		
		scripts_tab_bar.mouse_exited.disconnect(_on_tab_bar_mouse_exited)
		scripts_tab_bar.gui_input.disconnect(_on_tab_bar_gui_input)
		scripts_tab_bar.tab_close_pressed.disconnect(_on_tab_close)
		scripts_tab_bar.tab_rmb_clicked.disconnect(_on_tab_rmb)
		scripts_tab_bar.tab_hovered.disconnect(_on_tab_hovered)
		scripts_tab_bar.active_tab_rearranged.disconnect(_on_active_tab_rearranged)
		scripts_tab_bar.tab_changed.disconnect(_on_tab_changed)
	
	if scripts_item_list != null:
		scripts_item_list.allow_reselect = false
		scripts_item_list.get_parent().visible = true
		
		if script_filter_txt != null:
			script_filter_txt.gui_input.disconnect(_on_script_filter_input)

func update_editor():
	update_script_text_filter()
	
	if sync_script_list:
		if file_to_navigate != &"":
			EditorInterface.get_file_system_dock().navigate_to_path(file_to_navigate)
			EditorInterface.get_script_editor().get_current_editor().get_base_editor().grab_focus()
			file_to_navigate = &""
		
		sync_tab_with_script_list()
		sync_script_list = false
	
	update_tabs()
	
	if scripts_tab_bar: _customize_tabbar(scripts_tab_bar)

func _on_active_script_changed(script: Script):
	update_tabs()

func _on_script_modified(script: Script):
	if script == EditorInterface.get_script_editor().get_current_script():
		update_tabs()

func _customize_tabbar(tab_bar: TabBar) -> void:
	var editor_settings = EditorInterface.get_editor_settings()
	
	var sb_normal := StyleBoxFlat.new()
	var base_color: Color = editor_settings.get_setting("interface/theme/base_color")
	var contrast_factor: float = 0.15

	sb_normal.bg_color = base_color.darkened(contrast_factor)
	sb_normal.corner_radius_top_left = 25
	sb_normal.corner_radius_top_right = 25
	sb_normal.corner_radius_bottom_right = 25
	sb_normal.corner_radius_bottom_left = 25
	
	# inside padding
	sb_normal.content_margin_left = 17
	sb_normal.content_margin_right = 17
	sb_normal.content_margin_top = 2
	sb_normal.content_margin_bottom = 8
	
	# OUTSIDE padding
	sb_normal.expand_margin_left = -2
	sb_normal.expand_margin_right = -2
	sb_normal.expand_margin_top = 3
	sb_normal.expand_margin_bottom = -3

	var sb_hover := sb_normal.duplicate()
	sb_hover.bg_color = Color(0.146, 0.167, 0.2)

	var sb_focus := sb_normal.duplicate()
	var bg_color = editor_settings.get_setting("text_editor/theme/highlighting/background_color")
	sb_focus.bg_color = bg_color
	
	sb_focus.corner_radius_top_left = 14
	sb_focus.corner_radius_top_right = 14
	sb_focus.expand_margin_bottom = 100
	sb_focus.content_margin_top = 3

	tab_bar.add_theme_stylebox_override("tab_unselected", sb_normal)
	tab_bar.add_theme_stylebox_override("tab_hovered", sb_hover)
	tab_bar.add_theme_stylebox_override("tab_focus", sb_focus)
	tab_bar.add_theme_stylebox_override("tab_selected", sb_focus)

	tab_bar.add_theme_font_size_override("font_size", 15)

func handle_settings_change(changed_settings: PackedStringArray, settings_mgr: QuillSettingsManager):
	settings_manager = settings_mgr
	
	for setting: String in changed_settings:
		if setting == settings_manager.SCRIPT_LIST_VISIBLE:
			update_script_list_visibility()
		elif setting == settings_manager.SCRIPT_TABS_VISIBLE:
			scripts_tab_container.tabs_visible = settings_manager.is_script_tabs_visible

func cycle_tab_forward():
	var new_tab: int = scripts_tab_container.current_tab + 1
	if new_tab == scripts_tab_container.get_tab_count():
		new_tab = 0
	scripts_tab_container.current_tab = new_tab

func cycle_tab_backward():
	var new_tab: int = scripts_tab_container.current_tab - 1
	if new_tab == -1:
		new_tab = scripts_tab_container.get_tab_count() - 1
	scripts_tab_container.current_tab = new_tab

func update_script_text_filter():
	if script_filter_txt.text != &"":
		script_filter_txt.text = &""
		script_filter_txt.text_changed.emit(&"")

func update_script_list_visibility():
	scripts_item_list.get_parent().visible = settings_manager.is_script_list_visible

func update_tabs():
	for index: int in scripts_tab_container.get_tab_count():
		update_tab(index)

func update_tab(index: int):
	var tab_control: Control = scripts_tab_container.get_tab_control(index)
	if tab_control == null:
		return

	var script: Script = tab_control.get("script")
	if script:
		var name := script.resource_path.get_file()
		if name == "":
			name = script.resource_name
		if name == "":
			name = "[Built-in]"

		var icon = icon_manager.get_icon_for_script(script)

		scripts_tab_container.set_tab_title(index, name)
		scripts_tab_container.set_tab_icon(index, icon)
		scripts_tab_container.set_tab_tooltip(index, script.resource_path)
	else:
		if index < scripts_item_list.item_count:
			var title = scripts_item_list.get_item_text(index)
			scripts_tab_container.set_tab_title(index, title)
			scripts_tab_container.set_tab_icon(index, scripts_item_list.get_item_icon(index))
			scripts_tab_container.set_tab_tooltip(index, scripts_item_list.get_item_tooltip(index))

func update_tabs_position():
	scripts_tab_container.tabs_position = TabContainer.POSITION_TOP

func sync_tab_with_script_list():
	if selected_tab >= scripts_item_list.item_count:
		selected_tab = scripts_tab_bar.current_tab
	
	if selected_tab != -1 && scripts_item_list.item_count > 0 && !scripts_item_list.is_selected(selected_tab):
		scripts_item_list.select(selected_tab)
		scripts_item_list.item_selected.emit(selected_tab)
		scripts_item_list.ensure_current_is_visible()

func get_res_path(idx: int) -> String:
	var tab_control: Control = scripts_tab_container.get_tab_control(idx)
	if tab_control == null:
		return ''
	
	var path_var: Variant = tab_control.get(&"metadata/_edit_res_path")
	if path_var == null:
		return ''
	
	return path_var

func simulate_item_clicked(tab_idx: int, mouse_idx: int):
	scripts_item_list.item_clicked.emit(tab_idx, scripts_item_list.get_local_mouse_position(), mouse_idx)

func _on_script_filter_input(event: InputEvent):
	navigate_on_list(event, scripts_item_list, _select_script)

func _on_tab_changed(index: int):
	selected_tab = index

	if old_script_editor_base != null:
		old_script_editor_base.edited_script_changed.disconnect(_on_script_changed)
		var old_code_edit: CodeEdit = old_script_editor_base.get_base_editor()
		if old_code_edit:
			if old_code_edit.text_changed.is_connected(_on_script_text_changed):
				old_code_edit.text_changed.disconnect(_on_script_text_changed)
		old_script_editor_base = null

	var script_editor: ScriptEditor = EditorInterface.get_script_editor()
	var script_editor_base: ScriptEditorBase = script_editor.get_current_editor()

	if script_editor_base != null:
		script_editor_base.edited_script_changed.connect(_on_script_changed)
		old_script_editor_base = script_editor_base

		var code_edit: CodeEdit = script_editor_base.get_base_editor()
		if code_edit:
			code_edit.text_changed.connect(_on_script_text_changed)

	sync_script_list = true
	
	if settings_manager.is_auto_navigate_in_fs && script_editor.get_current_script() != null:
		var file: String = script_editor.get_current_script().get_path()
		
		if file.contains(BUILT_IN_SCRIPT):
			file = file.get_slice(BUILT_IN_SCRIPT, 0)
		
		file_to_navigate = file
	else:
		file_to_navigate = &""
	
	var script := script_editor.get_current_script()
	if script:
		emit_signal("script_tab_changed", script)

func _on_script_text_changed():
	if selected_tab == -1:
		return
	update_tab(selected_tab)


func _on_script_changed():
	if selected_tab == -1 || scripts_item_list.item_count == 0:
		return
	update_tab(selected_tab)

func _on_tab_close(tab_idx: int):
	update_script_text_filter()
	simulate_item_clicked(tab_idx, MOUSE_BUTTON_MIDDLE)
	
	selected_tab = scripts_tab_bar.current_tab
	
	_on_tab_changed(selected_tab)
	update_tabs()

func _on_tab_rmb(tab_idx: int):
	update_script_text_filter()
	simulate_item_clicked(tab_idx, MOUSE_BUTTON_RIGHT)

func _on_tab_hovered(idx: int):
	last_tab_hovered = idx

func _on_tab_bar_mouse_exited():
	last_tab_hovered = -1

func _on_active_tab_rearranged(idx_to: int):
	scripts_tab_container.current_tab = scripts_tab_container.current_tab
	selected_tab = scripts_tab_container.current_tab

func _on_tab_bar_gui_input(event: InputEvent):
	if last_tab_hovered == -1:
		return
	
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_MIDDLE:
			update_script_text_filter()
			simulate_item_clicked(last_tab_hovered, MOUSE_BUTTON_MIDDLE)
			
			if last_tab_hovered >= scripts_tab_bar.tab_count - 1:
				last_tab_hovered = -1

func _select_script(selected_idx: int):
	scripts_item_list.item_selected.emit(selected_idx)

func navigate_on_list(event: InputEvent, list: ItemList, submit: Callable):
	if event.is_action_pressed(&"ui_text_submit"):
		var index: int = get_list_index(list)
		if index == -1:
			return
		submit.call(index)
		list.accept_event()
	elif event.is_action_pressed(&"ui_down", true):
		var index: int = get_list_index(list)
		if index == list.item_count - 1:
			return
		navigate_list(list, index, 1)
	elif event.is_action_pressed(&"ui_up", true):
		var index: int = get_list_index(list)
		if index <= 0:
			return
		navigate_list(list, index, -1)
	elif event.is_action_pressed(&"ui_page_down", true):
		var index: int = get_list_index(list)
		if index == list.item_count - 1:
			return
		navigate_list(list, index, 5)
	elif event.is_action_pressed(&"ui_page_up", true):
		var index: int = get_list_index(list)
		if index <= 0:
			return
		navigate_list(list, index, -5)
	elif event is InputEventKey && list.item_count > 0 && !list.is_anything_selected():
		list.select(0)

func get_list_index(list: ItemList) -> int:
	var items: PackedInt32Array = list.get_selected_items()
	if items.is_empty():
		return -1
	return items[0]

func navigate_list(list: ItemList, index: int, amount: int):
	index = clamp(index + amount, 0, list.item_count - 1)
	list.select(index)
	list.ensure_current_is_visible()
	list.accept_event()

static func find_or_null(arr: Array[Node], index: int = 0) -> Node:
	if arr.is_empty():
		push_error("Required node not found for Script-IDE Tab Manager")
		return null
	return arr[index]

## Contains everything we modify on the Tab Control. Used to save and restore the behaviour
## to keep the Engine in a clean state when the plugin is disabled.
class TabStateCache:
	var tabs_visible: bool
	var drag_to_rearrange_enabled: bool
	var auto_translate_mode_state: Node.AutoTranslateMode
	var tab_bar_drag_to_rearrange_enabled: bool
	var tab_close_display_policy: TabBar.CloseButtonDisplayPolicy
	var select_with_rmb: bool
	
	func save(tab_container: TabContainer, tab_bar: TabBar):
		if tab_container != null:
			tabs_visible = tab_container.tabs_visible
			drag_to_rearrange_enabled = tab_container.drag_to_rearrange_enabled
		if tab_bar != null:
			tab_bar_drag_to_rearrange_enabled = tab_bar.drag_to_rearrange_enabled
			tab_close_display_policy = tab_bar.tab_close_display_policy
			select_with_rmb = tab_bar.select_with_rmb
			auto_translate_mode_state = tab_bar.auto_translate_mode
	
	func restore(tab_container: TabContainer, tab_bar: TabBar):
		if tab_container != null:
			tab_container.tabs_visible = tabs_visible
			tab_container.drag_to_rearrange_enabled = drag_to_rearrange_enabled
		if tab_bar != null:
			tab_bar.drag_to_rearrange_enabled = drag_to_rearrange_enabled
			tab_bar.tab_close_display_policy = tab_close_display_policy
			tab_bar.select_with_rmb = select_with_rmb
			tab_bar.auto_translate_mode = auto_translate_mode_state
