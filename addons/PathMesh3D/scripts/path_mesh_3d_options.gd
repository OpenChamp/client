@tool
extends MenuButton

enum Operation {BAKE, COLLISION}
enum Shape {TRIMESH, SINGLE_CONVEX, SIMPLE_CONVEX, MULTIPLE_CONVEX}
enum Placement {SIBLING, CHILD}

var path_mesh: Node
var ur: EditorUndoRedoManager

@onready var _err_dialog: AcceptDialog = $ErrDialog
@onready var _collision_dialog: ConfirmationDialog = $CollisionDialog
@onready var _shape_placement: OptionButton = $CollisionDialog/VBoxContainer/OptionButton
@onready var _shape_type: OptionButton = $CollisionDialog/VBoxContainer/OptionButton2
@onready var _bake_dialog: ConfirmationDialog = $BakeDialog
@onready var _bake_placement: OptionButton = $BakeDialog/VBoxContainer/OptionButton

func _ready() -> void:
	get_popup().index_pressed.connect(_on_menu_pressed)
	_bake_dialog.confirmed.connect(_on_bake_confirmed)
	_collision_dialog.confirmed.connect(_on_collision_shape_confirmed)


func _on_menu_pressed(id: int) -> void:
	match id:
		Operation.BAKE:
			_bake_dialog.popup_centered()
		Operation.COLLISION:
			_collision_dialog.popup_centered()


func _on_bake_confirmed() -> void:
	if not (path_mesh is PathMesh3D or path_mesh is PathExtrude3D):
		return

	if not ur:
		return

	var placement := _bake_placement.selected
	var p_owner := EditorInterface.get_edited_scene_root()
	if p_owner == path_mesh and placement == Placement.SIBLING:
		_err_dialog.dialog_text = "Can't add Mesh Instance as sibling of scene root."
		_err_dialog.popup_centered()
		return

	var mesh: Mesh = path_mesh.get_baked_mesh()
	if mesh == null:
		_err_dialog.dialog_text = "No mesh to create Instance from."
		_err_dialog.popup_centered()
		return

	var minstance := MeshInstance3D.new()
	minstance.mesh = mesh
	minstance.name = "MeshInstance3D"

	if placement == Placement.SIBLING:
		ur.add_do_method(path_mesh, "add_sibling", minstance, true)
		ur.add_do_method(minstance, "set_owner", p_owner)
		ur.add_do_reference(minstance)
		ur.add_undo_method(path_mesh.get_parent(), "remove_child", minstance)
	else:
		ur.add_do_method(path_mesh, "add_child", minstance, true)
		ur.add_do_method(minstance, "set_owner", p_owner)
		ur.add_do_reference(minstance)
		ur.add_undo_method(path_mesh, "remove_child", minstance)

	ur.commit_action()


func _on_collision_shape_confirmed() -> void:
	if not (path_mesh is PathMesh3D or path_mesh is PathExtrude3D):
		return

	if not ur:
		return

	var mesh: Mesh = path_mesh.get_baked_mesh()
	if mesh == null:
		_err_dialog.dialog_text = "No mesh to create Collision Shape from."
		_err_dialog.popup_centered()
		return

	var placement := _shape_placement.selected
	var shape_type := _shape_type.selected

	var str := "Collision Shape Sibling" if placement == Placement.SIBLING else "Static Body"

	match shape_type:
		Shape.TRIMESH: ur.create_action("Create Trimesh " + str)
		Shape.SINGLE_CONVEX: ur.create_action("Create Single Convex " + str)
		Shape.SIMPLE_CONVEX: ur.create_action("Create Simplified Convex "+ str)
		Shape.MULTIPLE_CONVEX: ur.create_action("Create Multiple Convex " + str)
		_: return

	if EditorInterface.get_edited_scene_root() == path_mesh and placement == 0:
		_err_dialog.dialog_text = "Can't create a collision shape as sibling for the scene root."
		_err_dialog.popup_centered()
		return

	var scene_owner := EditorInterface.get_edited_scene_root()
	var shapes: Array[Shape3D] = []
	match shape_type:
		Shape.TRIMESH:
			shapes.push_back(mesh.create_trimesh_shape())
		Shape.SINGLE_CONVEX:
			shapes.push_back(mesh.create_convex_shape(true, false))
		Shape.SIMPLE_CONVEX:
			shapes.push_back(mesh.create_convex_shape(true, true))
		Shape.MULTIPLE_CONVEX:
			var settings := MeshConvexDecompositionSettings.new()
			settings.max_convex_hulls = 32
			settings.max_concavity = 0.001
			shapes = mesh.convex_decompose(settings)

	if shapes.is_empty():
		_err_dialog.dialog_text = "Cannot create collision shape."
		_err_dialog.popup_centered()
		return

	var p_owner := EditorInterface.get_edited_scene_root()
	if placement == Placement.CHILD:
		var body := StaticBody3D.new()
		ur.add_do_method(path_mesh, "add_child", body, true)
		ur.add_do_method(body, "set_owner", p_owner)

		for shape: Shape3D in shapes:
			var cshape := CollisionShape3D.new()
			cshape.shape = shape
			ur.add_do_method(body, "add_child", cshape, true)
			ur.add_do_method(cshape, "set_owner", p_owner)

		ur.add_do_reference(body)
		ur.add_undo_method(path_mesh, "remove_child", body)
	else:
		for shape: Shape3D in shapes:
			var cshape := CollisionShape3D.new()
			cshape.shape = shape
			cshape.name = "CollisionShape3D"
			cshape.transform = path_mesh.transform
			ur.add_do_method(path_mesh, "add_sibling", cshape, true)
			ur.add_do_method(cshape, "set_owner", p_owner)
			ur.add_do_reference(cshape)
			ur.add_undo_method(path_mesh.get_parent(), "remove_child", cshape)

	ur.commit_action()
