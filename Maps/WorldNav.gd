extends NavigationRegion3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_turret_tree_exited():
	bake_navigation_mesh()
	pass # Replace with function body.
