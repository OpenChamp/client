extends OC_Entity
class_name Minion_Mage

@export var team := 1
func _ready() -> void:
	if Util.dedicated_server:
		get_tree().create_timer(10.0).timeout.connect(func():
			print("Minion ", name, " lifetime expired, cleaning up")
			queue_free()
		)
# Server
func _physics_process(delta: float) -> void:
	if Util.dedicated_server:
		move_towards_target(delta)

# Client
func _process(delta: float) -> void:
	if Util.dedicated_server:return;
	# Client-side move closer to server position
	var direction = server_pos - position
	var distance = direction.length()
	if distance > 2:
		# Desynced from server, fix pos
		direction = direction.normalized()
		look_at(direction)
		var move_amount = min(distance, MoveSpeed * delta)
		position += direction * move_amount
	else:
		move_towards_target(delta)

func move_towards_target(_delta: float) -> void:
	if target_pos == Vector3.ZERO:
		return
	if not NavAgent.is_target_reachable():
		print("Minion ", name, " target not reachable from ", position, " to ", target_pos)
		return
	var dest = NavAgent.get_next_path_position()
	var local_dest = dest - global_position
	var direction = local_dest.normalized()
	
	# Check if we've reached the destination
	if Util.dedicated_server and local_dest.length() < 1.0:
		_on_target_reached()
		return
		
	velocity = direction * MoveSpeed
	move_and_slide()
	
	# Update clients with current position
	if Util.dedicated_server:
		rpc("update_position", position)
	else:
		# Client-side position smoothing
		if (server_pos - position).length() < 1.0:
			position = server_pos

# === Server Only Functions === #
func _on_target_reached() -> void:
	if not Util.dedicated_server: 
		return
	
	print("Minion ", name, " reached target at ", position)
	# Minion has reached its destination - could attack, wait, or find new target
	# For now, just stop moving
	velocity = Vector3.ZERO
