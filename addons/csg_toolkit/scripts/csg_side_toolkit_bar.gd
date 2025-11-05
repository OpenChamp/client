@tool
class_name CSGSideToolkitBar extends Control

@onready var config: CsgTkConfig:
	get:
		return get_tree().root.get_node_or_null(CsgToolkit.AUTOLOAD_NAME) as CsgTkConfig

var operation: CSGShape3D.Operation = CSGShape3D.OPERATION_UNION
var selected_material: BaseMaterial3D
var selected_shader: ShaderMaterial

@onready var picker_button: Button = $ScrollContainer/HBoxContainer/Material/MaterialPicker

func _enter_tree():
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)

func _exit_tree():
	EditorInterface.get_selection().selection_changed.disconnect(_on_selection_changed)

func _on_selection_changed():
	if not config.auto_hide:
		print("not hiding")
		return
	var selection = EditorInterface.get_selection().get_selected_nodes()
	if selection.any(func (node): return node is CSGShape3D):
		show()
	else:
		hide()

func _ready():
	picker_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _on_box_pressed():
	create_csg(CSGBox3D)

func _on_cylinder_pressed():
	create_csg(CSGCylinder3D)

func _on_mesh_pressed():
	create_csg(CSGMesh3D)

func _on_polygon_pressed():
	create_csg(CSGPolygon3D)

func _on_sphere_pressed():
	create_csg(CSGSphere3D)

func _on_torus_pressed():
	create_csg(CSGTorus3D)

# Operation Toggle
func _on_operation_pressed(val):
	set_operation(val)

func _on_config_pressed():
	var config_view_scene = preload("res://addons/csg_toolkit/scenes/config_window.tscn")
	var config_view = config_view_scene.instantiate()
	config_view.close_requested.connect(func ():
		get_tree().root.remove_child(config_view)
		config_view.queue_free()
	)
	get_tree().root.add_child(config_view)

func _request_material():
	var dialog = EditorFileDialog.new()
	dialog.title = "Select Material"
	dialog.display_mode = EditorFileDialog.DISPLAY_LIST
	dialog.filters = ["*.tres, *.material, *.res"]
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	dialog.position = ((EditorInterface.get_base_control().size / 2) as Vector2i) - dialog.size
	dialog.close_requested.connect(func ():
		get_tree().root.remove_child(dialog)
		dialog.queue_free()
	)
	get_tree().root.add_child(dialog)
	dialog.show()
	var res_path = await dialog.file_selected
	var res = ResourceLoader.load(res_path)
	if res == null: 
		return
	if res is BaseMaterial3D:
		update_material(res)
	elif res is ShaderMaterial:
		update_shader(res)
	else:
		return
	var previewer = EditorInterface.get_resource_previewer()
	previewer.queue_edited_resource_preview(res, self, "_update_picker_icon", null) 
	
func _update_picker_icon(path, preview, thumbnail, userdata):
	picker_button.icon = preview
	

func set_operation(val: int):
	match val:
		0: operation = CSGShape3D.OPERATION_UNION
		1: operation = CSGShape3D.OPERATION_INTERSECTION
		2: operation = CSGShape3D.OPERATION_SUBTRACTION
		_: operation = CSGShape3D.OPERATION_UNION

func update_material(material: BaseMaterial3D):
	selected_material = material
	selected_shader = null

func update_shader(shader: ShaderMaterial):
	selected_material = null
	selected_shader = shader

func create_csg(type: Variant):
	var selected_nodes = EditorInterface.get_selection().get_selected_nodes()
	if selected_nodes.is_empty() or !(selected_nodes[0] is CSGShape3D):
		# Do not create a csg if not inside another csgshape
		return
	var selected_node: CSGShape3D = selected_nodes[0]
	var csg: CSGShape3D
	match type:
		CSGBox3D:
			csg = CSGBox3D.new()
		CSGCylinder3D:
			csg = CSGCylinder3D.new()
		CSGSphere3D:
			csg = CSGSphere3D.new()
		CSGMesh3D:
			csg = CSGMesh3D.new()
		CSGPolygon3D:
			csg = CSGPolygon3D.new()
		CSGTorus3D:
			csg = CSGTorus3D.new()
	
	csg.operation = operation
	if selected_material:
		csg.material = selected_material
	elif selected_shader:
		csg.material = selected_shader


	if (selected_node.get_owner() == null):
		return

	if Input.is_key_pressed(config.action_key):
		if config.default_behavior == CsgTkConfig.CSGBehavior.SIBLING:
			_add_as_child(selected_node, csg)
		elif config.default_behavior == CsgTkConfig.CSGBehavior.CHILD:
			_add_as_sibling(selected_node, csg)
	else:
		if config.default_behavior == CsgTkConfig.CSGBehavior.SIBLING:
			_add_as_sibling(selected_node, csg)
		elif config.default_behavior == CsgTkConfig.CSGBehavior.CHILD:
			_add_as_child(selected_node, csg)

	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(csg)

func _add_as_child(selected_node: CSGShape3D, csg: CSGShape3D):
	selected_node.add_child(csg, true)
	csg.owner = selected_node.get_owner()
	csg.global_position = selected_node.global_position
	
func _add_as_sibling(selected_node: CSGShape3D, csg: CSGShape3D):
	selected_node.get_parent().add_child(csg, true)
	csg.owner = selected_node.get_owner()
	csg.global_position = selected_node.global_position


func _on_material_picker_pressed() -> void:
	pass # Replace with function body.
