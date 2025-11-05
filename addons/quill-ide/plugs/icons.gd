@tool
class_name IconManager

var engine_func_icon: Texture2D
var func_icon: Texture2D
var func_get_icon: Texture2D
var func_set_icon: Texture2D
var property_icon: Texture2D
var export_icon: Texture2D
var signal_icon: Texture2D
var constant_icon: Texture2D
var class_icon: Texture2D
var scroll_top: Texture2D
var scroll_bottom: Texture2D

const GETTER: StringName = &"get"
const SETTER: StringName = &"set"

func init_icons():
	engine_func_icon = create_editor_texture(load_rel("icons/engine_func.svg"))
	func_icon = create_editor_texture(load_rel("icons/func.svg"))
	func_get_icon = create_editor_texture(load_rel("icons/func_get.svg"))
	func_set_icon = create_editor_texture(load_rel("icons/func_set.svg"))
	property_icon = create_editor_texture(load_rel("icons/property.svg"))
	export_icon = create_editor_texture(load_rel("icons/export.svg"))
	signal_icon = create_editor_texture(load_rel("icons/signal.svg"))
	constant_icon = create_editor_texture(load_rel("icons/constant.svg"))
	class_icon = create_editor_texture(load_rel("icons/class.svg"))
	scroll_top = create_editor_texture(load_rel("icons/scroll_top.svg"))
	scroll_bottom = create_editor_texture(load_rel("icons/scroll_bottom.svg"))

func create_editor_texture(texture: Texture2D) -> Texture2D:
	var image: Image = texture.get_image().duplicate()
	image.adjust_bcs(1.0, 1.0, get_editor_icon_saturation())
	return ImageTexture.create_from_image(image)

func get_func_icon(func_name: String) -> Texture2D:
	var icon: Texture2D = func_icon
	if func_name.begins_with(GETTER):
		icon = func_get_icon
	elif func_name.begins_with(SETTER):
		icon = func_set_icon
	return icon

func handle_settings_change(changed_settings: PackedStringArray):
	for setting: String in changed_settings:
		if setting == "interface/theme/icon_saturation":
			init_icons()
			break

func get_editor_icon_saturation() -> float:
	return EditorInterface.get_editor_settings().get_setting("interface/theme/icon_saturation")

func get_editor_scale() -> float:
	return EditorInterface.get_editor_scale()

func get_editor_corner_radius() -> int:
	return EditorInterface.get_editor_settings().get_setting("interface/theme/corner_radius")

func get_editor_accent_color() -> Color:
	return EditorInterface.get_editor_settings().get_setting("interface/theme/accent_color")

func load_rel(path: String) -> Variant:
	var base_path = "res://addons/quill-ide/"
	return load(base_path.path_join(path))
