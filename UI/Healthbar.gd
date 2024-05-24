extends ProgressBar

var camera : Camera3D

func _ready():
	camera = get_viewport().get_camera_3d()
	hide()
	
func _process(_delta):
	if(value < max_value):
		show()
	else:
		hide();

func update_loc(player_position: Vector3):
	if value < max_value && !value <= 0:
		show()
		var viewport = get_viewport()
			
		if camera:
			var screen_pos = camera.unproject_position(player_position)
			var screen_size = viewport.get_visible_rect().size
			var bar_pos = Vector2(screen_pos.x - 50, screen_pos.y - 50)
			# Adjust the offset (e.g., -50) to position the health bar above the player
			# You might need to tweak this value based on your game's camera settings
			set_position(bar_pos)
	else:
		hide()
