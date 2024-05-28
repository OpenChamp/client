class_name Trail3D extends MeshInstance3D

"""
Original Author: Oussama BOUKHELF
License: MIT
Version: 0.1
Email: o.boukhelf@gmail.com
Description: Advanced 2D/3D Trail system.
"""

enum {VIEW, NORMAL, OBJECT}
enum {X, Y, Z}

@export var emit: bool = true
@export var distance: float= 0.1
@export_range(0, 99999) var segments: int = 20
@export var lifetime: float= 0.5
@export_range(0, 99999) var base_width: float =  0.5
@export var tiled_texture: bool = false
@export var tiling: int = 0
@export var width_profile: Curve
@export_range(0, 3) var smoothing_iterations: int= 0
@export_range(0, 0.5) var smoothing_ratio: float = 0.25
@export_enum("View", "Normal", "Object") var alignment: int = VIEW
@export_enum("X", "Y", "Z") var axis: int = Y


var points := []
var color := Color(1, 1, 1, 1)
var always_update = false

var _target: Node3D
var _A: Point
var _B: Point
var _C: Point
var _temp_segment := []
var _points := []


class Point:
	var transform: Transform3D
	var age: float = 0.0

	func _init(_transform :Transform3D, _age :float) -> void:
		transform = _transform
		age = _age
	
	func update(delta: float, points: Array) -> void:
		age -= delta
		if age <= 0:
			points.erase(self)


func add_point(_transform :Transform3D) -> void:
	var point =  Point.new(_transform, lifetime)
	points.push_back(point)


func clear_points() -> void:
	points.clear()


func _prepare_geometry(point_prev :Point, point :Point, half_width :float, factor :float) -> Array:
	var normal := Vector3()
	
	if alignment == VIEW:
		if get_viewport().get_camera_3d():
			var cam_pos = get_viewport().get_camera_3d().get_global_transform().origin
			var path_direction :Vector3 = (point.transform.origin - point_prev.transform.origin).normalized()
			normal = (cam_pos - (point.transform.origin + point_prev.transform.origin)/2).cross(path_direction).normalized()
		else:
			print("There is no camera in the scene")
			
	elif alignment == NORMAL:
		if axis == X:
			normal = point.transform.basis.x.normalized()
		elif axis == Y:
			normal = point.transform.basis.y.normalized()
		else:
			normal = point.transform.basis.z.normalized()
	
	else:
		if axis == X:
			normal = _target.global_transform.basis.x.normalized()
		elif axis == Y:
			normal = _target.global_transform.basis.y.normalized()
		else:
			normal = _target.global_transform.basis.z.normalized()

	var width = half_width
	if width_profile:
		width = half_width * width_profile.sample(factor)

	var p1 = point.transform.origin-normal*width
	var p2 = point.transform.origin+normal*width
	return [p1, p2]


func render(update := false) -> void:
	if update:
		always_update = update
	else:
		_render_geometry(points)


func _render_realtime() -> void:
	var render_points = _points+_temp_segment+[_C]
	_render_geometry(render_points)


func _render_geometry(source: Array) -> void:
	var points_count = source.size()
	if points_count < 2:
		return

	# The following section is a hack to make orientation "view" work.
	# but it may cause an artifact at the end of the trail.
	# You can use transparency in the gradient to hide it for now.
	var _d :Vector3 = source[0].transform.origin - source[1].transform.origin
	var _t :Transform3D = source[0].transform
	_t.origin = _t.origin + _d
	var point = Point.new(_t, source[0].age)
	var to_be_rendered = [point]+source
	points_count += 1

	var half_width :float = base_width/2.0
	var u := 0.0

	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, null)
	for i in range(1, points_count):
		var factor :float = float(i)/(points_count-1)

		var vertices = _prepare_geometry(to_be_rendered[i-1], to_be_rendered[i], half_width, 1.0-factor)
		if tiled_texture:
			if tiling > 0:
				factor *= tiling
			else:
				var travel = (to_be_rendered[i-1].transform.origin - to_be_rendered[i].transform.origin).length()
				u += travel/base_width
				factor = u

		
		mesh.surface_set_uv(Vector2(factor, 0))
		mesh.surface_add_vertex(vertices[0])
		mesh.surface_set_uv(Vector2(factor, 1))
		mesh.surface_add_vertex(vertices[1])


	mesh.surface_end()



func _update_points() -> void:
	var delta = get_process_delta_time()
		
	_A.update(delta, _points)
	_B.update(delta, _points)
	_C.update(delta, _points)
	for point in _points:
		point.update(delta, _points)

	var size_multiplier = [1, 2, 4, 6][smoothing_iterations]
	var max_points_count :int = segments * size_multiplier
	if _points.size() > max_points_count:
		_points.reverse()
		_points.resize(max_points_count)
		_points.reverse()


func smooth() -> void:
	if points.size() < 3:
		return

	var output := [points[0]]
	for i in range(1, points.size()-1):
		output += _chaikin(points[i-1], points[i], points[i+1])
		
	output.push_back(points[-1])
	points = output


func _chaikin(A, B, C) -> Array:
	if smoothing_iterations == 0:
		return [B]

	var out := []
	var x :float = smoothing_ratio

	# Pre-calculate some parameters to improve performance
	var xi  :float = (1-x)
	var xpa :float = (x*x-2*x+1)
	var xpb :float = (-x*x+2*x)
	# transforms
	var A1_t  :Transform3D = A.transform.interpolate_with(B.transform, xi)
	var B1_t  :Transform3D = B.transform.interpolate_with(C.transform, x)
	# ages
	var A1_a  :float = lerp(A.age, B.age, xi)
	var B1_a  :float = lerp(B.age, C.age, x)

	if smoothing_iterations == 1:
		out = [Point.new(A1_t, A1_a), Point.new(B1_t, B1_a)]

	else:
		# transforms
		var A2_t  :Transform3D = A.transform.interpolate_with(B.transform, xpa)
		var B2_t  :Transform3D = B.transform.interpolate_with(C.transform, xpb)
		var A11_t :Transform3D = A1_t.interpolate_with(B1_t, x)
		var B11_t :Transform3D = A1_t.interpolate_with(B1_t, xi)
		# ages
		var A2_a  :float = lerp(A.age, B.age, xpa)
		var B2_a  :float = lerp(B.age, C.age, xpb)
		var A11_a :float = lerp(A1_a, B1_a, x)
		var B11_a :float = lerp(A1_a, B1_a, xi)

		if smoothing_iterations == 2:
			out += [Point.new(A2_t, A2_a), Point.new(A11_t, A11_a),
					Point.new(B11_t, B11_a), Point.new(B2_t, B2_a)]
		elif smoothing_iterations == 3:
			# transforms
			var A12_t  :Transform3D = A1_t.interpolate_with(B1_t, xpb)
			var B12_t  :Transform3D = A1_t.interpolate_with(B1_t, xpa)
			var A121_t :Transform3D = A11_t.interpolate_with(A2_t, x)
			var B121_t :Transform3D = B11_t.interpolate_with(B2_t, x)
			# ages
			var A12_a  :float = lerp(A1_a, B1_a, xpb)
			var B12_a  :float = lerp(A1_a, B1_a, xpa)
			var A121_a :float = lerp(A11_a, A2_a, x)
			var B121_a :float = lerp(B11_a, B2_a, x)
			out += [Point.new(A2_t, A2_a), Point.new(A121_t, A121_a), Point.new(A12_t, A12_a),
					Point.new(B12_t, B12_a), Point.new(B121_t, B121_a), Point.new(B2_t, B2_a)]

	return out


func _emit(delta) -> void:
	var _transform :Transform3D = _target.global_transform

	var point = Point.new(_transform, lifetime)
	if not _A:
		_A = point
		return
	elif not _B:
		_A.update(delta, _points)
		_B = point
		return

	if _B.transform.origin.distance_squared_to(_transform.origin) >= distance*distance:
		_A = _B
		_B = point
		_points += _temp_segment
		
	_C = point

	_update_points()
	_temp_segment = _chaikin(_A, _B, _C)
	_render_realtime()


func _ready() -> void:
	mesh = ImmediateMesh.new()
	_target = get_parent()
	top_level = true



func _process(delta) -> void:
	if emit:
		_emit(delta)
		return
		
	if always_update:
		# This is needed for alignment == view, so it can be updated every frame.
		_render_geometry(points)
