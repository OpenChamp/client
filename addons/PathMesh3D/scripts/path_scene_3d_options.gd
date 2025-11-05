@tool
extends MenuButton

enum Operation {BAKE}
enum Placement {SIBLING, CHILD}

var path_scene: Node
var ur: EditorUndoRedoManager

@onready var _err_dialog: AcceptDialog = $ErrDialog
@onready var _bake_dialog: ConfirmationDialog = $BakeDialog
@onready var _bake_placement: OptionButton = $BakeDialog/VBoxContainer/OptionButton

func _ready() -> void:
	get_popup().index_pressed.connect(_on_menu_pressed)
	_bake_dialog.confirmed.connect(_on_bake_confirmed)


func _on_menu_pressed(id: int) -> void:
	match id:
		Operation.BAKE:
			_bake_dialog.popup_centered()


func _on_bake_confirmed() -> void:
	if not (path_scene is PathScene3D):
		return

	if not ur:
		return

	var placement := _bake_placement.selected
	var p_owner := EditorInterface.get_edited_scene_root()
	if p_owner == path_scene and placement == Placement.SIBLING:
		_err_dialog.dialog_text = "Can't add instances as siblings of scene root."
		_err_dialog.popup_centered()
		return

	var instances: Array[Node3D] = path_scene.bake_instances()

	for i: Node3D in instances:
		if placement == Placement.SIBLING:
			ur.add_do_method(path_scene, "add_sibling", i, true)
			ur.add_do_method(i, "set_owner", p_owner)
			ur.add_do_reference(i)
			ur.add_undo_method(path_scene.get_parent(), "remove_child", i)
		else:

			ur.add_do_method(path_scene, "add_child", i, true)
			ur.add_do_method(i, "set_owner", p_owner)
			ur.add_do_reference(i)
			ur.add_undo_method(path_scene, "remove_child", i)

	ur.commit_action()
