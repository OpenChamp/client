extends AnimationPlayer
class_name NetworkAnimationPlayer

@export var auto_reset: bool = true

func _ready() -> void:
	callback_mode_method = AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE
	callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	add_to_group('network_sync')

func _network_process(input: Dictionary) -> void:
	if is_playing():
		advance(SyncManager.tick_time)

func _save_state() -> Dictionary:
	if is_playing() and (not auto_reset or current_animation != 'RESET'):
		return {
			is_playing = true,
			current_animation = current_animation,
			current_position = current_animation_position,
			current_speed = speed_scale,
		}
	else:
		return {
			is_playing = false,
			current_animation = '',
			current_position = 0.0,
			current_speed = 1
		}

func _load_state(state: Dictionary) -> void:
	if state['is_playing']:
		if not is_playing() or current_animation != state['current_animation']:
			play(state['current_animation'])
		seek(state['current_position'], true)
		speed_scale = state['current_speed']
	elif is_playing():
		if auto_reset and has_animation("RESET"):
			play("RESET")
		else:
			stop()
