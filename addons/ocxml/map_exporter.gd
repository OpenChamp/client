@tool
class_name MapExporter
extends EditorScript

### === Constants === ###
const spawn_groups = ["minion_spawn", "player_spawn"]

func export_scene(scene):
	if scene is not NavigationRegion3D:
		push_warning("Only Maps supported at this time...")
		return;
	process_map_scene(scene);
	
func process_map_scene(current_scene : NavigationRegion3D):
	var nodes = get_all_nodes(current_scene)
	print("Total nodes in scene: %d" % nodes.size())
	var map_data = {}

	# Get scene name for output
	var scene_name = current_scene.name.to_lower()

	# Export Navmesh Data
	export_navmesh_obj(current_scene, scene_name)

	# Export Structure Data
	var structure_data = []
	for child in nodes:
		if child is StaticBody3D and child.get_groups().has("structure"):
			var structure_info = {}
			structure_info["name"] = child.name
			structure_info["team"] = get_team(child)
			# Structure type is XML Template ID based on groups
			structure_info["type"] = get_structure_type(child)
			structure_info["position"] = [child.global_position.x, child.global_position.y, child.global_position.z]
			structure_info["rotation"] = [child.global_rotation.x, child.global_rotation.y, child.global_rotation.z]
			structure_info["scale"] = [child.scale.x, child.scale.y, child.scale.z]
			structure_data.append(structure_info)
	map_data["structures"] = structure_data

	# Export Spawn Points
	var spawn_points = []
	for child in nodes:
		if child is Marker3D:
			print("Marker3D found: %s" % child.name)
			var groups = child.get_groups()
			var is_spawn = false
			for group in groups:
				if spawn_groups.has(group):
					is_spawn = true
					break
			if is_spawn:
				var spawn_info = {}
				spawn_info["name"] = child.name
				spawn_info["team"] = get_team(child)
				spawn_info["position"] = [child.global_position.x, child.global_position.y, child.global_position.z]
				spawn_info["rotation"] = [child.global_rotation.x, child.global_rotation.y, child.global_rotation.z]
				spawn_points.append(spawn_info)
			else:
				print("Marker3D %s does not belong to spawn groups." % child.name)
	map_data["spawn_points"] = spawn_points

	# Export to XML
	var xml_string = export_map_to_xml(scene_name, map_data)
	if xml_string != null:
		var xml_file = FileAccess.open("res://data/maps/%s.xml" % scene_name, FileAccess.WRITE)
		if xml_file:
			xml_file.store_string(xml_string)
			xml_file.close()
			print("Map data exported to %s" % "res://data/maps/%s.xml" % scene_name)
		else:
			print("Failed to open XML file for writing.")
	else:
		print("Failed to serialize map data to XML.")

### === Helper Functions === ###

# Breadth-First Search to find connected nav component
func bfs_component(start: int, adjacency: Dictionary, visited: Dictionary) -> Array:
	var component = []
	var queue = [start]
	visited[start] = true
	while queue.size() > 0:
		var current = queue.pop_front()
		component.append(current)
		
		for neighbor in adjacency[current]:
			if not visited.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)
	return component

func filter_islands(vertices: PackedVector3Array, polygons: Array, used_vertices: Dictionary) -> Dictionary:
	# Build adjacency graph for vertices
	var adjacency = {}
	for vertex_idx in used_vertices.keys():
		adjacency[vertex_idx] = []
	
	for polygon in polygons:
		for i in range(polygon.size()):
			var v1 = polygon[i]
			var v2 = polygon[(i + 1) % polygon.size()]
			if not adjacency[v1].has(v2):
				adjacency[v1].append(v2)
			if not adjacency[v2].has(v1):
				adjacency[v2].append(v1)
	
	# Find largest connected component using BFS
	var visited = {}
	var largest_component = []
	
	for start_vertex in adjacency.keys():
		if not visited.has(start_vertex):
			var component = bfs_component(start_vertex, adjacency, visited)
			if component.size() > largest_component.size():
				largest_component = component
	
	# Create mapping from old vertex indices to new ones
	var vertex_map = {}
	var new_idx = 0
	for old_idx in largest_component:
		vertex_map[old_idx] = new_idx
		new_idx += 1
	
	return vertex_map

func get_all_nodes(node: Node) -> Array:
	var nodes := []
	nodes.append(node)
	for child in node.get_children():
		nodes += get_all_nodes(child)
	return nodes

func get_structure_type(node: Node) -> String:
	var name = node.name.to_lower()
	if name.find("tower") != -1:
		return "tower"
	elif name.find("core") != -1:
		return "core"
	# Could add gates and other map-structures here -- cmkrist 2/12/25
	else:
		return "unknown"

func get_team(node: Node) -> int:
	var groups := node.get_groups()
	if "team1" in groups:
		return 1
	elif "team2" in groups:
		return 2
	else:
		return 0

### === Export Functions === ###
func export_navmesh_obj(scene: NavigationRegion3D, scene_name: String) -> void:
	print("Exporting navmesh data to OBJ format")
	if scene is not NavigationRegion3D:
		push_warning("Scene is not a NavigationRegion3D")
		return
	
	var navmesh : NavigationMesh = scene.navigation_mesh
	var vertices = navmesh.get_vertices()
	var used_vertices = {}
	var polygons = []
	
	# Collect all polygons and their vertex indices
	for i in range(navmesh.get_polygon_count()):
		var polygon = navmesh.get_polygon(i)
		if polygon.size() > 0:
			polygons.append(polygon)
			for index in polygon:
				used_vertices[index] = true
	
	# Filter out island navmeshes - keep only the largest connected component
	var vertex_map = filter_islands(vertices, polygons, used_vertices)
	
	# Create remapped vertex list with full 3D coordinates
	var remapped_vertices = []
	var vertex_list = []
	for old_idx in vertex_map.keys():
		var vertex = vertices[old_idx]
		vertex_list.append(vertex)
	
	# Remap polygon indices
	var remapped_polygons = []
	for polygon in polygons:
		var remapped_polygon = []
		var valid = true
		for old_idx in polygon:
			if vertex_map.has(old_idx):
				remapped_polygon.append(vertex_map[old_idx])
			else:
				valid = false
				break
		if valid:
			remapped_polygons.append(remapped_polygon)
	
	# Write OBJ file
	var file = FileAccess.open("res://data/maps/%s.nav.obj" % scene_name, FileAccess.WRITE)
	if file:
		# Write OBJ header
		file.store_string("# OpenChamp Navigation Mesh\n")
		file.store_string("# Scene: %s\n" % scene_name)
		file.store_string("# Vertices: %d\n" % vertex_list.size())
		file.store_string("# Faces: %d\n" % remapped_polygons.size())
		file.store_string("\n")
		
		# Write vertices
		for vertex in vertex_list:
			file.store_string("v %.6f %.6f %.6f\n" % [vertex.x, vertex.y, vertex.z])
		
		file.store_string("\n")
		
		# Write faces (OBJ indices are 1-based)
		for polygon in remapped_polygons:
			var face_indices = []
			for index in polygon:
				face_indices.append(str(index + 1))
			file.store_string("f %s\n" % " ".join(face_indices))
		
		file.close()
		print("Navmesh exported to res://data/maps/%s.nav.obj" % scene_name)
		print("Polygons: %d, Vertices: %d" % [remapped_polygons.size(), vertex_list.size()])
	else:
		push_error("Failed to open OBJ file for writing.")

func export_map_to_xml(scene_name: String, map_data: Dictionary) -> String:
	var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
	xml += "<map\n"
	xml += "\txmlns=\"https://open-champ.com/mySchema\"\n"
	xml += "\txmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n"
	xml += "\txsi:schemaLocation=\"https://open-champ.com/mySchema ./maps/_map.xsd\"\n"
	xml += "\tid=\"%s\"\n" % scene_name
	xml += ">\n"
	xml += export_structures_xml(map_data.get("structures", []))
	xml += export_spawn_points_xml(map_data.get("spawn_points", []))
	
	xml += "</map>\n"
	return xml

func export_structures_xml(structures: Array) -> String:
	var xml = "\t<structures>\n"
	
	for structure in structures:
		xml += "\t\t<structure\n"
		xml += "\t\t\tid=\"%s\"\n" % structure["name"]
		xml += "\t\t\ttype=\"%s\"\n" % structure["type"]
		xml += "\t\t\tteam=\"%d\"\n" % structure["team"]
		xml += "\t\t>\n"
		
		# Position
		var pos = structure["position"]
		xml += "\t\t\t<position x=\"%.3f\" y=\"%.3f\" z=\"%.3f\" />\n" % [pos[0], pos[1], pos[2]]
		
		# Rotation
		var rot = structure["rotation"]
		xml += "\t\t\t<rotation x=\"%.3f\" y=\"%.3f\" z=\"%.3f\" />\n" % [rot[0], rot[1], rot[2]]
		
		# Scale
		var scale = structure["scale"]
		xml += "\t\t\t<scale x=\"%.3f\" y=\"%.3f\" z=\"%.3f\" />\n" % [scale[0], scale[1], scale[2]]
		
		xml += "\t\t</structure>\n"
	
	xml += "\t</structures>\n"
	return xml

func export_spawn_points_xml(spawn_points: Array) -> String:
	var xml = "\t<spawn_points>\n"
	
	for spawn in spawn_points:
		xml += "\t\t<spawn\n"
		xml += "\t\t\tid=\"%s\"\n" % spawn["name"]
		xml += "\t\t\tteam=\"%d\"\n" % spawn["team"]
		xml += "\t\t>\n"
		
		# Position
		var pos = spawn["position"]
		xml += "\t\t\t<position x=\"%.3f\" y=\"%.3f\" z=\"%.3f\" />\n" % [pos[0], pos[1], pos[2]]
		
		# Rotation (direction the spawn points toward)
		var rot = spawn["rotation"]
		xml += "\t\t\t<rotation x=\"%.3f\" y=\"%.3f\" z=\"%.3f\" />\n" % [rot[0], rot[1], rot[2]]
		
		xml += "\t\t</spawn>\n"
	
	xml += "\t</spawn_points>\n"
	return xml
