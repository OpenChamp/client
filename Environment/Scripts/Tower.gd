extends StaticBody3D

@export var team:int
@export var Health = 1000;

signal GameOver(team)
# Called when the node enters the scene tree for the first time.
func _ready():
	if team == 1:
		get_node("Towercrystal").set_surface_override_material(0, load("res://Environment/Materials/Blue.material"))
	elif team == 2:
		get_node("Towercrystal").set_surface_override_material(0, load("res://Environment/Materials/Red.material"))
	pass # Replace with function body.
	# Set Health
	$Healthbar.max_value = Health
	$Healthbar.value = Health

func _process(delta):
	$Healthbar.sync(Health)


func TakeDamage(amt):
	Health -= amt;
	$Healthbar.value -= amt;
	if Health <= 0:
		hide()
		emit_signal("GameOver", team)
