extends StaticBody3D

@export var Team : int = 0
@export var blue_color : Color
@export var red_color : Color
const TotalHP = 1000
@onready var CurrentHP : float = TotalHP

func _ready() -> void:
	var color :Vector4 = (func() -> Vector4:
		if Team == 1:
			return Vector4(blue_color.r, blue_color.g, blue_color.b, blue_color.a)
		else:
			return Vector4(red_color.r, red_color.g, red_color.b, red_color.a)
		).call()
	$Core.set_instance_shader_parameter("team_color", color)
	$MinorCrystals.set_instance_shader_parameter("team_color", color)
	$Portal_Banners.set_instance_shader_parameter("team_color", color)

	# Listeners
	#$Vision.body_entered.connect(_on_body_entered_range)
	
	# $AnimationPlayer.play("idle", -1, .5)

func _on_body_entered_range():
	pass;

@rpc("authority")
func _take_damage(dmg:float):
	CurrentHP -= dmg
	if CurrentHP <= 0:
		die()
		
func die():
	queue_free()
