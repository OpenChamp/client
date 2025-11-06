extends Button

@export var health: SpinBox;
@export var max_health: SpinBox;
@export var healthbar: Healthbar;

func _ready():
	assert(health != null);
	assert(max_health != null);
	assert(healthbar != null);
	pressed.connect(_on_pressed)

func _on_pressed():
	
	var hp: float = health.value;
	var mhp: float = max_health.value;
	hp = clamp(hp, 0.0, mhp);
	
	healthbar.set_health(hp);
	healthbar.set_max_health(mhp);
