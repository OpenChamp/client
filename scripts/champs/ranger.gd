extends Creature
class_name Ranger

# var debug_target_indicator: MeshInstance3D
#
# func _ready() -> void:
	# debug_target_indicator = MeshInstance3D.new()
	# debug_target_indicator.mesh = SphereMesh.new()
	# get_parent().add_child(debug_target_indicator)
	# set_process(true)
	#
## Server
# func _physics_process(delta: float) -> void:
	# if Util.dedicated_server:
		# move_towards_target(delta)
#
## Client
# func _process(delta: float) -> void:
	# if Util.dedicated_server:
		# return
	## Client-side move closer to server position
	# var direction = server_pos - position
	# var distance = direction.length()
	# if distance > 2:
		## Desynced from server, fix pos
		# direction = direction.normalized()
		# look_at(direction)
		# var move_amount = min(distance, stats.move_speed * delta)
		# position += direction * move_amount
	# else:
		# move_towards_target(delta)
	# if debug_target_indicator:
		# debug_target_indicator.global_position = target_pos
#
# func move_towards_target(_delta: float) -> void:
	# if target_pos == Vector3.ZERO:
		# return
	# if not nav_agent.is_target_reachable():
		# print(position)
		# print(target_pos)
		# print("Target is not reachable!")
		# return
	# var dest = nav_agent.get_next_path_position()
	# var local_dest = dest - global_position
	# var direction = local_dest.normalized()
	# if Util.dedicated_server and (local_dest - position).length() < 1:
		# _on_target_reached()
		# return
	# velocity = direction * move_speed
	# move_and_slide()
	## Update clients with current position
	# if Util.dedicated_server:
		# rpc("update_position", position)
	# else:
		# if 1 > (server_pos - position).length():
			# position = server_pos
#
## === Server Only Functions === #
# func _on_target_reached() -> void:
	# if not Util.dedicated_server: return