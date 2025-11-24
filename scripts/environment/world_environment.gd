extends WorldEnvironment

@export var day_duration_seconds: float = 120.0 # Time for one full day (2 minutes)
@onready var sun_light: DirectionalLight3D = $DirectionalLight3D
@onready var world_environment: WorldEnvironment = self
var time_of_day_degrees: float = 0.0 # 0 to 360 degrees for a full cycle

# Constants for common light properties (adjust as needed)
const DAY_ENERGY = 1.0
const NIGHT_ENERGY = 0.05
const MOON_ENERGY = 0.3 # Energy for the 'moon' light

var speed : float

func _ready():
	speed = 360/day_duration_seconds
	
func _process(delta: float):
	sun_light.rotation_degrees.x += speed * delta
	# 2. Adjust Light Intensity (Sun/Moon)
	var light_angle = sun_light.rotation.x
	var light_intensity: float
	
	if light_angle > 0.0 and light_angle < PI: # Roughly day time
		# Interpolate between max day energy and moon energy (or 0) for sunset/rise
		light_intensity = lerp(NIGHT_ENERGY, DAY_ENERGY, sin(light_angle))
		sun_light.light_color = Color.WHITE
	else: # Roughly night time
		# Treat this phase as the moon/night light
		light_intensity = MOON_ENERGY
		# Give the 'moon' light a blue tint
		sun_light.light_color = Color(0.5, 0.6, 1.0) 

	sun_light.light_energy = light_intensity

	# 3. Animate the Sky Material Properties
	var sky_mat = world_environment.environment.sky.sky_material
	if sky_mat is PhysicalSkyMaterial:
		var day_factor = max(0.0, light_intensity / DAY_ENERGY)
		sky_mat.energy_multiplier = lerp(0.0, 1.0, day_factor)
