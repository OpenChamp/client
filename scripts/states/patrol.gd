extends State
class_name PatrolState

var path_array = [];

func enter(entity):
	for point in entity.patrol_path.get_children():
		path_array.append(point)
	
