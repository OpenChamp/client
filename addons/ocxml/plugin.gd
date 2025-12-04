@tool
class_name OpenChampXMLTool
extends EditorPlugin

var button = Button.new();
var is_attached: bool = false;

@onready var map_exporter = MapExporter.new()


func button_setup():
	button.text = "Export XML"
	button.tooltip_text = "Export the current scene to OpenChamp XML format."
	button.hide();

func _enter_tree() -> void:
	button_setup()
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, button)
	# Check initial selection
	_on_selection_changed()

func _exit_tree() -> void:
	if is_attached:
		button.pressed.disconnect(_try_export)
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, button)
		is_attached = false
	# Disconnect from selection changes
	EditorInterface.get_selection().selection_changed.disconnect(_on_selection_changed)

func _on_selection_changed() -> void:
	var selected_nodes = EditorInterface.get_selection().get_selected_nodes()
	
	# Check if the first selected node is a NavigationRegion3D
	if selected_nodes.size() > 0 and selected_nodes[0] is NavigationRegion3D:
		if not is_attached:
			button.show();
			button.pressed.connect(_try_export)
			is_attached = true
	else:
		if is_attached:
			# Remove button if it's attached but node is not NavigationRegion3D
			button.pressed.disconnect(_try_export)
			button.hide();
			is_attached = false

func _try_export():
	map_exporter.export_scene(EditorInterface.get_edited_scene_root());
	
