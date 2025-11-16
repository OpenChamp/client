@tool
class_name OutlineManager

const UNDERSCORE: StringName = &"_"
const INLINE: StringName = &"@"
const GETTER: StringName = &"get"
const SETTER: StringName = &"set"

const ENGINE_FUNCS: StringName = &"Engine Callbacks"
const FUNCS: StringName = &"Functions"
const SIGNALS: StringName = &"Signals"
const EXPORTED: StringName = &"Exported Properties"
const PROPERTIES: StringName = &"Properties"
const CLASSES: StringName = &"Classes"
const CONSTANTS: StringName = &"Constants"

var outline_container: Control
var outline_parent: Control
var split_container: HSplitContainer
var old_outline: ItemList
var outline_filter_txt: LineEdit
var sort_btn: Button
var outline_tree: Tree
var outline_root: TreeItem

var category_items: Dictionary[StringName, TreeItem] = {}

var outline_cache: OutlineCache
var keywords: Dictionary[String, bool] = {}
var old_script_type: StringName

var settings_manager: QuillSettingsManager
var icon_manager: IconManager

func init(settings_mgr: QuillSettingsManager, icon_mgr: IconManager):
	settings_manager = settings_mgr
	icon_manager = icon_mgr
	
	EditorInterface.get_editor_settings().settings_changed.connect(_on_editor_settings_changed)
	
	var script_editor: ScriptEditor = EditorInterface.get_script_editor()
	split_container = find_or_null(script_editor.find_children("*", "HSplitContainer", true, false))
	outline_container = split_container.get_child(0)
	if settings_manager.is_outline_right:
		update_outline_position()
	
	# Replace existing outline with tree
	old_outline = find_or_null(outline_container.find_children("*", "ItemList", true, false), 1)
	outline_parent = old_outline.get_parent()
	outline_parent.remove_child(old_outline)
	
	outline_tree = Tree.new()
	outline_tree.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	outline_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outline_tree.hide_root = true
	outline_tree.allow_reselect = true
	outline_parent.add_child(outline_tree)
	outline_tree.item_selected.connect(_on_outline_item_selected)
	
	outline_root = outline_tree.create_item()
	
	outline_filter_txt = find_or_null(outline_container.find_children("*", "LineEdit", true, false), 1)
	outline_filter_txt.gui_input.connect(_on_outline_filter_input)
	outline_filter_txt.text_changed.connect(_on_outline_filter_changed)
	
	sort_btn = find_or_null(outline_container.find_children("*", "Button", true, false))
	sort_btn.pressed.connect(update_outline)
	
	if not script_editor.editor_script_changed.is_connected(_on_active_script_changed):
		script_editor.editor_script_changed.connect(_on_active_script_changed)

	if not script_editor.script_changed.is_connected(_on_script_modified):
		script_editor.script_changed.connect(_on_script_modified)

	_add_scroll_buttons()

func cleanup():
	if split_container != null:
		if split_container != outline_container.get_parent():
			split_container.add_child(outline_container)
		
		if settings_manager.is_outline_right:
			var split_offset: float = split_container.get_child(1).size.x
			split_container.split_offset = split_offset
		
		split_container.move_child(outline_container, 0)
		
		if outline_filter_txt:
			outline_filter_txt.gui_input.disconnect(_on_outline_filter_input)
			outline_filter_txt.text_changed.disconnect(_on_outline_filter_changed)
		if sort_btn:
			sort_btn.pressed.disconnect(update_outline)
		if outline_tree:
			outline_tree.item_selected.disconnect(_on_outline_item_selected)
		
		if outline_parent and outline_tree:
			outline_parent.remove_child(outline_tree)
			outline_parent.add_child(old_outline)
			outline_parent.move_child(old_outline, 2)
			outline_tree.free()
			
		if scroll_button_container:
			scroll_button_container.queue_free()
			scroll_button_container = null

func update_editor():
	update_outline_cache()
	update_outline()

func _on_editor_settings_changed():
	settings_manager.sync_settings_all()
	if settings_manager.is_outline_right: update_outline_position()
	else: update_outline_position()
	update_outline_cache()
	update_outline()


func _on_active_script_changed(script: Script):
	update_outline_cache()
	update_outline()

func _on_script_modified(script: Script):
	if script == EditorInterface.get_script_editor().get_current_script():
		update_outline_cache()
		update_outline()

func update_outline_position():
	if settings_manager.is_outline_right:
		var split_offset: float = split_container.get_child(1).size.x
		split_container.split_offset = split_offset
		split_container.move_child(outline_container, 1)
	else:
		split_container.move_child(outline_container, 0)

func update_keywords(script: Script):
	if script == null:
		return
	
	var new_script_type: StringName = script.get_instance_base_type()
	if old_script_type != new_script_type:
		old_script_type = new_script_type
		keywords.clear()
		keywords["_static_init"] = true
		register_virtual_methods(new_script_type)

func register_virtual_methods(clazz: String):
	for method_dict in ClassDB.class_get_method_list(clazz):
		if method_dict[&"flags"] & METHOD_FLAG_VIRTUAL > 0:
			keywords[method_dict[&"name"]] = true

func update_outline_cache():
	outline_cache = null
	var script: Script = EditorInterface.get_script_editor().get_current_script()
	if not script:
		return
	
	update_keywords(script)
	
	if script.get_path().contains("::GDScript"):
		script = script.duplicate()
	
	outline_cache = OutlineCache.new()
	for_each_script_member(script, func(array: Array[String], item: String): array.append(item))
	
	var base_script: Script = script.get_base_script()
	if base_script != null:
		for_each_script_member(base_script, func(array: Array[String], item: String): array.erase(item))

func for_each_script_member(script: Script, consumer: Callable):
	for dict in script.get_script_method_list():
		var func_name: String = dict[&"name"]
		if keywords.has(func_name):
			consumer.call(outline_cache.engine_funcs, func_name)
		else:
			if settings_manager.hide_private_members and func_name.begins_with(UNDERSCORE):
				continue
			if func_name.begins_with(INLINE):
				continue
			consumer.call(outline_cache.funcs, func_name)
		
	for dict in script.get_script_property_list():
		var property_name: String = dict[&"name"]
		if settings_manager.hide_private_members and property_name.begins_with(UNDERSCORE):
			continue
		
		var usage: int = dict[&"usage"]
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			if usage & PROPERTY_USAGE_STORAGE and usage & PROPERTY_USAGE_EDITOR:
				consumer.call(outline_cache.exports, property_name)
			else:
				consumer.call(outline_cache.properties, property_name)
	
	for dict in script.get_property_list():
		var property_name: String = dict[&"name"]
		if settings_manager.hide_private_members and property_name.begins_with(UNDERSCORE):
			continue
		
		var usage: int = dict[&"usage"]
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			consumer.call(outline_cache.properties, property_name)
	
	for dict in script.get_script_signal_list():
		var signal_name: String = dict[&"name"]
		consumer.call(outline_cache.signals, signal_name)
	
	for name_key in script.get_script_constant_map().keys():
		if settings_manager.hide_private_members and name_key.begins_with(UNDERSCORE):
			continue
		var obj: Variant = script.get_script_constant_map()[name_key]
		if obj is GDScript and not obj.has_source_code():
			consumer.call(outline_cache.classes, name_key)
		else:
			consumer.call(outline_cache.constants, name_key)

func update_outline():
	if not outline_tree or not outline_root:
		return
	
	outline_tree.clear()
	outline_root = outline_tree.create_item()
	category_items.clear()
	
	if outline_cache == null:
		return
	
	var filter_text: String = outline_filter_txt.get_text().to_lower()
	
	var categories_data = [
		{&"name": ENGINE_FUNCS, &"items": outline_cache.engine_funcs, &"icon": icon_manager.engine_func_icon, &"type": &"func", &"enabled": settings_manager.show_engine_funcs},
		{&"name": FUNCS, &"items": outline_cache.funcs, &"icon": icon_manager.func_icon, &"type": &"func", &"use_func_icons": true, &"enabled": settings_manager.show_funcs},
		{&"name": SIGNALS, &"items": outline_cache.signals, &"icon": icon_manager.signal_icon, &"type": &"signal", &"enabled": settings_manager.show_signals},
		{&"name": EXPORTED, &"items": outline_cache.exports, &"icon": icon_manager.export_icon, &"type": &"var", &"modifier": &"@export", &"enabled": settings_manager.show_exported},
		{&"name": PROPERTIES, &"items": outline_cache.properties, &"icon": icon_manager.property_icon, &"type": &"var", &"enabled": settings_manager.show_properties},
		{&"name": CLASSES, &"items": outline_cache.classes, &"icon": icon_manager.class_icon, &"type": &"class", &"enabled": settings_manager.show_classes},
		{&"name": CONSTANTS, &"items": outline_cache.constants, &"icon": icon_manager.constant_icon, &"type": &"const", &"modifier": &"enum", &"enabled": settings_manager.show_constants}
	]
	
	categories_data.sort_custom(func(a, b): return get_category_order(a[&"name"]) < get_category_order(b[&"name"]))
	
	for category_data in categories_data:
		var items: Array[String] = category_data[&"items"]
		if items.is_empty() or not category_data[&"enabled"]:
			continue
		
		var filtered_items: Array[String] = []
		for item in items:
			if filter_text.is_empty() or item.to_lower().contains(filter_text):
				filtered_items.append(item)
		
		if filtered_items.is_empty():
			continue
			
		if settings_manager.is_sorted():
			filtered_items.sort_custom(func(str1: String, str2: String): return str1.naturalnocasecmp_to(str2) < 0)
		
		var category_item: TreeItem = outline_tree.create_item(outline_root)
		category_item.set_text(0, category_data[&"name"] + " (" + str(filtered_items.size()) + ")")
		category_item.set_icon(0, category_data[&"icon"])
		category_item.set_selectable(0, false)
		category_item.collapsed = get_category_collapsed_state(category_data[&"name"])
		category_items[category_data[&"name"]] = category_item
		
		for item in filtered_items:
			var item_node: TreeItem = outline_tree.create_item(category_item)
			item_node.set_text(0, item)
			
			var item_icon: Texture2D = category_data[&"icon"]
			if category_data.has(&"use_func_icons"):
				item_icon = icon_manager.get_func_icon(item)
			item_node.set_icon(0, item_icon)
			
			var metadata: Dictionary[StringName, StringName] = {
				&"type": category_data[&"type"],
				&"modifier": category_data.get(&"modifier", &"")
			}
			item_node.set_metadata(0, metadata)

func get_category_order(category_name: StringName) -> int:
	var index = settings_manager.outline_order.find(category_name)
	return index if index != -1 else 999

func get_category_collapsed_state(category_name: StringName) -> bool:
	return true

func scroll_to_outline_item():
	var selected_item: TreeItem = outline_tree.get_selected()
	if not selected_item:
		return
	if not selected_item.get_metadata(0):
		return
	
	var script: Script = EditorInterface.get_script_editor().get_current_script()
	if not script:
		return
	
	var text: String = selected_item.get_text(0)
	var metadata: Dictionary[StringName, StringName] = selected_item.get_metadata(0)
	var modifier: StringName = metadata[&"modifier"]
	var type: StringName = metadata[&"type"]
	
	var type_with_text: String = type + " " + text
	if type == &"func":
		type_with_text += "("
	
	var lines: PackedStringArray = script.get_source_code().split("\n")
	var index: int = 0
	for line in lines:
		if line.begins_with(type_with_text):
			goto_line(index)
			return
		if modifier != &"" and line.begins_with(modifier):
			if line.begins_with(modifier + " " + type_with_text):
				goto_line(index)
				return
			elif modifier == &"enum" and line.contains("enum " + text):
				goto_line(index)
				return
		if type == &"var" and line.contains(type_with_text):
			goto_line(index)
			return
		index += 1
	
	push_error(type_with_text + " or " + modifier + " not found in source code")

func goto_line(index: int):
	var script_editor: ScriptEditor = EditorInterface.get_script_editor()
	script_editor.goto_line(index)
	
	var code_edit: CodeEdit = script_editor.get_current_editor().get_base_editor()
	code_edit.set_caret_line(index)
	code_edit.set_v_scroll(index)
	code_edit.set_caret_column(code_edit.get_line(index).length())
	code_edit.set_h_scroll(0)
	code_edit.grab_focus()

func _on_outline_item_selected():
	scroll_to_outline_item()

func _on_outline_filter_input(event: InputEvent):
	navigate_on_tree(event, outline_tree)

func _on_outline_filter_changed(text: String):
	update_outline()

func navigate_on_tree(event: InputEvent, tree: Tree):
	if event.is_action_pressed(&"ui_text_submit"):
		scroll_to_outline_item()
		tree.accept_event()
	elif event.is_action_pressed(&"ui_down", true):
		var selected: TreeItem = tree.get_selected()
		if selected:
			var next: TreeItem = selected.get_next_in_tree()
			if next:
				next.select(0)
				tree.ensure_cursor_is_visible()
		elif tree.get_root() and tree.get_root().get_first_child():
			tree.get_root().get_first_child().select(0)
		tree.accept_event()
	elif event.is_action_pressed(&"ui_up", true):
		var selected: TreeItem = tree.get_selected()
		if selected:
			var prev: TreeItem = selected.get_prev_in_tree()
			if prev:
				prev.select(0)
				tree.ensure_cursor_is_visible()
		tree.accept_event()
	elif event.is_action_pressed(&"ui_right", true):
		var selected: TreeItem = tree.get_selected()
		if selected and selected.get_children():
			selected.collapsed = false
		tree.accept_event()
	elif event.is_action_pressed(&"ui_left", true):
		var selected: TreeItem = tree.get_selected()
		if selected:
			if selected.get_children() and not selected.collapsed:
				selected.collapsed = true
			else:
				var parent: TreeItem = selected.get_parent()
				if parent and parent != tree.get_root():
					parent.select(0)
		tree.accept_event()
	elif event is InputEventKey and tree.get_root() and tree.get_root().get_first_child():
		if not tree.get_selected():
			tree.get_root().get_first_child().select(0)

var scroll_button_container: HBoxContainer

func _add_scroll_buttons():
	if scroll_button_container:
		scroll_button_container.free()

	scroll_button_container = HBoxContainer.new()
	scroll_button_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_button_container.size_flags_vertical = Control.SIZE_FILL
	scroll_button_container.custom_minimum_size.y = 60
	
	var scroll_top_btn := Button.new()
	scroll_top_btn.icon = icon_manager.scroll_top
	scroll_top_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scroll_top_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_top_btn.pressed.connect(_scroll_to_top)
	scroll_top_btn.custom_minimum_size.x = 60
	scroll_button_container.add_child(scroll_top_btn)

	var scroll_bottom_btn := Button.new()
	scroll_bottom_btn.icon = icon_manager.scroll_bottom
	scroll_bottom_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scroll_bottom_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_bottom_btn.pressed.connect(_scroll_to_bottom)
	scroll_bottom_btn.custom_minimum_size.x = 60
	scroll_button_container.add_child(scroll_bottom_btn)
	
	var editor_settings = EditorInterface.get_editor_settings()
	var base_color: Color = editor_settings.get_setting("interface/theme/base_color")

	var normal := StyleBoxFlat.new()
	normal.bg_color = base_color.darkened(0.2)
	normal.corner_radius_top_left = 12
	normal.corner_radius_top_right = 12
	normal.corner_radius_bottom_right = 12
	normal.corner_radius_bottom_left = 12
	normal.expand_margin_bottom = -3
	normal.expand_margin_top = -3
	normal.expand_margin_left = -3
	normal.expand_margin_right = -3

	var hover := normal.duplicate()
	hover.bg_color = base_color.lightened(0.1)

	var focus := normal.duplicate()
	focus.bg_color = base_color.darkened(0.3)
	
	scroll_top_btn.add_theme_stylebox_override("hover", hover)
	scroll_top_btn.add_theme_stylebox_override("normal", normal)
	scroll_top_btn.add_theme_stylebox_override("pressed", focus)
	scroll_top_btn.tooltip_text = "Scroll to Top"
	
	scroll_bottom_btn.add_theme_stylebox_override("hover", hover)
	scroll_bottom_btn.add_theme_stylebox_override("normal", normal)
	scroll_bottom_btn.add_theme_stylebox_override("pressed", focus)
	scroll_bottom_btn.tooltip_text = "Scroll to Bottom"
	
	outline_parent.add_child(scroll_button_container)
	outline_parent.move_child(scroll_button_container, outline_parent.get_child_count())

func _scroll_to_top():
	var script: Script = EditorInterface.get_script_editor().get_current_script()
	if not script:
		return

	var code_edit: CodeEdit = EditorInterface.get_script_editor().get_current_editor().get_base_editor()
	code_edit.set_caret_line(0)
	code_edit.set_v_scroll(0)
	code_edit.set_caret_column(0)
	code_edit.set_h_scroll(0)
	code_edit.grab_focus()

func _scroll_to_bottom():
	var script: Script = EditorInterface.get_script_editor().get_current_script()
	if not script:
		return

	var lines: PackedStringArray = script.get_source_code().split("\n")
	var last_index: int = lines.size() - 1

	var code_edit: CodeEdit = EditorInterface.get_script_editor().get_current_editor().get_base_editor()
	code_edit.set_caret_line(last_index)
	code_edit.set_v_scroll(last_index)
	code_edit.set_caret_column(lines[last_index].length())
	code_edit.set_h_scroll(0)
	code_edit.grab_focus()


func find_or_null(arr: Array[Node], index: int = 0) -> Node:
	if arr.is_empty():
		push_error("Required node not found for Script-IDE Outline Manager")
		return null
	return arr[index]

class OutlineCache:
	var classes: Array[String] = []
	var constants: Array[String] = []
	var signals: Array[String] = []
	var exports: Array[String] = []
	var properties: Array[String] = []
	var funcs: Array[String] = []
	var engine_funcs: Array[String] = []
