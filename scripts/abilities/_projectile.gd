extends RigidBody3D
class_name Projectile

# === Movement Config === #
var direction: Vector3 = Vector3.ZERO
var spawn_pos: Vector3 = Vector3.ZERO
var speed: float = 4.0
# === Targeting Config === #
var lockon : bool = false
var target_node: OC_Entity
var lifetime : float = 3.0
# === Ownership Config === #
var team: int
var creator: OC_Entity
# === Effect & Damage Properties === #
var damage: float = 10.0
var effect: Effect = Effect.new()

func _ready(pos: Vector3 = spawn_pos) -> void:
	global_position = pos
	if target_node:
		if target_node.Team == team:
			print("Targeting Teammate")
			queue_free()
	body_entered.connect(_on_body_entered_hitbox)
	target_node.died.connect(queue_free)
	if direction != Vector3.ZERO:
		linear_velocity = direction * speed
	else:
		print("Warning: Projectile created with zero direction!")
		queue_free()
	if Util.dedicated_server:
		if pos == Vector3.ZERO: queue_free();
	_setup()
	
func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0: 
		queue_free()
	rotate_y(delta * 5.0)
	
	if lockon and is_instance_valid(target_node):
		var distance_to_target = global_position.distance_to(target_node.global_position)
		if distance_to_target > 0.5:
			var direction_to_target = (target_node.global_position - global_position).normalized()
			linear_velocity = direction_to_target * speed

func _setup():
	print("Projectile Setup called on base class... ");

func _on_body_entered_hitbox(body: Node3D) -> void:
	if body.is_in_group(str("team", team)): return;
	hit(body)

func hit(entity:Node3D):
	if not Util.dedicated_server:
		_create_hit_effect();
		return;
	if not entity.has_method("take_damage"):
		queue_free()
	entity.take_damage.rpc(int(damage))
	if entity is OC_Entity:
		entity.apply_effect(effect)
	queue_free()

	
func _create_hit_effect():
	$MeshInstance3D.hide()
	if has_node("AudioStreamPlayer3D"):
		$AudioStreamPlayer3D.finished.connect(queue_free)
		$AudioStreamPlayer3D.play()
