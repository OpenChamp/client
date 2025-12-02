@tool
class_name MapExporter
extends EditorScript

### === Constants === ###
const spawn_groups = ["minion_spawn", "player_spawn"]
const structure_groups = ["tower", "core"]


func _run():
	parse_scene_to_map()
	pass;
	
func parse_scene_to_map():
	print("Parsing scene to map");
	# Get current scene
	var current_scene = EditorInterface.get_edited_scene_root()
	if current_scene == null:
		print("No scene is currently open.")
		return
	var nodes = get_all_nodes(current_scene)
	print("Total nodes in scene: %d" % nodes.size())
	var map_data = {}

	# Get scene name for output
	var scene_name = current_scene.name.to_lower()

	# Export Navmesh Data
	var navmesh_data = export_navmesh(current_scene)
	map_data["navmesh"] = navmesh_data

	# Export Structure Data
	var structure_data = []
	for child in nodes:
		if child is StaticBody3D and child.get_groups().has("structure"):
			var structure_info = {}
			structure_info["name"] = child.name
			structure_info["team"] = get_team(child)
			# Structure type is XML Template ID based on groups
			structure_info["type"] = get_structure_type(child)
			structure_info["position"] = [child.transform.origin.x, child.transform.origin.y, child.transform.origin.z]
			structure_info["rotation"] = [child.transform.basis.get_euler().x, child.transform.basis.get_euler().y, child.transform.basis.get_euler().z]
			structure_info["scale"] = [child.transform.basis.get_scale().x, child.transform.basis.get_scale().y, child.transform.basis.get_scale().z]
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
				spawn_info["position"] = [child.transform.origin.x, child.transform.origin.y, child.transform.origin.z]
				# Spawns should point towards their goal -- cmkrist 2/12/2025
				spawn_info["rotation"] = [child.transform.basis.get_euler().x, child.transform.basis.get_euler().y, child.transform.basis.get_euler().z]
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

func export_navmesh(scene) -> Dictionary:
	print("Exporting navmesh data")
	var navmesh_info = {}
	# Check if the scene has a NavigationRegion3D
	if scene is NavigationRegion3D:
		var navmesh : NavigationMesh = scene.navigation_mesh
		navmesh_info["vertices"] = []
		navmesh_info["indices"] = []
		# Extract vertices
		for vertex in navmesh.get_vertices():
			navmesh_info["vertices"].append([vertex.x, vertex.y, vertex.z])
		# Extract indices
		for i in range(navmesh.get_polygon_count()):
			var polygon = navmesh.get_polygon(i)
			for index in polygon:
				navmesh_info["indices"].append(index)

	return navmesh_info

### === Helper Functions === ###

func get_all_nodes(node: Node) -> Array:
	var nodes := []
	nodes.append(node)
	for child in node.get_children():
		nodes += get_all_nodes(child)
	return nodes

func get_structure_type(node: Node) -> String:
	var name = node.name.to_lower()
	if name.find("tower") != -1:
		return "structure_tower"
	elif name.find("core") != -1:
		return "structure_core"
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

### === XML Export Functions === ###

func export_map_to_xml(scene_name: String, map_data: Dictionary) -> String:
	var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
	xml += "<map\n"
	xml += "\txmlns=\"https://open-champ.com/mySchema\"\n"
	xml += "\txmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n"
	xml += "\txsi:schemaLocation=\"https://open-champ.com/mySchema ./maps/_map.xsd\"\n"
	xml += "\tid=\"%s\"\n" % scene_name
	xml += ">\n"
	
	# Export Navmesh
	xml += export_navmesh_xml(map_data.get("navmesh", {}))
	
	# Export Structures
	xml += export_structures_xml(map_data.get("structures", []))
	
	# Export Spawn Points
	xml += export_spawn_points_xml(map_data.get("spawn_points", []))
	
	xml += "</map>\n"
	return xml

func export_navmesh_xml(navmesh_data: Dictionary) -> String:
	var xml = "\t<navmesh>\n"
	
	var vertices = navmesh_data.get("vertices", [])
	var indices = navmesh_data.get("indices", [])
	
	# Export vertices
	xml += "\t\t<vertices>\n"
	for vertex in vertices:
		xml += "\t\t\t<vertex x=\"%.3f\" y=\"%.3f\" z=\"%.3f\" />\n" % [vertex[0], vertex[1], vertex[2]]
	xml += "\t\t</vertices>\n"
	
	# Export indices grouped into triangles
	xml += "\t\t<triangles>\n"
	for i in range(0, indices.size(), 3):
		if i + 2 < indices.size():
			xml += "\t\t\t<triangle v0=\"%d\" v1=\"%d\" v2=\"%d\" />\n" % [indices[i], indices[i+1], indices[i+2]]
	xml += "\t\t</triangles>\n"
	
	xml += "\t</navmesh>\n"
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
