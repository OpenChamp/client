extends Object

var _property_order: int = 1000

func _add_project_setting(name: String, type: int, default, hint = null, hint_string = null) -> void:
	if not ProjectSettings.has_setting(name):
		ProjectSettings.set_setting(name, default)
	
	ProjectSettings.set_initial_value(name, default)
	ProjectSettings.set_order(name, _property_order)
	
	_property_order += 1
	
	var info := {
		name = name,
		type = type,
	}
	if hint != null:
		info['hint'] = hint
	if hint_string != null:
		info['hint_string'] = hint_string
	
	ProjectSettings.add_property_info(info)

func add_project_settings() -> void:
	_add_project_setting('network/rollback/max_buffer_size', TYPE_INT, 20, PROPERTY_HINT_RANGE, "1, 60")
	_add_project_setting('network/rollback/ticks_to_calculate_advantage', TYPE_INT, 60, PROPERTY_HINT_RANGE, "1, 600")
	_add_project_setting('network/rollback/input_delay', TYPE_INT, 2, PROPERTY_HINT_RANGE, "0, 10")
	_add_project_setting('network/rollback/ping_frequency', TYPE_FLOAT, 1.0, PROPERTY_HINT_RANGE, "0.01, 5.0")
	_add_project_setting('network/rollback/interpolation', TYPE_BOOL, false)
	
	_add_project_setting('network/rollback/limits/max_input_frames_per_message', TYPE_INT, 5, PROPERTY_HINT_RANGE, "0, 60")
	_add_project_setting('network/rollback/limits/max_messages_at_once', TYPE_INT, 2, PROPERTY_HINT_RANGE, "0, 10")
	_add_project_setting('network/rollback/limits/max_ticks_to_regain_sync', TYPE_INT, 300, PROPERTY_HINT_RANGE, "0, 600")
	_add_project_setting('network/rollback/limits/min_lag_to_regain_sync', TYPE_INT, 5, PROPERTY_HINT_RANGE, "0, 60")
	_add_project_setting('network/rollback/limits/max_state_mismatch_count', TYPE_INT, 10, PROPERTY_HINT_RANGE, "0, 60")
	
	_add_project_setting('network/rollback/spawn_manager/reuse_despawned_nodes', TYPE_BOOL, false)
	_add_project_setting('network/rollback/sound_manager/default_sound_bus', TYPE_STRING, "Master")
	
	_add_project_setting('network/rollback/classes/network_adaptor', TYPE_STRING, "", PROPERTY_HINT_FILE, "*.gd")
	_add_project_setting('network/rollback/classes/message_serializer', TYPE_STRING, "", PROPERTY_HINT_FILE, "*.gd")
	
	_add_project_setting('network/rollback/debug/rollback_ticks', TYPE_INT, 0, PROPERTY_HINT_RANGE, "0, 60")
	_add_project_setting('network/rollback/debug/random_rollback_ticks', TYPE_INT, 0, PROPERTY_HINT_RANGE, "0, 60")
	_add_project_setting('network/rollback/debug/message_bytes', TYPE_INT, 0, PROPERTY_HINT_RANGE, "0, 2048")
	_add_project_setting('network/rollback/debug/skip_nth_message', TYPE_INT, 0, PROPERTY_HINT_RANGE, "0, 60")
	_add_project_setting('network/rollback/debug/physics_process_msecs', TYPE_FLOAT, 10.0, PROPERTY_HINT_RANGE, "0.0, 60.0")
	_add_project_setting('network/rollback/debug/process_msecs', TYPE_FLOAT, 10.0, PROPERTY_HINT_RANGE, "0.0, 60.0")
	_add_project_setting('network/rollback/debug/check_message_serializer_roundtrip', TYPE_BOOL, false)
	_add_project_setting('network/rollback/debug/check_local_state_consistency', TYPE_BOOL, false)
	_add_project_setting('network/rollback/debug/use_sync_debugger', TYPE_BOOL, false)
	
	_add_project_setting('network/rollback/log_inspector/replay_match_scene_path', TYPE_STRING, "", PROPERTY_HINT_FILE, "*.tscn,*.scn")
	_add_project_setting('network/rollback/log_inspector/replay_match_scene_method', TYPE_STRING, 'setup_match_for_replay')
	_add_project_setting('network/rollback/log_inspector/replay_arguments', TYPE_STRING, 'replay')
	_add_project_setting('network/rollback/log_inspector/replay_port', TYPE_INT, 49111)
