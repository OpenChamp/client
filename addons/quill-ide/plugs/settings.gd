@tool
class_name QuillSettingsManager

const GODOT_IDE: StringName = &"Quill/"

const GENERAL := GODOT_IDE + &"General/"
const HIDE_PRIVATE_MEMBERS: StringName = GENERAL + &"hide_private_members"
const AUTO_NAVIGATE_IN_FS: StringName = GENERAL + &"auto_navigate_in_filesystem_dock"
const SCRIPT_LIST_VISIBLE: StringName = GENERAL + &"script_list_visible"
const SCRIPT_TABS_VISIBLE: StringName = GENERAL + &"script_tabs_visible"

const OUTLINE := GODOT_IDE + &"Outline/"
const OUTLINE_ORDER: StringName = OUTLINE + &"outline_order"
const OUTLINE_POSITION_RIGHT: StringName = OUTLINE + &"outline_position_right"
const SHOW_FUNCS: StringName = OUTLINE + &"show_funcs"
const SHOW_SIGNALS: StringName = OUTLINE + &"show_signals"
const SHOW_CONSTANTS: StringName = OUTLINE + &"show_constants"
const SHOW_EXPORTED: StringName = OUTLINE + &"show_exported"
const SHOW_PROPERTIES: StringName = OUTLINE + &"show_properties"
const SHOW_CLASSES: StringName = OUTLINE + &"show_classes"
const SHOW_ENGINE_FUNCS: StringName = OUTLINE + &"show_engine_funcs"

var is_outline_right: bool = true
var is_script_list_visible: bool = false
var hide_private_members: bool = false
var is_auto_navigate_in_fs: bool = true
var is_script_tabs_visible: bool = true
var is_script_tabs_top: bool = true
var outline_order: PackedStringArray

var suppress_settings_sync: bool = false

var show_funcs := true
var show_signals := true
var show_constants := true
var show_exported := true
var show_properties := true
var show_classes := true
var show_engine_funcs := true

func init_settings():
	is_outline_right = get_setting(OUTLINE_POSITION_RIGHT, is_outline_right)
	hide_private_members = get_setting(HIDE_PRIVATE_MEMBERS, hide_private_members)
	is_script_list_visible = get_setting(SCRIPT_LIST_VISIBLE, is_script_list_visible)
	is_auto_navigate_in_fs = get_setting(AUTO_NAVIGATE_IN_FS, is_auto_navigate_in_fs)
	is_script_tabs_visible = get_setting(SCRIPT_TABS_VISIBLE, is_script_tabs_visible)
	init_outline_order()
	
	show_funcs = get_setting(SHOW_FUNCS, show_funcs)
	show_signals = get_setting(SHOW_SIGNALS, show_signals)
	show_constants = get_setting(SHOW_CONSTANTS, show_constants)
	show_exported = get_setting(SHOW_EXPORTED, show_exported)
	show_properties = get_setting(SHOW_PROPERTIES, show_properties)
	show_classes = get_setting(SHOW_CLASSES, show_classes)
	show_engine_funcs = get_setting(SHOW_ENGINE_FUNCS, show_engine_funcs)

func init_outline_order():
	var editor_settings: EditorSettings = get_editor_settings()
	if editor_settings.has_setting(OUTLINE_ORDER):
		outline_order = editor_settings.get_setting(OUTLINE_ORDER)
	else:
		outline_order = ["Engine Callbacks", "Functions", "Signals", "Exported Properties", "Properties", "Constants", "Classes"]
		editor_settings.set_setting(OUTLINE_ORDER, outline_order)


func sync_settings(changed_settings: PackedStringArray):
	if suppress_settings_sync: return
	
	for setting: String in changed_settings:
		if !setting.begins_with(GODOT_IDE): continue
		
		match setting:
			OUTLINE_ORDER: init_outline_order()
			OUTLINE_POSITION_RIGHT: is_outline_right = get_setting(setting, is_outline_right)
			HIDE_PRIVATE_MEMBERS: hide_private_members = get_setting(setting, hide_private_members)
			SCRIPT_LIST_VISIBLE: is_script_list_visible = get_setting(setting, is_script_list_visible)
			SCRIPT_TABS_VISIBLE: is_script_tabs_visible = get_setting(setting, is_script_tabs_visible)
			AUTO_NAVIGATE_IN_FS: is_auto_navigate_in_fs = get_setting(setting, is_auto_navigate_in_fs)
			SHOW_FUNCS: show_funcs = get_setting(setting, show_funcs)
			SHOW_SIGNALS: show_signals = get_setting(setting, show_signals)
			SHOW_CONSTANTS: show_constants = get_setting(setting, show_constants)
			SHOW_EXPORTED: show_exported = get_setting(setting, show_exported)
			SHOW_PROPERTIES: show_properties = get_setting(setting, show_properties)
			SHOW_CLASSES: show_classes = get_setting(setting, show_classes)
			SHOW_ENGINE_FUNCS: show_engine_funcs = get_setting(setting, show_engine_funcs)

func sync_settings_all():
	if suppress_settings_sync: return
	
	is_outline_right = get_setting(OUTLINE_POSITION_RIGHT, is_outline_right)
	hide_private_members = get_setting(HIDE_PRIVATE_MEMBERS, hide_private_members)
	is_script_list_visible = get_setting(SCRIPT_LIST_VISIBLE, is_script_list_visible)
	is_auto_navigate_in_fs = get_setting(AUTO_NAVIGATE_IN_FS, is_auto_navigate_in_fs)
	is_script_tabs_visible = get_setting(SCRIPT_TABS_VISIBLE, is_script_tabs_visible)
	init_outline_order()
	
	show_funcs = get_setting(SHOW_FUNCS, show_funcs)
	show_signals = get_setting(SHOW_SIGNALS, show_signals)
	show_constants = get_setting(SHOW_CONSTANTS, show_constants)
	show_exported = get_setting(SHOW_EXPORTED, show_exported)
	show_properties = get_setting(SHOW_PROPERTIES, show_properties)
	show_classes = get_setting(SHOW_CLASSES, show_classes)
	show_engine_funcs = get_setting(SHOW_ENGINE_FUNCS, show_engine_funcs)


func get_setting(property: StringName, alt: bool) -> bool:
	var editor_settings: EditorSettings = get_editor_settings()
	if editor_settings.has_setting(property):
		return editor_settings.get_setting(property)
	else:
		editor_settings.set_setting(property, alt)
		return alt

func set_setting(property: StringName, value: bool):
	var editor_settings: EditorSettings = get_editor_settings()
	suppress_settings_sync = true
	editor_settings.set_setting(property, value)
	suppress_settings_sync = false

func get_editor_settings() -> EditorSettings:
	return EditorInterface.get_editor_settings()

func is_sorted() -> bool:
	return get_editor_settings().get_setting("text_editor/script_list/sort_members_outline_alphabetically")
