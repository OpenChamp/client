extends Node3D

@export var team:int
@export var range = 5
@export var shoot_interval: float = 1.0
@export var bullet_speed: float = 40.0
@export var projectile: PackedScene 
@export var attack = 100
@export var target: CharacterBody3D = null

# Called when the node enters the scene tree for the first time.
func _ready():
	if team == 1:
		get_node("Crystal").set_surface_override_material(0, load("res://Environment/Materials/Blue.material"))
	elif team == 2:
		get_node("Crystal").set_surface_override_material(0, load("res://Environment/Materials/Red.material"))
	
	$RangeArea.body_entered.connect(self._on_RangeArea_body_entered)
	$RangeArea.body_exited.connect(self._on_RangeArea_body_exited)
	$ShootTimer.wait_time = shoot_interval
	$ShootTimer.timeout.connect(self._on_ShootTimer_timeout)
	
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_RangeArea_body_entered(body: CharacterBody3D):
	if body.team != self.team:
		target = body
		print("enemy detected")
		$ShootTimer.start()
	pass
	
func _on_RangeArea_body_exited(body: CharacterBody3D):
	if body == target:
		target = null
		$ShootTimer.stop()
	pass
	
func _on_ShootTimer_timeout():
	Attack()
	pass
	
func _process(delta):
	pass
	
func _enemy_in_range(Archer):
	pass
	
func Attack():
	var Arrow = projectile.instantiate()
	get_parent().add_child(Arrow)
	Arrow.position = position
	Arrow.target = self.target
	Arrow.damage = attack
	get_node("/root").add_child(Arrow)
	pass
