class_name ability extends Node3D

func get_mouse_3d():
	var mouse_pos:Vector2 = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_3d()
	var from = camera.project_ray_origin(mouse_pos)
	var direction = camera.project_ray_normal(mouse_pos)
	
	# Equation to find t where the ray intersects the y = 0 plane
	if direction.y == 0:
		return Vector3.ZERO  # Parallel to the plane, no intersection
	
	var t = -from.y / direction.y
	var intersection_point = from + direction * t
	
	return intersection_point
