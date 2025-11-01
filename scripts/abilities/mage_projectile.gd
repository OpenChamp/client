extends Projectile
class_name MageProjectile

func _setup():
	# == Projectile Setting ==#
	lockon = true
	speed *= 1.2
	# == Effect Setup == #
	effect.duration = 0.5
	effect.strength = 2.0
	effect.type = Effect.Type.SLOW
