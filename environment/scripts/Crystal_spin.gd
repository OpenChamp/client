extends MeshInstance3D

# Movement and rotation parameters
var move_speed: float = 2.0 # Speed of the up and down movement
var move_amplitude: float = .5 # Amplitude of the up and down movement
var rotation_speed: float = 1.0 # Speed of the rotation

# Initial position
var initial_position: Vector3

func _ready():
	# Store the initial position of the MeshInstance3D
	initial_position = global_transform.origin

func _process(delta: float):
	# Update the position to move up and down
	var new_y = initial_position.y + move_amplitude * sin(Time.get_ticks_msec() / 1000.0 * move_speed)
	var new_position = Vector3(initial_position.x, new_y, initial_position.z)
	global_transform.origin = new_position
	
	# Update the rotation
	rotate_y(delta * rotation_speed)
