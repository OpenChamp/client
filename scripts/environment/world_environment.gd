extends WorldEnvironment

signal new_day

@export var SecondsPerCycle: int = 60
@onready var Sun: DirectionalLight3D = $Sun
@onready var Moon: DirectionalLight3D = $Moon

var days: int = 0
var time: float = 0.0
var degrees_per_second: float = 0.0

func _ready():
	degrees_per_second = 360.0 / float(SecondsPerCycle)

func _process(delta: float) -> void:
	time += delta
	if time >= SecondsPerCycle:
		time -= SecondsPerCycle
		days += 1
		new_day.emit()
		print("New Day! Total Days: ", days)
	var current_angle_degrees: float = (time / SecondsPerCycle) * 360.0
	var new_rotation: Vector3 = Sun.rotation
	new_rotation.x = deg_to_rad(current_angle_degrees + 90.0) # Horizon Start
	Sun.rotation = new_rotation
	Moon.rotation = -new_rotation
