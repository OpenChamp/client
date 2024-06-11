extends Node3D

@onready var particles: GPUParticles3D = $GPUParticles3D
@onready var mesh : MeshInstance3D = $Marker
var hasPlayed = false
var attack_move : bool

func _ready():
	hide()
	particles.one_shot = true
	$AnimationPlayer.current_animation = "shrink_ring"
	$AnimationPlayer.animation_finished.connect(stop)

func play():
	show()
	$AnimationPlayer.stop()
	var meshmaterial : StandardMaterial3D = mesh.get_active_material(0)
	if attack_move:
		meshmaterial.albedo_color = Color(255,0,0)
	else:
		meshmaterial.albedo_color = Color(0,255,0)
		$AnimationPlayer.play()

func stop(_anim_name):
	print("Stopped");
	hide();
