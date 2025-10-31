extends OC_Entity
class_name Minion_Mage

@export var team := 1
func _ready() -> void:
	print("I'M ALIVE")
	if Util.dedicated_server:
		get_tree().create_timer(10.0).timeout.connect(func():queue_free())
# Server
func _physics_process(delta: float) -> void:
	pass

# Client
func _process(delta: float) -> void:
	if Util.dedicated_server:return;
	# Client-side move closer to server position
	var direction = server_pos - position
	var distance = direction.length()
	if distance > 2:
		# Desynced from server, fix pos
		direction = direction.normalized()
		var move_amount = min(distance, MoveSpeed * delta)
		position += direction * move_amount
