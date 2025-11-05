@tool
extends EditorPlugin

const PathMesh3DOptions := preload("res://addons/PathMesh3D/scripts/path_mesh_3d_options.gd")
const PathMesh3DOptionsScene := preload("res://addons/PathMesh3D/scenes/path_mesh_3d_options.tscn")

const PathScene3DOptions := preload("res://addons/PathMesh3D/scripts/path_scene_3d_options.gd")
const PathScene3DOptionsScene := preload("res://addons/PathMesh3D/scenes/path_scene_3d_options.tscn")

var _mesh_editor_button: PathMesh3DOptions
var _scene_editor_button: PathScene3DOptions

var _path_object

func _enter_tree() -> void:
	_mesh_editor_button = PathMesh3DOptionsScene.instantiate()
	add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, _mesh_editor_button)
	_mesh_editor_button.hide()

	_scene_editor_button = PathScene3DOptionsScene.instantiate()
	add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, _scene_editor_button)
	_scene_editor_button.hide()

func _exit_tree() -> void:
	remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, _mesh_editor_button)
	remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, _scene_editor_button)
	_mesh_editor_button.queue_free()
	_scene_editor_button.queue_free()


func _handles(object: Object) -> bool:
	return is_instance_valid(object) and (object is PathMesh3D or object is PathExtrude3D or object is PathScene3D)


func _edit(object: Object) -> void:
	if is_instance_valid(object) and (object is PathMesh3D or object is PathExtrude3D) and _mesh_editor_button:
		_path_object = object
		_mesh_editor_button.path_mesh = object
		_mesh_editor_button.ur = get_undo_redo()
	elif is_instance_valid(object) and object is PathScene3D and _scene_editor_button:
		_path_object = object
		_scene_editor_button.path_scene = object
		_scene_editor_button.ur = get_undo_redo()


func _make_visible(visible: bool) -> void:
	if is_instance_valid(_path_object) and (_path_object is PathMesh3D or _path_object is PathExtrude3D) and visible:
		_mesh_editor_button.visible = visible
	elif is_instance_valid(_path_object) and _path_object is PathScene3D and visible:
		_scene_editor_button.visible = visible
	elif not visible:
		_mesh_editor_button.visible = visible
		_scene_editor_button.visible = visible
